import SwiftUI
import UIKit

/// Draws any of the 50 breeds from its `BunnyLook`, with its idle behavior animated.
///
/// This is original placeholder art made from shapes and emoji, so every breed has a
/// distinct silhouette, pattern, and trait until illustrated artwork is added.
/// `size` is the bunny's full height, from ear tips to feet.
///
/// To use real artwork for a breed, add an image named `breed-<breed id>` (for example
/// `breed-honeybun`) to `Assets.xcassets`. It's picked up automatically and keeps the
/// breed's idle animation; breeds without artwork keep the drawn placeholder.
struct BreedBunnyView: View {
    let look: BunnyLook
    var behavior: BunnyBehavior = .hop
    var size: CGFloat = 60
    /// Drives the idle animation. Pass `nil` for a still portrait.
    var time: Double?
    var phase: Double = 0
    /// Emoji of an equipped accessory, if any.
    var accessory: String?
    /// Undiscovered breeds are shown as a soft silhouette.
    var isSilhouette = false
    /// The breed's ID, used to look up artwork named `breed-<id>`.
    var artID: String?

    init(breed: Breed, size: CGFloat = 60, time: Double? = nil, phase: Double = 0,
         accessory: String? = nil, isSilhouette: Bool = false) {
        look = breed.look
        behavior = breed.behavior
        self.size = size
        self.time = time
        self.phase = phase
        self.accessory = accessory
        self.isSilhouette = isSilhouette
        artID = breed.id
    }

    init(look: BunnyLook, size: CGFloat = 60) {
        self.look = look
        self.size = size
    }

    var body: some View {
        let s = size * CGFloat(look.size)
        let t = (time ?? 0) + phase
        let animated = time != nil && !isSilhouette
        let motion = Motion(behavior: behavior, t: t, s: s, animated: animated)

        ZStack {
            if look.traits.contains(.fairyWings) {
                wings(s: s, t: t, animated: animated)
            }
            if let artwork {
                Image(uiImage: artwork)
                    .resizable()
                    .scaledToFit()
                    .frame(width: s, height: s)
                    .overlay(alignment: .topTrailing) {
                        if let accessory {
                            AccessoryMark(emoji: accessory, size: s * 0.2)
                        }
                    }
            } else {
                BunnyFigure(look: look, s: s, t: t, motion: motion, accessory: accessory)
            }
            if animated {
                behaviorExtras(s: s, t: t)
                traitParticles(s: s, t: t)
            }
        }
        .rotationEffect(.degrees(motion.tilt), anchor: .bottom)
        .rotation3DEffect(.degrees(motion.spin), axis: (x: 0, y: 1, z: 0))
        .scaleEffect(x: motion.squashX, y: motion.squashY, anchor: .bottom)
        .offset(x: motion.dx, y: motion.dy)
        .shadow(color: look.traits.contains(.glow) && !isSilhouette ? Color(look.accent).opacity(0.9) : .clear,
                radius: look.traits.contains(.glow) ? s * 0.12 : 0)
        .frame(width: s * 0.8, height: s)
        .colorMultiply(isSilhouette ? Color(white: 0.35) : .white)
        .opacity(isSilhouette ? 0.45 : 1)
        .accessibilityHidden(true)
    }

    /// Illustrated artwork for this breed, if it's been added to the asset catalog.
    private var artwork: UIImage? {
        artID.flatMap { UIImage(named: "breed-\($0)") }
    }

    // MARK: Extras

    private func wings(s: CGFloat, t: Double, animated: Bool) -> some View {
        let flap = animated ? sin(t * 9) * 12 : 0
        return HStack(spacing: s * 0.2) {
            Ellipse()
                .fill(Color.white.opacity(0.55))
                .overlay(Ellipse().stroke(Color(look.accent), lineWidth: 1.5))
                .frame(width: s * 0.3, height: s * 0.42)
                .rotationEffect(.degrees(-30 - flap), anchor: .bottomTrailing)
            Ellipse()
                .fill(Color.white.opacity(0.55))
                .overlay(Ellipse().stroke(Color(look.accent), lineWidth: 1.5))
                .frame(width: s * 0.3, height: s * 0.42)
                .rotationEffect(.degrees(30 + flap), anchor: .bottomLeading)
        }
        .offset(y: s * 0.05)
    }

