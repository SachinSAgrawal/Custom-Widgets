//
//  WeatherWidget.swift
//  CustomWidgets
//
//  Created by Sachin Agrawal on 6/24/24.
//

import WidgetKit
import SwiftUI
import Charts
import MapKit
import CoreLocation
import Combine
import AppIntents

enum TemperatureUnit: String, AppEnum {
    case celsius = "metric"
    case fahrenheit = "imperial"
    
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Temperature Unit")
    
    static var caseDisplayRepresentations: [TemperatureUnit: DisplayRepresentation] = [
        .celsius: DisplayRepresentation(title: "Celsius"),
        .fahrenheit: DisplayRepresentation(title: "Fahrenheit")
    ]
}

struct UnitAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Weather"
    static var description = IntentDescription("Use Celsius/Fahrenheit or a custom location for the weather.")
    
    @Parameter(title: "Temperature Unit", default: .fahrenheit)
    var temperatureUnit: TemperatureUnit
    
    @Parameter(title: "Custom Location", default: false)
    var useCustomLocation: Bool

    @Parameter(title: "Latitude", default: 40.7)
    var latitude: Double?

    @Parameter(title: "Longitude", default: -74)
    var longitude: Double?
    
    @Parameter(title: "OpenWeatherMap", default: "API Key")
    var apiKey: String
}

class WidgetLocationManager: NSObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager?
    private var handler: ((CLLocation) -> Void)?

    override init() {
        super.init()
        DispatchQueue.main.async {
            self.checkLocationServices()
        }
    }
    
    private func checkLocationServices() {
        if CLLocationManager.locationServicesEnabled() {
            self.locationManager = CLLocationManager()
            self.locationManager?.delegate = self
        } else {
            print("Location services are not enabled")
        }
    }
    
    private func checkLocationAuthorization() {
        guard let locationManager = locationManager else { return }
        
        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted, .denied:
            print("Location authorization restricted or denied")
        case .authorizedWhenInUse, .authorizedAlways:
            print("Check Authorization: \(locationManager.location!.coordinate)")
            
            let latitude = locationManager.location!.coordinate.latitude
            let longitude = locationManager.location!.coordinate.longitude
            
            UserDefaults.standard.setValue(latitude, forKey: "latitude")
            UserDefaults.standard.setValue(longitude, forKey: "longitude")
        @unknown default:
            print("Unknown location authorization status")
        }
    }

    func fetchLocation(handler: @escaping (CLLocation) -> Void) {
        self.handler = handler
        guard let locationManager = self.locationManager else {
            print("Location manager is not initialized")
            return
        }
        
        if locationManager.authorizationStatus == .authorizedWhenInUse || locationManager.authorizationStatus == .authorizedAlways {
            locationManager.requestLocation()
        } else {
            print("Location services are not authorized")
        }
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            self.handler?(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
    }
}

class NetworkService {
    static let shared = NetworkService()
    
    func fetchDailyForecast(latitude: Double, longitude: Double, temperatureUnit: TemperatureUnit, apiKey: String, completion: @escaping (Result<WeatherResponse, Error>) -> Void) {
        
        let baseURL = "https://api.openweathermap.org/data/3.0/onecall?exclude=minutely,hourly,alerts"
        
        let rawKey = apiKey.isEmpty ? "tokenMustBeSetUsingConfigIntent" : apiKey
        let key = rawKey
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .joined()
        
        let urlString = "\(baseURL)&lat=\(latitude)&lon=\(longitude)&appid=\(key)&units=\(temperatureUnit.rawValue)"
        
        print(urlString)
        
        guard let url = URL(string: urlString) else {
            completion(.failure(NetworkError.invalidURL))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NetworkError.noData))
                return
            }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .secondsSince1970
                let forecast = try decoder.decode(WeatherResponse.self, from: data)
                completion(.success(forecast))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

enum NetworkError: Error {
    case invalidURL
    case noData
}

struct WeatherResponse: Codable {
    let timezone: String
    let daily: [Daily]
    let current: Current
}

struct Daily: Codable, Equatable, Hashable {
    let dt: Int
    let temp: Temperature
    let weather: [Conditions]
    let pop: Double
}

struct Temperature: Codable, Equatable, Hashable {
    let morn: Double
    let day: Double
    let eve: Double
    let night: Double
    let min: Double
    let max: Double
}

struct Conditions: Codable, Equatable, Hashable {
    let icon: String
}

struct Current: Codable, Equatable, Hashable {
    let temp: Double
    let weather: [Condition]
}

struct Condition: Codable, Equatable, Hashable {
    let description: String
}

class WeatherProvider: AppIntentTimelineProvider {
    typealias Intent = UnitAppIntent
    
