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
    /// 1 for max, 2 for avg
    @State var symptomType: Int = 1
    @State var monthsToLoad: Int = 3
    var cdData: [simpleHistoryEntry] {
        var arr:[simpleHistoryEntry] = []
        let date = Date()
        for his in historyList {
            let months = date.months(from: his.date ?? Date())
            if months < self.monthsToLoad-1 {
                arr.append(simpleHistoryEntry(history: his))
            }
        }
        return arr
    }
    
    var body: some View {
        VStack {
//            Button(action: {
//                print(historyList)
//                for hist in historyList {
//                    print(hist.date ?? "Unkown")
//                    print(hist.trigger ?? "History trigger was nil")
//                }
//            }) { Text("TEST").fontWeight(.semibold) }.padding()
            VStack {
                Text("Symptoms graph by: ")
                Picker(selection: $symptomType, label: Text("Symptoms graph by: ")) {
                    Text("Max Severity").tag(1)
                    Text("Average Severity").tag(2)
                }.pickerStyle(SegmentedPickerStyle())
                Text("Amount of data to load: ")
                Picker(selection: $monthsToLoad, label: Text("Amount of data to load")) {
                    Text("3 months").tag(3)
                    Text("6 months").tag(6)
                    Text("1 year").tag(12)
                    Text("All").tag(50)
                }.pickerStyle(SegmentedPickerStyle())
            }.padding(5)
            .isHidden(tabIndex == 3,remove:true)
            
            TabView(selection: $tabIndex) {
                BarCharts(cdData: self.cdData, symptomType: self.symptomType).tabItem { Group{
                    Image(systemName: "chart.bar")
                    Text("Bar charts")
                }}.tag(0)
                MultiLineCharts(cdData: self.cdData, symptomType: self.symptomType).tabItem { Group{
                    Image(systemName: "waveform.path.ecg")
                    Text("MultiLine charts")
                }}.tag(1)
                List {
                    ForEach(historyList, id: \.self) { history in
                        RawHistoryView(history: history)
                    }
                }.tabItem { Group{
                    Image(systemName: "list.dash")
                    Text("Raw Data")
                } }.tag(3)
            }
        }.background(Color.gray.opacity(0.1).edgesIgnoringSafeArea(.all))
    }
}

struct MultiLineCharts: View {
    var cdData: [simpleHistoryEntry]
    var symptomType: Int
    var chartStyle: ChartStyle {
        let style = Styles.barChartStyleNeonBlueLight
        style.darkModeStyle = Styles.barChartStyleNeonBlueDark
        return style
    }
    var graphedData: [[Double]] {
        var arr: [[Double]] = [[],[],[],[]]
        for entry in cdData {
            if self.symptomType == 1 {
                arr[0].append(entry.msSymptom*100)
            } else {
                arr[0].append(entry.avgSymptom*100)
            }
            arr[1].append(entry.grassPollenIndex)
            arr[2].append(entry.treePollenIndex)
            arr[3].append(entry.weedPollenIndex)
        }
        arr[0].reverse()
        arr[1].reverse()
        arr[2].reverse()
        arr[3].reverse()
        return arr
    }
    var body: some View {
        VStack {
            Text("Symptom Severity and Major Pollen Types").font(.title).multilineTextAlignment(.center)
            MultiLineChartView(data: [(graphedData[0], GradientColors.orange),
                                      (graphedData[1], GradientColors.blu),
                                      (graphedData[2], GradientColor(start: Color.green, end: Color(Color.RGBColorSpace.sRGB, red: 0, green: 1.0, blue: 0.5, opacity: 1.0))),
                                      (graphedData[3], GradientColors.purple)],
                               title: "Recorded Symptoms",
                               style: chartStyle,
                               form: CGSize(width: 360, height: 241))
            ScrollView {
                Text("Shows the symptoms in orange compared to the different types of pollen's concentrations. The pollen type you are most senstive to is likely to track the orange line the closest. Grass is blue, Tree is green and Ragweed is purple")
            }
        }.padding()
    }
}

struct BarCharts: View {
    var cdData: [simpleHistoryEntry]
    var symptomType: Int
    var graphedData: [(String, Double)] {
        var arr: [(String, Double)] = []
        var numberPerMonth: [Int] = []
        var previousMonth: Int?
        for entry in cdData {
            let calendarDate = Calendar.current.dateComponents([.year, .month], from: entry.date)
            var symptomVal: Double = 0
            if self.symptomType == 1 {
                symptomVal = entry.msSymptom
            } else {
                symptomVal = entry.avgSymptom
            }
            if let prevMonthNotNil = previousMonth {
                if calendarDate.month! != prevMonthNotNil {
                    let i = arr.count
                    arr[i-1].1 /= Double(numberPerMonth[i-1])
                    arr.append((getDateString(date: entry.date), symptomVal))
                    previousMonth = calendarDate.month!
                    numberPerMonth.append(1)
                } else {
                    let i = arr.count
                    arr[i-1].1 += symptomVal
                    numberPerMonth[i-1]+=1
                }
            } else {
                previousMonth = calendarDate.month!
                arr.append((getDateString(date: entry.date), symptomVal))
                numberPerMonth.append(1)
            }
        }
        arr.reverse()
        numberPerMonth.reverse()
        return arr
    }
    
    var chartStyle: ChartStyle {
        let style = Styles.barChartStyleNeonBlueLight
        style.darkModeStyle = Styles.barChartStyleNeonBlueDark
        return style
    }
    
    var body: some View {
        VStack {
            Text("Overall Severity by Month").font(.title).multilineTextAlignment(.center)
            BarChartView(data: ChartData(values: graphedData),
                         title: "Symptoms over Time",
                         legend: "Monthly",
                         style: chartStyle,
                         form: ChartForm.extraLarge,
                         cornerImage: Image(systemName: "wind"))
            ScrollView {
                Text("This graph shows symptoms for each month. You can either compile max severity or average severity. This can be used over time to show when you have the most sever symptoms. Drag over the graph to see what month each bar corresponds to.")
            }
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

struct RawHistoryView: View {
    var history: History
    var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }
    var simpleHistory: simpleHistoryEntry {
        return simpleHistoryEntry(history: history)
    }
    
    
    var body: some View {
        HStack {
            VStack {
                Text(formatter.string(from: history.date ?? Date()))
                Text("Max Symptom: \(simpleHistory.msSymptom, specifier: "%.0f")")
                Text("Average Symptom: \(simpleHistory.avgSymptom, specifier: "%.1f")")
            }
            Spacer()
            VStack {
                Text("Grass:Tree:Pollen")
                Text("\(simpleHistory.grassPollenIndex, specifier: "%.0f"):\(simpleHistory.treePollenIndex, specifier: "%.0f"):\(simpleHistory.weedPollenIndex, specifier: "%.0f")")
            }
        }
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

