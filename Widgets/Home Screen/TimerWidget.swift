//
//  TimerWidget.swift
//  CustomWidgets
//
//  Created by Sachin Agrawal on 6/24/24.
//

import WidgetKit
import SwiftUI

struct TimerProvider: TimelineProvider {
    func placeholder(in context: Context) -> TimerEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (TimerEntry) -> Void) {
        completion(.placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<TimerEntry>) -> Void) {
        let currentDate = Date()
        let nearEndDate = Calendar.current.date(byAdding: .second, value: 20, to: currentDate) ?? currentDate
        let endDate = Calendar.current.date(byAdding: .second, value: 30, to: currentDate) ?? currentDate

        let entries = [
            TimerEntry(date: currentDate, displayDate: endDate, countdownState: .counting),
            TimerEntry(date: nearEndDate, displayDate: endDate, countdownState: .nearEnd),
            TimerEntry(date: endDate, displayDate: endDate, countdownState: .end)
        ]

        let timeline = Timeline(entries: entries, policy: .never)
        completion(timeline)
    }
}

struct TimerEntry: TimelineEntry {
    let date: Date
    var displayDate: Date
    var countdownState: CountdownState
    
    static var placeholder: Self {
        .counting
    }

    static var counting: Self {
        .init(
            date: .now,
            displayDate: Calendar.current.date(byAdding: .minute, value: 1, to: .now) ?? .now,
            countdownState: .counting
        )
    }

    static var nearEnd: Self {
        .init(
            date: .now,
            displayDate: Calendar.current.date(byAdding: .second, value: 10, to: .now) ?? .now,
            countdownState: .nearEnd
        )
    }

    static var end: Self {
        .init(
            date: .now,
            displayDate: .now,
            countdownState: .end
        )
    }
    
    enum CountdownState: Codable {
        case counting
        case nearEnd
        case end
    }
}

struct TimerWidgetEntryView: View {
    var entry: TimerProvider.Entry

    var body: some View {
        VStack {
            Text("Timer:")
            contentView
        }
        .multilineTextAlignment(.center)
        .font(.system(size: 30))
        .containerBackground(.green.gradient, for: .widget)
    }

    @ViewBuilder
    private var contentView: some View {
        timerView
            .foregroundStyle(textColor)
            .id(entry.countdownState)
    }

    @ViewBuilder
    private var timerView: some View {
        switch entry.countdownState {
        case .counting, .nearEnd:
            Text(entry.displayDate, style: .timer)
        case .end:
            Text("End")
        }
    }

    private var textColor: Color {
        switch entry.countdownState {
        case .counting:
            .primary
        case .nearEnd:
            .red
        case .end:
            .secondary
        }
    }
}

struct TimerWidget: Widget {
    let kind: String = "TimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: TimerProvider()) { entry in
            TimerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Timer")
        .description("Displays the time counting down from 1 minute.")
        .supportedFamilies([.systemSmall])
    }
}

struct TimerWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TimerWidgetEntryView(entry: .counting)
                .previewContext(WidgetPreviewContext(family: .systemSmall))

            TimerWidgetEntryView(entry: .nearEnd)
                .previewContext(WidgetPreviewContext(family: .systemSmall))

            TimerWidgetEntryView(entry: .end)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
        }
        .environment(\.colorScheme, .dark)
    }
}
