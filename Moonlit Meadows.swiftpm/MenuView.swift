import AVFoundation
import SwiftUI
import UIKit
import os

/// Problems with art (a missing sprite frame, say) are logged here instead of crashing.
let artLog = Logger(subsystem: "MoonlitMeadows", category: "art")

// MARK: - Menus on both screens

extension View {
    /// The start screen and the pause menu, laid over the whole game.
    func gameMenus(_ meadow: Meadow) -> some View {
        overlay {
            ZStack {
                if meadow.isAtMainMenu {
                    MainMenuView(meadow: meadow)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                } else if meadow.showsIntro {
                    IntroView(meadow: meadow)
                        .transition(.opacity)
                } else if meadow.isPaused {
                    PauseMenuView(meadow: meadow)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.8), value: meadow.showsIntro)
            .overlay {
                if meadow.showsStartSparkle {
                    StartSparkle(meadow: meadow)
                }
            }
            .animation(.easeOut(duration: 0.25), value: meadow.isAtMainMenu)
            .animation(.easeOut(duration: 0.25), value: meadow.isPaused)
        }
    }
}

/// The menu art on top, the buttons on the paper panel below, split at the fold on tall
/// screens like the rest of the game.
private struct MenuLayout<Buttons: View>: View {
    let title: String
    /// How many buttons, so they're sized to all fit on the panel.
    var rows = 4
    var dimmed = false
    @ViewBuilder let buttons: () -> Buttons

    var body: some View {
        GeometryReader { geo in
            let tall = geo.size.height > geo.size.width * 0.75
            let gap: CGFloat = tall ? 40 : 0
            let artHeight = tall ? (geo.size.height - gap) / 2 : geo.size.height * 0.45

            VStack(spacing: gap) {
                ZStack {
                    Palette.night
                    if let art = UIImage(named: "menu-art") {
                        Image(uiImage: art)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFill()
                            .frame(width: geo.size.width, height: artHeight)
                            .clipped()
                    }
                    if dimmed { Color.black.opacity(0.25) }
                }
                .frame(height: artHeight)

                let panel = tall ? (geo.size.height - gap) / 2 : geo.size.height - artHeight
                let spacing: CGFloat = 10
                let buttonHeight = max(36, min(62, (panel - 40 - 48 - spacing * CGFloat(rows)) / CGFloat(rows)))
                VStack(spacing: spacing) {
                    Text(title)
                        .font(.system(size: min(34, buttonHeight * 0.6), weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.lilac)
                        .shadow(color: .white, radius: 0, x: 2, y: 2)
                        .shadow(color: Palette.ink.opacity(0.5), radius: 0, x: -1, y: -1)
                    buttons()
                        .environment(\.menuButtonHeight, buttonHeight)
                }
                .frame(maxWidth: 460)
                .padding(20)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background {
                    if let paper = WorldArt.panel {
                        Image(uiImage: paper).resizable().scaledToFill()
                    } else {
                        Palette.lavender
                    }
                }
                .clipped()
            }
        }
        .background(Palette.night.ignoresSafeArea())
        .ignoresSafeArea()
        .fontDesign(.rounded)
    }
}

private struct MenuButtonHeightKey: EnvironmentKey {
    static let defaultValue: CGFloat = 62
}

extension EnvironmentValues {
    /// How tall the menu buttons are, so a whole menu fits on its panel.
    var menuButtonHeight: CGFloat {
        get { self[MenuButtonHeightKey.self] }
        set { self[MenuButtonHeightKey.self] = newValue }
    }
}

/// A big pixel button with its icon, like the menu mockups.
private struct MenuButton: View {
    let title: String
    let icon: String
    let fill: Color
    let edge: Color
    var isEnabled = true
    /// Shown instead of the icon art when there's none yet.
    var emoji: String?
    let action: () -> Void
    @Environment(\.menuButtonHeight) private var height

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                if let image = UIImage(named: icon) {
                    Image(uiImage: image)
                        .resizable()
                        .interpolation(.none)
                        .scaledToFit()
                        .frame(width: 40, height: 34)
                } else if let emoji {
                    Text(emoji).font(.system(size: 28)).frame(width: 40, height: 34)
                }
                Text(title)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                    .shadow(color: edge, radius: 0, x: 2, y: 2)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 22)
            .frame(maxWidth: .infinity)
            .frame(height: height)
            .pixelPanel(fill, edge: Palette.ink, cornerRadius: 18)
        }
        .buttonStyle(SquishButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }
}

