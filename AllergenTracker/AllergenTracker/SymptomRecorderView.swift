//
//  SymptomRecorderView.swift
//  AllergenTracker
//
//  Created by Willie Wu on 9/18/20.
//  Copyright © 2020 Willie Wu. All rights reserved.
//

import SwiftUI
import CoreML
import Combine

struct SymptomRecorderView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var pollenDataRetriever: PollenDataRetriever
    @ObservedObject var predictionModel: PredictionModel
    @State var date = Date()
    @State private var experiencingSymptoms = false
    @State private var symptomDataList: [(doesExist: Bool, severity: Int)] = Array(repeating: (false, 0), count: Symptoms.symptomList.count)
    @State private var manualLGID: [String] = ["","",""]
    
    var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateStyle = .short
        formatter.timeStyle = .none
        return formatter
        }
    
    var body: some View {
        NavigationView {
            Form {
                DatePicker(selection: $date, in: ...Date(), displayedComponents: .date) {
                                Text("Select a date")
                            }
                if Calendar.current.compare(Date(), to: date, toGranularity: .day) != .orderedSame {
                    Section(header: Text("Past data requires manual trigger entry")) {
                        
                        TextField("Grass Concentration", text: $manualLGID[0])
                            .keyboardType(.numberPad)
                            .onReceive(Just(manualLGID[0])) { newValue in
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered != newValue {
                                    self.manualLGID[0] = filtered
                                }
                        }
                        TextField("Tree Concentration", text: $manualLGID[1])
                            .keyboardType(.numberPad)
                            .onReceive(Just(manualLGID[1])) { newValue in
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered != newValue {
                                    self.manualLGID[1] = filtered
                                }
                        }
                        TextField("Weed Concentration", text: $manualLGID[2])
                            .keyboardType(.numberPad)
                            .onReceive(Just(manualLGID[2])) { newValue in
                                let filtered = newValue.filter { "0123456789".contains($0) }
                                if filtered != newValue {
                                    self.manualLGID[2] = filtered
                                }
                        }
                    }
                }
                
                Section(header: Text("Experiencing Symptoms?")) {
                    Picker(selection: $experiencingSymptoms, label: Text("Are you experiencing symptoms today?")) {
                        Text("No").tag(false)
                        Text("Yes").tag(true)
                    }.pickerStyle(SegmentedPickerStyle())
                }
                if experiencingSymptoms {
                    Section(header: Text("Symptoms and Severity")) {
                        ForEach(0..<Symptoms.symptomList.count, id: \.self) { index in
                            VStack {
                                Toggle(isOn: $symptomDataList[index].doesExist.animation()) {
                                    Text(Symptoms.symptomList[index])
                                }
                                Picker(selection: $symptomDataList[index].severity, label: Text("How severe are your symptoms?")) {
                                    Text("Minimal").tag(1)
                                    Text("Moderate").tag(2)
                                    Text("Severe").tag(3)
                                }.pickerStyle(SegmentedPickerStyle())
                                .isHidden(!symptomDataList[index].doesExist,remove:true)
                            }
                        }
                    }
                }
                Section {
                    Button(action: {
                            self.saveData()
                            self.presentationMode.wrappedValue.dismiss() }) {
                        Text("Submit")
                    }
                    .disabled(!manualLGID[0].isNumber() || !manualLGID[1].isNumber() || !manualLGID[2].isNumber())
                }
            }
            .navigationBarTitle(Text("\(date, formatter: dateFormatter) Symptoms"))
        }
    }
    
    func saveData() {
        var symptomString = ""
        
        var triggerList: [Trigger] = []
        
        if Calendar.current.compare(Date(), to: date, toGranularity: .day) != .orderedSame {
            triggerList.append(Trigger(LGID: Int(self.manualLGID[0])!, Name: "Unknown", Genus: "Unknown", PlantType: "Grass"))
            triggerList.append(Trigger(LGID: Int(self.manualLGID[1])!, Name: "Unknown", Genus: "Unknown", PlantType: "Tree"))
            triggerList.append(Trigger(LGID: Int(self.manualLGID[2])!, Name: "Unknown", Genus: "Unknown", PlantType: "Ragweed"))
        } else {
            let identTriggers = self.pollenDataRetriever.getTodaysTriggers()
            for identTrigger in identTriggers {
                triggerList.append(identTrigger.trigger)
            }
        }
        
        let jsonData = try! JSONEncoder().encode(triggerList)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        for tup in self.symptomDataList {
            if tup.doesExist {
                symptomString+=String(tup.severity)
            } else {
                symptomString+="0"
            }
        }
        let cdHistory = History(context: self.moc)
        cdHistory.id = UUID()
        cdHistory.symptoms = symptomString
        cdHistory.trigger = jsonString
        cdHistory.date = self.date
        try? self.moc.save()
        let pollenTypeIndexes = consolidateTriggerListByType(triggers: triggerList)
        if let arr = try? MLMultiArray(shape: [3], dataType: MLMultiArrayDataType.float32) {
            arr[0] = NSNumber(floatLiteral: pollenTypeIndexes[0]/5)
            arr[1] = NSNumber(floatLiteral: pollenTypeIndexes[1]/15)
            arr[2] = NSNumber(floatLiteral: pollenTypeIndexes[2]/2)
            predictionModel.update(inputArray: arr, output: symptomString)
        } else { print(#function, "Failed to create MLMultiArray") }
    }
    
    func consolidateTriggerListByType(triggers: [Trigger]) -> [Double] {
        var grassTotal = 0.0
        var treeTotal = 0.0
        var weedTotal = 0.0
        for trigger in triggers {
            switch trigger.PlantType {
            case "Grass":
                grassTotal+=Double(trigger.LGID)
            case "Tree":
                treeTotal+=Double(trigger.LGID)
            case "Ragweed":
                weedTotal+=Double(trigger.LGID)
            default:
                print("Error unknown type found")
            }
        }
        return [grassTotal, treeTotal, weedTotal]
    }
}

struct SymptomRecorderView_Previews: PreviewProvider {
    static var previews: some View {
        SymptomRecorderView(pollenDataRetriever: PollenDataRetriever(), predictionModel: PredictionModel())
    }
}
