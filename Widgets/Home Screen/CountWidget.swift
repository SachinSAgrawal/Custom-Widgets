//
//  CountWidget.swift
//  WidgetsExtension
//
//  Created by Sachin Agrawal on 7/6/24.
//

import SwiftUI
import WidgetKit
import AppIntents

struct CountProvider: TimelineProvider {
    func placeholder(in context: Context) -> CountEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (CountEntry) -> Void) {
        completion(.placeholder)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CountEntry>) -> Void) {
        let id = EventCounter.placeholder.id
        let key = CounterDefaultKey.eventCounter(id: id)
        let value = UserDefaults.standard.integer(forKey: key)
        let entry = CountEntry(counter: .init(id: id, value: value))
        completion(.init(entries: [entry], policy: .never))
    }
}

struct CountEntry: TimelineEntry {
    var date: Date = .now
    var counter: EventCounter

    static var placeholder: Self {
        .init(counter: .placeholder)
    }
}

struct CountWidgetEntryView: View {
    let entry: CountEntry

    var body: some View {
        VStack {
            CountWidgetHeaderView(title: "Interactive")
            
            Spacer()
            
            HStack {
                Text("Counter: \(entry.counter.value)")
                    .font(.subheadline)
                
                Spacer()
            }
            
            Spacer()
            
            HStack {
                Button(intent: CountWidgetIncreaseIntent(counter: entry.counter)) {
                    Image(systemName: "plus")
                        .font(.system(size: 12))
                        .frame(width: 12)
                        .padding(1)
                }
                
                Button(intent: CountWidgetResetIntent(counter: entry.counter)) {
                    Image(systemName: "arrow.circlepath")
                        .font(.system(size: 12))
                        .frame(width: 12)
                }
            }
            .buttonStyle(.bordered)
            .tint(.black)
        }
        .containerBackground(.orange.gradient, for: .widget)
        .foregroundColor(.white)
    }
}

struct CountWidget: Widget {
    private let kind: String = "countWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CountProvider()) {
            CountWidgetEntryView(entry: $0)
        }
        .configurationDisplayName("Count")
        .description("Interact with buttons to increment or reset a counter.")
        .supportedFamilies([.systemSmall])
    }
}

struct CountWidgetPreviews: PreviewProvider {
    static var previews: some View {
        Group {
            CountWidgetEntryView(entry: .placeholder)
                .previewContext(WidgetPreviewContext(family: .systemSmall))
        }
        .environment(\.colorScheme, .dark)
    }
}

struct EventCounter: Identifiable {
    var id: Int
    var value: Int

    static var placeholder: Self {
        .init(id: 1, value: 1)
    }
}

struct CountWidgetHeaderView: View {
    var title: LocalizedStringResource

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .fixedSize()
            Spacer(minLength: 0)
        }
    }
}

struct CountWidgetIncreaseIntent: AppIntent {
    static var title: LocalizedStringResource = "Increase Event Counter"

    @Parameter(title: "Event Counter")
    var counter: EventCounterEntity

    init(counter: EventCounter) {
        self.counter = .init(from: counter)
    }

    init() {}

    func perform() async throws -> some IntentResult {
        let key = CounterDefaultKey.eventCounter(id: counter.id)
        UserDefaults.standard.set(counter.value + 1, forKey: key)
        return .result()
    }
}

struct CountWidgetResetIntent: AppIntent {
    static var title: LocalizedStringResource = "Reset Event Counter"

    @Parameter(title: "Event Counter")
    var counter: EventCounterEntity

    init(counter: EventCounter) {
        self.counter = .init(from: counter)
    }

    init() {}

    func perform() async throws -> some IntentResult {
        let key = CounterDefaultKey.eventCounter(id: counter.id)
        UserDefaults.standard.set(0, forKey: key)
        return .result()
    }
}

struct EventCounterEntity: AppEntity, Identifiable, Hashable {
    var id: EventCounter.ID
    var value: Int

    init(id: EventCounter.ID, value: Int) {
        self.id = id
        self.value = value
    }

    init(from counter: EventCounter) {
        id = counter.id
        value = counter.value
    }

    var displayRepresentation: DisplayRepresentation {
        .init(title: "\(value)")
    }

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Event Counter")
    static var defaultQuery = EventCounterEntityQuery()
}

struct EventCounterEntityQuery: EntityQuery, Sendable {
    func entities(for identifiers: [EventCounterEntity.ID]) async throws -> [EventCounterEntity] {
        identifiers.map {
            let key = CounterDefaultKey.eventCounter(id: $0)
            let value = UserDefaults.standard.integer(forKey: key)
            return .init(id: $0, value: value)
        }
    }

    func suggestedEntities() async throws -> [EventCounterEntity] {
        [.init(from: .placeholder)]
    }
}

enum CounterDefaultKey {
    static func eventCounter(id: Int) -> String {
        "eventCounter-\(id)"
    }
}
