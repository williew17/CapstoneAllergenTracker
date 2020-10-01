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
            // The updated model is not present at its designated path.
            print("model not found in path")
            if let defaultURL = Bundle.main.url(forResource: modelNameString, withExtension: "mlmodelc") {
                print(defaultURL)
                print(url)
                do { try FileManager.default.copyItem(at: defaultURL, to: url)
                    print("copied model")
                } catch { }
            }
            return
        }
        print(FileManager.default.fileExists(atPath: url.path))
        guard let model = try? MLModel(contentsOf: url) else {
            return
        }
        print("model successfully loaded")
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
            // more code here
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
                                                print("line 73 PredictionModel")
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

let applicationDocumentsDirectory: URL = {
  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
}()

@discardableResult func copyIfNotExists(from: URL, to: URL) -> Bool {
  if !FileManager.default.fileExists(atPath: to.path) {
    do {
      try FileManager.default.copyItem(at: from, to: to)
      return true
    } catch {
      print("Error: \(error)")
    }
  }
  return false
}

func removeIfExists(at url: URL) {
  try? FileManager.default.removeItem(at: url)
}

func createDirectory(at url: URL) {
  try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: false)
}

func contentsOfDirectory(at url: URL) -> [URL]? {
  try? FileManager.default.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
}

func contentsOfDirectory(at url: URL, matching predicate: (URL) -> Bool) -> [URL] {
  contentsOfDirectory(at: url)?.filter(predicate) ?? []
}
