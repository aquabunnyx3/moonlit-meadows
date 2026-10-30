import AVFoundation
import SwiftUI

// MARK: - Intro drama (added by Merlin, 2026-10-30, while Claude was rate-limited)

/// The opening movie: a first-person anime mini-drama (about 80 seconds with the female
/// farmer's narration, about 67 with the male's) that plays once, right after you make
/// your farmer, replacing the old painted-slideshow intro. The farmer is never shown —
/// the narration is her (or his) own thoughts. The two cuts live in Assets as the data
/// sets `intro-drama-female` and `intro-drama-male`; if one is missing, the intro is
/// simply skipped, exactly like a missing bedtime video.
///
/// The movie is widescreen, so on a tall screen a friendly card asks the player to turn
/// the device sideways first. When it ends (or is skipped), `Meadow.finishIntro` raises
/// the "Let's get started" welcome card over the farm.
struct IntroDramaView: View {
    let meadow: Meadow
    @State private var player: AVPlayer?
    @State private var started = false
    @State private var paused = false
    @State private var muted = false
    /// The fade-from-black beat between "Start farming" and the movie: the screen
    /// arrives black, holds a moment, then lifts into the rotate card or the film.
    @State private var curtainLifted = false
    @State private var startWhenLifted = false

    private var videoName: String {
        meadow.farmerGender == .male ? "intro-drama-male" : "intro-drama-female"
    }

    var body: some View {
        GeometryReader { geo in
            let portrait = geo.size.height > geo.size.width * 1.05
            ZStack {
                Color.black
                if started, let player {
                    VideoLayer(player: player)
                }
                if !started && portrait {
                    rotateCard
                }
                if started {
                    VStack {
                        HStack {
                            Spacer()
                            controls
                        }
                        Spacer()
                    }
                    .padding(16)
                }
                if !curtainLifted {
                    Color.black
                        .ignoresSafeArea()
                }
            }
            .ignoresSafeArea()
            .onAppear {
                // The movie carries its own music and narration, so the game's
                // song stops outright (both crossfade players, not just the
                // active one) instead of playing on underneath it.
                MusicPlayer.shared.silenceMusic()
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(700))
                    withAnimation(.easeInOut(duration: 0.9)) { curtainLifted = true }
                    if !portrait || startWhenLifted { start() }
                }
            }
            .onChange(of: portrait) { _, isPortrait in
                if !isPortrait && !started {
                    if curtainLifted { start() } else { startWhenLifted = true }
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { note in
                guard let item = note.object as? AVPlayerItem, item === player?.currentItem else { return }
                finish()
            }
            .onDisappear { player?.pause() }
        }
        .background(Palette.ink.ignoresSafeArea())
        .ignoresSafeArea()
        .fontDesign(.rounded)
    }

    /// Shown on tall screens before the movie: turn the device for the full picture.
    private var rotateCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "play.rectangle.fill")
                .font(.system(size: 52))
                .foregroundStyle(Palette.rose)
            Text("The intro is a little movie")
                .font(.title3.bold())
                .foregroundStyle(Palette.cream)
                .multilineTextAlignment(.center)
            Text("Please turn your device to landscape so it fills the screen — then tap Play.")
                .font(.callout)
                .foregroundStyle(Palette.cream.opacity(0.85))
                .multilineTextAlignment(.center)
            DialogButton(label: "Play ▸") { start() }
            DialogButton(label: "Skip the intro", pink: false) { finish() }
        }
        .padding(28)
        .frame(maxWidth: 430)
        .padding(24)
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
            control(paused ? "play.fill" : "pause.fill", paused ? "Resume" : "Pause") {
                paused.toggle()
                if paused { player?.pause() } else { player?.play() }
            }
            control("forward.end.fill", "Skip the intro") { finish() }
            control(muted ? "speaker.slash.fill" : "speaker.wave.2.fill", muted ? "Unmute" : "Mute") {
                muted.toggle()
                player?.isMuted = muted
            }
        }
    }

    private func start() {
        guard !started else { return }
        started = true
        guard let url = DateSceneView.url(for: videoName) else { finish(); return }
        let ready = AVPlayer(url: url)
        ready.actionAtItemEnd = .pause
        player = ready
        ready.play()
    }

    private func finish() {
        guard meadow.showsIntro else { return }
        player?.pause()
        meadow.finishIntro()
    }
}

/// The card that greets you on the farm when the movie ends: "Let's get started!"
/// The deck's action button dismisses it too (see `ControlDeck`), as does its own
/// button. It shows exactly once per save (`introWelcomeSeen`).
struct WelcomeCard: View {
    let meadow: Meadow

    var body: some View {
        ZStack {
            Palette.ink.opacity(0.45)
                .ignoresSafeArea()
            VStack(spacing: 12) {
                Text("🌙").font(.system(size: 40))
                Text("Let's get started!")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text("Your meadow is waiting.")
                    .font(.callout)
                    .opacity(0.8)
                    .multilineTextAlignment(.center)
                DialogButton(label: "Begin ▸") { meadow.dismissWelcome() }
                Text("…or press the action button")
                    .font(.caption)
                    .opacity(0.6)
            }
            .padding(24)
            .frame(maxWidth: 420)
            .pixelPanel(Palette.cream, edge: Palette.lilacEdge, cornerRadius: 20)
            .padding(24)
        }
        .foregroundStyle(Palette.ink)
        .fontDesign(.rounded)
    }
}
