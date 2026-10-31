import AVFoundation
import SwiftUI

// MARK: - Bedtime scenes (added by Merlin, 2026-10-29, while Claude was out of tokens)

/// Your farmer's goodnight scene: when you Rest, a short video of *your* farmer — your body,
/// hairstyle and outfit — yawning and saying "It's late... time to get some rest." plays over
/// the bedroom, then the usual sleeping room takes over until morning.
///
/// One video per look lives in `Assets.xcassets` as a data set named after the look, like
/// `scene-bedtime-female-long-waves-jacket`. The twelve names are:
/// females (jacket / sundress): curly-buns, long-waves, bald;
/// males (jacket / hoodie): curly-top, curly-fade, bald.
/// If a look's video isn't in the app, sleep is exactly as it was before: no scene, just the
/// blanket. Nothing about the night itself changes either way.
enum BedtimeScene {
    /// The data set name for the farmer's current look, or `nil` when that video isn't in the app.
    static func videoName(for meadow: Meadow) -> String? {
        guard let look = meadow.farmerLook else { return nil }
        let styles = look.gender.hairStyles
        let styleName = look.hairStyle >= 0 && look.hairStyle < styles.count ? styles[look.hairStyle] : ""
        let hair: String
        switch styleName {
        case "Curly Buns": hair = "curly-buns"
        case "Long Waves": hair = "long-waves"
        case "Curly Top": hair = "curly-top"
        case "Curly Fade": hair = "curly-fade"
        case "Bald": hair = "bald"
        default: return nil
        }
        let cut = Outfit.find(look.outfit)?.cut ?? .jacket
        let outfit: String
        switch (look.gender, cut) {
        case (_, .sundress): outfit = "sundress"
        case (.male, .hoodie): outfit = "hoodie"
        default: outfit = "jacket"
        }
        let name = "scene-bedtime-\(look.gender.rawValue)-\(hair)-\(outfit)"
        // Skin variants (Michelle, 2026-10-30): tones 1-3 (Fair, Golden, Tan)
        // have their own data sets, `...-skin<tone>`; tone 4 (Deep) is the
        // art's own skin and uses the base name. A variant that isn't in the
        // app yet falls back to the base video, so sleep never breaks while
        // the variant set is still being made.
        if look.skinTone >= 1 && look.skinTone < 4 {
            let variant = "\(name)-skin\(look.skinTone)"
            if DateSceneView.url(for: variant) != nil { return variant }
        }
        // Same check the date scenes use: no data set, no scene.
        return DateSceneView.url(for: name) != nil ? name : nil
    }
}

/// Plays one bedtime video full-screen over the bedroom. Unlike the date scenes, the video's
/// own sound is ON — your farmer's line is baked into the video. Pause, replay, mute and skip
/// sit in the corner; tapping the picture also ends the scene (and, like tapping the room,
/// asks to wake early). When it ends, `finish` hands sleep back to the bedroom.
struct BedtimeSceneView: View {
    let meadow: Meadow
    let video: String
    let finish: () -> Void

    @State private var player: AVPlayer?
    @State private var paused = false
    @State private var muted = false

    var body: some View {
        ZStack {
            Color.black
            if let player {
                VideoLayer(player: player)
            }
            VStack(spacing: 12) {
                HStack {
                    Spacer()
                    controls
                }
                Spacer()
                caption
            }
            .padding(16)
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
            if isPaused { player?.pause() } else if !paused { player?.play() }
        }
        .onDisappear { player?.pause() }
    }

    /// The line, over the bottom of the video, so it can be read with the sound off.
    private var caption: some View {
        Text("It's late... time to get some rest.")
            .font(.subheadline.bold())
            .foregroundStyle(.white)
            .multilineTextAlignment(.center)
            .shadow(color: .black.opacity(0.8), radius: 3)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Palette.ink.opacity(0.55), in: .rect(cornerRadius: 14))
            .frame(maxWidth: 640)
    }

    private var controls: some View {
        let side: CGFloat = 40
        func control(_ symbol: String, _ label: String, action: @escaping () -> Void) -> some View {
            Button(action: action) {
                Image(systemName: symbol)
                    .font(.system(size: side * 0.42, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: side, height: side)
                    .pixelPanel(Palette.ink.opacity(0.75), edge: Palette.lilacEdge, cornerRadius: side * 0.25)
            }
            .buttonStyle(SquishButtonStyle())
            .accessibilityLabel(label)
        }
        return HStack(spacing: 8) {
            control(paused ? "play.fill" : "pause.fill", paused ? "Resume" : "Pause") { togglePause() }
            control("forward.end.fill", "Skip the scene") { end() }
            control("arrow.counterclockwise", "Watch again") { replay() }
            control(muted ? "speaker.slash.fill" : "speaker.wave.2.fill", muted ? "Unmute" : "Mute") {
                muted.toggle()
                player?.isMuted = muted
            }
        }
    }

    private func start() async {
        guard let url = DateSceneView.url(for: video) else { finish(); return }
        let ready = AVPlayer(url: url)
        ready.actionAtItemEnd = .pause
        player = ready
        if !meadow.isPaused { ready.play() }
    }

    private func togglePause() {
        paused.toggle()
        if paused { player?.pause() } else if !meadow.isPaused { player?.play() }
    }

    private func replay() {
        guard let player else { return }
        paused = false
        player.seek(to: .zero)
        if !meadow.isPaused { player.play() }
    }

    private func end() {
        player?.pause()
        finish()
    }
}
