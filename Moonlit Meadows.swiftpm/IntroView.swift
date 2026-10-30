import SwiftUI
import UIKit

// MARK: - Opening story

/// One painted scene of the opening story.
struct IntroScene {
    enum Kind { case letter, road, gate, key, bunnies, moon }

    let kind: Kind
    let background: String
    let caption: String
    /// Seconds the scene is planned for (fading up, on screen, fading to black, the black pause).
    /// `duration` stretches it when the narration needs longer.
    let planned: Double
    /// A slow zoom (and pan, when the focus moves) around a point of the picture.
    let zoom: (from: CGFloat, to: CGFloat)
    let focus: (from: UnitPoint, to: UnitPoint)

    static let all: [IntroScene] = [
        IntroScene(kind: .letter, background: "intro-1-letter",
                   caption: "A letter arrived on a rainy evening… with a key, and a sprig of lavender.",
                   planned: 7, zoom: (1.0, 1.18), focus: (UnitPoint(x: 0.45, y: 0.55), UnitPoint(x: 0.47, y: 0.6))),
        IntroScene(kind: .road, background: "intro-2-road",
                   caption: "It led down a winding road, far from the city.",
                   planned: 8, zoom: (1.15, 1.15), focus: (UnitPoint(x: 0.25, y: 0.9), UnitPoint(x: 0.5, y: 0.6))),
        IntroScene(kind: .gate, background: "intro-3-gate",
                   caption: "At the garden gate, someone was waiting with a lantern.",
                   planned: 7, zoom: (1.0, 1.12), focus: (UnitPoint(x: 0.5, y: 0.7), UnitPoint(x: 0.53, y: 0.6))),
        IntroScene(kind: .key, background: "intro-4-key",
                   caption: "“The farm is yours now. It's been waiting for someone like you.”",
                   planned: 7, zoom: (1.0, 1.2), focus: (UnitPoint(x: 0.5, y: 0.56), UnitPoint(x: 0.5, y: 0.56))),
        IntroScene(kind: .bunnies, background: "intro-5-bunnies",
                   caption: "And two little friends hopped over to say hello.",
                   planned: 7, zoom: (1.08, 1.0), focus: (UnitPoint(x: 0.5, y: 0.8), UnitPoint(x: 0.5, y: 0.8))),
        IntroScene(kind: .moon, background: "intro-6-moon",
                   caption: "Welcome home to Moonlit Meadows.",
                   planned: 7, zoom: (1.5, 1.3), focus: (UnitPoint(x: 0.5, y: 1.0), UnitPoint(x: 0.665, y: 0.0))),
    ]

    /// How long each scene's narration (`VoiceLines.intro`) runs, in seconds.
    static let voiceSeconds = [7.08, 3.96, 3.62, 4.30, 3.79, 2.90]
    /// The line starts once the picture has faded up, and the scene holds this long after it ends.
    static let afterVoice = 1.2

    /// The planned length, or long enough for the whole line plus a beat before fading to black.
    var duration: Double {
        guard let index = IntroScene.all.firstIndex(where: { $0.kind == kind }) else { return planned }
        let isLast = index == IntroScene.all.count - 1
        let needed = IntroView.fadeIn + Self.voiceSeconds[index] + Self.afterVoice
            + (isLast ? 0 : IntroView.fadeOut + IntroView.blackPause)
        return max(planned, needed)
    }

    /// When each scene starts, in seconds from the beginning.
    static func start(of index: Int) -> Double {
        all.prefix(max(index, 0)).reduce(0) { $0 + $1.duration }
    }

    static var total: Double { start(of: all.count) }

    /// The scene showing at a moment of the story.
    static func index(at elapsed: Double) -> Int {
        var index = 0
        while index + 1 < all.count && start(of: index + 1) <= elapsed { index += 1 }
        return index
    }
}

/// The opening story after "Start farming": six painted scenes with slow pans and zooms,
/// your own farmer walking in with a suitcase, the host lifting her lantern at the gate,
/// fireflies, petals, and two bunnies hopping in. Tap to move on, or Skip. It plays once,
/// for a new farmer. On tall screens the pictures sit on top and the words below the fold.
struct IntroView: View {
    let meadow: Meadow
    @State private var start = Date()
    /// Seconds jumped ahead by tapping.
    @State private var skipped: Double = 0