private enum MenuColors {
    static let pink = Color(red: 0.96, green: 0.68, blue: 0.80)
    static let pinkEdge = Color(red: 0.80, green: 0.40, blue: 0.58)
    static let purple = Color(red: 0.76, green: 0.66, blue: 0.92)
    static let purpleEdge = Color(red: 0.50, green: 0.40, blue: 0.72)
    static let blue = Color(red: 0.50, green: 0.62, blue: 0.90)
    static let blueEdge = Color(red: 0.28, green: 0.36, blue: 0.66)
}

// MARK: - Main menu

struct MainMenuView: View {
    let meadow: Meadow
    @State private var confirmsNewGame = false
    @State private var showsSettings = false
    @State private var showsFeedback = false

    var body: some View {
        MenuLayout(title: "Moonlit Meadows", rows: 4) {
            MenuButton(title: "New Game", icon: "menu-newgame", fill: MenuColors.pink, edge: MenuColors.pinkEdge) {
                if meadow.hasSavedGame { confirmsNewGame = true } else { startNewGame() }
            }
            MenuButton(title: meadow.hasSavedGame ? "Load" : "Load (no save yet)", icon: "menu-load",
                       fill: MenuColors.purple, edge: MenuColors.purpleEdge, isEnabled: meadow.hasSavedGame) {
                meadow.welcomeBack()
                meadow.isAtMainMenu = false
            }
            MenuButton(title: "Settings", icon: "menu-settings", fill: MenuColors.blue, edge: MenuColors.blueEdge) {
                showsSettings = true
            }
            MenuButton(title: "Feedback", icon: "menu-feedback", fill: MenuColors.pink, edge: MenuColors.pinkEdge) {
                showsFeedback = true
            }
        }
        .onAppear { StartSparkle.preload() }
        .confirmationDialog("Start a new farm?", isPresented: $confirmsNewGame, titleVisibility: .visible) {
            Button("Start over", role: .destructive) { startNewGame() }
            Button("Keep my farm", role: .cancel) {}
        } message: {
            Text("Your current farm, bunnies, and friendships will be replaced. This can't be undone.")
        }
        .sheet(isPresented: $showsSettings) { SettingsSheet() }
        .sheet(isPresented: $showsFeedback) { FeedbackSheet() }
    }

    /// The menu music stops, the sparkle sound plays, and the sparkle transition takes over
    /// the screen; the new game begins once it has gone black (see `StartSparkle`).
    private func startNewGame() {
        guard !meadow.showsStartSparkle else { return }
        MusicPlayer.shared.pauseMusic()
        MusicPlayer.shared.playEffect(.startSparkle)
        meadow.showsStartSparkle = true
    }
}

// MARK: - Pause menu

struct PauseMenuView: View {
    let meadow: Meadow
    @State private var confirmsRestart = false
    @State private var showsSettings = false
    @State private var justSaved = false

    var body: some View {
        MenuLayout(title: "Paused", rows: 5, dimmed: true) {
            MenuButton(title: "Resume", icon: "menu-resume", fill: MenuColors.pink, edge: MenuColors.pinkEdge) {
                meadow.isPaused = false
            }
            // The farm also saves itself every few seconds; this saves right now and says so.
            MenuButton(title: justSaved ? "Saved ✓" : "Save", icon: "menu-save", fill: MenuColors.blue,
                       edge: MenuColors.blueEdge, emoji: "💾") {
                meadow.save()
                withAnimation { justSaved = true }
                Task {
                    try? await Task.sleep(for: .seconds(1.6))
                    withAnimation { justSaved = false }
                }
            }
            MenuButton(title: "Restart", icon: "menu-restart", fill: MenuColors.purple, edge: MenuColors.purpleEdge) {
                confirmsRestart = true
            }
            MenuButton(title: "Settings", icon: "menu-settings", fill: MenuColors.blue, edge: MenuColors.blueEdge) {
                showsSettings = true
            }
            MenuButton(title: "Main Menu", icon: "menu-mainmenu", fill: MenuColors.pink, edge: MenuColors.pinkEdge) {
                meadow.save()
                meadow.isPaused = false
                meadow.isAtMainMenu = true
            }
        }
        .confirmationDialog("Restart your farm?", isPresented: $confirmsRestart, titleVisibility: .visible) {
            Button("Restart", role: .destructive) {
                meadow.resetGame()
                meadow.isPaused = false
            }
            Button("Keep playing", role: .cancel) {}
        } message: {
            Text("You'll start a brand-new farm. This can't be undone.")
        }
        .sheet(isPresented: $showsSettings) { SettingsSheet() }
    }
}

