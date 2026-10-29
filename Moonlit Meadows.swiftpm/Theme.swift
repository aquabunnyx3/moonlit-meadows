import SwiftUI
import UIKit

/// The pastel colors used everywhere in the game.
///
/// They live in their own namespace so they don't collide with built-in colors like `Color.mint`.
enum Palette {
    static let blush = Color(red: 1.0, green: 0.91, blue: 0.93)
    static let petal = Color(red: 0.98, green: 0.73, blue: 0.82)
    static let rose = Color(red: 0.93, green: 0.52, blue: 0.66)
    static let lavender = Color(red: 0.86, green: 0.81, blue: 0.98)
    static let lilac = Color(red: 0.72, green: 0.64, blue: 0.93)
    static let mint = Color(red: 0.78, green: 0.94, blue: 0.87)
    static let butter = Color(red: 1.0, green: 0.94, blue: 0.72)
    static let peach = Color(red: 1.0, green: 0.85, blue: 0.76)
    static let sky = Color(red: 0.80, green: 0.90, blue: 1.0)
    static let cream = Color(red: 1.0, green: 0.98, blue: 0.95)
    static let cocoa = Color(red: 0.47, green: 0.31, blue: 0.37)
    static let meadow = Color(red: 0.74, green: 0.91, blue: 0.75)
    static let farHill = Color(red: 0.82, green: 0.93, blue: 0.84)
    static let soil = Color(red: 0.86, green: 0.70, blue: 0.64)
    static let darkSoil = Color(red: 0.76, green: 0.58, blue: 0.53)
    static let bark = Color(red: 0.72, green: 0.55, blue: 0.50)
    static let night = Color(red: 0.36, green: 0.32, blue: 0.58)

    // Pixel-meadow colors, sampled from the world and panel art.
    /// The meadow grass, shown around the art on very wide screens.
    static let ground = Color(red: 0.765, green: 0.796, blue: 0.98)
    /// Dark navy text, like the lettering in the pixel mockups.
    static let ink = Color(red: 0.243, green: 0.247, blue: 0.471)
    static let periwinkle = Color(red: 0.80, green: 0.82, blue: 0.98)
    static let periwinkleEdge = Color(red: 0.50, green: 0.54, blue: 0.84)
    static let lilacCard = Color(red: 0.93, green: 0.85, blue: 0.97)
    static let lilacEdge = Color(red: 0.64, green: 0.53, blue: 0.83)
    static let pinkCard = Color(red: 0.98, green: 0.83, blue: 0.90)
    static let pinkEdge = Color(red: 0.87, green: 0.53, blue: 0.70)
}

/// A chunky card with a dark outer edge and a light inner rim, like the pixel-art mockups.
struct PixelPanel: ViewModifier {
    var fill: Color
    var edge: Color
    var cornerRadius: CGFloat = 12

    func body(content: Content) -> some View {
        content
            .background {
                let shape = RoundedRectangle(cornerRadius: cornerRadius)
                shape.fill(fill)
                    .overlay(shape.inset(by: 3).strokeBorder(.white.opacity(0.55), lineWidth: 1.5))
                    .overlay(shape.strokeBorder(edge, lineWidth: 2.5))
                    .shadow(color: edge.opacity(0.35), radius: 0, x: 0, y: 2)
            }
    }
}

extension View {
    func pixelPanel(_ fill: Color, edge: Color, cornerRadius: CGFloat = 12) -> some View {
        modifier(PixelPanel(fill: fill, edge: edge, cornerRadius: cornerRadius))
    }
}

extension Color {
    init(_ rgb: RGB) {
        self.init(red: rgb.r, green: rgb.g, blue: rgb.b)
    }
}

/// Text where every "🪙" is drawn as the silver moon coin from the design art.
///
/// Prices and rewards keep using "🪙" in their strings, so this is the one place that turns
/// it into the coin image.
func coinText(_ string: String) -> Text {
    let parts = string.components(separatedBy: "🪙")
    var text = Text(parts[0])
    for part in parts.dropFirst() {
        text = text + Text(Image("moon-coin")).baselineOffset(-3) + Text(part)
    }
    return text
}

