import SwiftUI
import UIKit

/// A character portrait from the illustrated art: the head crop (`face-<id>`) for small
/// icons, the full detailed portrait (`person-<id>`) for big ones. Characters whose art
/// hasn't been added yet show a soft circle with their initial.
struct PersonPortrait: View {
    /// Kept so callers can pass today's look; the art itself doesn't change by day.
    let look: PersonLook
    /// The character's ID, used to look up artwork.
    var artID: String?
    var size: CGFloat = 60
    var time: Double?
    var isBlushing = false

    var body: some View {
        if size < 100, let face = PersonArt.face(for: artID) {
            Image(uiImage: face)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
                .background(Palette.lilacCard)
                .clipShape(.circle)
                .overlay(Circle().strokeBorder(Palette.lilacEdge.opacity(0.6), lineWidth: max(size * 0.03, 1)))
                .accessibilityHidden(true)
        } else if let artwork = PersonArt.image(for: artID) {
            Image(uiImage: artwork)
                .resizable()
                .scaledToFit()
                .frame(width: size * 0.85, height: size)
                .accessibilityHidden(true)
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        let side = size < 100 ? size : size * 0.6
        return Text(Person.find(artID ?? "")?.name.prefix(1).uppercased() ?? "?")
            .font(.system(size: side * 0.45, weight: .bold, design: .rounded))
            .foregroundStyle(Palette.ink.opacity(0.6))
            .frame(width: side, height: side)
            .background(Palette.lilacCard, in: .circle)
            .overlay(Circle().strokeBorder(Palette.lilacEdge.opacity(0.6), lineWidth: max(side * 0.03, 1)))
            .frame(height: size)
            .accessibilityHidden(true)
    }
}

/// A full-body walking sprite for the meadow (`walk-<id>-<facing>`). Shows nothing for
/// characters without walking art yet.
///
/// While walking, it steps: sideways it alternates the left and right art (one flipped), which
/// swaps the arms and legs like a two-frame walk cycle, and every step lifts and rocks the
/// sprite a little. Standing still, it breathes.
struct PersonFigure: View {
    let look: PersonLook
    var artID: String?
    var size: CGFloat = 60
    var time: Double?
    /// Which way they're walking.
    var facing: PersonArt.Facing = .front
    /// Walking plays the walk cycle; standing still bobs gently.
    var isWalking = false

    /// Idle bob: about 6 points of travel over a slow 3.2-second loop.
    static let bobHeight: CGFloat = 6
    static let bobPeriod = 3.2

    var body: some View {
        let t = time ?? 0
        // A walk cycle cut from video moves the legs itself. Without one, the picture glides
        // along smoothly (no fake bouncing or swaying).
        let cycle = isWalking ? PersonArt.cycleFrame(for: artID, facing: facing, time: t)
            : PersonArt.standFrame(for: artID, facing: facing)
        if let frame = cycle ?? PersonArt.walkFrame(for: artID, facing: facing, step: 0) {
            let bob = isWalking ? 0 : (1 - cos(t * 2 * .pi / Self.bobPeriod)) / 2 * Self.bobHeight

            ZStack(alignment: .bottom) {
                Ellipse()
                    .fill(Palette.ink.opacity(0.16 - 0.03 * bob / Self.bobHeight))
                    .frame(width: size * 0.36, height: size * 0.07)
                    .offset(y: size * 0.025)
                Image(uiImage: frame.image)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(height: size)
                    .scaleEffect(x: frame.isFlipped ? -1 : 1, y: 1)
                    .offset(y: -bob)
            }
        }
    }
}

/// Looks up illustrated character artwork in the asset catalog:
/// - `person-<id>`: the big detailed portrait used in dialogs and profiles.
/// - `face-<id>`: a head crop for small icons.
/// - `walk-<id>-front/back/left/right`: pixel sprites for walking around the meadow.
///
/// Your farmer's IDs start with `farmer|` and describe the whole look; their art is
/// recolored on the fly by `FarmerRenderer`.
enum PersonArt {
    enum Facing: String {
        case front, back, left, right

