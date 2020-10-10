//
//  HistoryView.swift
//  AllergenTracker
//
//  Created by Willie Wu on 9/18/20.
//  Copyright © 2020 Willie Wu. All rights reserved.
//

import SwiftUI
import CoreData
import SwiftUICharts

struct HistoryView: View {
    @FetchRequest(entity: History.entity(),
                  sortDescriptors: [NSSortDescriptor(keyPath: \History.date, ascending: false)]) var historyList: FetchedResults<History>
//    @Environment(\.managedObjectContext) var moc
    @State var tabIndex: Int = 1
    var cdData: [simpleHistoryEntry] {
        var arr:[simpleHistoryEntry] = []
        for his in historyList {
            arr.append(simpleHistoryEntry(history: his))
        }
        return arr
    }
    
    var body: some View {
        VStack {
            
            Button(action: {
                print(historyList)
                for hist in historyList {
                    print(hist.date ?? "Unkown")
                    print(hist.trigger ?? "History trigger was nil")
                }
                
            }) { Text("TEST").fontWeight(.semibold) }
            
            TabView(selection: $tabIndex) {
                BarCharts(cdData: self.cdData).tabItem { Group{
                    Image(systemName: "chart.bar")
                    Text("Bar charts")
                }}.tag(0)
                MultiLineCharts(cdData: self.cdData).tabItem { Group{
                    Image(systemName: "waveform.path.ecg")
                    Text("MultiLine charts")
                }}.tag(1)
            }
        }
    }
}

struct MultiLineCharts: View {
    var cdData: [simpleHistoryEntry]
    var graphedData: [[Double]] {
        var arr: [[Double]] = [[],[],[],[]]
        for entry in cdData {
            arr[0].append(entry.msSymptom*100)
            arr[1].append(entry.grassPollenIndex)
            arr[2].append(entry.treePollenIndex)
            arr[3].append(entry.weedPollenIndex)
        }
        arr[0].reverse()
        arr[1].reverse()
        arr[2].reverse()
        arr[3].reverse()
//        print(arr)
        return arr
    }
    var body: some View {
        VStack {
            Text("Maximum Symptom Severity vs Major Pollen Types").font(.title)
            MultiLineChartView(data: [(graphedData[0], GradientColors.orange),
                                      (graphedData[1], GradientColors.blue),
                                      (graphedData[2], GradientColors.green),
                                      (graphedData[3], GradientColors.blu)],
                               title: "Recorded Symptoms",
                               form: ChartForm.extraLarge)
            Spacer()
        }.padding()
    }
}

struct BarCharts: View {
    var cdData: [simpleHistoryEntry]
    var graphedData: [(String, Double)] {
        var arr: [(String, Double)] = []
        var numberPerMonth: [Int] = []
        var previousMonth: Int?
        for entry in cdData {
            let calendarDate = Calendar.current.dateComponents([.year, .month], from: entry.date)
            if let prevMonthNotNil = previousMonth {
                if calendarDate.month! != prevMonthNotNil {
                    arr.append((getDateString(date: entry.date), entry.msSymptom))
                    previousMonth = calendarDate.month!
                    numberPerMonth.append(1)
                } else {
                    let i = arr.count
                    arr[i-1].1 += entry.msSymptom
                    numberPerMonth[i-1]+=1
                }
            } else {
                previousMonth = calendarDate.month!
                arr.append((getDateString(date: entry.date), entry.msSymptom))
                numberPerMonth.append(1)
            }
        }
        arr.reverse()
        numberPerMonth.reverse()
        return arr
    }
    
    var body: some View {
        VStack {
            Text("Overall Severity month-to-month").font(.title)
            BarChartView(data: ChartData(values: graphedData), title: "Symptoms over Time", style: Styles.barChartStyleOrangeLight, form: ChartForm.extraLarge)
            Spacer()
        }.padding()
    }
    
    func getDateString(date: Date) -> String{
        let dateFormatter = DateFormatter() // get a date formatter instance
        let calendar = dateFormatter.calendar
        guard let year = calendar?.component(.year, from: date) else { return "2020"}// Result: 2020
        guard let month = calendar?.component(.month, from: date) else { return "1" } // Result: 4
        let monthsWithShortName = dateFormatter.shortMonthSymbols! // Result: ["Jan”, "Feb”, "Mar”, "Apr”, "May”, "Jun”, "Jul”, "Aug”, "Sep”, "Oct”, "Nov”, "Dec”]
        return "\(monthsWithShortName[Int(month)-1]), \(year)"
    }
}

struct simpleHistoryEntry {
    var avgSymptom: Double
    var msSymptom: Double
    var grassPollenIndex: Double
    var treePollenIndex: Double
    var weedPollenIndex: Double
    var date: Date
    
    init(history: History) {
        // TODO check this maybe a better way or perhaps this nil coalescing will never happen
        self.date = history.date ?? Date()
        var totalSymptom = 0.0
        var maxSymptom = 0.0
        for char in history.symptoms ?? "00000" {
            if let number = Double(String(char)) {
                if number > maxSymptom {
                    maxSymptom = number
                }
                totalSymptom+=Double(number)
            }
        }
        self.msSymptom = maxSymptom
        self.avgSymptom = totalSymptom / 5.0
        self.grassPollenIndex = 0
        self.treePollenIndex = 0
        self.weedPollenIndex = 0
        let decoder = JSONDecoder()
        do {
            let triggers = try decoder.decode([Trigger].self, from: Data((history.trigger ?? "[]").utf8))
            for trigger in triggers {
                switch trigger.PlantType {
                case "Ragweed":
                    self.weedPollenIndex+=Double(trigger.LGID)
                case "Tree":
                    self.treePollenIndex+=Double(trigger.LGID)
                case "Grass":
                    self.grassPollenIndex+=Double(trigger.LGID)
                default:
                    print(#function, "Problem in plant type")
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
}


struct HistoryView_Previews: PreviewProvider {
    static var previews: some View {
        HistoryView()
    }
}

