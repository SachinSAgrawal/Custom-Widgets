//
//  ImageWidget.swift
//  CustomWidgets
//
//  Created by Sachin Agrawal on 6/24/24.
//

import WidgetKit
import SwiftUI

struct ImageProvider: TimelineProvider {
    func placeholder(in context: Context) -> ImageEntry {
        ImageEntry(date: Date())
    }

    func getSnapshot(in context: Context, completion: @escaping (ImageEntry) -> Void) {
        let entry = ImageEntry(date: Date())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ImageEntry>) -> Void) {
        let currentDate = Date()
        let entry = ImageEntry(date: currentDate)
        let timeline = Timeline(entries: [entry], policy: .atEnd)
        completion(timeline)
    }
}

struct ImageEntry: TimelineEntry {
    let date: Date
}

struct ImageWidgetEntryView: View {
    var entry: ImageProvider.Entry

    var body: some View {
        VStack {
            Image("rickastley")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .cornerRadius(10)
        }
        .containerBackground(.black, for: .widget)
    }
}

struct ImageWidget: Widget {
    let kind: String = "ImageWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ImageProvider()) { entry in
            ImageWidgetEntryView(entry: entry)
        }
        .contentMarginsDisabled()
        .containerBackgroundRemovable(false)
        .configurationDisplayName("Image")
        .description("Displays a large image of Rick Astley.")
        .supportedFamilies([.systemLarge])
    }
}

struct ImageWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ImageWidgetEntryView(entry: ImageEntry(date: .now))
                .previewContext(WidgetPreviewContext(family: .systemLarge))
        }
        .environment(\.colorScheme, .dark)
    }
}