    static let artNames = IntroScene.all.map(\.background)
        + ["intro-host", "intro-fashionista-holding-suitcase", "intro-4-hand", "intro-4-hand-labels",
           "intro-bunny-clover", "intro-bunny-snowflake", "intro-firefly"]
    /// Each scene fades up from black, and at its end fades down to black and holds there a
    /// moment before the next one begins.
    static let fadeIn = 0.8
    static let fadeOut = 0.8
    static let blackPause = 0.6

    /// How visible a scene is at a moment of the story: 0 is black, 1 fully shown.
    static func visibility(of index: Int, at elapsed: Double) -> Double {
        let begins = IntroScene.start(of: index)
        let ends = IntroScene.start(of: index + 1)
        let shownFor = elapsed - begins
        guard shownFor >= 0, elapsed < ends || index == IntroScene.all.count - 1 else { return 0 }
        let rising = min(shownFor / fadeIn, 1)
        // The last scene doesn't go dark: the game fades in over it.
        guard index < IntroScene.all.count - 1 else { return rising }
        let falling = (ends - blackPause - elapsed) / fadeOut
        return max(min(rising, falling, 1), 0)
    }

    var body: some View {
        GeometryReader { geo in
            let tall = geo.size.height > geo.size.width * 0.75
            let gap: CGFloat = tall ? 40 : 0
            let artHeight = tall ? (geo.size.height - gap) / 2 : geo.size.height

            TimelineView(.animation) { timeline in
                let elapsed = timeline.date.timeIntervalSince(start) + skipped
                let index = IntroScene.index(at: elapsed)

                VStack(spacing: gap) {
                    IntroStage(meadow: meadow, elapsed: elapsed)
                        .frame(width: geo.size.width, height: artHeight)
                        .clipped()
                        .contentShape(Rectangle())
                        .onTapGesture { next(from: elapsed) }
                        .overlay(alignment: .bottom) {
                            if !tall {
                                caption(index, elapsed: elapsed)
                                    .frame(maxWidth: 560)
                                    .padding(.horizontal, 20)
                                    .padding(.bottom, 24)
                                    .allowsHitTesting(false)
                            }
                        }
                        .overlay(alignment: .topTrailing) {
                            if !tall {
                                skipButton.padding(.top, 50).padding(.trailing, 20)
                            }
                        }

                    if tall {
                        VStack(spacing: 18) {
                            caption(index, elapsed: elapsed)
                            HStack(spacing: 12) {
                                DialogButton(label: "Skip", pink: false) { finish() }
                                DialogButton(label: index + 1 < IntroScene.all.count ? "Next ▸" : "Begin ▸") {
                                    next(from: elapsed)
                                }
                            }
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
                // Each scene's line is said as the scene begins.
                // Each scene's line begins once its picture has faded up from black.
                .task(id: index) {
                    try? await Task.sleep(for: .seconds(Self.fadeIn))
                    guard !Task.isCancelled else { return }
                    MusicPlayer.shared.speak([VoiceLines.intro[index]])
                }
            }
        }
        .background(Palette.ink.ignoresSafeArea())
        .ignoresSafeArea()
        .fontDesign(.rounded)
        .onAppear {
            // Recolor and trim the figures before the scenes need them.
            if let look = meadow.farmerLook {
                _ = IntroFigure.farmer(look)
                _ = IntroFigure.hand(look)
            }
            _ = IntroFigure.trimmed("intro-host")
        }
        .onDisappear { MusicPlayer.shared.stopVoice() }
        .task(id: skipped) {
            // Ends on its own when the last scene is done.
            let left = IntroScene.total - (Date().timeIntervalSince(start) + skipped)
            if left > 0 { try? await Task.sleep(for: .seconds(left)) }
            guard !Task.isCancelled else { return }
            finish()
        }
    }

    private func caption(_ index: Int, elapsed: Double) -> some View {
        let shown = elapsed - IntroScene.start(of: index)
        return Text(IntroScene.all[index].caption)
            .font(.system(size: 17, weight: .semibold, design: .rounded))
            .foregroundStyle(Palette.cocoa)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity, minHeight: 64)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .pixelPanel(Palette.cream, edge: Palette.lilacEdge, cornerRadius: 16)
            .opacity(min(max((shown - 0.3) / 0.6, 0), 1) * Self.visibility(of: index, at: elapsed))
            .offset(y: 8 * (1 - min(max((shown - 0.3) / 0.6, 0), 1)))
    }

    private var skipButton: some View {
        Button { finish() } label: {
            Text("Skip ▸▸")
                .font(.subheadline.bold())
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .pixelPanel(Palette.periwinkle, edge: Palette.periwinkleEdge, cornerRadius: 14)
        }
        .buttonStyle(SquishButtonStyle())
    }

    /// Fades this scene to black (then the pause and the next scene follow), or ends after the
    /// last one. Tapping again while it's already fading goes straight to the next scene.
    private func next(from elapsed: Double) {
        let index = IntroScene.index(at: elapsed)
        guard index + 1 < IntroScene.all.count else {
            finish()
            return
        }
        let nextStart = IntroScene.start(of: index + 1)
        let fadeStart = nextStart - Self.blackPause - Self.fadeOut
        skipped += max((elapsed < fadeStart ? fadeStart : nextStart) - elapsed, 0)
    }

    private func finish() {
        guard meadow.showsIntro else { return }
        meadow.finishIntro()
    }
}

// MARK: - The pictures

/// The scenes, crossfading into each other. Each scene's picture keeps its shape and fills
/// the space (cropping the edges), and everything on it moves with its zoom and pan.
private struct IntroStage: View {
    let meadow: Meadow
    let elapsed: Double

    /// The intro paintings are all 2096 × 1184.
    static let aspect: CGFloat = 2096.0 / 1184.0

    var body: some View {
        GeometryReader { geo in
            let w = max(geo.size.width, geo.size.height * Self.aspect)
            let h = w / Self.aspect
            ZStack {
                Color.black
                ForEach(IntroScene.all.indices, id: \.self) { index in
                    let visible = IntroView.visibility(of: index, at: elapsed)
                    if visible > 0 {
                        IntroSceneLayer(meadow: meadow, scene: IntroScene.all[index],
                                        time: elapsed - IntroScene.start(of: index), size: CGSize(width: w, height: h))
                            .opacity(visible)
                    }
                }
            }
            .frame(width: w, height: h)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }
}

private struct IntroSceneLayer: View {
    let meadow: Meadow
    let scene: IntroScene
    /// Seconds since this scene started (negative while it fades in).
    let time: Double
    let size: CGSize

    var body: some View {
        let p = min(max(time / scene.duration, 0), 1)
        let eased = CGFloat(p * p * (3 - 2 * p))
        let zoom = scene.zoom.from + (scene.zoom.to - scene.zoom.from) * eased
        let focus = UnitPoint(x: scene.focus.from.x + (scene.focus.to.x - scene.focus.from.x) * eased,
                              y: scene.focus.from.y + (scene.focus.to.y - scene.focus.from.y) * eased)

        ZStack(alignment: .topLeading) {
            IntroArt(name: scene.background)
                .frame(width: size.width, height: size.height)
            extras(p: p)
        }
        .frame(width: size.width, height: size.height, alignment: .topLeading)
        .scaleEffect(zoom, anchor: focus)
    }

    private var w: CGFloat { size.width }
    private var h: CGFloat { size.height }
    private var t: Double { max(time, 0) }

    @ViewBuilder
    private func extras(p: Double) -> some View {
        switch scene.kind {
        case .letter:
            Glow(color: Palette.butter, radius: h * 0.2, strength: 0.4 + 0.08 * sin(t * 2.6))
                .position(x: w * 0.34, y: h * 0.34)
            Rain(time: t)
                .frame(width: w * 0.44, height: h * 0.46)
                .position(x: w * 0.69, y: h * 0.25)
        case .road:
            Fireflies(time: t, count: 12, size: size)
            walkingFarmer(fromX: -0.12, toX: 0.3, walkUntil: 0.75, p: p)
        case .gate:
            Fireflies(time: t, count: 8, size: size)
            host(p: p)
            // Up the garden path from the bottom left, not through the fence.
            walkingFarmer(fromX: 0.3, toX: 0.43, fromFeet: 1.5, walkUntil: 0.6, p: p)
        case .key:
            farmerHand
            Glow(color: Palette.butter, radius: h * 0.22, strength: 0.45 + 0.12 * sin(t * 7) * sin(t * 2.3))
                .position(x: w * 0.81, y: h * 0.1)
            Fireflies(time: t, count: 8, size: size)
            Petals(time: t, count: 22)
                .frame(width: w, height: h)
        case .bunnies:
            Fireflies(time: t, count: 10, size: size)
            HoppingBunny(name: "intro-bunny-clover", time: t, from: -0.12, to: 0.33, y: 0.93,
                         delay: 0.3, height: h * 0.26, size: size)
            HoppingBunny(name: "intro-bunny-snowflake", time: t, from: 1.12, to: 0.67, y: 0.94,
                         delay: 0.9, height: h * 0.26, size: size)
        case .moon:
            Glow(color: Palette.butter, radius: h * 0.16, strength: 0.25 + 0.08 * sin(t * 1.5))
                .position(x: w * 0.665, y: h * 0.105)
            Fireflies(time: t, count: 14, size: size)
        }
    }

    /// Your farmer walking in with real steps (their walk cycle from video), then standing in the
    /// big picture holding the suitcase once they stop. Without a walk cycle the picture glides in.
    /// Sized by height only, the same height as the host.
    private func walkingFarmer(fromX: CGFloat, toX: CGFloat, fromFeet: CGFloat = IntroFigure.baseline,
                               walkUntil: Double, p: Double) -> some View {
        let height = h * IntroFigure.standingHeight
        let walk = CGFloat(min(p / walkUntil, 1))
        let x = (fromX + (toX - fromX) * walk) * w
        let feet = h * (fromFeet + (IntroFigure.baseline - fromFeet) * walk)
        let look = meadow.farmerLook
        let cycle = PersonArt.cycleFrame(for: look.map(FarmerRenderer.artID(for:)), facing: .right, time: t)
        // Seconds since they stopped, for the crossfade into the standing picture.
        let stopped = (p - walkUntil) * scene.duration
        let standing = cycle == nil ? 1 : min(max(stopped / 0.35, 0), 1)

        return ZStack {
            if let cycle, standing < 1 {
                Image(uiImage: cycle.image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(height: height)
                    .scaleEffect(x: cycle.isFlipped ? -1 : 1, y: 1)
                    .opacity(1 - standing)
                    .position(x: x, y: feet - height / 2)
            }
            if let look, let art = IntroFigure.farmer(look), standing > 0 {
                IntroFigure(image: art, height: height)
                    .opacity(standing)
                    .position(x: x, y: feet - height / 2)
            }
        }
        .frame(width: w, height: h)
        .allowsHitTesting(false)
    }

    /// The hand taking the key is your farmer's, so it's drawn in your skin tone: a cut-out of
    /// it (`intro-4-hand`, at `IntroFigure.handBox` in the 2096 × 1184 painting) is recolored and
    /// laid over the painting.
    @ViewBuilder
    private var farmerHand: some View {
        let box = IntroFigure.handBox
        if let look = meadow.farmerLook, let hand = IntroFigure.hand(look) {
            Image(uiImage: hand)
                .resizable()
                .interpolation(.none)
                .frame(width: w * box.width / 2096, height: h * box.height / 1184)
                .position(x: w * box.midX / 2096, y: h * box.midY / 1184)
                .allowsHitTesting(false)
        }
    }

    /// The host at the gate. She lifts her lantern as you arrive, and its light breathes.
    private func host(p: Double) -> some View {
        let hostHeight = h * IntroFigure.standingHeight
        let art = IntroFigure.trimmed("intro-host")
        let hostWidth = art.map { hostHeight * $0.size.width / max($0.size.height, 1) } ?? hostHeight * 0.45
        let x = w * 0.585, feet = h * IntroFigure.baseline
        let lift = CGFloat(min(max((p - 0.45) / 0.25, 0), 1))
        let liftEased = lift * lift * (3 - 2 * lift)
        let lanternX = x - hostWidth / 2 + hostWidth * 0.24
        let lanternY = feet - hostHeight + hostHeight * 0.64 - liftEased * hostHeight * 0.05

        return ZStack {
            if let art {
                IntroFigure(image: art, height: hostHeight)
                    .rotationEffect(.degrees(-3 * liftEased), anchor: .bottom)
                    .position(x: x, y: feet - hostHeight / 2)
            }
            Glow(color: Palette.butter, radius: hostHeight * (0.22 + 0.1 * liftEased),
                 strength: 0.35 + 0.35 * Double(liftEased) + 0.08 * sin(t * 6) * sin(t * 2.1))
                .position(x: lanternX, y: lanternY)
        }
        .frame(width: w, height: h)
        .allowsHitTesting(false)
    }
}

/// A standing figure in the intro. The farmer and the host share one height and one
/// baseline, and each picture is scaled by its height only: see-through margins are trimmed
/// first, so the drawn figure itself (head to boots) is what fills that height.
private struct IntroFigure: View {
    let image: UIImage
    let height: CGFloat

    /// Both figures, as a fraction of the picture's height.
    static let standingHeight: CGFloat = 0.46
    /// Where their feet stand, as a fraction of the picture's height.
    static let baseline: CGFloat = 0.88

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .interpolation(.none)
            .scaledToFit()
            .frame(height: height)
    }

    /// Your farmer standing still once they've walked in, recolored for your look: the same
    /// front sprite they have in the creator and the meadow, so the intro matches what you
    /// picked (the older `intro-stand-…` poses drew Curly Buns as one puff). The old pose is
    /// only used if a look has no front sprite.
    static func farmer(_ look: FarmerLook) -> UIImage? {
        let cut = Outfit.find(look.outfit)?.cut ?? .jacket
        let name = "intro-stand-\(look.gender.rawValue)-s\(look.hairStyle)\(cut.artSuffix)"
        var art = FarmerRenderer.image(.front, look: look)
        if art == nil { art = FarmerRenderer.image(named: name, look: look) }
        if art == nil { artLog.notice("Missing intro art \(name, privacy: .public) and the farmer's front sprite") }
        return art.map { ArtTrim.trimmed($0, key: "\(FarmerRenderer.artID(for: look))|intro-stand") }
    }

    /// Where the farmer's hand sits in the key painting.
    static let handBox = CGRect(x: 742, y: 514, width: 964, height: 616)
    /// The farmer art's own (Deep) skin color, for art drawn in another skin tone.
    static let drawnSkin = RGB(0xA66D4C)

    static func hand(_ look: FarmerLook) -> UIImage? {
        FarmerRenderer.image(named: "intro-4-hand", look: look, drawnSkin: drawnSkin)
    }

    static func trimmed(_ name: String) -> UIImage? {
        guard let image = UIImage(named: name) else {
            artLog.notice("Missing intro art \(name, privacy: .public)")
            return nil
        }
        return ArtTrim.trimmed(image, key: name)
    }
}

/// A picture from the asset catalog, kept crisp.
private struct IntroArt: View {
    let name: String

    var body: some View {
        if let image = UIImage(named: name) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
        } else {
            Palette.night
                .onAppear { artLog.notice("Missing intro art \(name, privacy: .public)") }
        }
    }
}

// MARK: - Little moving things

/// Repeatable pseudo-random numbers from 0 to 1, so things scatter the same way every frame.
private func scatter(_ i: Int, _ salt: Double) -> Double {
    let v = sin(Double(i) * 12.9898 + salt * 78.233) * 43758.5453
    return v - floor(v)
}

/// A soft round light, like a lamp or a lantern's glow.
private struct Glow: View {
    let color: Color
    let radius: CGFloat
    let strength: Double

    var body: some View {
        Circle()
            .fill(RadialGradient(colors: [color.opacity(strength), color.opacity(0)],
                                 center: .center, startRadius: 0, endRadius: radius))
            .frame(width: radius * 2, height: radius * 2)
            .blendMode(.screen)
            .allowsHitTesting(false)
    }
}

/// Rain streaking down the window.
private struct Rain: View {
    let time: Double

    var body: some View {
        Canvas { context, size in
            for i in 0..<36 {
                let speed = 0.9 + scatter(i, 3) * 0.6
                let fall = (scatter(i, 2) + time * speed).truncatingRemainder(dividingBy: 1)
                let x = CGFloat(scatter(i, 1)) * size.width - CGFloat(fall) * size.height * 0.08
                let y = CGFloat(fall * 1.15 - 0.1) * size.height
                var line = Path()
                line.move(to: CGPoint(x: x, y: y))
                line.addLine(to: CGPoint(x: x - size.height * 0.015, y: y + size.height * 0.07))
                context.stroke(line, with: .color(.white.opacity(0.28)), lineWidth: 1.5)
            }
        }
        .allowsHitTesting(false)
    }
}

/// Fireflies drifting and blinking across the whole scene.
private struct Fireflies: View {
    let time: Double
    let count: Int
    let size: CGSize

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                let x = CGFloat(scatter(i, 11) + sin(time * 0.5 + Double(i)) * 0.03) * size.width
                let y = CGFloat(0.25 + scatter(i, 12) * 0.7 + cos(time * 0.4 + Double(i) * 1.3) * 0.04) * size.height
                let blink = 0.5 + 0.5 * sin(time * (1.6 + scatter(i, 13)) + Double(i) * 2.1)
                IntroArt(name: "intro-firefly")
                    .frame(width: size.height * 0.04, height: size.height * 0.04)
                    .opacity(0.3 + 0.7 * blink)
                    .position(x: x, y: y)
            }
        }
        .frame(width: size.width, height: size.height)
        .allowsHitTesting(false)
    }
}

