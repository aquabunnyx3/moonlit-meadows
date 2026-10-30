import AVFoundation
import SwiftUI

// MARK: - Date scenes

/// A date's own video (a `scene-…-date` data set, seen through your eyes, the same for every
/// farmer look). The chat opens as usual, then fades to the video filling the screen while the
/// narrator and then your date say the line over it. The video's own sound stays off, so the
/// voices play over the romance music. Pause, skip, replay and mute sit in the corner, and once
/// it's over (or skipped) "💕 Aww" closes it. Seen once, it's in the Journal to watch again.
struct DateSceneView: View {
    let meadow: Meadow
    let moment: Moment
    let video: String
    let close: () -> Void

    private enum Phase { case chat, video, done }

    @State private var phase = Phase.chat
    @State private var player: AVPlayer?
    @State private var paused = false
    @State private var replays = 0
    @State private var voiceToken: Int?
    @AppStorage("voicesMuted") private var voicesMuted = false

    /// How long the chat shows before it fades to the video.
    private static let chatSeconds = 2.2
    private static var urls: [String: URL] = [:]

    /// The video copied out to a file AVPlayer can open, once per scene.
    static func url(for video: String) -> URL? {
        if let url = urls[video] { return url }
        guard let asset = NSDataAsset(name: video) else {
            artLog.notice("Missing date video \(video, privacy: .public); showing the chat instead")
            return nil
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(video).mp4")
        do {
            try asset.data.write(to: url, options: .atomic)
        } catch {
            artLog.error("Couldn't prepare \(video, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
        urls[video] = url
        return url
    }

    /// The narrator's clip first, then your date's.
    private var clips: [String] {
        let all = VoiceLines.clips(owner: moment.personID, text: moment.text)
        return all.filter { $0.hasSuffix("-N") } + all.filter { !$0.hasSuffix("-N") }
    }

    var body: some View {
        let person = Person.find(moment.personID)

        ZStack {
            ChatDialogScreen {
                ChatScene(meadow: meadow, speaker: person.map { ChatSpeaker.person($0) } ?? ChatSpeaker.narrator(nil),
                          name: person?.name, text: moment.text, speaksAloud: false)
            } controls: {
                Text(moment.title).font(.headline)
            }

            if phase != .chat {
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
                        if phase == .done {
                            VStack(spacing: 8) {
                                Text(moment.title).font(.headline).foregroundStyle(.white)
                                DialogButton(label: "💕 Aww", action: finish)
                                    .frame(maxWidth: 320)
                            }
                            .transition(.opacity)
                        }
                    }
                    .padding(16)
                }
                .ignoresSafeArea()
                .transition(.opacity)
            }
        }
        .task { await start() }
        .task(id: replays) { await playVoices() }
        .onReceive(NotificationCenter.default.publisher(for: .AVPlayerItemDidPlayToEndTime)) { note in
            guard let item = note.object as? AVPlayerItem, item === player?.currentItem else { return }
            withAnimation(.easeOut(duration: 0.4)) { phase = .done }
        }
        .onChange(of: meadow.isPaused) { _, isPaused in
            if isPaused { holdPlayback() } else if !paused { carryOn() }
        }
        .onDisappear {
            player?.pause()
            MusicPlayer.shared.stopVoice(token: voiceToken)
        }
    }

    /// The line, over the bottom of the video, so it can be read with voices muted.
    private var caption: some View {
        Text(moment.text)
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
            if phase == .video {
                control(paused ? "play.fill" : "pause.fill", paused ? "Resume" : "Pause") { togglePause() }
                control("forward.end.fill", "Skip to the end") { skip() }
            }
            control("arrow.counterclockwise", "Watch again") { replay() }
            control(voicesMuted ? "speaker.slash.fill" : "speaker.wave.2.fill", voicesMuted ? "Unmute voices" : "Mute voices") {
                voicesMuted.toggle()
                if voicesMuted { MusicPlayer.shared.stopVoice(token: voiceToken) }
            }
        }
    }

    private func start() async {
        guard let url = Self.url(for: video) else { return }
        let ready = AVPlayer(url: url)
        ready.isMuted = true
        ready.actionAtItemEnd = .pause
        player = ready
        try? await Task.sleep(for: .seconds(Self.chatSeconds))
        if Task.isCancelled { return }
        withAnimation(.easeInOut(duration: 0.8)) { phase = .video }
        if !meadow.isPaused { ready.play() }
        replays += 1
    }

    /// Says the line over the video: each time it starts, and again on replay.
    private func playVoices() async {
        guard replays > 0 else { return }
        MusicPlayer.shared.stopVoice(token: voiceToken)
        if voicesMuted || clips.isEmpty { return }
        // A little moment for the picture to fade in before anyone speaks.
        try? await Task.sleep(for: .seconds(0.6))
        if Task.isCancelled || phase == .done { return }
        voiceToken = MusicPlayer.shared.speak(clips)
        if paused || meadow.isPaused { MusicPlayer.shared.pauseVoice(token: voiceToken) }
    }

    private func togglePause() {
        paused.toggle()
        if paused { holdPlayback() } else { carryOn() }
    }

    private func holdPlayback() {
        player?.pause()
        MusicPlayer.shared.pauseVoice(token: voiceToken)
    }

    private func carryOn() {
        guard phase == .video else { return }
        player?.play()
        MusicPlayer.shared.resumeVoice(token: voiceToken)
    }

    private func skip() {
        paused = false
        player?.pause()
        if let duration = player?.currentItem?.duration, duration.isNumeric {
            player?.seek(to: duration)
        }
        MusicPlayer.shared.stopVoice(token: voiceToken)
        withAnimation(.easeOut(duration: 0.4)) { phase = .done }
    }

    private func replay() {
        guard let player else { return }
        paused = false
        player.seek(to: .zero)
        withAnimation(.easeOut(duration: 0.3)) { phase = .video }
        if !meadow.isPaused { player.play() }
        replays += 1
    }

    private func finish() {
        player?.pause()
        MusicPlayer.shared.stopVoice(token: voiceToken)
        close()
    }
}