/// A small pause button for the top bar.
struct PauseButton: View {
    let meadow: Meadow

    var body: some View {
        Button {
            meadow.save()
            meadow.isPaused = true
        } label: {
            Image(systemName: "pause.fill")
                .font(.caption.bold())
                .foregroundStyle(Palette.ink)
                .frame(width: 30, height: 30)
                .pixelPanel(Palette.lilacCard, edge: Palette.lilacEdge, cornerRadius: 10)
        }
        .buttonStyle(SquishButtonStyle())
        .accessibilityLabel("Pause")
    }
}

// MARK: - Settings and feedback

private struct SettingsSheet: View {
    @AppStorage("laptopMode") private var isLaptopMode = false
    @AppStorage(MusicPlayer.volumeKey) private var musicVolume = MusicPlayer.defaultVolume
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Sound") {
                    HStack {
                        Image(systemName: "speaker.fill")
                        Slider(value: $musicVolume, in: 0...1)
                        Image(systemName: "speaker.wave.3.fill")
                    }
                    .accessibilityLabel("Music volume")
                    Text("Music plays quietly and gets softer while people talk. The silent switch mutes it.")
                        .font(.caption)
                }
                Section("Screen") {
                    Toggle("Laptop mode (iPhone Duo fold)", isOn: $isLaptopMode)
                    Text("Splits the screen in half: the meadow on top, the controls below.")
                        .font(.caption)
                }
                Section("Game") {
                    LabeledContent("Day length", value: "15 minutes")
                    Text("Animations follow your device's Reduce Motion setting.")
                        .font(.caption)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}

private struct FeedbackSheet: View {
    @AppStorage("feedbackDraft") private var draft = ""
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("What do you love? What felt off? Your note is kept on this device, and Share sends it by Messages or Mail.")
                    .font(.callout)
                TextEditor(text: $draft)
                    .padding(8)
                    .background(Palette.cream, in: .rect(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Palette.lilacEdge, lineWidth: 2))
                ShareLink(item: "Moonlit Meadows feedback:\n\(draft)") {
                    Label("Share feedback", systemImage: "square.and.arrow.up")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(12)
                        .pixelPanel(MenuColors.pink, edge: MenuColors.pinkEdge, cornerRadius: 16)
                }
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(20)
            .background(Palette.lavender.opacity(0.4))
            .navigationTitle("Feedback")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) { Button("Done") { dismiss() } }
            }
        }
    }
}


// MARK: - New Game sparkle transition

/// After New Game: `start-sparkle-transition.mp4` (3 seconds, ending on black) plays over the
/// whole screen, ignoring touches. Once it's black, the new game starts under it, then the black
/// fades away to show the meadow. If the video can't play, sparkles are drawn instead with the
/// same timing.
struct StartSparkle: View {
    let meadow: Meadow
    @State private var useFallback = false
    @State private var cover = 1.0
    @State private var started = Date()

    static let seconds = 3.0
    private static var player: AVPlayer?

    /// Gets the video ready while the menu is up, so it starts without a pause or a flash.
    static func preload() {
        guard player == nil else { return }
        guard let asset = NSDataAsset(name: "start-sparkle-transition") else {
            artLog.notice("Missing video start-sparkle-transition; the sparkles will be drawn instead")
            return
        }
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("start-sparkle-transition.mp4")
        do {
            try asset.data.write(to: url, options: .atomic)
        } catch {
            artLog.error("Couldn't prepare the sparkle video: \(error.localizedDescription, privacy: .public)")
            return
        }
        let item = AVPlayerItem(url: url)
        let ready = AVPlayer(playerItem: item)
        ready.isMuted = true
        ready.automaticallyWaitsToMinimizeStalling = false
        ready.actionAtItemEnd = .pause
        player = ready
    }