        /// What to show when a direction has no sprite yet.
        var fallbacks: [Facing] {
            switch self {
            case .front: return [.front, .right, .left]
            case .back: return [.back, .front, .right]
            case .left: return [.left, .right, .front]
            case .right: return [.right, .left, .front]
            }
        }
    }

    static func image(for id: String?) -> UIImage? {
        guard let id else { return nil }
        if let look = FarmerRenderer.look(from: id) { return FarmerRenderer.image(.person, look: look) }
        return UIImage(named: "person-\(id)")
    }

    static func face(for id: String?) -> UIImage? {
        guard let id else { return nil }
        if let look = FarmerRenderer.look(from: id) { return FarmerRenderer.image(.face, look: look) }
        return UIImage(named: "face-\(id)")
    }

    /// The sprite for one step of a walk. Sideways, odd steps use the opposite side's art
    /// flipped, so the arms and legs swap; front and back always use their own art.
    static func walkFrame(for id: String?, facing: Facing, step: Int) -> (image: UIImage, isFlipped: Bool)? {
        if step % 2 != 0, facing == .left || facing == .right, let id, !carriesHandbag(id) {
            let opposite: Facing = facing == .left ? .right : .left
            if let own = exactWalking(for: id, facing: facing), let other = exactWalking(for: id, facing: opposite),
               own !== other {
                return (other, true)
            }
        }
        return walking(for: id, facing: facing).map { ($0, false) }
    }

    /// Walk cycles cut from video: `<sprite>-00`, `<sprite>-01`, … (like `farmer-female-s1-right-00`
    /// or `walk-june-right-00`), played at the video's 24 frames a second.
    static let cycleFPS = 24.0
    /// Short drawn walk cycles play slower, so a full stride takes about as long as a filmed one.
    static let cycleRates: [String: Double] = ["walk-sol-pinafore-left": 4.6]
    private static var cycleLengths: [String: Int] = [:]

    private static func cycleLength(_ name: String) -> Int {
        if let count = cycleLengths[name] { return count }
        var count = 0
        while UIImage(named: name + String(format: "-%02d", count)) != nil { count += 1 }
        cycleLengths[name] = count
        return count
    }

    /// The step of each walk cycle with the feet closest together, for standing still side-on.
    static let standFrames: [String: Int] = ["farmer-female-s0-right": 11, "farmer-female-s0-sundress-right": 3, "farmer-female-s1-right": 8, "farmer-female-s1-sundress-right": 6, "farmer-female-s2-right": 5, "farmer-female-s2-sundress-right": 1, "farmer-male-s0-hoodie-right": 12, "farmer-male-s0-right": 17, "farmer-male-s1-hoodie-right": 16, "farmer-male-s1-right": 3, "farmer-male-s2-hoodie-right": 20, "farmer-male-s2-right": 7, "walk-bree-right": 25, "walk-silas-right": 12, "walk-june-right": 14, "walk-kai-right": 8, "walk-roz-right": 10, "walk-sol-right": 20, "walk-theo-right": 6, "walk-vi-right": 5, "walk-wes-right": 16]

    /// Standing still side-on: the feet-together step of their walk (for someone with no front
    /// picture). `nil` facing the front, or without a walk cycle.
    static func standFrame(for id: String?, facing: Facing) -> (image: UIImage, isFlipped: Bool)? {
        guard let id, facing == .left || facing == .right else { return nil }
        let look = FarmerRenderer.look(from: id)
        let name = look.map { FarmerRenderer.artName(.right, look: $0) } ?? "walk-\(id)-right"
        guard let index = standFrames[name] else { return nil }
        let frame = name + String(format: "-%02d", index)
        guard let image = look.map({ FarmerRenderer.image(named: frame, look: $0) }) ?? UIImage(named: frame) else {
            logMissing(frame, using: nil)
            return nil
        }
        return (image, facing == .left)
    }