/// Pink petals tumbling down on the breeze.
private struct Petals: View {
    let time: Double
    let count: Int

    var body: some View {
        Canvas { context, size in
            for i in 0..<count {
                let fall = (scatter(i, 21) + time * (0.07 + scatter(i, 22) * 0.06)).truncatingRemainder(dividingBy: 1)
                let x = CGFloat(scatter(i, 23) - fall * 0.25 + sin(time * 0.9 + Double(i)) * 0.03) * size.width
                let y = CGFloat(fall * 1.2 - 0.1) * size.height
                let petal = size.height * CGFloat(0.018 + scatter(i, 24) * 0.012)
                var leaf = context
                leaf.translateBy(x: x, y: y)
                leaf.rotate(by: .radians(time * (1 + scatter(i, 25)) + Double(i)))
                leaf.fill(Path(ellipseIn: CGRect(x: -petal, y: -petal * 0.55, width: petal * 2, height: petal * 1.1)),
                          with: .color(i % 3 == 0 ? Palette.blush : Palette.petal))
            }
        }
        .allowsHitTesting(false)
    }
}

/// A bunny hopping in from the side, then settling with a happy little bounce.
private struct HoppingBunny: View {
    let name: String
    let time: Double
    let from: Double
    let to: Double
    let y: Double
    let delay: Double
    let height: CGFloat
    let size: CGSize

