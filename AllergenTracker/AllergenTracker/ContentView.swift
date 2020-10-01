//
//  ContentView.swift
//  AllergenTracker
//
//  Created by Willie Wu on 9/17/20.
//  Copyright © 2020 Willie Wu. All rights reserved.
//

import SwiftUI
import CoreLocation
import CoreML

struct ContentView: View {
//    @ObservedObject private var atmosphereSummary = AtmosphereSummary()
    @ObservedObject private var pollenDataRetriever = PollenDataRetriever()
    @ObservedObject private var predictionModel = PredictionModel()
    @ObservedObject var locationManager = LocationManager()
    @State private var showingSymptomRecorder = false
    @State private var symptomSeverities: [String] = ["0", "0", "0", "0", "0"]
    
    @State private var oldZip = "Not Found"
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Current Allergen Summary")
                VStack {
                    Text(pollenDataRetriever.getGeneralSummary(periodType: "Today"))
                    ForEach(pollenDataRetriever.getTodaysTriggers()) { iTrigger in
                        Text(iTrigger.trigger.createTextString())
                    }
                }
                VStack {
                    Text("Symptoms:")
                    ForEach((0...Symptoms.symptomList.count-1), id:\.self) { index in
                        Text("\(Symptoms.symptomList[index]) = \(symptomSeverities[index])")
                    }
                }
                Button(action: {
                    self.showingSymptomRecorder = true
                }) { Text("Record Symptoms") }
                Spacer()
            }
            .sheet(isPresented: $showingSymptomRecorder) {
                SymptomRecorderView(pollenDataRetriever: pollenDataRetriever, predictionModel: predictionModel)
            }
            .navigationBarTitle(Text("Allergen Tracker"))
            .navigationBarItems(leading: NavigationLink(destination: HistoryView()) { Text("History") },
                                trailing: Button(action: {loadInformation()}) { Text("Refresh")})
        }
        .onReceive(locationManager.objectWillChange) { outPut in
            if outPut != self.oldZip {
                self.oldZip = outPut
                loadInformation()
            }
        }
    }
    
    func parsePrediction(predictionString: String) {
        for index in 0...predictionString.count-1 {
            self.symptomSeverities[index] = String(predictionString[index])
        }
        
    }
    
    func loadInformation() {
        pollenDataRetriever.loadData(placemark: locationManager.placemark)
        let triggerList = pollenDataRetriever.getTodaysTriggers()
        let pollenTypeIndexes = consolidateTriggerListByType(triggers: triggerList)
        if let arr = try? MLMultiArray(shape: [3], dataType: MLMultiArrayDataType.float32) {
            arr[0] = NSNumber(floatLiteral: pollenTypeIndexes[0])
            arr[1] = NSNumber(floatLiteral: pollenTypeIndexes[1])
            arr[2] = NSNumber(floatLiteral: pollenTypeIndexes[2])
            parsePrediction(predictionString: predictionModel.predict(inputArray: arr) ?? "00000")
        } else { print("failed") }
    }
    
    func consolidateTriggerListByType(triggers: [IdentifiableTrigger]) -> [Double] {
        var grassTotal = 0.0
        var treeTotal = 0.0
        var weedTotal = 0.0
        for identTrigger in triggers {
            switch identTrigger.trigger.PlantType {
            case "Grass":
                grassTotal+=Double(identTrigger.trigger.LGID)
            case "Tree":
                treeTotal+=Double(identTrigger.trigger.LGID)
            case "Ragweed":
                weedTotal+=Double(identTrigger.trigger.LGID)
            default:
                print("Error unknown type found")
            }
        }
        return [grassTotal, treeTotal, weedTotal]
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
