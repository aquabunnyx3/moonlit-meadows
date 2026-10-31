import AVFoundation
import SwiftUI

// MARK: - End of day (Michelle, 2026-10-30)

/// The end-of-day sequence that replaced the bedtime pop-up video: the room
/// fades to black, the sun sets over the town while its lights go out one by
/// one, the screen fades to black again, and a card names the new day and the
/// season in the game's own style — then morning. The clip lives in the asset
/// catalog as `scene-town-sunset`; without it, sleep is the fades and the card.
enum SunsetScene {
    static let videoName = "scene-town-sunset"
    static var isAvailable: Bool { DateSceneView.url(for: videoName) != nil }
}

/// The town at sundown, full-screen and silent, with no controls: the picture
/// is the transition. It ends when the clip ends; tapping skips it.
struct SunsetSceneView: View {
    let meadow: Meadow
    let finish: () -> Void

    @State private var player: AVPlayer?
    @State private var ended = false

    var body: some View {
        ZStack {
            Color.black
            if let player {
                VideoLayer(player: player)
            }
        }
        .ignoresSafeArea()
        .contentShape(.rect)
        .onTapGesture { end() }
        .task { await start() }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { note in
            guard let item = note.object as? AVPlayerItem, item === player?.currentItem else { return }
            end()
        }
        .onChange(of: meadow.isPaused) { _, isPaused in
            if isPaused { player?.pause() } else { player?.play() }
        }
        .onDisappear { player?.pause() }
    }

    private func start() async {
        guard let url = DateSceneView.url(for: SunsetScene.videoName) else { finish(); return }
        let ready = AVPlayer(url: url)
        ready.actionAtItemEnd = .pause
        ready.isMuted = true
        player = ready
        if !meadow.isPaused { ready.play() }
    }

    private func end() {
        guard !ended else { return }
        ended = true
        player?.pause()
        finish()
    }
}

/// The new day's card: the season over the day number, ink on the game's pink
/// plaque, on plain black — the shape of the classic farm-sim morning card,
/// in Moonlit Meadows' own font and colors. Shown before `wakeUp()` runs, so
/// the day it names is the one being entered (`dayCount + 1`).
struct DayCardView: View {
    let meadow: Meadow

    var body: some View {
        ZStack {
            Color.black
            VStack(spacing: 6) {
                Text("\(meadow.season.emoji) \(meadow.season.name)")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                Text("Day \(meadow.dayCount + 1)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
            }
            .foregroundStyle(Palette.ink)
            .padding(.horizontal, 36)
            .padding(.vertical, 18)
            .pixelPanel(Palette.pinkCard, edge: Palette.pinkEdge, cornerRadius: 18)
        }
        .ignoresSafeArea()
    }
}
