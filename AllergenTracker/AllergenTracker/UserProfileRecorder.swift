//
//  UserProfileRecorder.swift
//  AllergenTracker
//
//  Created by Willie Wu on 10/2/20.
//  Copyright © 2020 Willie Wu. All rights reserved.
//

import SwiftUI

struct UserProfileRecorder: View {
    @Environment(\.colorScheme) var colorScheme
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject var predictionModel: PredictionModel
    @State var userProfile = UserProfile()
    
    var body: some View {
        ScrollView {
            Text("Welcome to Allergen Tracker!").font(.largeTitle).multilineTextAlignment(.center).fixedSize(horizontal: false, vertical: true)
            Text("The goal of this application is to record your allergy related symptoms to best predict what your symptoms will be for a given day. In order to give us the best chance of predicting accurately, submit any prior experience you have with your seasonal allergies. The app will learn over time your specific sensitivities as you submit more entries, in other words, the more you use it the better it gets!").font(.headline).fixedSize(horizontal: false, vertical: true)
            Spacer()
            Text("How often do you experience severe symptoms during your typical allergen season?").font(.headline).fixedSize(horizontal: false, vertical: true)
            Picker(selection: $userProfile.typicalSensitivity, label: Text("How severe are your symptoms?")) {
                Text("Never").tag("Never")
                Text("Rarely").tag("Rarely")
                Text("Occasionally").tag("Sometimes")
                Text("Often").tag("Often")
            }.pickerStyle(DefaultPickerStyle())
            Text("What season do you typically experience the most severe symptoms?").font(.headline).fixedSize(horizontal: false, vertical: true)
            Picker(selection: $userProfile.sensitiveSeason, label: Text("What season are you sensitive?")) {
                Text("Spring/Early Summer").tag("Spring")
                Text("Late Summer/Fall").tag("Summer")
                Text("About Even").tag("Even")
            }.pickerStyle(DefaultPickerStyle())
            Spacer()
            Button(action: {
                self.saveData()
                self.predictionModel.chooseModel()
                self.presentationMode.wrappedValue.dismiss()
            }) { Text("Done!").fontWeight(.semibold) }
            .frame(minWidth: 0, maxWidth: .infinity)
            .padding()
            .foregroundColor(.white)
            .background(Color.accentColor)
            .cornerRadius(40)
        }.padding()
        .background(AngularGradient(gradient: Gradient(colors: [Color.green, colorScheme == .dark ? Color.black : Color.white, Color.green]), center: .top ).edgesIgnoringSafeArea(.all))
    }
    
    func saveData() {
        let encoder = JSONEncoder()
        if let data = try? encoder.encode(self.userProfile) {
            UserDefaults.standard.set(data, forKey: "profile")
        }
    }
}

struct UserProfileRecorder_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileRecorder(predictionModel: PredictionModel())
    }
}