/// A crop or treat icon. Magical crops get a hue shift and a soft glow until real art exists.
struct ItemIcon: View {
    let itemID: String
    var size: CGFloat = 24

    var body: some View {
        if let art = UIImage(named: "crop-\(itemID)") {
            Image(uiImage: art)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: size * 1.15, height: size * 1.15)
                .accessibilityLabel(ItemInfo.name(itemID))
        } else {
            emoji
        }
    }

    private var emoji: some View {
        let crop = Crop.find(itemID)
        return Text(ItemInfo.emoji(itemID))
            .font(.system(size: size))
            .hueRotation(.degrees(crop?.hueShift ?? 0))
            .shadow(color: crop?.glow.map { Color($0) } ?? .clear, radius: crop?.glow == nil ? 0 : size * 0.3)
            .overlay(alignment: .topTrailing) {
                if crop?.isMagical == true {
                    Text("✨")
                        .font(.system(size: size * 0.4))
                        .offset(x: size * 0.15, y: -size * 0.1)
                }
            }
            .accessibilityLabel(ItemInfo.name(itemID))
    }
}

/// A decoration's pixel icon (`decor-icon-<id>`), or its emoji until art exists.
struct DecorIcon: View {
    let item: Decor
    var size: CGFloat = 32

    var body: some View {
        if let art = UIImage(named: "decor-icon-\(item.id)") {
            Image(uiImage: art)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: size, height: size)
                .accessibilityLabel(item.name)
        } else {
            Text(item.emoji).font(.system(size: size * 0.85))
        }
    }
}

/// Pops (1.0 → `scale` → 1.0) whenever `value` goes up, for coins, gems, and item counts.
struct PopOnIncrease: ViewModifier {
    let value: Int
    var scale: CGFloat = 1.1
    @State private var popped = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(popped ? scale : 1)
            .onChange(of: value) { old, new in
                guard new > old else { return }
                withAnimation(.easeOut(duration: 0.12)) { popped = true }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(140))
                    withAnimation(.easeIn(duration: 0.14)) { popped = false }
                }
            }
    }
}

extension View {
    func popOnIncrease(_ value: Int, scale: CGFloat = 1.1) -> some View {
        modifier(PopOnIncrease(value: value, scale: scale))
    }
}

/// When a ready crop is harvested, its icon pops (1.0 → 1.15 → 1.0) with a little sparkle.
struct HarvestPop: ViewModifier {
    let isReady: Bool
    let cropID: String?
    let size: CGFloat
    @State private var poppedID: String?
    @State private var scale: CGFloat = 1
    @State private var lastReadyID: String?

    func body(content: Content) -> some View {
        content
            .overlay {
                if let poppedID {
                    ZStack {
                        ItemIcon(itemID: poppedID, size: size)
                            .scaleEffect(scale)
                        Text("✨")
                            .font(.system(size: size * 0.6))
                            .offset(x: size * 0.45, y: -size * 0.45)
                            .scaleEffect(scale)
                    }
                    .allowsHitTesting(false)
                    .transition(.opacity)
                }
            }
            .onAppear { if isReady { lastReadyID = cropID } }
            .onChange(of: isReady) { wasReady, ready in
                if ready { lastReadyID = cropID; return }
                guard wasReady, let id = lastReadyID else { return }
                poppedID = id
                withAnimation(.easeOut(duration: 0.12)) { scale = 1.15 }
                Task { @MainActor in
                    try? await Task.sleep(for: .milliseconds(130))
                    withAnimation(.easeIn(duration: 0.14)) { scale = 1 }
                    try? await Task.sleep(for: .milliseconds(260))
                    withAnimation(.easeOut(duration: 0.2)) { poppedID = nil }
                }
            }
    }
}