    static let hops = 4.0
    static let hopSeconds = 0.42

    var body: some View {
        let travel = Self.hops * Self.hopSeconds
        let moving = min(max((time - delay) / travel, 0), 1)
        let hopPhase = moving < 1 ? (moving * Self.hops).truncatingRemainder(dividingBy: 1) : 0
        // One more hop on the spot once they arrive.
        let settle = time - delay - travel - 0.6
        let joy = settle > 0 && settle < Self.hopSeconds ? settle / Self.hopSeconds : 0
        let arc = CGFloat(max(sin(hopPhase * .pi), sin(joy * .pi)))
        let squash: CGFloat = arc < 0.15 && moving > 0 && (moving < 1 || joy > 0) ? 0.08 : 0
        let x = CGFloat(from + (to - from) * moving) * size.width
        let feet = CGFloat(y) * size.height - arc * height * 0.28
        let bob: CGFloat = moving >= 1 && joy == 0 ? CGFloat(1 - cos(time * 2 * .pi / 3.2)) / 2 * height * 0.02 : 0

        IntroArt(name: name)
            .frame(height: height)
            .scaleEffect(x: 1 + squash, y: 1 - squash, anchor: .bottom)
            .position(x: x, y: feet - height / 2 - bob)
            .frame(width: size.width, height: size.height)
            .allowsHitTesting(false)
    }
}