    @ViewBuilder
    private func behaviorExtras(s: CGFloat, t: Double) -> some View {
        switch behavior {
        case .nap:
            Text("💤")
                .font(.system(size: s * 0.22))
                .offset(x: s * 0.3, y: -s * 0.35 + sin(t) * 4)
                .opacity(0.5 + 0.4 * sin(t * 0.8))
        case .stargaze:
            Text("⭐️")
                .font(.system(size: s * 0.16))
                .offset(x: -s * 0.3, y: -s * 0.55)
                .opacity(0.4 + 0.6 * abs(sin(t * 1.3)))
        case .dig:
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Palette.bark.opacity(0.7))
                    .frame(width: s * 0.05, height: s * 0.05)
                    .offset(x: -s * 0.3 - CGFloat(index) * s * 0.06,
                            y: s * 0.42 - abs(sin(t * 6 + Double(index))) * s * 0.15)
            }
        case .nibble:
            Text("🥕")
                .font(.system(size: s * 0.14))
                .offset(x: -s * 0.18, y: s * 0.12)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    private func traitParticles(s: CGFloat, t: Double) -> some View {
        let particles: [(BunnyLook.Trait, String)] = [(.sparkles, "✨"), (.snowflakes, "❄️"), (.petals, "🌸"), (.bubbles, "🫧")]
        ForEach(particles.filter { look.traits.contains($0.0) }.indices, id: \.self) { index in
            let emoji = particles.filter { look.traits.contains($0.0) }[index].1
            ForEach(0..<2, id: \.self) { n in
                let cycle = (t * 0.6 + Double(n) * 0.5 + Double(index) * 0.25).truncatingRemainder(dividingBy: 1)
                Text(emoji)
                    .font(.system(size: s * 0.14))
                    .offset(x: (n == 0 ? -1 : 1) * s * (0.3 + 0.05 * Double(index)),
                            y: -s * 0.1 - CGFloat(cycle) * s * 0.4)
                    .opacity(1 - cycle)
            }
        }
    }
}

// MARK: - Motion

/// How a behavior moves the whole bunny at time `t`.
private struct Motion {
    var dx: CGFloat = 0
    var dy: CGFloat = 0
    var tilt: Double = 0
    var spin: Double = 0
    var squashX: CGFloat = 1
    var squashY: CGFloat = 1
    var eyesClosed = false
    var headTilt: Double = 0
    var noseWiggle: CGFloat = 0

    init(behavior: BunnyBehavior, t: Double, s: CGFloat, animated: Bool) {
        let blink = t.truncatingRemainder(dividingBy: 4) < 0.14
        eyesClosed = animated && blink
        guard animated else { return }
        switch behavior {
        case .hop:
            dy = -abs(sin(t * 4)) * s * 0.12
        case .nap:
            eyesClosed = true
            squashY = 1 + sin(t * 1.5) * 0.03
        case .nibble:
            headTilt = sin(t * 10) * 3
            noseWiggle = sin(t * 14) * 1.5
        case .groom:
            headTilt = sin(t * 2) * 8
        case .zoomies:
            dx = sin(t * 7) * s * 0.18
            dy = -abs(sin(t * 14)) * s * 0.08
        case .float:
            dy = -s * 0.08 - sin(t * 1.8) * s * 0.04
        case .twirl:
            let cycle = t.truncatingRemainder(dividingBy: 4)
            spin = cycle < 0.8 ? cycle / 0.8 * 360 : 0
            dy = cycle < 0.8 ? -sin(cycle / 0.8 * .pi) * s * 0.15 : 0
        case .dig:
            tilt = 12 + sin(t * 12) * 3
        case .flop:
            let cycle = t.truncatingRemainder(dividingBy: 7)
            tilt = cycle > 4 && cycle < 6 ? 75 : 0
            eyesClosed = cycle > 4 && cycle < 6
        case .sniff:
            dx = sin(t * 0.8) * s * 0.04
            noseWiggle = sin(t * 18) * 2
        case .wiggle:
            squashX = 1 + sin(t * 8) * 0.04
            noseWiggle = sin(t * 20) * 2
        case .stargaze:
            headTilt = -10
        }
    }
}

// MARK: - Figure

/// The bunny itself: ears, body, head, face, pattern, and worn traits.
private struct BunnyFigure: View {
    let look: BunnyLook
    let s: CGFloat
    let t: Double
    let motion: Motion
    let accessory: String?

