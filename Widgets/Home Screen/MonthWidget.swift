//
//  MonthWidget.swift
//  CustomWidgets
//
//  Created by Sachin Agrawal on 6/24/24.
//

import WidgetKit
import SwiftUI

struct MonthProvider: TimelineProvider {
    func placeholder(in context: Context) -> MonthEntry {
        MonthEntry(date: Date(), monthDates: generateMonthDates())
    }

    func getSnapshot(in context: Context, completion: @escaping (MonthEntry) -> Void) {
        let entry = MonthEntry(date: Date(), monthDates: generateMonthDates())
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MonthEntry>) -> Void) {
        let currentDate = Date()
        let entry = MonthEntry(date: currentDate, monthDates: generateMonthDates())
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }

    func generateMonthDates() -> [Date] {
        let calendar = Calendar.current
        let currentDate = Date()
        guard let range = calendar.range(of: .day, in: .month, for: currentDate),
              let firstDayOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: currentDate)),
              let firstWeekday = calendar.dateComponents([.weekday], from: firstDayOfMonth).weekday else {
            return []
        }
        
        let monthDates = range.compactMap { day -> Date? in
            var components = calendar.dateComponents([.year, .month], from: currentDate)
            components.day = day
            return calendar.date(from: components)
        }
        
        let offsetDates = Array(repeating: Date.distantPast, count: firstWeekday - calendar.firstWeekday) + monthDates
        return offsetDates
    }
}

struct MonthEntry: TimelineEntry {
    let date: Date
    let monthDates: [Date]
}

struct MonthWidgetEntryView: View {
    var entry: MonthProvider.Entry

    private let daysOfWeek = Calendar.current.shortWeekdaySymbols

    var body: some View {
        VStack(spacing: 4) {
            Text(entry.date, style: .date)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .padding([.bottom], 5)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
                ForEach(daysOfWeek, id: \.self) { day in
                    
                    Text(day.prefix(1))
                        .font(.system(size: 10))
                        .foregroundColor(.white)
                }
                
                ForEach(entry.monthDates, id: \.self) { date in
                    if Calendar.current.isDate(date, equalTo: Date.distantPast, toGranularity: .day) {
                        Text("")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        Text("\(Calendar.current.component(.day, from: date))")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Calendar.current.isDate(date, inSameDayAs: entry.date) ? Color.gray : Color.clear)
                            .cornerRadius(2)
                            .foregroundColor(.white)
                    }
                }
                .font(.system(size: 7))
            }
        }
        .padding()
        .containerBackground(.blue.gradient, for: .widget)
    }
}

struct MonthWidget: Widget {
    let kind: String = "MonthWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MonthProvider()) { entry in
            MonthWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Calendar")
        .description("Displays the current month with dates.")
        .supportedFamilies([.systemSmall])
    }
}

struct MonthWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MonthWidgetEntryView(entry: MonthEntry(date: .now, monthDates: MonthProvider().generateMonthDates()))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
        }
        .environment(\.colorScheme, .dark)
    }
}
