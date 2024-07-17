//
//  AudioPlayerWidget.swift
//  CustomWidgets
//
//  Created by Sachin Agrawal on 7/6/24.
//

import WidgetKit
import SwiftUI
import AVFoundation
import OSLog
import AppIntents

enum Sound: String {
    case main
    case song

    var url: URL {
        Bundle.main.url(forResource: rawValue, withExtension: "mp3")!
    }
}

final class AudioPlayer {
    static let shared = AudioPlayer()

    private var player: AVAudioPlayer?
    private var state: State = .stopped

    private enum State {
        case playing
        case paused
        case stopped
        case disabled
    }

    private init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            state = .disabled
        }
    }

    var isEnabled: Bool {
        state != .disabled
    }

    var isPlaying: Bool {
        state == .playing
    }

    func play(sound: Sound) {
        guard isEnabled else { return }
        player = player ?? createPlayer(for: sound)
        player?.play()
        state = .playing
    }

    func pause() {
        guard isEnabled else { return }
        player?.pause()
        state = .paused
    }

    func stop() {
        guard isEnabled else { return }
        player?.stop()
        state = .stopped
        player = nil
    }

    private func createPlayer(for sound: Sound) -> AVAudioPlayer? {
        do {
            return try AVAudioPlayer(contentsOf: sound.url)
        } catch {
            return nil
        }
    }
}

struct AudioWidgetPlayIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Play Music"

    private let sound: Sound

    init(sound: Sound) {
        self.sound = sound
    }

    init() {
        self.init(sound: .song)
    }

    func perform() async throws -> some IntentResult {
        AudioPlayer.shared.play(sound: sound)
        return .result()
    }
}

struct AudioWidgetPauseIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Pause Music"

    func perform() async throws -> some IntentResult {
        AudioPlayer.shared.pause()
        return .result()
    }
}

struct AudioWidgetStopIntent: AudioPlaybackIntent {
    static var title: LocalizedStringResource = "Stop Music"

    func perform() async throws -> some IntentResult {
        AudioPlayer.shared.stop()
        return .result()
    }
}

struct AudioWidget: Widget {
    let kind: String = "AudioWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            AudioWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Audio")
        .description("Play and pause music directly in the background.")
        .supportedFamilies([.systemSmall])
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> AudioWidgetEntry {
        AudioWidgetEntry(isPlaying: false)
    }

    func getSnapshot(in context: Context, completion: @escaping (AudioWidgetEntry) -> Void) {
        let isPlaying = AudioPlayer.shared.isPlaying
        completion(AudioWidgetEntry(isPlaying: isPlaying))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<AudioWidgetEntry>) -> Void) {
        let isPlaying = AudioPlayer.shared.isPlaying
        let entry = AudioWidgetEntry(isPlaying: isPlaying)
        completion(Timeline(entries: [entry], policy: .never))
    }
}

struct AudioWidgetEntry: TimelineEntry {
    var date: Date = .now
    var isPlaying: Bool
}

struct AudioWidgetEntryView: View {
    var entry: AudioWidgetEntry

    var body: some View {
        VStack(alignment: .leading) {
            Text("Audio Player")
                .font(.headline)
            
            Spacer()
            
            albumArtistView()
            
            Spacer()
            
            AudioWidgetButtonsView()
        }
        .containerBackground(.red.gradient, for: .widget)
        .foregroundColor(.white)
    }
}

struct AudioWidgetButtonsView: View {
    var body: some View {
        HStack(spacing: 8) {
            Button(intent: AudioWidgetPlayIntent(sound: .song)) {
                Image(systemName: "play")
                    .font(.system(size: 12))
                    .frame(width: 12)
            }

            Button(intent: AudioWidgetPauseIntent()) {
                Image(systemName: "pause")
                    .font(.system(size: 12))
                    .frame(width: 12)
            }

            Button(intent: AudioWidgetStopIntent()) {
                Image(systemName: "stop")
                    .font(.system(size: 12))
                    .frame(width: 12)
            }
        }
        .buttonStyle(.bordered)
        .tint(.black)
    }
}

struct albumArtistView: View {
    var body: some View {
        HStack {
            Image("albumcover")
                .resizable()
                .frame(width: 40, height: 40)
                .padding(.leading, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("Never Gonna Give You Up")
                    .font(.system(size: 12))
                Text("Rick Astley")
                    .font(.system(size: 10))
            }
        }
    }
}

struct AudioWidget_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            AudioWidgetEntryView(entry: AudioWidgetEntry(isPlaying: false))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
        }
        .environment(\.colorScheme, .dark)
    }
}
