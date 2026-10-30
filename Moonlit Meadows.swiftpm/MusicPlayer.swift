import AVFoundation
import SwiftUI
import UIKit

// MARK: - Which song plays

extension Meadow {
    /// Every 7th day is a festival day, celebrating the current season's festival.
    var isFestivalDay: Bool { dayCount > 0 && dayCount % 7 == 0 }

    /// The background music for what's on screen right now (a `music-…` file in the assets).
    var musicTrack: String {
        if isAtMainMenu { return "music-menu" }
        if showsIntro { return "music-story" }
        if isSleeping { return "music-sleep" }
        if let scene = presentedScene {
            switch scene {
            case .story(let event):
                return event.path == .romance || event.isCrossroads ? "music-romance" : "music-story"
            case .moment(let moment):
                return moment.video != nil || isDating(moment.personID) ? "music-romance" : "music-story"
            case .completion:
                return "music-story"
            }
        }
        if isBedtime { return "music-night" }
        if let personID = focusedPersonID, profileTalk != nil {
            return isDating(personID) ? "music-romance" : "music-story"
        }
        if isAtHome { return "music-home" }
        if isFestivalDay && timeOfDay != .night { return "music-festival-\(season.rawValue)" }
        switch timeOfDay {
        case .dawn, .day: return "music-day"
        case .dusk: return "music-dusk"
        case .night: return "music-night"
        }
    }

    /// Which bell the last change of light rang: night from dusk's end, day from morning.
    var isNightBell: Bool { timeOfDay == .night }

    /// Someone is talking, so the music sits lower.
    var isDialogueShowing: Bool {
        presentedScene != nil || profileTalk != nil || (isBedtime && !isSleeping) || showsIntro
    }
}

extension View {
    /// Plays the right song for each scene, crossfading as you move around.
    func backgroundMusic(_ meadow: Meadow) -> some View {
        modifier(BackgroundMusic(meadow: meadow))
    }
}

private struct BackgroundMusic: ViewModifier {
    let meadow: Meadow
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(MusicPlayer.volumeKey) private var volume = MusicPlayer.defaultVolume

    func body(content: Content) -> some View {
        content
            .onChange(of: meadow.musicTrack, initial: true) { _, track in
                MusicPlayer.shared.play(track)
            }
            .onChange(of: meadow.isDialogueShowing || meadow.isPaused, initial: true) { _, quiet in
                MusicPlayer.shared.isDucked = quiet
            }
            .onChange(of: volume, initial: true) { _, value in
                MusicPlayer.shared.volume = Float(value)
            }
            .onChange(of: meadow.isNightBell) { _, isNight in
                // A bell when day turns to night and night to day, not on menus or the intro.
                guard !meadow.isAtMainMenu && !meadow.showsIntro && !meadow.showsFarmerCreator else { return }
                MusicPlayer.shared.playEffect(isNight ? .nightBell : .dayBell)
            }
            .onChange(of: meadow.voiceCue) { _, cue in
                guard let cue else { return }
                MusicPlayer.shared.speak(VoiceLines.clips(owner: cue.owner, text: cue.text, farmer: meadow.farmerGender))
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .background { MusicPlayer.shared.suspend() }
                if phase == .active { MusicPlayer.shared.resume() }
            }
    }
}

// MARK: - Sound effects

/// One-shot sounds (`sfx-…` data sets in the assets). They play over the music, which keeps going.
enum SoundEffect: String, CaseIterable {
    case buttonTap = "sfx-button-tap"
    case dayBell = "sfx-day-bell"
    case nightBell = "sfx-night-bell"
    case startSparkle = "sfx-start-sparkle"
}

// MARK: - Player

/// Loops each song with no gap (the silence MP3s add at the start and end is trimmed) and
/// crossfades between songs. Uses the ambient audio category, so the silent switch mutes it
/// and it mixes with anything else that's playing.
@MainActor
final class MusicPlayer {
    static let shared = MusicPlayer()
    static let volumeKey = "musicVolume"
    static let defaultVolume = 0.6

    /// 0 to 1, from Settings.
    var volume: Float = Float(MusicPlayer.defaultVolume)
    /// Lower under dialogue and the pause menu.
    var isDucked = false

    /// Music is always quiet: at full Settings volume it still sits under the game.
    private static let baseLevel: Float = 0.5
    /// Effects are quiet too, a little softer again while someone is talking.
    private static let effectLevel: Float = 0.35
    /// Voices sit clearly above the (lowered) music.
    private static let voiceLevel: Float = 1.0
    private static let duckLevel: Float = 0.45
    /// Even lower while a voice line is playing.
    private static let voiceDuckLevel: Float = 0.5
    /// A beat of silence between clips in one line (the narrator, then the character).
    static let clipGap = 0.5
    private static let fadeSeconds: Float = 1.6

    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var activeIndex = 0
    private var currentTrack: String?
    private var buffers: [String: AVAudioPCMBuffer] = [:]
    private var effectPlayers: [SoundEffect: AVAudioPlayerNode] = [:]
    private var blipPlayer: AVAudioPlayerNode?
    private var blipPitch: AVAudioUnitVarispeed?
    private var voicePlayer: AVAudioPlayerNode?
    private var voiceFormat: AVAudioFormat?
    private var voiceToken = 0
    /// When the voice line now playing ends (with its pauses).
    private var voiceEnds = Date.distantPast
    private var loggedMissingVoices: Set<String> = []
    /// Clips to say before the next line, like your answer before their reply.
    var voiceLeadIn: [String] = []
    private var fader: Task<Void, Never>?
    private var isSetUp = false