    func placeholder(in context: Context) -> WeatherEntry {
        WeatherEntry(date: Date(), dailyForecasts: Array(repeating: Daily(dt: 0, temp: Temperature(morn: 0, day: 0, eve: 0, night: 0, min: 0, max: 0), weather: [Conditions(icon: "unknown")], pop: 0), count: 4), currentWeather: Current(temp: 0, weather: [Condition(description: "placeholder")]))
    }

    func snapshot(for configuration: UnitAppIntent, in context: Context) async -> WeatherEntry {
        let entry = WeatherEntry(date: Date(), dailyForecasts: Array(repeating: Daily(dt: 0, temp: Temperature(morn: 0, day: 0, eve: 0, night: 0, min: 0, max: 0), weather: [Conditions(icon: "unknown")], pop: 0), count: 4), currentWeather: Current(temp: 0, weather: [Condition(description: "snapshot")]))
        return entry
    }

    var widgetLocationManager = WidgetLocationManager()
    
    func timeline(for configuration: UnitAppIntent, in context: Context) async -> Timeline<WeatherEntry> {
        return await withCheckedContinuation { continuation in
            if configuration.useCustomLocation {
                let defaultLatitude: Double = 40.7
                let defaultLongitude: Double = -74.0

                let latitude: Double = {
                    if let configLatitude = configuration.latitude {
                        return (configLatitude >= -90 && configLatitude <= 90) ? configLatitude : defaultLatitude
                    } else {
                        return defaultLatitude
                    }
                }()

                let longitude: Double = {
                    if let configLongitude = configuration.longitude {
                        return (configLongitude >= -180 && configLongitude <= 180) ? configLongitude : defaultLongitude
                    } else {
                        return defaultLongitude
                    }
                }()
                
                UserDefaults.standard.setValue(latitude, forKey: "latitude")
                UserDefaults.standard.setValue(longitude, forKey: "longitude")
                
                let currLocation = String(format: "Location: %.2f, %.2f", latitude, longitude)
                print(currLocation)
                
                let location = CLLocation(latitude: latitude, longitude: longitude)
                location.fetchLocationDetails { locality, administrativeArea, country, error in
                    guard let locality = locality, let administrativeArea = administrativeArea, let country = country, error == nil else { return }
                    
                    let locationStringWithoutCountry = locality + ", " + administrativeArea
                    let locationStringWithCountry = locationStringWithoutCountry + ", " + country

                    let locationString = locationStringWithCountry.count > 24 ? locationStringWithoutCountry : locationStringWithCountry

                    UserDefaults.standard.setValue(locationString, forKey: "location")
                    print(locationString)
                }
            } else {
                widgetLocationManager.fetchLocation { location in
                    let latitude = location.coordinate.latitude
                    let longitude = location.coordinate.longitude
                    
                    UserDefaults.standard.setValue(latitude, forKey: "latitude")
                    UserDefaults.standard.setValue(longitude, forKey: "longitude")
                    
                    let currLocation = String(format: "Location: %.2f, %.2f", latitude, longitude)
                    print(currLocation)
                    
                    location.fetchLocationDetails { locality, administrativeArea, country, error in
                        guard let locality = locality, let administrativeArea = administrativeArea, let country = country, error == nil else { return }
                        
                        let locationStringWithoutCountry = locality + ", " + administrativeArea
                        let locationStringWithCountry = locationStringWithoutCountry + ", " + country
                        
                        let locationString = locationStringWithCountry.count > 24 ? locationStringWithoutCountry : locationStringWithCountry
                        
                        UserDefaults.standard.setValue(locationString, forKey: "location")
                        print(locationString)
                    }
                }
            }
            
            let latitude = UserDefaults.standard.object(forKey: "latitude") as? Double ?? 40.7
            let longitude = UserDefaults.standard.object(forKey: "longitude") as? Double ?? -74.0
            
            let temperatureUnit = configuration.temperatureUnit
            let apiKey = configuration.apiKey
        
            NetworkService.shared.fetchDailyForecast(latitude: latitude, longitude: longitude, temperatureUnit: temperatureUnit, apiKey: apiKey) { result in
                var entries: [WeatherEntry] = []
                let currentDate = Date()
                
                switch result {
                case .success(let forecast):
                    let firstFourDays = Array(forecast.daily.prefix(4))
                    let entryDate = currentDate
                    let entry = WeatherEntry(date: entryDate, dailyForecasts: firstFourDays, currentWeather: forecast.current)
                    entries.append(entry)
                    
                    if let encodedEntry = try? JSONEncoder().encode(entry) {
                        UserDefaults.standard.set(encodedEntry, forKey: "lastSuccessfulWeatherEntry")
                    }
                    
                case .failure(let error):
                    print("Failed to fetch weather data: \(error.localizedDescription)")
                    
                    if let lastSuccessfulData = UserDefaults.standard.data(forKey: "lastSuccessfulWeatherEntry"),
                       let lastSuccessfulEntry = try? JSONDecoder().decode(WeatherEntry.self, from: lastSuccessfulData) {
                        
                        let timeSinceLastUpdate = currentDate.timeIntervalSince(lastSuccessfulEntry.date)
                        
                        if timeSinceLastUpdate <= 6 * 3600 {
                            let currentWeather: Current
                            
                            if timeSinceLastUpdate > 3 * 3600 {
                                currentWeather = Current(temp: 0, weather: [Condition(description: "data outdated")])
                            } else {
                                currentWeather = lastSuccessfulEntry.currentWeather
                            }
                            
                            let entry = WeatherEntry(date: lastSuccessfulEntry.date, dailyForecasts: lastSuccessfulEntry.dailyForecasts, currentWeather: currentWeather)
                            entries.append(entry)
                        } else {
                            let entryDate = currentDate
                            let entry = WeatherEntry(date: entryDate, dailyForecasts: Array(repeating: Daily(dt: 0, temp: Temperature(morn: 0, day: 0, eve: 0, night: 0, min: 0, max: 0), weather: [Conditions(icon: "unknown")], pop: 0), count: 4), currentWeather: Current(temp: 0, weather: [Condition(description: "update failed")]))
                            entries.append(entry)
                        }
                    } else {
                        let entryDate = currentDate
                        let entry = WeatherEntry(date: entryDate, dailyForecasts: Array(repeating: Daily(dt: 0, temp: Temperature(morn: 0, day: 0, eve: 0, night: 0, min: 0, max: 0), weather: [Conditions(icon: "unknown")], pop: 0), count: 4), currentWeather: Current(temp: 0, weather: [Condition(description: "entry missing")]))
                        entries.append(entry)
                    }
                }
                
                let nextUpdate = Calendar.current.date(byAdding: DateComponents(minute: 30), to: currentDate)!
                let myTimeline = Timeline(entries: entries, policy: .after(nextUpdate))
                
                continuation.resume(returning: myTimeline)
            }
        }
    }
}

