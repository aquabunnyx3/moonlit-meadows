import AVFoundation
import SwiftUI

// MARK: - The fishing view (added by Merlin, 2026-10-30)

/// First-person fishing from the Pond dock: your hands, the rod, the bobber on
/// the water. Cast → wait → bite → the timing meter — tap the action button
/// (or the water) to stop the sweeping marker in the green, or the gold sliver
/// for a Perfect. The session's clock runs here, a frame at a time, and holds
/// still while the game is paused.
struct FishingView: View {
    let meadow: Meadow
    @State private var lastTick: Date?
    @State private var catchPlayer: AVPlayer?

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: meadow.isPaused)) { timeline in
            ZStack {
                if let art = TownArt.image("fishing-fpv") {
                    Image(uiImage: art)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(red: 0.35, green: 0.45, blue: 0.65)
                }

                if meadow.fishing?.phase == .caught, let catchPlayer {
                    VideoLayer(player: catchPlayer)
                }

                if let session = meadow.fishing {
                    overlay(session)
                }
            }
            .clipped()
            .contentShape(Rectangle())
            .onTapGesture {
                if meadow.fishing?.phase == .meter { meadow.fishingTap() }
            }
            .onChange(of: timeline.date) { _, date in
                tick(date)
            }
            .onChange(of: meadow.fishing?.phase) { _, phase in
                // Sounds live in the view layer (MusicPlayer is main-actor
                // isolated; the model never touches it).
                switch phase {
                case .casting: MusicPlayer.shared.playEffect(.fishCast)
                case .waiting: MusicPlayer.shared.playEffect(.fishBobber)
                case .bite: MusicPlayer.shared.playEffect(.fishBite)
                case .meter: MusicPlayer.shared.playEffect(.fishReel)
                case .caught:
                    MusicPlayer.shared.playEffect(meadow.fishing?.perfect == true ? .fishPerfect : .fishCatch)
                    startCatchVideo()
                case .escaped: MusicPlayer.shared.playEffect(.fishEscape)
                case nil: catchPlayer = nil
                }
            }
        }
        .fontDesign(.rounded)
    }

    private func tick(_ date: Date) {
        defer { lastTick = date }
        guard let last = lastTick else { return }
        meadow.advanceFishing(dt: min(date.timeIntervalSince(last), 0.05))
    }

    private func startCatchVideo() {
        guard let url = DateSceneView.url(for: "fishing-anim-catch") else { return }
        let player = AVPlayer(url: url)
        player.actionAtItemEnd = .pause
        catchPlayer = player
        player.play()
    }

    @ViewBuilder
    private func overlay(_ session: FishingSession) -> some View {
        VStack {
            HStack {
                Spacer()
                if session.phase != .caught && session.phase != .escaped {
                    Button {
                        meadow.endFishing()
                    } label: {
                        Text("✕")
                            .font(.headline.bold())
                            .foregroundStyle(.white)
                            .frame(width: 36, height: 36)
                            .pixelPanel(Palette.ink.opacity(0.7), edge: Palette.lilacEdge, cornerRadius: 12)
                    }
                    .buttonStyle(SquishButtonStyle())
                    .accessibilityLabel("Stop fishing")
                }
            }
            Spacer()
            switch session.phase {
            case .casting:
                caption("Casting…")
            case .waiting:
                caption("Waiting for a bite…")
            case .bite:
                VStack(spacing: 4) {
                    Text("❗").font(.system(size: 54))
                    caption("A bite!")
                }
            case .meter:
                meter(session)
            case .caught:
                catchCard(session)
            case .escaped:
                resultCard(title: "It got away…", line: "The line goes slack. The pond keeps its secrets — this time.")
            }
        }
        .padding(14)
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.subheadline.bold())
            .foregroundStyle(.white)
            .shadow(color: .black.opacity(0.8), radius: 3)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Palette.ink.opacity(0.5), in: .capsule)
    }

    /// The timing meter: green catches, the gold sliver is Perfect, anywhere
    /// else the fish escapes. The marker sweeps until the player stops it.
    private func meter(_ session: FishingSession) -> some View {
        let zones = session.fish.map { FishingMeter.zones(for: $0.rarity) } ?? (green: 0.29...0.63, gold: 0.845...0.915)
        return VStack(spacing: 8) {
            Text("Tap the action button to stop the marker!")
                .font(.subheadline.bold())
                .foregroundStyle(Palette.ink)
            GeometryReader { geo in
                let width = geo.size.width
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Palette.ink.opacity(0.85))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.72, green: 0.85, blue: 0.69))
                        .frame(width: width * (zones.green.upperBound - zones.green.lowerBound))
                        .offset(x: width * zones.green.lowerBound)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.96, green: 0.79, blue: 0.36))
                        .frame(width: max(width * (zones.gold.upperBound - zones.gold.lowerBound), 3))
                        .offset(x: width * zones.gold.lowerBound)
                    Rectangle()
                        .fill(.white)
                        .frame(width: 4)
                        .overlay(Rectangle().stroke(Palette.rose, lineWidth: 1.5).frame(width: 8))
                        .offset(x: width * session.marker - 2)
                }
            }
            .frame(height: 30)
            Text("Green catches · gold is a Perfect ✨")
                .font(.caption.bold())
                .foregroundStyle(Palette.ink.opacity(0.75))
        }
        .padding(14)
        .frame(maxWidth: 520)
        .pixelPanel(Palette.cream.opacity(0.95), edge: Palette.lilacEdge, cornerRadius: 16)
    }

    private func catchCard(_ session: FishingSession) -> some View {
        let fish = session.fish
        return VStack(spacing: 8) {
            if session.perfect {
                Text("✨ PERFECT! ✨")
                    .font(.headline.bold())
                    .foregroundStyle(Palette.rose)
            }
            if let fish {
                Group {
                    if let art = UIImage(named: "fish-\(fish.id)") {
                        Image(uiImage: art).resizable().scaledToFit()
                    } else {
                        Text("🐟").font(.system(size: 64))
                    }
                }
                .frame(height: 96)
                if session.isNew {
                    Text("✨ New species for your Fish book!")
                        .font(.caption.bold())
                        .foregroundStyle(Palette.rose)
                }
                Text(fish.name).font(.title3.bold())
                RarityTag(rarity: fish.rarity)
                Text(fish.description)
                    .font(.callout)
                    .multilineTextAlignment(.center)
                    .opacity(0.85)
                Text(session.perfect
                     ? "📏 \(session.size) cm · 🪙 \(fish.value) + \(fish.value / 2) Perfect bonus"
                     : "📏 \(session.size) cm · 🪙 \(fish.value)")
                    .font(.subheadline.bold())
            }
            HStack(spacing: 10) {
                DialogButton(label: "Fish again 🎣") { meadow.fishAgain() }
                DialogButton(label: "Done", pink: false) { meadow.endFishing() }
            }
        }
        .padding(18)
        .frame(maxWidth: 430)
        .pixelPanel(Palette.cream, edge: Palette.lilacEdge, cornerRadius: 20)
        .foregroundStyle(Palette.ink)
    }

    private func resultCard(title: String, line: String) -> some View {
        VStack(spacing: 8) {
            Text(title).font(.title3.bold())
            Text(line)
                .font(.callout)
                .multilineTextAlignment(.center)
                .opacity(0.85)
            HStack(spacing: 10) {
                DialogButton(label: "Fish again 🎣") { meadow.fishAgain() }
                DialogButton(label: "Done", pink: false) { meadow.endFishing() }
            }
        }
        .padding(18)
        .frame(maxWidth: 430)
        .pixelPanel(Palette.cream, edge: Palette.lilacEdge, cornerRadius: 20)
        .foregroundStyle(Palette.ink)
    }
}
