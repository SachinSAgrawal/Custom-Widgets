//
//  InputWidget.swift
//  CustomWidgets
//
//  Created by Sachin Agrawal on 6/24/24.
//

import WidgetKit
import SwiftUI

struct InputProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> InputEntry {
        InputEntry(date: Date(), configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> InputEntry {
        InputEntry(date: Date(), configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<InputEntry> {
        var entries: [InputEntry] = []

        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = InputEntry(date: entryDate, configuration: configuration)
            entries.append(entry)
        }

        return Timeline(entries: entries, policy: .atEnd)
    }
}

struct InputEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationAppIntent
}

struct InputWidgetEntryView: View {
    var entry: InputProvider.Entry

    var body: some View {
        VStack(spacing: 6) {
            Text("Input:")
            Text(entry.configuration.input)
            VStack {
                Text("Press and hold on the widget to edit the input text.")
                    .font(.system(size: 12))
                Text("Tap on the widget to have the text be deep linked.")
                    .font(.system(size: 12))
            }
        }
        .font(.system(size: 24))
        .containerBackground(.indigo.gradient, for: .widget)
        .foregroundColor(.white)
    }
}

struct InputWidget: Widget {
    let kind: String = "InputWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: InputProvider()) { entry in
            InputWidgetEntryView(entry: entry)
                .widgetURL(URL(string: "inputwidget://show?text=\(entry.configuration.input.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")!)
        }
        .configurationDisplayName("Input")
        .description("Displays inputted text that can be deep linked.")
        .supportedFamilies([.systemMedium])
    }
}

extension ConfigurationAppIntent {
    fileprivate static var def: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.input = "Default"
        return intent
    }
}

/*
#Preview(as: .systemSmall) {
    Widgets()
} timeline: {
    SimpleEntry(date: .now, configuration: .def)
}
*/
 
struct InputWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            InputWidgetEntryView(entry: InputEntry(date: .now, configuration: .def))
                .previewContext(WidgetPreviewContext(family: .systemMedium))
        }
        .environment(\.colorScheme, .dark)
    }
}