struct WeatherEntry: TimelineEntry, Codable {
    let date: Date
    let dailyForecasts: [Daily]
    let currentWeather: Current
}

struct DailyForecastView: View {
    var daily: Daily
    var minTemp: Double
    var maxTemp: Double

    var body: some View {
            VStack {
                ZStack {
                    TemperatureChartForDay(daily: daily, minTemp: minTemp, maxTemp: maxTemp)
                        .frame(height: 30)
                        .opacity(0.5)
                    
                    VStack(spacing: -1) {
                        Text("\(abbreviatedDayOfWeek(from: daily.dt))")
                            .font(.system(size: 7))
                            .textCase(.uppercase)
                        
                        Text("H: \(daily.temp.max, specifier: "%.0f")°")
                            .font(.system(size: 8, weight: .bold))
                        
                        Text("L: \(daily.temp.min, specifier: "%.0f")°")
                            .font(.system(size: 8, weight: .bold))
                        
                        Image(systemName: weatherIconMap[daily.weather[0].icon] ?? "questionmark.circle")
                            .font(.system(size: 8))
                            .frame(height: 14)
                        
                        Divider()
                            .frame(height: 0.5)
                            .overlay(.white)
                    }
                }
                
                HStack(spacing: 1) {
                    let raindropCount = Int(daily.pop * 5)
                    ForEach(0..<raindropCount, id: \.self) { _ in
                        Image(systemName: "drop.fill")
                            .font(.system(size: 5))
                    }
                    ForEach(0..<(5 - raindropCount), id: \.self) { _ in
                        Image(systemName: "drop")
                            .font(.system(size: 5))
                    }
                }
            }
    }

    func abbreviatedDayOfWeek(from timestamp: Int) -> String {
        let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE"
        return dateFormatter.string(from: date)
    }
}

struct TemperatureChartForDay: View {
    var daily: Daily
    var minTemp: Double
    var maxTemp: Double

