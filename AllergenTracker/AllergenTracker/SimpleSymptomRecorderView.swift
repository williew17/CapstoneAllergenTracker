//
//  SimpleSymptomRecorderView.swift
//  AllergenTracker
//
//  Created by Willie Wu on 9/25/20.
//  Copyright © 2020 Willie Wu. All rights reserved.
//

import SwiftUI

struct SimpleSymptomRecorderView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var experiencingSymptoms = false
    @State private var symptomSeverity = 0
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Experiencing Symptoms?")) {
                    Picker(selection: $experiencingSymptoms, label: Text("Are you experiencing symptoms today?")) {
                        Text("No").tag(false)
                        Text("Yes").tag(true)
                    }.pickerStyle(SegmentedPickerStyle())
                }
                if experiencingSymptoms {
                    Section(header: Text("Symptoms and Severity")) {
                        Picker(selection: $symptomSeverity, label: Text("How severe are your symptoms?")) {
                            Text("Minimal").tag(1)
                            Text("2").tag(2)
                            Text("3").tag(3)
                            Text("4").tag(4)
                            Text("Severe").tag(5)
                        }
                        .pickerStyle(SegmentedPickerStyle())
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
            .navigationBarTitle(Text("Todays Symptoms"))
        }
    }
    //TODO: SAVE THE DATA SOMEWHERE PERMANENT
    func saveData() {
        
    }
}

struct SimpleSymptomRecorderView_Previews: PreviewProvider {
    static var previews: some View {
        SimpleSymptomRecorderView()
    }
}
