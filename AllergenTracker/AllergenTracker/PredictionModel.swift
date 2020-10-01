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
            print(prediction?.featureNames ?? "Not Found")
            return output
        } catch {
            print("there was an issue with predict")
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
                                                
                                                print("Updated model saved to:\n\t\(updatableModelURL)")
                                            } catch let error {
                                                print("Could not save updated model to the file system: \(error)")
                                                return
                                            }
                                            self.loadModel(url: updatableModelURL)
                                           })
        updateTask.resume()
    }
}