extension View {
    func harvestPop(isReady: Bool, cropID: String?, size: CGFloat) -> some View {
        modifier(HarvestPop(isReady: isReady, cropID: cropID, size: size))
    }
}

/// A pixel icon from the asset catalog, or an emoji until the art exists.
struct ArtIcon: View {
    let name: String
    let emoji: String
    var size: CGFloat = 28

    var body: some View {
        if let art = UIImage(named: name) {
            Image(uiImage: art)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            Text(emoji).font(.system(size: size * 0.8))
        }
    }
}

/// The rarity stars (`rarity-0` … `rarity-4`, colored by rarity) with the rarity's name.
struct RarityTag: View {
    let rarity: Rarity
    var showsName = true
    var height: CGFloat = 14

    var body: some View {
        HStack(spacing: 4) {
            if let art = UIImage(named: "rarity-\(rarity.rawValue)") {
                Image(uiImage: art)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(height: height)
            } else {
                Text(rarity.stars).font(.system(size: height * 0.7))
            }
            if showsName {
                Text(rarity.name).font(.caption2.bold())
            }
        }
        .padding(.horizontal, showsName ? 7 : 0)
        .padding(.vertical, showsName ? 3 : 0)
        .background(showsName ? Color(rarity.color) : .clear, in: .capsule)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(rarity.name), \(rarity.rawValue + 1) star\(rarity.rawValue == 0 ? "" : "s")")
    }
}

/// Squishes a little when pressed, with the tap sound.
struct SquishButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { MusicPlayer.shared.playEffect(.buttonTap) }
            }
    }
}

/// Looks like `.plain`, with the tap sound.
struct PlainTapButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
            .onChange(of: configuration.isPressed) { _, pressed in
                if pressed { MusicPlayer.shared.playEffect(.buttonTap) }
            }
    }
}

/// Set once on the whole game: buttons without a style of their own keep their usual look
/// and play the tap sound. Buttons with their own style (like `SquishButtonStyle`) play it there.
struct TapSoundButtonStyle: PrimitiveButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button(role: configuration.role) {
            MusicPlayer.shared.playEffect(.buttonTap)
            configuration.trigger()
        } label: {
            configuration.label
        }
        .buttonStyle(.automatic)
    }
}

/// A soft rounded card used for rows in the control panel.
struct CozyCard<Content: View>: View {
    var tint: Color = .white
    @ViewBuilder let content: () -> Content

    var body: some View {
        content()
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint.opacity(0.8), in: .rect(cornerRadius: 18))
    }
}

/// A pill-shaped button, like "🪙 120" or "Bake".
struct PriceButton: View {
    let label: String
    let isEnabled: Bool
    var color: Color = Palette.rose
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            coinText(label)
                .font(.subheadline.bold())
                .monospacedDigit()
                .lineLimit(1)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(isEnabled ? color : Palette.cocoa.opacity(0.12), in: .capsule)
                .foregroundStyle(isEnabled ? .white : Palette.cocoa.opacity(0.5))
        }
        .buttonStyle(SquishButtonStyle())
        .disabled(!isEnabled)
    }
}

/// Section title with a little heart, like the headers on the concept board.
struct SectionTitle: View {
    let text: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: "heart.fill")
                .foregroundStyle(Palette.rose)
                .font(.caption)
            Text(text)
                .font(.headline)
            Spacer()
        }
    }
}

/// A small rounded tag, like "Rare" or "Helper".
struct CozyTag: View {
    let text: String
    var color: Color = Palette.mint

    var body: some View {
        Text(text)
            .font(.caption2.bold())
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color, in: .capsule)
    }
}

/// A row of reward labels.
struct RewardList: View {
    let rewards: [Reward]

    var body: some View {
        coinText(rewards.map(\.label).joined(separator: "  ·  "))
            .font(.caption.weight(.semibold))
            .opacity(0.8)
    }
}