    /// Whether this character has a video walk cycle for a direction (a mirrored one counts).
    static func hasWalkCycle(for id: String?, facing: Facing) -> Bool {
        cycleFrame(for: id, facing: facing, time: 0) != nil
    }

    /// The frame of a video walk cycle at a moment, when this character has one for this
    /// direction. Walking left can use the right cycle mirrored (and the other way around).
    static func cycleFrame(for id: String?, facing: Facing, time: Double) -> (image: UIImage, isFlipped: Bool)? {
        guard let id else { return nil }
        var options: [(direction: Facing, flipped: Bool)] = [(facing, false)]
        if facing == .left { options.append((.right, true)) }
        if facing == .right { options.append((.left, true)) }
        let look = FarmerRenderer.look(from: id)
        for option in options {
            let name = look.map { FarmerRenderer.artName(FarmerRenderer.Part(rawValue: option.direction.rawValue) ?? .front, look: $0) }
                ?? "walk-\(id)-\(option.direction.rawValue)"
            let count = cycleLength(name)
            guard count > 0 else { continue }
            let frame = name + String(format: "-%02d", Int(max(time, 0) * (cycleRates[name] ?? cycleFPS)) % count)
            let image = look.map { FarmerRenderer.image(named: frame, look: $0) } ?? UIImage(named: frame)
            if let image { return (image, option.flipped) }
            logMissing(frame, using: nil)
        }
        return nil
    }

    /// The fashionista look (the female farmer) carries her handbag on one side. Mirroring
    /// the other side's frame would flip the bag and her hair across her body every step,
    /// so she walks on her own frame for each direction, with the step bounce and sway.
    static func carriesHandbag(_ id: String) -> Bool {
        FarmerRenderer.look(from: id)?.gender == .female
    }

    /// Only the sprite for exactly this direction, with no fallback.
    static func exactWalking(for id: String, facing: Facing) -> UIImage? {
        if let look = FarmerRenderer.look(from: id) {
            return FarmerRenderer.image(FarmerRenderer.Part(rawValue: facing.rawValue) ?? .front, look: look)
        }
        return UIImage(named: "walk-\(id)-\(facing.rawValue)")
    }

    /// Whether this character has art facing the viewer (otherwise they stand side-on).
    static func hasFrontSprite(_ id: String) -> Bool {
        exactWalking(for: id, facing: .front) != nil
    }

    static func walking(for id: String?, facing: Facing) -> UIImage? {
        guard let id else { return nil }
        if let look = FarmerRenderer.look(from: id) {
            let part = FarmerRenderer.Part(rawValue: facing.rawValue) ?? .front
            if let sprite = FarmerRenderer.image(part, look: look) {
                return sprite
            }
            // Never another character's art: their own front sprite stands in.
            logMissing(FarmerRenderer.artName(part, look: look),
                       using: facing == .front ? nil : FarmerRenderer.artName(.front, look: look))
            return facing == .front ? nil : FarmerRenderer.image(.front, look: look)
        }
        for direction in facing.fallbacks {
            if let sprite = UIImage(named: "walk-\(id)-\(direction.rawValue)") {
                if direction != facing { logMissing("walk-\(id)-\(facing.rawValue)", using: "walk-\(id)-\(direction.rawValue)") }
                return sprite
            }
        }
        logMissing("walk-\(id)-\(facing.rawValue)", using: nil)
        return nil
    }

    /// Logs each missing sprite once. Only the same character's own art is ever used instead.
    private static var loggedMissing: Set<String> = []
    private static func logMissing(_ name: String, using fallback: String?) {
        guard !loggedMissing.contains(name) else { return }
        loggedMissing.insert(name)
        artLog.notice("Missing sprite \(name, privacy: .public); using \(fallback ?? "nothing", privacy: .public)")
    }
}

/// Pictures with their see-through margins cut off, so a figure is framed by the art itself
/// (some portraits have empty space above the head).
enum ArtTrim {
    private static let cache = NSCache<NSString, UIImage>()

