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
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject private var pollenDataRetriever = PollenDataRetriever()
    @ObservedObject private var predictionModel = PredictionModel()
    @ObservedObject var locationManager = LocationManager()
    
    @State var activeSheet: ActiveSheet? = UserDefaults.standard.object(forKey: "profile") == nil ? .first : nil
    @State private var showingSymptomRecorder = false
    @State private var symptomSeverities: [String] = ["0", "0", "0", "0", "0"]
    @State private var oldZip = "Not Found"
    
    private var gridHeaders = ["Type", "Concentration", "Name"]
    private var todaysTriggers: [IdentifiableTrigger] {
        pollenDataRetriever.getTodaysTriggers()
    }
    
    var body: some View {
        NavigationView {
            VStack {
                Text("Current Allergens").font(.largeTitle).padding()
                VStack {
                    Text("Today in \(pollenDataRetriever.getDisplayLocation(periodType: "Today"))").font(.title)
                    Text("Pollen Index: \(pollenDataRetriever.getPollenIndex(periodType: "Today"))").font(.title)
                    GridStack(rows: self.todaysTriggers.count, columns: 3, headers: gridHeaders) { row, col in
                        if col == 0 {
                            Text("\(todaysTriggers[row].trigger.PlantType)")
                        } else if col == 1 {
                            Text("\(todaysTriggers[row].trigger.LGID)")
                        } else {
                            Text("\(todaysTriggers[row].trigger.Name)")
                        }
                    }
                    
                }
                Spacer()
                VStack {
                    Text("Predicted Symptoms").font(.title)
                    ForEach((0...Symptoms.symptomList.count-1), id:\.self) { index in
                        Text("\(Symptoms.symptomList[index]): \(Symptoms.numberSeverity[symptomSeverities[index], default: "Unknown"])")
                    }
                    Button(action: {
                        self.activeSheet = .second
                    }) { Text("Record Symptoms").fontWeight(.semibold) }
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .foregroundColor(.white)
                    .background(Color.accentColor)
                    .cornerRadius(40)
                }
                .padding(10)
                .frame(minWidth: 0, maxWidth: .infinity)
                .background(colorScheme == .dark ? Color.black.opacity(0.2).edgesIgnoringSafeArea(.all) : Color.white.opacity(0.2).edgesIgnoringSafeArea(.all))
                .border(width: 1, edges: [.top], color: Color.black)
            }
            .background(AngularGradient(gradient: Gradient(colors: [Color.green, colorScheme == .dark ? Color.black : Color.white, Color.green]), center: .top ).edgesIgnoringSafeArea(.all))
            .sheet(item: $activeSheet, onDismiss: { activeSheet = nil }) { item in
                switch item {
                case .first:
                    UserProfileRecorder(predictionModel: predictionModel).allowAutoDismiss { false }
                case .second:
                    SymptomRecorderView(pollenDataRetriever: pollenDataRetriever, predictionModel: predictionModel)
                }
                
            }
            .navigationBarTitle(Text("Allergen Tracker"), displayMode: .inline)
            .navigationBarItems(leading: NavigationLink(destination: HistoryView()) { Text("History") },
                                trailing: Button(action: {loadInformation()}) {Image(systemName: "arrow.clockwise")})
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
