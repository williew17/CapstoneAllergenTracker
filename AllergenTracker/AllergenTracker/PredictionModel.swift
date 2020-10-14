//
//  PredictionModel.swift
//  AllergenTracker
//
//  Created by Willie Wu on 9/20/20.
//  Copyright © 2020 Willie Wu. All rights reserved.
//

import Foundation
import CoreML

class PredictionModel: ObservableObject {
    var updatableModel: MLModel?
    var modelNameString: String = "UpdatableKNN"
    private static let appDirectory = FileManager.default.urls(for: .applicationSupportDirectory,
                                                               in: .userDomainMask).first!
    public func printStatus() {
        let updatableModelURL = PredictionModel.appDirectory.appendingPathComponent("\(modelNameString).mlmodelc")
        print(#function, "Does exist? \(FileManager.default.fileExists(atPath: updatableModelURL.path))")
    }
    
    func chooseModel() {
        if let profileData = UserDefaults.standard.data(forKey: "profile") {
            let decoder = JSONDecoder()
            if let decoded = try? decoder.decode(UserProfile.self, from: profileData) {
                let userProfile = decoded
//                let defaultChosenURL = urlFromProfile(userProfile: userProfile)
//                loadModel(url: defaultChosenURL)
                let trainingSet = createTrainingSet(userProfile: userProfile)
                initialTraining(trainingSet: trainingSet)
                print(#function, "Finished Initial Training")
                return
            }
        }
    }
    
    private func createTrainingSet(userProfile: UserProfile) -> [MLFeatureProvider] {
        var batchInputs: [MLFeatureProvider] = []
        print(#function, userProfile)
        let limit = Symptoms.profileSeverityMap[userProfile.typicalSensitivity] ?? 0
        for i in 0...limit {
            for j in 0...limit {
                for k in 0...limit {
                    for l in 0...limit {
                        for h in 0...limit {
                            let answerString = String(i) + String(j) + String(k) + String(l) + String(h)
                            let percentile = Double(i+j+k+l+h)/(5*(Double(limit)+0.1))
                            let fuzzed = giveRandomAll(percentile: percentile, sensitiveSeason: userProfile.sensitiveSeason)
                            if let arr = try? MLMultiArray(shape: [3], dataType: MLMultiArrayDataType.float32) {
                                arr[0] = NSNumber(floatLiteral: fuzzed[0])
                                arr[1] = NSNumber(floatLiteral: fuzzed[1])
                                arr[2] = NSNumber(floatLiteral: fuzzed[2])
                                let input = UpdatableKNNTrainingInput(input: arr, output: answerString)
                                print(input)
                                batchInputs.append(input)
                            } else { print(#function, "Failed to create MLMultiArray") }
                        }
                    }
                }
            }
        }
        return batchInputs
    }
    
    private func initialTraining(trainingSet: [MLFeatureProvider]) {
        let updatableModelURL = PredictionModel.appDirectory.appendingPathComponent("\(modelNameString).mlmodelc")
        let tempUpdatableModelURL = PredictionModel.appDirectory.appendingPathComponent("temp\(modelNameString).mlmodelc")
        guard FileManager.default.fileExists(atPath: updatableModelURL.path) else {
            do {
                try FileManager.default.copyItem(at: Bundle.main.url(forResource: modelNameString, withExtension: "mlmodelc")!, to: updatableModelURL)
                print(#function, "Copied model into \(updatableModelURL.path)")
            } catch { }
            return
        }
        let updateTask = try! MLUpdateTask(forModelAt: updatableModelURL,
                                           trainingData: MLArrayBatchProvider(array: trainingSet),
                                           configuration: self.updatableModel!.configuration,
                                           completionHandler: { context in
                                            let updatedModel = context.model
                                            let fileManager = FileManager.default
                                            do {
                                                // Create a directory for the updated model.
                                                try fileManager.createDirectory(at: tempUpdatableModelURL,
                                                                                withIntermediateDirectories: true,
                                                                                attributes: nil)
                                                // Save the updated model to temporary filename.
                                                try updatedModel.write(to: tempUpdatableModelURL)
                                                // Replace any previously updated model with this one.
                                                _ = try fileManager.replaceItemAt(updatableModelURL,
                                                                                  withItemAt: tempUpdatableModelURL)
                                                print(#function, "Updated model saved to:\n\t\(updatableModelURL)")
                                            } catch let error {
                                                print(#function, "Could not save updated model to the file system: \(error)")
                                                return
                                            }
                                            self.loadModel(url: updatableModelURL)
                                           })
        updateTask.resume()
    }
    
    private func giveRandomAll(percentile: Double, sensitiveSeason: String) -> [Double] {
        switch sensitiveSeason {
        //grass and tree
        case "Spring":
            return [(Double.random(in: -5...5) + 100)*percentile,
                    (Double.random(in: -5...5) + 100)*percentile,
                    (Double.random(in: -5...5) + 100)*0.5]
            //ragweed
        case "Summer":
            return [(Double.random(in: -5...5) + 100)*0.5,
                    (Double.random(in: -5...5) + 100)*0.5,
                    (Double.random(in: -5...5) + 100)*percentile]
        default:
            return [(Double.random(in: -5...5) + 100)*percentile,
                    (Double.random(in: -5...5) + 100)*percentile,
                    (Double.random(in: -5...5) + 100)*percentile]
        }
    }
    
//    private func urlFromProfile(userProfile: UserProfile) -> URL {
//        let modelURL = PredictionModel.appDirectory.appendingPathComponent("\(modelNameString).mlmodelc")
//        return modelURL
//    }
    
    private func loadModel(url: URL) {
        guard FileManager.default.fileExists(atPath: url.path) else {
            // The updated model is not present at its designated path. We need to copy the model in and then load a default
            print(#function, "Model not found in path")
            if let defaultURL = Bundle.main.url(forResource: modelNameString, withExtension: "mlmodelc") {
                do {
                    // copy the model for later so we can get updates
                    try FileManager.default.copyItem(at: defaultURL, to: url)
                    print(#function, "Copied model into \(url.path) using default model until copy is complete")
                } catch {
                    print(#function, "Failed to copy model using default model")
                }
                //load the default model and return
                guard let model = try? MLModel(contentsOf: url) else {
                    return
                }
                print(#function, "Model successfully loaded")
                updatableModel = model
            }
            // couldn't get default url need to return failure case
            return
        }
        //the model is already present, no copying necessary so we just try and load it
        guard let model = try? MLModel(contentsOf: url) else {
            return
        }
        print(#function, "Model successfully loaded")
        updatableModel = model
    }
    
    init () {
        let modelURL = PredictionModel.appDirectory.appendingPathComponent("\(modelNameString).mlmodelc")
        loadModel(url: modelURL)
    }
    
    func predict(inputArray: MLMultiArray) -> String? {
        let input = UpdatableKNNInput(input: inputArray)
        do {
            let prediction = try updatableModel?.prediction(from: input)
            let output = prediction?.featureValue(for: "output")?.stringValue
            return output
        } catch {
            print(#function, "There was an issue with prediction")
        }
        return nil
    }
    
    private func batchProvider(inputArray: MLMultiArray, output: String) -> MLArrayBatchProvider {
        var batchInputs: [MLFeatureProvider] = []
        let input = UpdatableKNNTrainingInput(input: inputArray, output: output)
        batchInputs.append(input)
        return MLArrayBatchProvider(array: batchInputs)
    }
    
    func update(inputArray: MLMultiArray, output: String) {
        let trainingData = batchProvider(inputArray: inputArray, output: output)
        let updatableModelURL = PredictionModel.appDirectory.appendingPathComponent("\(modelNameString).mlmodelc")
        let tempUpdatableModelURL = PredictionModel.appDirectory.appendingPathComponent("temp\(modelNameString).mlmodelc")
        guard FileManager.default.fileExists(atPath: updatableModelURL.path) else {
            do {
                try FileManager.default.copyItem(at: Bundle.main.url(forResource: modelNameString, withExtension: "mlmodelc")!, to: updatableModelURL)
                print(#function, "Copied model into \(updatableModelURL.path)")
            } catch { }
            return
        }
        let updateTask = try! MLUpdateTask(forModelAt: updatableModelURL,
                                           trainingData: trainingData,
                                           configuration: self.updatableModel!.configuration,
                                           completionHandler: { context in
                                            let updatedModel = context.model
                                            let fileManager = FileManager.default
                                            do {
                                                // Create a directory for the updated model.
                                                try fileManager.createDirectory(at: tempUpdatableModelURL,
                                                                                withIntermediateDirectories: true,
                                                                                attributes: nil)
                                                // Save the updated model to temporary filename.
                                                try updatedModel.write(to: tempUpdatableModelURL)
                                                // Replace any previously updated model with this one.
                                                _ = try fileManager.replaceItemAt(updatableModelURL,
                                                                                  withItemAt: tempUpdatableModelURL)
                                                print(#function, "Updated model saved to:\n\t\(updatableModelURL)")
                                            } catch let error {
                                                print(#function, "Could not save updated model to the file system: \(error)")
                                                return
                                            }
                                            self.loadModel(url: updatableModelURL)
                                           })
        updateTask.resume()
    }
}
