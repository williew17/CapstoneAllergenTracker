//
//  SymptomRecorderView.swift
//  AllergenTracker
//
//  Created by Willie Wu on 9/18/20.
//  Copyright © 2020 Willie Wu. All rights reserved.
//

import SwiftUI
import CoreML

struct SymptomRecorderView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.managedObjectContext) var moc
    @ObservedObject var pollenDataRetriever: PollenDataRetriever
    @ObservedObject var predictionModel: PredictionModel
    @State var date = Date()
    @State private var experiencingSymptoms = false
    @State private var symptomDataList: [(doesExist: Bool, severity: Int)] = Array(repeating: (false, 0), count: Symptoms.symptomList.count)
    
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
                }
            }
            .navigationBarTitle(Text("\(date, formatter: dateFormatter) Symptoms"))
        }
    }
    
    func saveData() {
        var symptomString = ""
        let identTriggers = self.pollenDataRetriever.getTodaysTriggers()
        var triggerList: [Trigger] = []
        for identTrigger in identTriggers {
            triggerList.append(identTrigger.trigger)
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
        let cdHistory = CDHistory(context: self.moc)
        cdHistory.id = UUID()
        cdHistory.symptoms = symptomString
        cdHistory.trigger = jsonString
        cdHistory.date = Date()
        try? self.moc.save()
        let pollenTypeIndexes = consolidateTriggerListByType(triggers: identTriggers)
        if let arr = try? MLMultiArray(shape: [3], dataType: MLMultiArrayDataType.float32) {
            arr[0] = NSNumber(floatLiteral: pollenTypeIndexes[0])
            arr[1] = NSNumber(floatLiteral: pollenTypeIndexes[1])
            arr[2] = NSNumber(floatLiteral: pollenTypeIndexes[2])
            predictionModel.update(inputArray: arr, output: symptomString)
        } else { print("failed in SymptomRecorder") }
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

struct SymptomRecorderView_Previews: PreviewProvider {
    static var previews: some View {
        SymptomRecorderView(pollenDataRetriever: PollenDataRetriever(), predictionModel: PredictionModel())
    }
}
