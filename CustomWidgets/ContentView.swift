//
//  ContentView.swift
//  CustomWidgets
//
//  Created by Sachin Agrawal on 6/24/24.
//

import SwiftUI
import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    var locationManager: CLLocationManager?

    func checkLocationServices() {
        DispatchQueue.global().async {
            if CLLocationManager.locationServicesEnabled() {
                self.locationManager = CLLocationManager()
                self.locationManager?.delegate = self
            } else {
                print("Location services are not enabled")
            }
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
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        checkLocationAuthorization()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        
        print("On Location Updated: \(location)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get user location: \(error.localizedDescription)")
    }
}

struct ContentView: View {
    @State private var hiddenText: String?
    
    @StateObject private var locationManager = LocationManager()

    var body: some View {
        VStack {
            Text("Main App")
                .font(.system(size: 24))
                .padding(.bottom)
            
            let latitude = UserDefaults.standard.object(forKey: "latitude") as? Double ?? 40.5
            let longitude = UserDefaults.standard.object(forKey: "longitude") as? Double ?? -74.0
            let locationString = String(format: "Location: %.2f, %.2f", latitude, longitude)
            
            Text("\(locationString)")
                .padding()
                .font(.system(size: 18))
            
            if let hiddenText = hiddenText {
                Text("Deep Link: \(hiddenText)")
                    .padding()
                    .font(.system(size: 18))
            }
        }
        .onOpenURL { url in
            guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = urlComponents.queryItems else {
                return
            }
            
            for queryItem in queryItems {
                if queryItem.name == "text", let text = queryItem.value {
                    hiddenText = text.removingPercentEncoding
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        hiddenText = nil
                    }
                }
            }
        }
        .onAppear {
            locationManager.checkLocationServices()
        }
    }
}

#Preview {
    ContentView()
}
