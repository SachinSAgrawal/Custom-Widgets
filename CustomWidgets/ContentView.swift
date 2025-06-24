//
//  ContentView.swift
//  CustomWidgets
//
//  Created by Sachin Agrawal on 6/24/24.
//

import SwiftUI
import CoreLocation
import MapKit
import Combine
import Network

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager?
    
    @Published var latitude: Double = 40.7
    @Published var longitude: Double = -74.0
    @Published var accuracy: Double = 0.0
    @Published var locationString: String = "Reverse Geolocation Failed"

    override init() {
        super.init()
        DispatchQueue.main.async {
            self.checkLocationServices()
        }
    }
    
    func checkLocationServices() {
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
            if locationManager.location != nil {
                updateLocationData(location: locationManager.location!)
            } else {
                loadSavedLocationData()
            }
        @unknown default:
            print("Unknown location authorization status")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        updateLocationData(location: location)
        print("On Location Updated: \(location)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
    }
    
    private func updateLocationData(location: CLLocation) {
        self.latitude = location.coordinate.latitude
        self.longitude = location.coordinate.longitude
        self.accuracy = location.horizontalAccuracy

        location.fetchMoreLocationDetails { subLocality, locality, administrativeArea, country, error in
            var addressText = ""
            if let subLocality = subLocality, !subLocality.isEmpty {
                addressText += "\(subLocality)\n"
            }
            var cityState = [String]()
            if let locality = locality, !locality.isEmpty {
                cityState.append(locality)
            }
            if let administrativeArea = administrativeArea, !administrativeArea.isEmpty {
                cityState.append(administrativeArea)
            }
            if !cityState.isEmpty {
                addressText += cityState.joined(separator: ", ") + "\n"
            }
            if let country = country, !country.isEmpty {
                addressText += country
            }
            if addressText.isEmpty {
                addressText = "Reverse Geolocation Failed"
            }
            self.locationString = addressText
        }
        
        saveLocationData()
    }
    
    private func loadSavedLocationData() {
        self.latitude = UserDefaults.standard.object(forKey: "latitude") as? Double ?? 40.7
        self.longitude = UserDefaults.standard.object(forKey: "longitude") as? Double ?? -74.0
        self.accuracy = UserDefaults.standard.object(forKey: "accuracy") as? Double ?? 0.0
        self.locationString = UserDefaults.standard.object(forKey: "location") as? String ?? "Reverse Geolocation Failed"
    }
    
    private func saveLocationData() {
        UserDefaults.standard.setValue(latitude, forKey: "latitude")
        UserDefaults.standard.setValue(longitude, forKey: "longitude")
        UserDefaults.standard.setValue(accuracy, forKey: "accuracy")
        UserDefaults.standard.setValue(locationString, forKey: "location")
    }
}

class NetworkMonitor: ObservableObject {
    private var monitor: NWPathMonitor
    private var queue = DispatchQueue.global(qos: .background)
    
    @Published var isConnected: Bool = true

    init() {
        self.monitor = NWPathMonitor()
        self.startMonitoring()
    }
    
    private func startMonitoring() {
        monitor.pathUpdateHandler = { path in
            DispatchQueue.main.async {
                self.isConnected = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
}

struct ContentView: View {
    @State private var hiddenText: String?
    @State private var selectedTab: Int = 0
    
    @StateObject private var locationManager = LocationManager()
    @StateObject private var networkMonitor = NetworkMonitor()
    
    @State private var locationCheckTimer: Timer?
    @State private var mapCoordinate: CLLocationCoordinate2D?
    
    @State private var shouldUpdateMap: Bool = true

    var body: some View {
        TabView(selection: $selectedTab) {
            VStack {
                if !networkMonitor.isConnected {
                    Image(systemName: "wifi.slash")
                        .font(.system(size: 50))
                        .padding(.bottom, 16)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                    
                    Text("No Internet Connection")
                        .font(.title2)
                        .padding(.bottom, 12)
                    
                    Text("Your device isn't connected to the internet. To view the most updated weather in the lock screen widget, turn off Airplane mode or connect to a Wi-Fi/cellular network.")
                        .multilineTextAlignment(.center)
                        .padding(.bottom, 12)
                    
                    Button(action: {
                        if let url = URL(string:"App-prefs:MOBILE_DATA_SETTINGS_ID") {
                            if UIApplication.shared.canOpenURL(url) {
                                UIApplication.shared.open(url)
                            }
                        }
                    }) {
                        Text("Go to Settings")
                            .font(.headline)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("About")
                            .font(.title)
                            .padding(.bottom, 8)
                            .padding(.top, 32)
                    
                        Text("There are 8 widgets total, 7 for your home screen and 1 for your lock screen.")
                            .padding(.bottom, 8)
                            .font(.system(size: 18))

                        Text("Audio Widget - Play and pause music directly in the background. ")
                        
                        Text("Count Widget - Interact with buttons to increment or reset a counter.")
                        
                        Text("Clock Widget - Display a clock that shows the time in various formats.")
                        
                        Text("Timer Widget - Displays the time counting down from 1 minute.")
                        
                        Text("Month Widget - Displays the current month with dates.")
                        
                        Text("Input Widget - Displays inputted text that can be deep linked.")
                        
                        Text("Image Widget - Displays a large image of Rick Astley.")
                        
                        Text("Weather Widget - Displays a fancy 4-day weather forecast on your lock screen.")
                            .padding(.bottom, 8)
                        
                        Spacer()
                    }
                    .font(.system(size: 16))
                }
            }
            .padding([.leading, .trailing], 20)
            .tag(0)
            
            VStack(alignment: .leading) {
                Text("Add Widgets")
                    .font(.title)
                    .padding(.bottom, 8)
                    .padding(.top, 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("1. From the Home Screen, touch and hold on an empty area of your screen until the apps jiggle.")
                    
                    Text("2. Tap the Edit button in the upper-left corner, the select the Add Widgets button.")
                    
                    Text("3. Scroll down to the Custom Widgets app section and select your desired widget.")
                    
                    Text("4. Add the widget, move it, then tap the Done button in the upper-right corner.")
                }
                .font(.system(size: 16))
                .padding(.bottom, 8)
                
                Image("AddWidgets")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100)
                    .cornerRadius(8)
                    .padding(.bottom, 8)
                
                Text("For more information, please visit Apple Support: https://support.apple.com/en-us/118610")
                    .font(.system(size: 16))
                
                Spacer()
            }
            .padding([.leading, .trailing], 20)
            .tag(1)
            
            VStack(alignment: .leading) {
                Text("Other")
                    .font(.title)
                    .padding(.bottom, 8)
                    .padding(.top, 32)
                
                Text("Deep Link:")
                    .padding(.bottom, 8)
                    .font(.system(size: 18))
                
                if let hiddenText = hiddenText {
                    Text(hiddenText)
                        .padding(.bottom, 8)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 16))
                } else {
                    Text("<null>")
                        .padding(.bottom, 8)
                        .multilineTextAlignment(.center)
                        .font(.system(size: 16))
                }
                
                Text("Add the Input widget to your home screen. Press and hold on the widget to edit the input text. Finally tap on the widget to have the text be deep linked to here.")
                    .padding(.bottom, 8)
                    .font(.system(size: 16))
                
                Text("App Icons:")
                    .padding(.bottom, 8)
                    .font(.system(size: 18))
                
                Text("Updated to support the new iOS 26 rendering modes, including light, dark, clear, and tinted.")
                    .padding(.bottom, 8)
                    .font(.system(size: 16))
                
                Image("IconLight")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 80)
                    .padding(.bottom, 8)

                Image("IconDark")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 80)
                    .padding(.bottom, 8)
                
                Image("IconTinted")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 80)
                    .padding(.bottom, 8)
                
