//
//  UserProfile.swift
//  AllergenTracker
//
//  Created by Willie Wu on 10/2/20.
//  Copyright © 2020 Willie Wu. All rights reserved.
//

import Foundation

struct UserProfile: Codable {
    var typicalSensitivity: String
    var sensitiveSeason: String
    
    init() {
        /// Never Rarely Occasionally Often
        self.typicalSensitivity = "Unknown"
        ///Spring, Summer, Even
        self.sensitiveSeason = "Unknown"
    }
}