    private var fur: Color { Color(look.fur) }
    private var accent: Color { Color(look.accent) }
    private var outline: Color { Palette.cocoa.opacity(0.3) }
    private var line: CGFloat { max(s * 0.02, 0.8) }

    private var furStyle: AnyShapeStyle {
        look.pattern == .gradient
            ? AnyShapeStyle(LinearGradient(colors: [fur, accent], startPoint: .top, endPoint: .bottom))
            : AnyShapeStyle(fur)
    }

    var body: some View {
        ZStack {
            tail
            if !isLop(left: true) { ear(left: true) }
            if !isLop(left: false) { ear(left: false) }

            // Body
            Ellipse()
                .fill(furStyle)
                .overlay(bodyPattern)
                .clipShape(Ellipse())
                .overlay(Ellipse().stroke(outline, lineWidth: line))
                .frame(width: s * 0.56, height: s * 0.42)
                .offset(y: s * 0.27)
            if look.isFluffy { fluff(width: s * 0.56, height: s * 0.42, y: s * 0.27) }
            feet

            head
                .rotationEffect(.degrees(motion.headTilt), anchor: .bottom)

            neckwear
        }
    }

    // MARK: Ears

    private func isLop(left: Bool) -> Bool {
        switch look.ears {
        case .lop: return true
        case .halfLop: return !left
        default: return false
        }
    }

    private var earHeight: CGFloat {
        switch look.ears {
        case .long: return s * 0.46
        case .tiny: return s * 0.18
        default: return s * 0.36
        }
    }

    private var earInner: AnyShapeStyle {
        look.traits.contains(.aurora)
            ? AnyShapeStyle(LinearGradient(colors: [Palette.mint, Palette.lavender, Palette.petal], startPoint: .top, endPoint: .bottom))
            : AnyShapeStyle(Palette.petal)
    }

    private func ear(left: Bool) -> some View {
        let angle: Double = look.ears == .tiny ? 20 : (look.ears == .long ? 8 : 14)
        return Capsule()
            .fill(furStyle)
            .overlay(Capsule().stroke(outline, lineWidth: line))
            .overlay(Capsule().fill(earInner).padding(.horizontal, s * 0.04).padding(.vertical, s * 0.05))
            .overlay(alignment: .top) {
                if look.ears == .tufted {
                    Circle().fill(Color.white).frame(width: s * 0.12, height: s * 0.12).offset(y: -s * 0.03)
                }
                if look.traits.contains(.crystals) {
                    Text("💎").font(.system(size: s * 0.1)).offset(y: -s * 0.06)
                }
            }
            .frame(width: s * 0.15, height: earHeight)
            .rotationEffect(.degrees((left ? -angle : angle) + (left ? -1 : 1) * sin(t * 2.2) * 3), anchor: .bottom)
            .offset(x: (left ? -1 : 1) * s * 0.12, y: -s * 0.15 - earHeight / 2)
    }

    private func lopEar(left: Bool) -> some View {
        Capsule()
            .fill(furStyle)
            .overlay(Capsule().stroke(outline, lineWidth: line))
            .overlay(Capsule().fill(earInner).padding(.horizontal, s * 0.04).padding(.vertical, s * 0.05).opacity(0.6))
            .frame(width: s * 0.14, height: s * 0.32)
            .rotationEffect(.degrees(left ? 14 : -14), anchor: .top)
            .offset(x: (left ? -1 : 1) * s * 0.29, y: s * 0.06)
    }

    // MARK: Head

    private var head: some View {
        ZStack {
            Ellipse()
                .fill(furStyle)
                .overlay(headPattern)
                .clipShape(Ellipse())
                .overlay(Ellipse().stroke(outline, lineWidth: line))
                .frame(width: s * 0.6, height: s * 0.48)
                .offset(y: -s * 0.02)
            if look.isFluffy { fluff(width: s * 0.6, height: s * 0.48, y: -s * 0.02) }
            if isLop(left: true) { lopEar(left: true) }
            if isLop(left: false) { lopEar(left: false) }

            HStack(spacing: s * 0.2) {
                eye
                eye
            }
            .offset(y: -s * 0.04)
            HStack(spacing: s * 0.28) {
                cheek
                cheek
            }
            .offset(y: s * 0.05)
            Ellipse()
                .fill(Palette.rose)
                .frame(width: s * 0.05 + motion.noseWiggle, height: s * 0.035)
                .offset(y: s * 0.03)

            headwear
        }
    }