                Spacer()
            }
            .padding([.leading, .trailing], 20)
            .tag(2)
            
            VStack(alignment: .leading) {
                Text("Location:")
                    .font(.title)
                    .padding(.bottom, 8)
                    .padding(.top, 32)
                
                Text(String(format: "Latitude: %.5f", locationManager.latitude))
                    .padding(.bottom, 8)
                    .font(.system(size: 16))

                Text(String(format: "Longitude: %.5f", locationManager.longitude))
                    .padding(.bottom, 8)
                    .font(.system(size: 16))
                
                Text(String(format: "Accuracy: %.0f meters", locationManager.accuracy))
                    .padding(.bottom, 8)
                    .font(.system(size: 16))
                
                MapView(coordinate: mapCoordinate ?? CLLocationCoordinate2D(latitude: locationManager.latitude, longitude: locationManager.longitude))
                    .frame(height: 350)
                    .cornerRadius(8)
                    .padding(.bottom, 8)
                
                if !networkMonitor.isConnected {
                    Text("No Internet Connection")
                        .padding(.bottom, 8)
                        .font(.system(size: 16))
                } else {
                    Text("\(locationManager.locationString)")
                        .padding(.bottom, 8)
                        .font(.system(size: 16))
                }
                
                Spacer()
            }
            .padding([.leading, .trailing], 20)
            .tag(3)
            .onAppear {
                startLocationCheckTimer()
                if shouldUpdateMap {
                    mapCoordinate = CLLocationCoordinate2D(latitude: locationManager.latitude, longitude: locationManager.longitude)
                    shouldUpdateMap = false
                }
            }
            .onDisappear {
                stopLocationCheckTimer()
            }
        }
        .tabViewStyle(PageTabViewStyle(indexDisplayMode: .always))
        .onOpenURL { url in
            guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = urlComponents.queryItems else {
                return
            }
            
            for queryItem in queryItems {
                if queryItem.name == "text", let text = queryItem.value {
                    hiddenText = text.removingPercentEncoding
                    selectedTab = 2
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        hiddenText = nil
                    }
                }
            }
        }
        .onAppear {
            setupPageControlAppearance()
            locationManager.checkLocationServices()
        }
    }
    
    private func setupPageControlAppearance() {
        UIPageControl.appearance().currentPageIndicatorTintColor = .gray
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.gray.withAlphaComponent(0.3)
    }
    
    private func startLocationCheckTimer() {
        locationCheckTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
            locationManager.checkLocationServices()
        }
    }

    private func stopLocationCheckTimer() {
        locationCheckTimer?.invalidate()
        locationCheckTimer = nil
    }
}

struct MapView: UIViewRepresentable {
    var coordinate: CLLocationCoordinate2D
    
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.showsUserTrackingButton = true
        return mapView
    }
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        uiView.setRegion(MKCoordinateRegion(
            center: coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        ), animated: true)
    }
}

extension CLLocation {
    func fetchMoreLocationDetails(completion: @escaping (_ subLocality: String?, _ locality: String?, _ administrativeArea: String?, _ country: String?, _ error: Error?) -> Void) {
        if let request = MKReverseGeocodingRequest(location: self) {
            request.getMapItems { mapItems, error in
                let placemark = mapItems?.first?.placemark
                completion(
                    placemark?.subLocality,
                    placemark?.locality,
                    placemark?.administrativeArea,
                    placemark?.country,
                    error
                )
            }
        }
    }
}

#Preview {
    ContentView()
}
