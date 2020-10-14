//
//  Constants.swift
//  AllergenTracker
//
//  Created by Willie Wu on 9/19/20.
//  Copyright © 2020 Willie Wu. All rights reserved.
//

import Foundation
import SwiftUI

struct Symptoms {
    static let symptomList: [String] = ["Runny nose", "Itchy eyes", "Congestion", "Sneezing", "Sinus pressure"]
    static let severityColors: [String: Color] = ["None": .green, "Mild": .yellow, "Moderate": .orange, "Severe": .red]
    static let numberSeverity: [String: String] = ["0" : "None", "1": "Mild", "2" : "Moderate", "3" : "Severe"]
    static let profileSeverityMap: [String: Int] = ["Never": 0, "Rarely": 1, "Occasionally": 2, "Often": 3]
}

extension View {
    
    /// Hide or show the view based on a boolean value.
    ///
    /// Example for visibility:
    /// ```
    /// Text("Label")
    ///     .isHidden(true)
    /// ```
    ///
    /// Example for complete removal:
    /// ```
    /// Text("Label")
    ///     .isHidden(true, remove: true)
    /// ```
    ///
    /// - Parameters:
    ///   - hidden: Set to `false` to show the view. Set to `true` to hide the view.
    ///   - remove: Boolean value indicating whether or not to remove the view.
    @ViewBuilder func isHidden(_ hidden: Bool, remove: Bool = false) -> some View {
        if hidden {
            if !remove {
                self.hidden()
            }
        } else {
            self
        }
    }
}

extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

extension StringProtocol {
    subscript(offset: Int) -> Character {
        self[index(startIndex, offsetBy: offset)]
    }
}

struct GridStack<Content: View>: View {
    let rows: Int
    let columns: Int
    let content: (Int, Int) -> Content
    let headers: [String]

    var body: some View {
        HStack {
            ForEach(0 ..< columns, id: \.self) { column in
                VStack {
                    Text(headers[column]).font(.headline)
                    ForEach(0 ..< self.rows, id: \.self) { row in
                        self.content(row, column)
                    }
                }
            }
        }
    }

    init(rows: Int, columns: Int, headers: [String], @ViewBuilder content: @escaping (Int, Int) -> Content) {
        self.rows = rows
        self.columns = columns
        self.content = content
        self.headers = headers
    }
}

struct EdgeBorder: Shape {

    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var x: CGFloat {
                switch edge {
                case .top, .bottom, .leading: return rect.minX
                case .trailing: return rect.maxX - width
                }
            }

            var y: CGFloat {
                switch edge {
                case .top, .leading, .trailing: return rect.minY
                case .bottom: return rect.maxY - width
                }
            }

            var w: CGFloat {
                switch edge {
                case .top, .bottom: return rect.width
                case .leading, .trailing: return self.width
                }
            }

            var h: CGFloat {
                switch edge {
                case .top, .bottom: return self.width
                case .leading, .trailing: return rect.height
                }
            }
            path.addPath(Path(CGRect(x: x, y: y, width: w, height: h)))
        }
        return path
    }
}

///source: https://gist.github.com/mobilinked/9b6086b3760bcf1e5432932dad0813c0
struct MbModalHackView: UIViewControllerRepresentable {
    var dismissable: () -> Bool = { false }
    func makeUIViewController(context: UIViewControllerRepresentableContext<MbModalHackView>) -> UIViewController {
        UIViewController()
    }
    func updateUIViewController(_ uiViewController: UIViewController, context: UIViewControllerRepresentableContext<MbModalHackView>) {
        rootViewController(of: uiViewController).presentationController?.delegate = context.coordinator
    }
    private func rootViewController(of uiViewController: UIViewController) -> UIViewController {
        if let parent = uiViewController.parent {
            return rootViewController(of: parent)
        }
        else {
            return uiViewController
        }
    }
    func makeCoordinator() -> Coordinator {
        Coordinator(dismissable: dismissable)
    }
    class Coordinator: NSObject, UIAdaptivePresentationControllerDelegate {
        var dismissable: () -> Bool = { false }
        init(dismissable: @escaping () -> Bool) {
            self.dismissable = dismissable
        }
        func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
            dismissable()
        }
    }
}

extension View {
    public func allowAutoDismiss(_ dismissable: @escaping () -> Bool) -> some View {
        self
            .background(MbModalHackView(dismissable: dismissable))
    }
}


///from https://stackoverflow.com/questions/58837007/multiple-sheetispresented-doesnt-work-in-swiftui
enum ActiveSheet: Identifiable {
    case first, second
    
    var id: Int {
        hashValue
    }
}

///from https://stackoverflow.com/questions/27182023/getting-the-difference-between-two-dates-months-days-hours-minutes-seconds-in
extension Date {
    /// Returns the amount of years from another date
    func years(from date: Date) -> Int {
        return Calendar.current.dateComponents([.year], from: date, to: self).year ?? 0
    }
    /// Returns the amount of months from another date
    func months(from date: Date) -> Int {
        return Calendar.current.dateComponents([.month], from: date, to: self).month ?? 0
    }
    /// Returns the amount of weeks from another date
    func weeks(from date: Date) -> Int {
        return Calendar.current.dateComponents([.weekOfMonth], from: date, to: self).weekOfMonth ?? 0
    }
    /// Returns the amount of days from another date
    func days(from date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date, to: self).day ?? 0
    }
    /// Returns the amount of hours from another date
    func hours(from date: Date) -> Int {
        return Calendar.current.dateComponents([.hour], from: date, to: self).hour ?? 0
    }
    /// Returns the amount of minutes from another date
    func minutes(from date: Date) -> Int {
        return Calendar.current.dateComponents([.minute], from: date, to: self).minute ?? 0
    }
    /// Returns the amount of seconds from another date
    func seconds(from date: Date) -> Int {
        return Calendar.current.dateComponents([.second], from: date, to: self).second ?? 0
    }
    /// Returns the a custom time interval description from another date
    func offset(from date: Date) -> String {
        if years(from: date)   > 0 { return "\(years(from: date))y"   }
        if months(from: date)  > 0 { return "\(months(from: date))M"  }
        if weeks(from: date)   > 0 { return "\(weeks(from: date))w"   }
        if days(from: date)    > 0 { return "\(days(from: date))d"    }
        if hours(from: date)   > 0 { return "\(hours(from: date))h"   }
        if minutes(from: date) > 0 { return "\(minutes(from: date))m" }
        if seconds(from: date) > 0 { return "\(seconds(from: date))s" }
        return ""
    }
}