    static func trimmed(_ image: UIImage, key: String) -> UIImage {
        if let done = cache.object(forKey: key as NSString) { return done }
        let result = trim(image)
        cache.setObject(result, forKey: key as NSString)
        return result
    }

    private static func trim(_ image: UIImage) -> UIImage {
        guard let cg = image.cgImage else { return image }
        let width = cg.width, height = cg.height
        var pixels = [UInt8](repeating: 0, count: width * height * 4)
        let drawn = pixels.withUnsafeMutableBytes { buffer -> Bool in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                          bytesPerRow: width * 4, space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        guard drawn else { return image }
        var minX = width, minY = height, maxX = -1, maxY = -1
        for y in 0..<height {
            for x in 0..<width where pixels[(y * width + x) * 4 + 3] > 8 {
                minX = min(minX, x); maxX = max(maxX, x)
                minY = min(minY, y); maxY = max(maxY, y)
            }
        }
        guard maxX >= minX, maxY >= minY,
              let cropped = cg.cropping(to: CGRect(x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1))
        else { return image }
        return UIImage(cgImage: cropped, scale: image.scale, orientation: image.imageOrientation)
    }
}

/// Draws your farmer: the art for their gender and hairstyle, with skin, hair, eyes, and
/// clothes recolored. Each image has a matching `-labels` map that marks those parts
/// (red = part × 32, green = brightness relative to the part), so shading and outlines are kept.
enum FarmerRenderer {
    enum Part: String {
        case person, face, front, back, left, right
    }

    private enum Label: Int, CaseIterable {
        case skin = 1, hair, iris, jacket, pants, top, boots
    }

    private static let cache = NSCache<NSString, UIImage>()

    /// The art ID for a look, like `farmer|female|1|2|pink|blue|latteWeekend`.
    static func artID(for look: FarmerLook) -> String {
        "farmer|\(look.gender.rawValue)|\(look.hairStyle)|\(look.skinTone)|\(look.hairColor)|\(look.eyeColor)|\(look.outfit)"
    }

    static func look(from id: String) -> FarmerLook? {
        let parts = id.split(separator: "|").map(String.init)
        guard parts.count == 7, parts[0] == "farmer", let gender = FarmerGender(rawValue: parts[1]),
              let style = Int(parts[2]), let tone = Int(parts[3]) else { return nil }
        return FarmerLook(gender: gender, hairStyle: style, skinTone: tone,
                          hairColor: parts[4], eyeColor: parts[5], outfit: parts[6])
    }

    static func image(_ part: Part, look: FarmerLook) -> UIImage? {
        image(named: artName(part, look: look), look: look)
    }

    /// Like `farmer-female-s1-front`, or `farmer-male-s2-hoodie-front` for an outfit with its own cut.
    static func artName(_ part: Part, look: FarmerLook) -> String {
        let cut = Outfit.find(look.outfit)?.cut ?? .jacket
        return "farmer-\(look.gender.rawValue)-s\(look.hairStyle)\(cut.artSuffix)-\(part.rawValue)"
    }

    /// Whether this hairstyle is drawn in this cut (the big portrait is enough: missing walking
    /// frames fall back to the front sprite).
    static func hasArt(gender: FarmerGender, hairStyle: Int, cut: OutfitCut) -> Bool {
        UIImage(named: "farmer-\(gender.rawValue)-s\(hairStyle)\(cut.artSuffix)-person") != nil
    }

