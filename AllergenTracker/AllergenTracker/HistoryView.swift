//
//  HistoryView.swift
//  AllergenTracker
//
//  Created by Willie Wu on 9/18/20.
//  Copyright © 2020 Willie Wu. All rights reserved.
//

import SwiftUI
import CoreData

struct HistoryView: View {
    @FetchRequest(entity: CDHistory.entity(), sortDescriptors: [NSSortDescriptor(keyPath: \CDHistory.date, ascending: true)]) var historyList: FetchedResults<CDHistory>
    @Environment(\.managedObjectContext) var moc
    
    var body: some View {
        List {
            ForEach(historyList, id: \.self) { history in
                Text(history.symptoms ?? "Not found")
            }
        }
    }
}

struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}
