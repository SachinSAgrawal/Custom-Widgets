//
//  ClockWidget.swift
//  CustomWidgets
//
//  Created by Sachin Agrawal on 6/24/24.
//

import WidgetKit
import SwiftUI

struct ClockProvider: TimelineProvider {
    func placeholder(in context: Context) -> ClockEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (ClockEntry) -> Void) {
        completion(.placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClockEntry>) -> Void) {
        let currentDate = Date()
        let seconds = Calendar.current.component(.second, from: currentDate)
        let startDate = Calendar.current.date(byAdding: .second, value: -seconds, to: currentDate) ?? currentDate
        let entries = (0 ..< 60).map {
            let date = Calendar.current.date(byAdding: .second, value: $0 * 60 - 1, to: startDate) ?? startDate
            return ClockEntry(date: date)
        }
        completion(.init(entries: entries, policy: .atEnd))
    }
}

struct ClockEntry: TimelineEntry {
    var date: Date
    
    static var placeholder: Self {
        .init(date: .now)
    }
}

struct ClockWidgetEntryView: View {
    var entry: ClockProvider.Entry

    var body: some View {
        VStack(spacing: 2) {
            Text("Time (AM/PM):")
            Text(Calendar.current.date(byAdding: .second, value: 1, to: entry.date) ?? entry.date, style: .time)
            
            Text("Time (24hr):")
            Text("\(Calendar.current.date(byAdding: .second, value: 1, to: entry.date) ?? entry.date, formatter: Self.dateFormatter)")
            
            Text("Seconds:")
            Text(Calendar.current.startOfDay(for: .now), style: .timer)
        }
        .font(.system(size: 16))
        .multilineTextAlignment(.center)
        .containerBackground(.yellow.gradient, for: .widget)
        .foregroundColor(.white)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = .init(identifier: "en_US_POSIX")
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
}

struct ClockWidget: Widget {
    let kind: String = "ClockWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ClockProvider()) { entry in
            ClockWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Clock")
        .description("Display a clock that shows the time in various formats.")
        .supportedFamilies([.systemSmall])
    }
}

struct ClockWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ClockWidgetEntryView(entry: .placeholder)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
        }
        .environment(\.colorScheme, .dark)
    }
}