    /// Any farmer picture recolored for a look, using its `<name>-labels` map (like the intro's
    /// `intro-fashionista-holding-suitcase`). Without a labels map it's shown as drawn.
    /// `drawnSkin` is for art whose skin isn't drawn in the farmer's own color (like the intro's
    /// hand): it's used when the look keeps the farmer's drawn skin tone.
    static func image(named name: String, look: FarmerLook, drawnSkin: RGB? = nil) -> UIImage? {
        let key = "\(artID(for: look))|\(name)" as NSString
        if let cached = cache.object(forKey: key) { return cached }
        guard let base = UIImage(named: name) else { return nil }
        var colors = targets(for: look)
        if colors[.skin] == nil { colors[.skin] = drawnSkin }
        var result = base
        if !colors.isEmpty, let labels = UIImage(named: "\(name)-labels") {
            // A map drawn for an older version of the picture would paint colors in the wrong
            // places, so it's only used when it matches the picture pixel for pixel.
            if labels.size == base.size, labels.scale == base.scale {
                if let recolored = recolor(base, labels: labels, colors: colors) { result = recolored }
            } else {
                artLog.notice("\(name, privacy: .public)-labels doesn't match the picture; showing it as drawn")
            }
        }
        cache.setObject(result, forKey: key)
        return result
    }

    private static func targets(for look: FarmerLook) -> [Label: RGB] {
        var colors: [Label: RGB] = [:]
        colors[.skin] = FarmerLook.skinSwatches[look.skinTone]?.rgb
        colors[.hair] = FarmerLook.hair(look.hairColor)?.rgb
        colors[.iris] = FarmerLook.eyes(look.eyeColor)?.rgb
        let outfit = Outfit.find(look.outfit)?.colors ?? OutfitColors()
        colors[.jacket] = outfit.jacket
        colors[.top] = outfit.top
        colors[.pants] = outfit.pants
        colors[.boots] = outfit.boots
        return colors
    }

    /// How much of the art's shading each part keeps: skin stays soft and even, clothes and
    /// hair keep more of their folds and shine.
    private static func contrast(_ label: Label) -> Double {
        switch label {
        case .skin: return 0.5
        case .hair: return 0.8
        case .iris: return 1
        default: return 0.85
        }
    }

    /// Maps the labels' shade value (128 = the part's typical brightness, ±64 per doubling)
    /// to a color: darker than typical scales the color down, brighter blends toward white.
    /// The shades of one color for every shading level. Hue and saturation come from the chosen
    /// color; lightness follows the art's own shading (labels' green channel), so a color looks
    /// the same on the big portrait and the small sprite instead of a multiply tint washing out.
    private static func ramp(_ color: RGB, contrast k: Double) -> [(UInt8, UInt8, UInt8)] {
        let (h, s, l) = hsl(color.r, color.g, color.b)
        return (0..<256).map { index in
            let f = pow(pow(2, (Double(index) - 128) / 64), k)
            let lightness = f <= 1 ? l * f : l + (1 - l) * min(f - 1, 1) * 0.75
            let (r, g, b) = rgb(h, s, max(0, min(1, lightness)))
            return (UInt8(max(0, min(255, r * 255))), UInt8(max(0, min(255, g * 255))), UInt8(max(0, min(255, b * 255))))
        }
    }

    private static func hsl(_ r: Double, _ g: Double, _ b: Double) -> (Double, Double, Double) {
        let mx = max(r, g, b), mn = min(r, g, b), l = (mx + mn) / 2
        guard mx > mn else { return (0, 0, l) }
        let d = mx - mn
        let s = l > 0.5 ? d / (2 - mx - mn) : d / (mx + mn)
        var h: Double
        if mx == r { h = (g - b) / d + (g < b ? 6 : 0) } else if mx == g { h = (b - r) / d + 2 } else { h = (r - g) / d + 4 }
        h /= 6
        return (h, s, l)
    }

    private static func rgb(_ h: Double, _ s: Double, _ l: Double) -> (Double, Double, Double) {
        guard s > 0 else { return (l, l, l) }
        let q = l < 0.5 ? l * (1 + s) : l + s - l * s, p = 2 * l - q
        func channel(_ t0: Double) -> Double {
            var t = t0
            if t < 0 { t += 1 }
            if t > 1 { t -= 1 }
            if t < 1 / 6 { return p + (q - p) * 6 * t }
            if t < 1 / 2 { return q }
            if t < 2 / 3 { return p + (q - p) * (2 / 3 - t) * 6 }
            return p
        }
        return (channel(h + 1 / 3), channel(h), channel(h - 1 / 3))
    }