    var body: some View {
        let data = [
            (time: "9am", temperature: daily.temp.morn),
            (time: "1pm", temperature: daily.temp.day),
            (time: "5pm", temperature: daily.temp.eve),
            (time: "9pm", temperature: daily.temp.night)
        ]
        
        return Chart {
            ForEach(data, id: \.time) { point in
                LineMark(
                    x: .value("Time", point.time),
                    y: .value("Temperature", point.temperature)
                )
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .frame(height: 30)
        .chartYScale(domain: minTemp...maxTemp)
    }
}
 
struct WeatherWidgetEntryView : View {
    var entry: WeatherProvider.Entry

    var body: some View {
        let temps = entry.dailyForecasts.flatMap { [$0.temp.morn, $0.temp.day, $0.temp.eve, $0.temp.night] }
        let minTemp = temps.min() ?? 0
        let maxTemp = temps.max() ?? 0
        
        VStack(spacing: 0) {
            let latitude = UserDefaults.standard.object(forKey: "latitude") as? Double ?? 40.7
            let longitude = UserDefaults.standard.object(forKey: "longitude") as? Double ?? -74.0
            let currLocation = UserDefaults.standard.object(forKey: "location") as? String ?? "New York, NY, US"
            
            let locationString = String(format: "%.2f, %.2f", latitude, longitude)
            
            HStack {
                Text(currLocation)
                    .font(.system(size: 7))
                
                Spacer()
                
                Text(locationString)
                    .font(.system(size: 7))
            }
            
            HStack(spacing: 0) {
                Divider()
                    .frame(width: 0.5, height: 46)
                    .overlay(.white)
                
                ForEach(entry.dailyForecasts.prefix(4), id: \.dt) { daily in
                    DailyForecastView(daily: daily, minTemp: minTemp, maxTemp: maxTemp)
                    
                    Divider()
                        .frame(width: 0.5, height: 46)
                        .overlay(.white)
                }
            }
            
            HStack(spacing: 2) {
                Text("Current: \(entry.currentWeather.temp, specifier: "%.0f")° & \(entry.currentWeather.weather.first?.description ?? "unknown")")
                    .font(.system(size: 6))
                    .frame(width: 110, alignment: .leading)
                
                Text(entry.date, style: .timer)
                    .font(.system(size: 6))
                    .frame(width: 36)
            }
            .multilineTextAlignment(.trailing)
        }
        .foregroundColor(.white)
        .containerBackground(.white.gradient, for: .widget)
        .unredacted()
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    return formatter
}()

let weatherIconMap: [String: String] = [
    "01d": "sun.max",
    "01n": "moon",
    "02d": "cloud.sun",
    "02n": "cloud.moon",
    "03d": "cloud",
    "03n": "cloud.fill",
    "04d": "cloud",
    "04n": "cloud.fill",
    "09d": "cloud.rain",
    "09n": "cloud.rain.fill",
    "10d": "cloud.sun.rain",
    "10n": "cloud.moon.rain",
    "11d": "cloud.bolt",
    "11n": "cloud.bolt.fill",
    "13d": "snowflake",
    "13n": "snowflake",
    "50d": "cloud.fog",
    "50n": "cloud.fog.fill",
    "unknown": "questionmark.circle"
]

struct WeatherWidget: Widget {
    let kind: String = "WeatherWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: UnitAppIntent.self, provider: WeatherProvider()) { entry in
            WeatherWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Weather")
        .description("Displays the 4-day weather forecast.")
        .supportedFamilies([.accessoryRectangular])
    }
}

struct WeatherWidget_Previews: PreviewProvider {
    static var previews: some View {
        WeatherWidgetEntryView(entry: WeatherEntry(date: Date(), dailyForecasts: [
            Daily(dt: 1719676800, temp: Temperature(morn: 12, day: 28, eve: 22, night: 17, min: 20, max: 25), weather: [Conditions(icon: "09d")], pop: 0.6),
            Daily(dt: 1719763200, temp: Temperature(morn: 10, day: 30, eve: 20, night: 15, min: 20, max: 25), weather: [Conditions(icon: "10d")], pop: 0.4),
            Daily(dt: 1719849600, temp: Temperature(morn: 12, day: 22, eve: 24, night: 21, min: 20, max: 25), weather: [Conditions(icon: "01d")], pop: 0.0),
            Daily(dt: 1719936000, temp: Temperature(morn: 21, day: 28, eve: 18, night: 9, min: 20, max: 25), weather: [Conditions(icon: "03d")], pop: 0.2)
        ], currentWeather: Current(temp: -3, weather: [Condition(description: "snow")])))
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
    }
}

extension CLLocation {
    func fetchLocationDetails(completion: @escaping (_ locality: String?, _ administrativeArea: String?, _ country: String?, _ error: Error?) -> ()) {
        if let request = MKReverseGeocodingRequest(location: self) {
            request.getMapItems { mapItems, error in
                let placemark = mapItems?.first?.placemark
                completion(
                    placemark?.locality,
                    placemark?.administrativeArea,
                    placemark?.isoCountryCode,
                    error
                )
            }
        }
    }
}
