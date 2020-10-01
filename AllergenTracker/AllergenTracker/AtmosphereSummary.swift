//
//  AtmosphereSummary.swift
//  AllergenTracker
//
//  Created by Willie Wu on 9/18/20.
//  Copyright © 2020 Willie Wu. All rights reserved.
//

import Foundation
import CoreML

class AtmosphereSummary:Equatable, ObservableObject {
    
    
    let baseURLString = "https://api.ambeedata.com"
    let apiKey = "80NXCBEqOS6lGGmta0ffx4SiFDAOPuHA3c7OD2p5"
    @Published var pollenSummary: PollenSummary
    @Published var stationSummary: StationSummary
    @Published var predictionModel: PredictionModel
    @Published var predictedSymptoms: [String]
    
    
    static func == (lhs: AtmosphereSummary, rhs: AtmosphereSummary) -> Bool {
        return lhs.pollenSummary == rhs.pollenSummary
    }
    
    func loadData(lat: Double, lng: Double) {
        loadPollen(lat: lat, lng: lng)
        loadPollution(lat: lat, lng: lng)
    }
    
    func loadPollen(lat:Double, lng: Double) {
        guard let pollenURL = URL(string: baseURLString+"/latest/pollen/by-lat-lng?lat=\(lat)&lng=\(lng)") else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: pollenURL)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let jsonString = String(data: data, encoding: .utf8) {
                            print(jsonString)
                         }
                if let decodedResponse = try? JSONDecoder().decode(PollenResponse.self, from: data) {
                    // we have good data – go back to the main thread
                    print("response decoded")
                    if decodedResponse.message.lowercased() == "success" {
                        DispatchQueue.main.async {
                            // update our UI
                            self.pollenSummary = decodedResponse.data ?? PollenSummary()
                            if let arr = try? MLMultiArray(shape: [3], dataType: MLMultiArrayDataType.float32) {
                                arr[0] = NSNumber(floatLiteral: Double(self.pollenSummary.weed_pollen ?? -1))
                                arr[1] = NSNumber(floatLiteral: Double(self.pollenSummary.tree_pollen ?? -1))
                                arr[2] = NSNumber(floatLiteral: Double(self.pollenSummary.grass_pollen ?? -1))
                                let prediction = self.predictionModel.predict(inputArray: arr) ?? "00000"
                                for index in 0...4 {
                                    self.predictedSymptoms[index] = String(prediction[index])
                                }
                            }
                        }
                    } else {
                        // if we're still here it means there was a problem
                        
                        self.pollenSummary = decodedResponse.data ?? PollenSummary()
                        if let arr = try? MLMultiArray(shape: [3], dataType: MLMultiArrayDataType.float32) {
                            arr[0] = NSNumber(floatLiteral: 132)
                            arr[1] = NSNumber(floatLiteral: 50)
                            arr[2] = NSNumber(floatLiteral: 14)
                            let prediction = self.predictionModel.predict(inputArray: arr) ?? "00000"
                            for index in 0...4 {
                                self.predictedSymptoms[index] = String(prediction[index])
                            }
                        }
                        print("Fetch failed, message status: \(decodedResponse.message)")
                    }
                    return
                }
            } else {
                // if we're still here it means there was a problem
                print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }.resume()
    }
    
    func loadPollution(lat:Double, lng: Double) {
        guard let pollenURL = URL(string: baseURLString+"/latest/by-lat-lng?lat=\(lat)&lng=\(lng)") else {
            print("Invalid URL")
            return
        }
        var request = URLRequest(url: pollenURL)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "accept")
        request.addValue(apiKey, forHTTPHeaderField: "x-api-key")
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let data = data {
                if let jsonString = String(data: data, encoding: .utf8) {
                            print(jsonString)
                         }
                if let decodedResponse = try? JSONDecoder().decode(PollutantsResponse.self, from: data) {
                    // we have good data – go back to the main thread
                    print("response decoded")
                    if decodedResponse.message.lowercased() == "success" {
                        DispatchQueue.main.async {
                            // update our UI
                            self.stationSummary = decodedResponse.stations?[0] ?? StationSummary()
                        }
                    } else {
                        // if we're still here it means there was a problem
                        print("Fetch failed, message status: \(decodedResponse.message)")
                    }

                    // everything is good, so we can exit
                    return
                }
                print("decoding failure")
            } else {
                // if we're still here it means there was a problem
                print("Fetch failed: \(error?.localizedDescription ?? "Unknown error")")
            }
        }.resume()
    }
    
    
    init() {
        self.pollenSummary = PollenSummary()
        self.stationSummary = StationSummary()
        self.predictionModel = PredictionModel()
        self.predictedSymptoms = ["0", "0", "0", "0", "0"]
    }
}

struct PollenResponse: Codable {
    var message: String
    var data: PollenSummary?
}

struct PollenSummary: Codable, Equatable  {
    static func == (lhs: PollenSummary, rhs: PollenSummary) -> Bool {
        return lhs.weed_pollen == rhs.weed_pollen && lhs.tree_pollen == rhs.tree_pollen && lhs.grass_pollen == rhs.grass_pollen
    }
    
    var risk: String?
    var weed_pollen: Int?
    var tree_pollen: Int?
    var grass_pollen: Int?
    
    init() { }
}

struct PollutantsResponse: Codable {
    var message: String
    var stations: [StationSummary]?
}

struct StationSummary: Codable, Equatable {
    var placeId : String?
    var placeName: String?
    var state: String?
    var city: String?
    var division: String?
    var countryCode: String?
    var postalCode: String?
    var lat: Double?
    var lng: Double?
    var lastUpdate: String?
    var AQI: Double?
    var PM25: Double?
    var PM10: Double?
    var NO: Double?
    var NO2: Double?
    var NOx: Double?
    var SO2: Double?
    var CO: Double?
    var OZONE: Double?
    var aqiInfo: String?
    var createdAt: Int?
    var updatedAt: String?
    var updatesTs: String?
    var cleaned: Bool?
    var distance: Double?
    
    
    init() {}
}

