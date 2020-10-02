//
//  PollenData.swift
//  AllergenTracker
//
//  Created by Willie Wu on 9/25/20.
//  Copyright © 2020 Willie Wu. All rights reserved.
//

import Foundation
import CoreLocation

class PollenDataRetriever: ObservableObject {
    let baseURLString = "https://www.pollen.com/api/forecast/current/pollen/"
    let UserAgentString = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/65.0.3325.181 Safari/537.36"
    @Published var pollenDataResponse: PollenDataResponse
    
    init() {
        self.pollenDataResponse = PollenDataResponse()
    }
    
    func loadData(placemark: CLPlacemark?) {
        guard let zip = placemark?.postalCode else {
            print(#function, "placemark wasn't valid returning with no data")
            return
        }
        let fullURLString = baseURLString+zip
        let pollenURL = URL(string: fullURLString)!
        var request = URLRequest(url: pollenURL)
        request.httpMethod = "GET"
        request.addValue(fullURLString, forHTTPHeaderField: "Referer")
        request.addValue(UserAgentString, forHTTPHeaderField: "User-Agent")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let decodedResponse = try? JSONDecoder().decode(PollenDataResponse.self, from: data) {
                    print(#function, "Response decoded successfully")
                    DispatchQueue.main.async {
                        // update our UI by updating the published variable
                        self.pollenDataResponse = decodedResponse
                    }
                    return
                }
            } else {
                // if we're still here it means there was a problem
                print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }.resume()
    }
    
    func getTodaysTriggers() -> [IdentifiableTrigger] {
        if let locationResponse: LocationResponse = self.pollenDataResponse.Location {
            for period in locationResponse.periods {
                if period.Type == "Today" {
                    var res: [IdentifiableTrigger] = []
                    for trigger in period.Triggers {
                        res.append(IdentifiableTrigger(t: trigger))
                    }
                    return res
                }
            }
        }
        return []
    }
    
    
    func getDisplayLocation(periodType: String) -> String {
        if let locationResponse: LocationResponse = self.pollenDataResponse.Location {
            for period in locationResponse.periods {
                if period.Type == periodType {
                    return locationResponse.DisplayLocation
                }
            }
        }
        return "Unknown Location"
    }
    
    func getPollenIndex(periodType: String) -> String {
        if let locationResponse: LocationResponse = self.pollenDataResponse.Location {
            for period in locationResponse.periods {
                if period.Type == periodType {
                    return String(period.Index)
                }
            }
        }
        return "???"
    }
}

struct PollenDataResponse: Codable {
    var `Type`: String?
    var ForecastDate: String?
    var Location: LocationResponse?
}

struct LocationResponse: Codable {
    var ZIP: String
    var State: String
    var periods: [Period]
    var DisplayLocation: String
}

struct Period: Codable {
    var Triggers: [Trigger]
    var Period: String
    var `Type`: String
    var Index: Double
}

struct Trigger: Codable {
    var LGID: Int
    var Name: String
    var Genus: String
    var PlantType: String
}

struct IdentifiableTrigger: Identifiable {
    var id = UUID()
    var trigger: Trigger
    
    init(t: Trigger) {
        self.trigger = t
    }
}