    var body: some View {
        ZStack {
            Color.black
            if useFallback {
                SparkleField(start: started)
            } else if let player = Self.player {
                VideoLayer(player: player)
            }
        }
        .opacity(cover)
        .ignoresSafeArea()
        .contentShape(Rectangle())
        .allowsHitTesting(cover > 0.5)
        .task { await run() }
    }

    private func run() async {
        Self.preload()
        started = Date()
        if let player = Self.player, player.currentItem?.status != .failed {
            await player.seek(to: .zero)
            player.play()
        } else {
            useFallback = true
        }
        try? await Task.sleep(for: .seconds(0.4))
        if let player = Self.player, player.currentItem?.status == .failed || player.rate == 0 && player.currentTime().seconds < 0.1 {
            artLog.notice("The sparkle video didn't start; drawing the sparkles instead")
            useFallback = true
        }
        // Wait for the end, when the screen is fully black.
        try? await Task.sleep(for: .seconds(max(Self.seconds - Date().timeIntervalSince(started), 0) + 0.05))
        useFallback = false
        Self.player?.pause()
        meadow.resetGame()
        meadow.isAtMainMenu = false
        try? await Task.sleep(for: .seconds(0.3))
        withAnimation(.easeOut(duration: 0.6)) { cover = 0 }
        try? await Task.sleep(for: .seconds(0.65))
        meadow.showsStartSparkle = false
    }
}

/// Shows a video player's picture filling the screen, with no controls.
private struct VideoLayer: UIViewRepresentable {
    let player: AVPlayer

    final class PlayerView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
        var playerLayer: AVPlayerLayer { layer as! AVPlayerLayer }
    }

    func makeUIView(context: Context) -> PlayerView {
        let view = PlayerView()
        view.backgroundColor = .black
        view.isUserInteractionEnabled = false
        view.playerLayer.videoGravity = .resizeAspectFill
        view.playerLayer.player = player
        return view
    }

    func updateUIView(_ view: PlayerView, context: Context) {
        view.playerLayer.player = player
    }
}

/// The drawn stand-in for the sparkle video: twinkling stars over a lilac night, fading to black.
private struct SparkleField: View {
    let start: Date

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSince(start)
            let dark = min(max((t - 1.8) / 1.1, 0), 1)
            Canvas { context, size in
                context.fill(Path(CGRect(origin: .zero, size: size)),
                             with: .linearGradient(Gradient(colors: [Palette.ink, Palette.night]),
                                                   startPoint: .zero, endPoint: CGPoint(x: 0, y: size.height)))
                for i in 0..<140 {
                    let x = hash01(i, 21) * size.width, y = hash01(i, 22) * size.height
                    let twinkle = 0.5 + 0.5 * sin(t * (3 + hash01(i, 23) * 4) + Double(i))
                    let r = (2 + hash01(i, 24) * 5) * twinkle
                    let colors: [Color] = [.white, Palette.butter, Palette.petal, Palette.sky, Palette.lilac]
                    var star = Path()
                    star.move(to: CGPoint(x: x, y: y - r * 2)); star.addLine(to: CGPoint(x: x + r * 0.4, y: y))
                    star.addLine(to: CGPoint(x: x, y: y + r * 2)); star.addLine(to: CGPoint(x: x - r * 0.4, y: y))
                    star.closeSubpath()
                    star.move(to: CGPoint(x: x - r * 2, y: y)); star.addLine(to: CGPoint(x: x, y: y + r * 0.4))
                    star.addLine(to: CGPoint(x: x + r * 2, y: y)); star.addLine(to: CGPoint(x: x, y: y - r * 0.4))
                    star.closeSubpath()
                    context.fill(star, with: .color(colors[i % colors.count].opacity(0.4 + 0.6 * twinkle)))
                }
                context.fill(Path(CGRect(origin: .zero, size: size)), with: .color(.black.opacity(dark)))
            }
        }
    }
}