    private init() {}

    func play(_ track: String) {
        guard track != currentTrack else { return }
        setUpIfNeeded()
        guard isSetUp, let buffer = buffer(for: track) else {
            artLog.notice("Missing music \(track, privacy: .public)")
            return
        }
        currentTrack = track
        activeIndex = 1 - activeIndex
        let player = players[activeIndex]
        player.stop()
        engine.connect(player, to: engine.mainMixerNode, format: buffer.format)
        player.volume = 0
        player.scheduleBuffer(buffer, at: nil, options: .loops)
        if !engine.isRunning { try? engine.start() }
        player.play()
        startFading()
    }

    /// Plays a sound once, from the start (a quick second tap restarts it).
    func playEffect(_ effect: SoundEffect) {
        setUpIfNeeded()
        guard isSetUp, let buffer = buffer(for: effect.rawValue) else {
            artLog.notice("Missing sound \(effect.rawValue, privacy: .public)")
            return
        }
        let player: AVAudioPlayerNode
        if let existing = effectPlayers[effect] {
            player = existing
        } else {
            player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: engine.mainMixerNode, format: buffer.format)
            effectPlayers[effect] = player
        }
        // The start sparkle plays on its own (the music is paused), so it can be a little fuller.
        player.volume = effect == .startSparkle ? 0.7 : Self.effectLevel * (isDucked ? 0.7 : 1)
        if !engine.isRunning { try? engine.start() }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
    }

    /// How long each of these voice clips runs, in seconds (0 for a missing one).
    func clipSeconds(_ ids: [String]) -> [Double] {
        ids.map { id in
            guard let buffer = buffer(for: id, keeps: false) else { return 0 }
            return Double(buffer.frameLength) / buffer.format.sampleRate
        }
    }

    private static func silence(_ seconds: Double, like buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        let frames = AVAudioFrameCount(seconds * buffer.format.sampleRate)
        guard let gap = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: frames),
              let channels = gap.floatChannelData else { return nil }
        gap.frameLength = frames
        for channel in 0..<Int(buffer.format.channelCount) {
            channels[channel].update(repeating: 0, count: Int(frames))
        }
        return gap
    }

    /// Stops the song where it is, right away (no fade). The next song starts from its beginning.
    func pauseMusic() {
        guard isSetUp else { return }
        players[activeIndex].pause()
        currentTrack = nil
    }

    /// A soft talk blip, at a pitch for whoever's talking. Quieter than the other sounds.
    func playBlip(pitch: Float) {
        setUpIfNeeded()
        guard isSetUp, let buffer = buffer(for: "sfx-talk-blip") else {
            if !loggedMissingVoices.contains("sfx-talk-blip") {
                loggedMissingVoices.insert("sfx-talk-blip")
                artLog.notice("Missing sound sfx-talk-blip")
            }
            return
        }
        if blipPlayer == nil {
            let player = AVAudioPlayerNode(), varispeed = AVAudioUnitVarispeed()
            engine.attach(player)
            engine.attach(varispeed)
            engine.connect(player, to: varispeed, format: buffer.format)
            engine.connect(varispeed, to: engine.mainMixerNode, format: buffer.format)
            blipPlayer = player
            blipPitch = varispeed
        }
        guard let player = blipPlayer else { return }
        blipPitch?.rate = pitch
        player.volume = Self.effectLevel * 0.45
        if !engine.isRunning { try? engine.start() }
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        if !player.isPlaying { player.play() }
    }

    /// Says a line's clips one after another, once each, stopping whatever line was playing.
    /// A missing clip is logged and skipped: the text still shows, just without a voice.
    @discardableResult
    func speak(_ ids: [String]) -> Int {
        let clips = voiceLeadIn + ids
        voiceLeadIn = []
        voicePlayer?.stop()
        voiceToken += 1
        guard !clips.isEmpty else { return voiceToken }
        setUpIfNeeded()
        guard isSetUp else { return voiceToken }
        let buffers = clips.compactMap { id -> AVAudioPCMBuffer? in
            if let buffer = buffer(for: id, keeps: false) { return buffer }
            if !loggedMissingVoices.contains(id) {
                loggedMissingVoices.insert(id)
                artLog.notice("Missing voice \(id, privacy: .public)")
            }
            return nil
        }
        guard let first = buffers.first else { return voiceToken }
        let player: AVAudioPlayerNode
        if let existing = voicePlayer {
            player = existing
        } else {
            player = AVAudioPlayerNode()
            engine.attach(player)
            voicePlayer = player
        }
        if voiceFormat != first.format {
            engine.disconnectNodeOutput(player)
            engine.connect(player, to: engine.mainMixerNode, format: first.format)
            voiceFormat = first.format
        }
        player.volume = Self.voiceLevel
        if !engine.isRunning { try? engine.start() }
        var seconds = 0.0
        for (index, buffer) in buffers.enumerated() where buffer.format == first.format {
            if index > 0, let gap = Self.silence(Self.clipGap, like: buffer) {
                player.scheduleBuffer(gap, at: nil, options: [])
                seconds += Self.clipGap
            }
            player.scheduleBuffer(buffer, at: nil, options: [])
            seconds += Double(buffer.frameLength) / buffer.format.sampleRate
        }
        voiceEnds = Date().addingTimeInterval(seconds)
        player.play()
        return voiceToken
    }

    /// Holds the line playing (the chat's pause button), to carry on with `resumeVoice`.
    func pauseVoice(token: Int? = nil) {
        if let token, token != voiceToken { return }
        voicePlayer?.pause()
    }

    func resumeVoice(token: Int? = nil) {
        if let token, token != voiceToken { return }
        if !engine.isRunning { try? engine.start() }
        voicePlayer?.play()
    }

    /// Stops the line playing. With a token, only if that line is still the one playing (so a
    /// screen closing doesn't cut off the next screen's line).
    func stopVoice(token: Int? = nil) {
        if let token, token != voiceToken { return }
        voiceLeadIn = []
        voicePlayer?.stop()
    }

    func suspend() {
        engine.pause()
    }

    func resume() {
        guard isSetUp, currentTrack != nil else { return }
        try? engine.start()
    }

    private func setUpIfNeeded() {
        guard !isSetUp else { return }
        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        players = [AVAudioPlayerNode(), AVAudioPlayerNode()]
        players.forEach { engine.attach($0) }
        isSetUp = true
    }

    /// Moves each player toward its volume a little at a time: the new song fades in,
    /// the old one fades out and stops.
    private func startFading() {
        fader?.cancel()
        fader = Task { @MainActor [weak self] in
            while let self, !Task.isCancelled {
                let speaking = Date() < self.voiceEnds && self.voicePlayer?.isPlaying == true
                let target = self.volume * Self.baseLevel * (self.isDucked ? Self.duckLevel : 1)
                    * (speaking ? Self.voiceDuckLevel : 1)
                let step = max(target, 0.05) / (Self.fadeSeconds * 20)
                for (index, player) in self.players.enumerated() {
                    let goal: Float = index == self.activeIndex ? target : 0
                    if player.volume < goal {
                        player.volume = min(goal, player.volume + step)
                    } else if player.volume > goal {
                        player.volume = max(goal, player.volume - step)
                        if index != self.activeIndex && player.volume == 0 { player.stop() }
                    }
                }
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }

    /// Decodes a song or sound from the asset catalog once and keeps it, trimmed for a seamless loop.
    /// Voice clips aren't kept (there are hundreds); songs and sounds are.
    private func buffer(for track: String, keeps: Bool = true) -> AVAudioPCMBuffer? {
        if let cached = buffers[track] { return cached }
        guard let asset = NSDataAsset(name: track) else { return nil }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("\(track).mp3")
        do {
            // Rewrite the copy when the asset changed (a new version of a song), so an old
            // copy left from before an update never plays instead.
            let saved = (try? FileManager.default.attributesOfItem(atPath: url.path))?[.size] as? Int
            if saved != asset.data.count {
                try asset.data.write(to: url, options: .atomic)
            }
            let file = try AVAudioFile(forReading: url)
            guard let full = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: AVAudioFrameCount(file.length)) else {
                return nil
            }
            try file.read(into: full)
            let trimmed = Self.trimSilence(full) ?? full
            if keeps { buffers[track] = trimmed }
            return trimmed
        } catch {
            artLog.error("Couldn't load music \(track, privacy: .public): \(error.localizedDescription, privacy: .public)")
            return nil
        }
    }

    /// Cuts the near-silent padding at both ends so the loop point doesn't hiccup.
    private static func trimSilence(_ buffer: AVAudioPCMBuffer) -> AVAudioPCMBuffer? {
        guard let channels = buffer.floatChannelData else { return nil }
        let count = Int(buffer.frameLength), channelCount = Int(buffer.format.channelCount)
        let threshold: Float = 0.001
        func loud(_ frame: Int) -> Bool {
            (0..<channelCount).contains { abs(channels[$0][frame]) > threshold }
        }
        var start = 0, end = count - 1
        while start < end && !loud(start) { start += 1 }
        while end > start && !loud(end) { end -= 1 }
        let length = end - start + 1
        guard length > 4096, start > 0 || end < count - 1,
              let out = AVAudioPCMBuffer(pcmFormat: buffer.format, frameCapacity: AVAudioFrameCount(length)),
              let outChannels = out.floatChannelData else { return nil }
        for channel in 0..<channelCount {
            outChannels[channel].update(from: channels[channel] + start, count: length)
        }
        out.frameLength = AVAudioFrameCount(length)
        return out
    }
}