    private static func pixels(of image: UIImage, width: Int, height: Int) -> [UInt8]? {
        guard let cg = image.cgImage else { return nil }
        var data = [UInt8](repeating: 0, count: width * height * 4)
        let drawn: Bool = data.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                                          bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else { return false }
            context.draw(cg, in: CGRect(x: 0, y: 0, width: width, height: height))
            return true
        }
        return drawn ? data : nil
    }

    private static func recolor(_ base: UIImage, labels: UIImage, colors: [Label: RGB]) -> UIImage? {
        guard let cg = base.cgImage else { return nil }
        let width = cg.width, height = cg.height
        guard var px = pixels(of: base, width: width, height: height),
              let lb = pixels(of: labels, width: width, height: height) else { return nil }
        var ramps = [[(UInt8, UInt8, UInt8)]?](repeating: nil, count: 8)
        for (label, color) in colors { ramps[label.rawValue] = ramp(color, contrast: contrast(label)) }

        for i in 0..<(width * height) {
            let o = i * 4
            let label = (Int(lb[o]) + 16) / 32
            guard label > 0, label < 8, let table = ramps[label] else { continue }
            let alpha = Int(px[o + 3])
            guard alpha > 0 else { continue }
            var (r, g, b) = (Int(table[Int(lb[o + 1])].0), Int(table[Int(lb[o + 1])].1), Int(table[Int(lb[o + 1])].2))
            // Blue marks blush on skin: a soft pink laid over whatever skin tone you chose,
            // instead of the drawn (darker) cheek color.
            let blush = Int(lb[o + 2])
            if label == Label.skin.rawValue, blush > 0 {
                let k = blush * 45 / 255
                r = (r * (100 - k) + 0xF2 * k) / 100
                g = (g * (100 - k) + 0x84 * k) / 100
                b = (b * (100 - k) + 0x9A * k) / 100
            }
            px[o] = UInt8(r * alpha / 255)
            px[o + 1] = UInt8(g * alpha / 255)
            px[o + 2] = UInt8(b * alpha / 255)
        }

        let image: CGImage? = px.withUnsafeMutableBytes { buffer in
            CGContext(data: buffer.baseAddress, width: width, height: height, bitsPerComponent: 8,
                      bytesPerRow: width * 4, space: CGColorSpace(name: CGColorSpace.sRGB)!,
                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)?.makeImage()
        }
        return image.map { UIImage(cgImage: $0, scale: base.scale, orientation: .up) }
    }
}

extension Meadow {
    /// The art ID for your farmer (optionally in another outfit), or `nil` before they're made.
    func farmerArtID(wearing outfitID: String? = nil) -> String? {
        guard var look = farmerLook else { return nil }
        if let outfitID { look.outfit = outfitID }
        return FarmerRenderer.artID(for: look)
    }
}

extension PersonLook {
    /// The player's farmer, dressed in their chosen outfit.
    static func farmer(wearing outfit: Outfit) -> PersonLook {
        PersonLook(skin: RGB(0xF2CBB0), hair: RGB(0x6B4B3E), hairStyle: .bob, eyes: RGB(0x4A3540),
                   outfit: outfit.main, outfitAccent: outfit.accent,
                   accessory: outfit.id == "bunnyHoodie" ? .headband : .none, accessoryColor: outfit.accent)
    }
}

#Preview {
    HStack {
        ForEach(Person.all) { person in
            VStack {
                PersonPortrait(look: person.look(onDay: 0), artID: person.id, size: 90)
                Text(person.name).font(.caption)
            }
        }
    }
    .padding()
    .background(Palette.blush)
}