    private var eye: some View {
        Capsule()
            .fill(Color(look.eye))
            .frame(width: s * 0.055, height: motion.eyesClosed ? s * 0.012 : s * 0.075)
            .overlay(alignment: .topTrailing) {
                if !motion.eyesClosed {
                    Circle().fill(Color.white).frame(width: s * 0.02, height: s * 0.02).offset(x: -s * 0.005, y: s * 0.008)
                }
            }
    }

    private var cheek: some View {
        Ellipse()
            .fill(Palette.petal.opacity(0.75))
            .frame(width: s * 0.1, height: s * 0.055)
    }

    @ViewBuilder
    private var headwear: some View {
        let top = -s * 0.24
        if look.traits.contains(.moonHalo) {
            Ellipse()
                .stroke(Palette.butter, lineWidth: max(s * 0.03, 1.5))
                .frame(width: s * 0.36, height: s * 0.08)
                .offset(y: top - s * 0.12)
        }
        if look.traits.contains(.flowerCrown) {
            Text("🌸🌼🌸").font(.system(size: s * 0.1)).offset(y: top)
        }
        if look.traits.contains(.crown) {
            Text("👑").font(.system(size: s * 0.16)).offset(y: top - s * 0.02)
        }
        if look.traits.contains(.leafSprout) {
            Text("🌱").font(.system(size: s * 0.14)).offset(y: top - s * 0.02)
        }
        if look.traits.contains(.mushroomCap) {
            Text("🍄").font(.system(size: s * 0.14)).offset(x: s * 0.14, y: top)
        }
        if look.traits.contains(.starMark) {
            Text("⭐️").font(.system(size: s * 0.08)).offset(y: -s * 0.14)
        }
        if look.traits.contains(.berryClip) {
            Text("🍓").font(.system(size: s * 0.1)).offset(x: -s * 0.2, y: top + s * 0.04)
        }
        if let accessory {
            AccessoryMark(emoji: accessory, size: s * 0.18).offset(x: s * 0.2, y: top + s * 0.04)
        }
    }

    // MARK: Body parts

    private var tail: some View {
        let isRainbow = look.traits.contains(.rainbowTail)
        let isCloud = look.traits.contains(.cloudPuff)
        let size = s * (isCloud ? 0.24 : (isRainbow ? 0.22 : 0.16))
        return Circle()
            .fill(isRainbow
                  ? AnyShapeStyle(AngularGradient(colors: [Palette.petal, Palette.butter, Palette.mint, Palette.sky, Palette.lavender, Palette.petal], center: .center))
                  : AnyShapeStyle(isCloud ? Color.white : fur))
            .overlay(Circle().stroke(outline, lineWidth: line))
            .frame(width: size, height: size)
            .offset(x: s * 0.27, y: s * 0.3)
    }

    private var feet: some View {
        let sockColor = look.pattern == .socks ? accent : fur
        return HStack(spacing: s * 0.12) {
            Ellipse().fill(sockColor).overlay(Ellipse().stroke(outline, lineWidth: line)).frame(width: s * 0.16, height: s * 0.09)
            Ellipse().fill(sockColor).overlay(Ellipse().stroke(outline, lineWidth: line)).frame(width: s * 0.16, height: s * 0.09)
        }
        .offset(y: s * 0.46)
    }

    @ViewBuilder
    private var neckwear: some View {
        if look.traits.contains(.scarf) {
            Capsule().fill(accent).frame(width: s * 0.42, height: s * 0.07).offset(y: s * 0.21)
            Capsule().fill(accent).frame(width: s * 0.07, height: s * 0.16).offset(x: s * 0.12, y: s * 0.28)
        }
        if look.traits.contains(.bowtie) {
            HStack(spacing: -s * 0.01) {
                Triangle().fill(accent).frame(width: s * 0.08, height: s * 0.07).rotationEffect(.degrees(90))
                Circle().fill(accent).frame(width: s * 0.04, height: s * 0.04)
                Triangle().fill(accent).frame(width: s * 0.08, height: s * 0.07).rotationEffect(.degrees(-90))
            }
            .offset(y: s * 0.21)
        }
        if look.traits.contains(.bell) {
            Circle().fill(Palette.butter).overlay(Circle().stroke(outline, lineWidth: line)).frame(width: s * 0.07, height: s * 0.07).offset(y: s * 0.23)
        }
    }

