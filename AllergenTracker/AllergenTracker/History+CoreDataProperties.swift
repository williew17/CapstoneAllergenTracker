//
//  History+CoreDataProperties.swift
//  AllergenTracker
//
//  Created by Willie Wu on 10/4/20.
//  Copyright © 2020 Willie Wu. All rights reserved.
//
//

import Foundation
import CoreData


extension History {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<History> {
        return NSFetchRequest<History>(entityName: "History")
    }
    
    public var wrappedSymptoms: String {
        symptoms ?? "Unknown"
    }
    
    public var wrappedTrigger: String {
        trigger ?? "Unknown"
    }

    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var symptoms: String?
    @NSManaged public var trigger: String?

}

extension History : Identifiable {

}