    /// Scalloped puffs around an ellipse, for fluffy breeds.
    private func fluff(width: CGFloat, height: CGFloat, y: CGFloat) -> some View {
        ForEach(0..<10, id: \.self) { index in
            let angle = Double(index) / 10 * 2 * .pi
            Circle()
                .fill(furStyle)
                .frame(width: s * 0.1, height: s * 0.1)
                .offset(x: cos(angle) * width * 0.48, y: y + sin(angle) * height * 0.48)
        }
    }

    // MARK: Patterns

    @ViewBuilder
    private var bodyPattern: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            switch look.pattern {
            case .spots:
                ForEach(0..<5, id: \.self) { i in
                    Circle().fill(accent)
                        .frame(width: w * 0.12, height: w * 0.12)
                        .position(x: w * (0.2 + 0.6 * hash01(i, 3)), y: h * (0.25 + 0.5 * hash01(i, 4)))
                }
            case .speckles:
                ForEach(0..<14, id: \.self) { i in
                    Circle().fill(accent)
                        .frame(width: w * 0.04, height: w * 0.04)
                        .position(x: w * hash01(i, 5), y: h * hash01(i, 6))
                }
            case .patches:
                Ellipse().fill(accent).frame(width: w * 0.45, height: h * 0.5).position(x: w * 0.25, y: h * 0.4)
                Ellipse().fill(accent).frame(width: w * 0.3, height: h * 0.35).position(x: w * 0.8, y: h * 0.7)
            case .saddle:
                Ellipse().fill(accent).frame(width: w * 0.6, height: h * 0.55).position(x: w * 0.5, y: h * 0.75)
            case .tuxedo:
                Ellipse().fill(accent).frame(width: w * 0.4, height: h * 0.8).position(x: w * 0.5, y: h * 0.6)
            case .stripe:
                ForEach(0..<3, id: \.self) { i in
                    Capsule().fill(accent)
                        .frame(width: w * 0.08, height: h * 0.7)
                        .position(x: w * (0.3 + 0.2 * Double(i)), y: h * 0.4)
                }
            case .heart:
                Image(systemName: "heart.fill").font(.system(size: w * 0.3)).foregroundStyle(accent).position(x: w * 0.5, y: h * 0.45)
            case .crescent:
                Image(systemName: "moon.fill").font(.system(size: w * 0.3)).foregroundStyle(accent).position(x: w * 0.6, y: h * 0.4)
            case .socks, .mask, .gradient, .solid:
                EmptyView()
            }
        }
    }

    @ViewBuilder
    private var headPattern: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height
            switch look.pattern {
            case .mask:
                Ellipse().fill(accent).frame(width: w * 0.75, height: h * 0.32).position(x: w * 0.5, y: h * 0.42)
            case .patches:
                Ellipse().fill(accent).frame(width: w * 0.32, height: h * 0.38).position(x: w * 0.3, y: h * 0.4)
            case .spots:
                Circle().fill(accent).frame(width: w * 0.1, height: w * 0.1).position(x: w * 0.7, y: h * 0.25)
            case .speckles:
                ForEach(0..<5, id: \.self) { i in
                    Circle().fill(accent)
                        .frame(width: w * 0.035, height: w * 0.035)
                        .position(x: w * (0.15 + 0.7 * hash01(i, 8)), y: h * (0.1 + 0.3 * hash01(i, 9)))
                }
            case .tuxedo:
                Ellipse().fill(accent).frame(width: w * 0.35, height: h * 0.4).position(x: w * 0.5, y: h * 0.85)
            default:
                EmptyView()
            }
        }
    }
}

struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    ScrollView {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))]) {
            ForEach(Breed.all) { breed in
                VStack {
                    BreedBunnyView(breed: breed, size: 70)
                    Text(breed.name).font(.caption2)
                }
            }
        }
        .padding()
    }
    .background(Palette.meadow)
}

/// A bunny's accessory: its icon (`accessory-<id>`) when there is one, otherwise its emoji.
struct AccessoryMark: View {
    let emoji: String
    let size: CGFloat

    var body: some View {
        if let accessory = BunnyAccessory.all.first(where: { $0.emoji == emoji }) {
            ArtIcon(name: "accessory-\(accessory.id)", emoji: emoji, size: size)
        } else {
            Text(emoji).font(.system(size: size * 0.8))
        }
    }
}
