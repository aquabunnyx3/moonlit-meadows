import SwiftUI
import UIKit

/// Plays a story chapter line by line, with a choice at the end. Also shows short moments
/// (gift reactions, activities, dates) and the collection-complete finale.
struct StorySceneView: View {
    let meadow: Meadow
    let scene: ScenePresentation
    let close: () -> Void

    var body: some View {
        ZStack {
            switch scene {
            case .story(let event):
                StoryPlayer(meadow: meadow, event: event, close: close)
            case .moment(let moment):
                MomentView(meadow: meadow, moment: moment, close: close)
            case .completion:
                CompletionView(meadow: meadow, close: close)
            }
            // Silas's little spy is always there for the big moments (story
            // bible, section 9): story chapters and the completion finale.
            if showsSpyBee {
                SpyBee()
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(.top, 56)
                    .padding(.trailing, 20)
            }
        }
    }

    private var showsSpyBee: Bool {
        switch scene {
        case .moment: return false
        default: return true
        }
    }
}

/// One particular bee of Silas's — golden, with a single lavender stripe —
/// who turns up wherever something important is happening and reports back
/// to the hive. She bobs and drifts a little, the way bees do.
struct SpyBee: View {
    var size: CGFloat = 36

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Image("bee-spy")
                .resizable()
                .interpolation(.none)
                .scaledToFit()
                .frame(width: size, height: size)
                .offset(x: sin(t * 0.8) * 6, y: sin(t * 2.2) * 4)
        }
        .frame(width: size + 16, height: size + 12)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Dialog stage

/// The meadow, softly blurred, behind every dialog.
struct DialogBackdrop: View {
    var isRomantic: Bool

    var body: some View {
        ZStack {
            if let art = WorldArt.meadow {
                Image(uiImage: art)
                    .resizable()
                    .scaledToFill()
                    .blur(radius: 6)
            }
            LinearGradient(colors: isRomantic
                           ? [Palette.blush.opacity(0.75), Palette.lavender.opacity(0.6), Palette.petal.opacity(0.8)]
                           : [Palette.cream.opacity(0.55), Palette.lavender.opacity(0.45), Palette.periwinkle.opacity(0.7)],
                           startPoint: .top, endPoint: .bottom)
            if isRomantic {
                FloatingHearts()
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Chat scenes

/// How someone looks while they say a line, read from its words (what's inside the quotes,
/// when the line has narration too). Shows `chat-<id>-<mood>`: a face painted over their chat
/// scene at `ChatLayout.faces`, or `person-<id>-<mood>` for someone who uses the shared scene.
enum ChatMood: String {
    case neutral, happy, sad, surprised, blush

    private static let blushWords = #"\b(blush|blushing|blushes|cheeks|kiss|kissed|romantic|crush|flustered|my heart|date)\b"#
    private static let surprisedWords = #"\b(whoa|wow|no way|what\?|really\?|wait[!,—]|stop[.!]|oh my|is that a|for me\?)|\?!|!\?"#
    private static let sadWords = #"\b(sorry|miss|missed|sad|cry|crying|tears|lonely|worried|worry|afraid|scared|hurts?|lost|wish|nervous|alone|ugh)\b"#
    private static let happyWords = #"!|\b(haha|ha|love|loved|thank|thanks|glad|yay|happy|best|favorite|laugh|perfect|wonderful|lucky)\b"#

    static func of(_ text: String) -> ChatMood {
        let quotes = text.split(separator: "“").dropFirst().compactMap { $0.split(separator: "”").first }
        let said = (quotes.isEmpty ? text : quotes.joined(separator: " ")).lowercased()
        // Blushing goes by the whole line: the narration often says it ("cheeks pink").
        if text.lowercased().range(of: blushWords, options: .regularExpression) != nil { return .blush }
        for (pattern, mood) in [(surprisedWords, ChatMood.surprised), (sadWords, .sad), (happyWords, .happy)]
        where said.range(of: pattern, options: .regularExpression) != nil {
            return mood
        }
        return .neutral
    }
}

/// Where the name tag and the words sit on a chat image (`chat-<id>`), as fractions of the
/// image. The images come with their pixel boxes drawn in, with the text removed.
struct ChatLayout {
    let tag: CGRect
    let box: CGRect
    let tagIsLight: Bool

    /// Where each expression face (`chat-<id>-<mood>`) sits on its chat image.
    static let faces: [String: CGRect] = [
        "bree-blush": rect(0.2515, 0.1347, 0.389, 0.4305),
        "bree-happy": rect(0.234, 0.1391, 0.387, 0.4269),
        "bree-sad": rect(0.254, 0.1382, 0.395, 0.4287),
        "bree-surprised": rect(0.237, 0.1391, 0.391, 0.4278),
        "farmer-female-blush": rect(0.2055, 0.2165, 0.3565, 0.485),
        "farmer-female-happy": rect(0.2085, 0.2227, 0.3535, 0.4877),
        "farmer-female-s0-blush": rect(0.189, 0.0998, 0.3557, 0.5052),
        "farmer-female-s0-happy": rect(0.191, 0.0964, 0.3472, 0.5095),
        "farmer-female-s0-sad": rect(0.192, 0.0885, 0.3502, 0.5078),
        "farmer-female-s0-surprised": rect(0.1994, 0.0998, 0.3725, 0.5122),
        "farmer-female-s1-sundress-blush": rect(0.19, 0.3446, 0.3596, 0.4045),
        "farmer-female-s2-blush": rect(0.1429, 0.0686, 0.3586, 0.5078),
        "farmer-female-s2-happy": rect(0.1409, 0.0686, 0.3591, 0.5122),
        "farmer-female-s2-sad": rect(0.1414, 0.0365, 0.369, 0.5104),
        "farmer-female-s2-surprised": rect(0.1543, 0.0677, 0.3611, 0.4922),
        "farmer-female-sad": rect(0.206, 0.2192, 0.3555, 0.4859),
        "farmer-female-surprised": rect(0.216, 0.2245, 0.3665, 0.4912),
        "farmer-male-blush": rect(0.3985, 0.1963, 0.6025, 0.5431),
        "farmer-male-happy": rect(0.3965, 0.1787, 0.5925, 0.5255),
        "farmer-male-s0-blush": rect(0.1865, 0.184, 0.3438, 0.5269),
        "farmer-male-s0-happy": rect(0.1875, 0.1832, 0.3457, 0.4714),
        "farmer-male-s0-hoodie-blush": rect(0.1885, 0.1823, 0.3472, 0.5286),
        "farmer-male-s0-hoodie-happy": rect(0.184, 0.184, 0.3482, 0.4818),
        "farmer-male-s0-hoodie-sad": rect(0.19, 0.1892, 0.3487, 0.4748),
        "farmer-male-s0-hoodie-surprised": rect(0.1726, 0.1797, 0.3403, 0.4939),
        "farmer-male-s0-sad": rect(0.1885, 0.184, 0.3433, 0.4601),
        "farmer-male-s0-surprised": rect(0.1801, 0.178, 0.3373, 0.4722),
        "farmer-male-s2-blush": rect(0.1478, 0.0825, 0.3562, 0.5174),
        "farmer-male-s2-happy": rect(0.1463, 0.0851, 0.3562, 0.4444),
        "farmer-male-s2-hoodie-blush": rect(0.129, 0.0807, 0.3646, 0.5764),
        "farmer-male-s2-hoodie-happy": rect(0.125, 0.0825, 0.3631, 0.4948),
        "farmer-male-s2-hoodie-sad": rect(0.125, 0.0773, 0.3631, 0.5356),
        "farmer-male-s2-hoodie-surprised": rect(0.1746, 0.0825, 0.3869, 0.5017),
        "farmer-male-s2-sad": rect(0.1458, 0.0842, 0.3606, 0.4965),
        "farmer-male-s2-surprised": rect(0.1915, 0.0851, 0.3775, 0.4514),
        "farmer-male-sad": rect(0.396, 0.1805, 0.593, 0.5255),
        "farmer-male-surprised": rect(0.3995, 0.1769, 0.594, 0.5326),
        "june-blush": rect(0.197, 0.0898, 0.3245, 0.3715),
        "june-happy": rect(0.1965, 0.0907, 0.3405, 0.3636),
        "june-sad": rect(0.2, 0.1065, 0.3555, 0.3715),
        "june-surprised": rect(0.198, 0.0924, 0.3295, 0.3644),
        "kai-blush": rect(0.159, 0.1259, 0.325, 0.4269),
        "kai-happy": rect(0.1665, 0.147, 0.3195, 0.4243),
        "kai-sad": rect(0.162, 0.1611, 0.324, 0.441),
        "kai-surprised": rect(0.1715, 0.147, 0.325, 0.4313),
        "rowan-blush": rect(0.1696, 0.2899, 0.3299, 0.3542),
        "rowan-happy": rect(0.1592, 0.0122, 0.3413, 0.4323),
        "rowan-sad": rect(0.1637, 0.02, 0.3442, 0.4366),
        "rowan-surprised": rect(0.186, 0.0851, 0.3542, 0.4618),
        "roz-blush": rect(0.1319, 0.0512, 0.376, 0.4792),
        "roz-happy": rect(0.1314, 0.0399, 0.3646, 0.4792),
        "roz-sad": rect(0.1319, 0.0356, 0.3631, 0.4835),
        "roz-surprised": rect(0.125, 0.0234, 0.3497, 0.4774),
        "silas-blush": rect(0.185, 0.1215, 0.3274, 0.388),
        "silas-happy": rect(0.1999, 0.112, 0.311, 0.3681),
        "silas-sad": rect(0.2059, 0.1241, 0.3244, 0.375),
        "silas-surprised": rect(0.1994, 0.0972, 0.3145, 0.3681),
        "sol-blush": rect(0.2405, 0.1382, 0.376, 0.419),
        "sol-happy": rect(0.2135, 0.1417, 0.371, 0.4208),
        "sol-sad": rect(0.214, 0.1382, 0.373, 0.4199),
        "sol-surprised": rect(0.215, 0.1356, 0.3705, 0.419),
        "theo-blush": rect(0.1516, 0.1797, 0.312, 0.4867),
        "theo-happy": rect(0.1531, 0.1781, 0.3115, 0.4844),
        "theo-sad": rect(0.1526, 0.2273, 0.3115, 0.4875),
        "theo-surprised": rect(0.1526, 0.1719, 0.3109, 0.4891),
        "vi-blush": rect(0.216, 0.1294, 0.363, 0.463),
        "vi-happy": rect(0.216, 0.1347, 0.366, 0.4648),
        "vi-sad": rect(0.216, 0.1373, 0.3675, 0.4648),
        "vi-surprised": rect(0.2135, 0.2183, 0.366, 0.4648),
        "wes-blush": rect(0.1615, 0.1593, 0.305, 0.3935),
        "wes-happy": rect(0.159, 0.1567, 0.311, 0.4049),
        "wes-sad": rect(0.1835, 0.1585, 0.3125, 0.4085),
        "wes-surprised": rect(0.1955, 0.1514, 0.3445, 0.4129),
    ]

    /// Most chat images are 2000 × 1136 (the dialog screen is laid out for that shape).
    static let aspect: CGFloat = 2000.0 / 1136.0

    private static func rect(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> CGRect {
        CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }

    static let all: [String: ChatLayout] = [
        "farmer-male": ChatLayout(tag: rect(0.1125, 0.7236, 0.25, 0.7711), box: rect(0.0925, 0.8046, 0.907, 0.9489), tagIsLight: false),
        "farmer-female-s0": ChatLayout(tag: rect(0.067, 0.7622, 0.2257, 0.816), box: rect(0.0094, 0.8403, 0.9901, 0.9826), tagIsLight: false),
        "farmer-female": ChatLayout(tag: rect(0.065, 0.7676, 0.2325, 0.8231), box: rect(0.0095, 0.8477, 0.99, 0.9824), tagIsLight: false),
        "kai": ChatLayout(tag: rect(0.155, 0.7262, 0.27, 0.7702), box: rect(0.1195, 0.7984, 0.877, 0.956), tagIsLight: true),
        "sol": ChatLayout(tag: rect(0.0675, 0.6761, 0.21, 0.7421), box: rect(0.047, 0.7667, 0.952, 0.9489), tagIsLight: false),
        "sol-pinafore": ChatLayout(tag: rect(0.105, 0.785, 0.35, 0.84), box: rect(0.11, 0.845, 0.9, 0.985), tagIsLight: true),
        "sol-overalls": ChatLayout(tag: rect(0.05, 0.79, 0.33, 0.855), box: rect(0.068, 0.865, 0.94, 0.985), tagIsLight: true),
        "june": ChatLayout(tag: rect(0.1525, 0.7042, 0.2975, 0.7526), box: rect(0.114, 0.7817, 0.888, 0.956), tagIsLight: true),
        "wes": ChatLayout(tag: rect(0.1525, 0.713, 0.29, 0.757), box: rect(0.12, 0.787, 0.8725, 0.9498), tagIsLight: true),
        "vi": ChatLayout(tag: rect(0.15, 0.6954, 0.29, 0.7526), box: rect(0.1135, 0.7773, 0.888, 0.9489), tagIsLight: true),
        "roz": ChatLayout(tag: rect(0.0645, 0.6771, 0.2183, 0.7465), box: rect(0.0347, 0.7535, 0.9673, 0.9809), tagIsLight: false),
        "bree": ChatLayout(tag: rect(0.1575, 0.7086, 0.29, 0.757), box: rect(0.1225, 0.7852, 0.8775, 0.9498), tagIsLight: false),
        "imani": ChatLayout(tag: rect(0.018, 0.733, 0.153, 0.787), box: rect(0.008, 0.758, 0.992, 0.968), tagIsLight: true),
        "shop": ChatLayout(tag: rect(0.105, 0.685, 0.295, 0.745), box: rect(0.105, 0.735, 0.895, 0.955), tagIsLight: true),
        "theo": ChatLayout(tag: rect(0.0911, 0.7641, 0.2552, 0.8109), box: rect(0.0781, 0.8125, 0.9245, 0.9648), tagIsLight: false),
        "farmer-female-s1-sundress": ChatLayout(tag: rect(0.0546, 0.7535, 0.2381, 0.8203), box: rect(0.0248, 0.8247, 0.9722, 0.9766), tagIsLight: false),
        "farmer-female-s2": ChatLayout(tag: rect(0.0546, 0.7535, 0.2381, 0.8203), box: rect(0.0248, 0.8247, 0.9722, 0.9766), tagIsLight: false),
        "farmer-male-s0": ChatLayout(tag: rect(0.0546, 0.7535, 0.2381, 0.8203), box: rect(0.0248, 0.8247, 0.9722, 0.9766), tagIsLight: false),
        "farmer-male-s2": ChatLayout(tag: rect(0.0546, 0.7535, 0.2381, 0.8203), box: rect(0.0248, 0.8247, 0.9722, 0.9766), tagIsLight: false),
        "farmer-male-s0-hoodie": ChatLayout(tag: rect(0.0546, 0.7535, 0.2381, 0.8203), box: rect(0.0248, 0.8247, 0.9722, 0.9766), tagIsLight: false),
        "farmer-male-s1-hoodie": ChatLayout(tag: rect(0.0546, 0.7535, 0.2381, 0.8203), box: rect(0.0248, 0.8247, 0.9722, 0.9766), tagIsLight: false),
        "farmer-male-s2-hoodie": ChatLayout(tag: rect(0.0546, 0.7535, 0.2381, 0.8203), box: rect(0.0248, 0.8247, 0.9722, 0.9766), tagIsLight: false),
        "rowan": ChatLayout(tag: rect(0.1414, 0.6901, 0.31, 0.7595), box: rect(0.1017, 0.7639, 0.8929, 0.9679), tagIsLight: true),
        "silas": ChatLayout(tag: rect(0.1414, 0.6901, 0.31, 0.7595), box: rect(0.1017, 0.7639, 0.8929, 0.9679), tagIsLight: true),
        "generic": ChatLayout(tag: rect(0.15, 0.6954, 0.29, 0.7526), box: rect(0.1135, 0.7773, 0.888, 0.9489), tagIsLight: true),
    ]
}

/// Whose chat scene to show.
enum ChatSpeaker {
    case person(Person)
    case farmer
    /// Story narration happens in the character's scene.
    case narrator(Person?)
}

/// The moving parts of a character's chat face, as fractions of their chat image: where the
/// eyes and the mouth are, which expressions can blink (eyes drawn open), and which already have
/// an open mouth (they close it when the line ends). Frames are `chat-<id>-<mood>-blink1/2`,
/// `chat-<id>-mouthopen` and `chat-<id>-mouthclosed`, cut from the character's own art.
struct ChatFaceParts {
    let eyes: CGRect
    let mouth: CGRect
    let blinks: Set<ChatMood>
    let openMouth: Set<ChatMood>

    private static func rect(_ x0: Double, _ y0: Double, _ x1: Double, _ y1: Double) -> CGRect {
        CGRect(x: x0, y: y0, width: x1 - x0, height: y1 - y0)
    }

    static let all: [String: ChatFaceParts] = [
        "june": ChatFaceParts(eyes: rect(0.2075, 0.191, 0.3115, 0.2518), mouth: rect(0.237, 0.2808, 0.276, 0.3415),
                     blinks: [.neutral, .sad, .surprised], openMouth: [.surprised, .happy]),
        "roz": ChatFaceParts(eyes: rect(0.191, 0.2821, 0.3199, 0.3429), mouth: rect(0.2282, 0.395, 0.2827, 0.4427),
                     blinks: [.neutral, .sad, .surprised, .blush], openMouth: [.surprised]),
        "theo": ChatFaceParts(eyes: rect(0.1604, 0.2711, 0.2953, 0.3203), mouth: rect(0.1938, 0.3781, 0.262, 0.4453),
                     blinks: [.neutral, .happy, .sad, .surprised, .blush], openMouth: [.surprised]),
        "kai": ChatFaceParts(eyes: rect(0.191, 0.2359, 0.2865, 0.2923), mouth: rect(0.204, 0.331, 0.2575, 0.4014),
                     blinks: [.neutral, .happy, .sad, .surprised, .blush], openMouth: [.surprised, .happy]),
        "sol": ChatFaceParts(eyes: rect(0.2495, 0.2306, 0.3515, 0.2923), mouth: rect(0.289, 0.3398, 0.3245, 0.4049),
                     blinks: [.neutral, .sad, .surprised, .blush], openMouth: [.surprised, .happy]),
        "wes": ChatFaceParts(eyes: rect(0.2015, 0.2077, 0.289, 0.2579), mouth: rect(0.223, 0.2984, 0.266, 0.3609),
                     blinks: [.neutral, .happy, .sad, .surprised, .blush], openMouth: [.surprised, .happy]),
        "bree": ChatFaceParts(eyes: rect(0.254, 0.2306, 0.3555, 0.3178), mouth: rect(0.2835, 0.3415, 0.323, 0.4023),
                     blinks: [.neutral, .sad, .surprised, .blush], openMouth: [.surprised, .happy]),
        "vi": ChatFaceParts(eyes: rect(0.2265, 0.2614, 0.3445, 0.3398), mouth: rect(0.2735, 0.3697, 0.3155, 0.441),
                     blinks: [.neutral, .happy, .sad, .surprised, .blush], openMouth: [.surprised, .happy]),
        "farmer-female": ChatFaceParts(eyes: rect(0.213, 0.272, 0.3405, 0.331), mouth: rect(0.2445, 0.3944, 0.3015, 0.4718),
                     blinks: [.neutral, .sad, .surprised, .blush], openMouth: [.surprised, .happy]),
        "farmer-male": ChatFaceParts(eyes: rect(0.445, 0.3107, 0.563, 0.3592), mouth: rect(0.4665, 0.3803, 0.5415, 0.4701),
                     blinks: [.neutral, .sad, .surprised, .blush], openMouth: [.surprised, .happy]),
        "farmer-female-s0": ChatFaceParts(eyes: rect(0.2133, 0.2821, 0.3348, 0.3559), mouth: rect(0.2331, 0.3993, 0.3026, 0.4688),
                     blinks: [.neutral, .sad, .surprised, .blush], openMouth: [.happy, .surprised]),
        "farmer-female-s1-sundress": ChatFaceParts(eyes: rect(0.2083, 0.3082, 0.3423, 0.3559), mouth: rect(0.2455, 0.4167, 0.3026, 0.4644),
                     blinks: [.neutral, .blush], openMouth: []),
        "farmer-female-s2": ChatFaceParts(eyes: rect(0.2034, 0.2821, 0.3472, 0.3559), mouth: rect(0.2257, 0.408, 0.2778, 0.4557),
                     blinks: [.neutral, .happy, .sad, .surprised, .blush], openMouth: [.surprised, .happy]),
        "farmer-male-s0": ChatFaceParts(eyes: rect(0.2083, 0.3142, 0.3299, 0.349), mouth: rect(0.2331, 0.408, 0.3026, 0.4688),
                     blinks: [.neutral, .happy, .sad, .surprised, .blush], openMouth: [.surprised, .happy]),
        "farmer-male-s2": ChatFaceParts(eyes: rect(0.2133, 0.276, 0.3423, 0.3316), mouth: rect(0.2331, 0.3733, 0.3075, 0.434),
                     blinks: [.neutral, .happy, .sad, .surprised, .blush], openMouth: [.surprised, .happy]),
        "farmer-male-s0-hoodie": ChatFaceParts(eyes: rect(0.2158, 0.3038, 0.3299, 0.349), mouth: rect(0.2331, 0.4167, 0.3026, 0.4774),
                     blinks: [.neutral, .happy, .sad, .surprised, .blush], openMouth: [.surprised, .happy]),
        "farmer-male-s1-hoodie": ChatFaceParts(eyes: rect(0.2133, 0.2847, 0.3323, 0.3229), mouth: rect(0.2331, 0.3819, 0.3026, 0.4427),
                     blinks: [.neutral], openMouth: []),
        "farmer-male-s2-hoodie": ChatFaceParts(eyes: rect(0.1984, 0.2951, 0.3423, 0.349), mouth: rect(0.2282, 0.4297, 0.3175, 0.4991),
                     blinks: [.neutral, .happy, .sad, .surprised, .blush], openMouth: [.surprised, .happy]),
        "silas": ChatFaceParts(eyes: rect(0.2059, 0.2031, 0.3051, 0.2431), mouth: rect(0.2292, 0.2899, 0.2867, 0.3385),
                     blinks: [.neutral, .sad, .surprised, .blush], openMouth: [.surprised, .happy]),
        "rowan": ChatFaceParts(eyes: rect(0.1895, 0.2483, 0.3051, 0.2891), mouth: rect(0.2207, 0.3472, 0.2902, 0.3906),
                     blinks: [.neutral, .happy, .sad, .surprised, .blush], openMouth: [.surprised, .happy]),
    ]

    /// Talk blip pitch per speaker (1 is the recorded pitch).
    static let blipPitch: [String: Float] = [
        "june": 1.15, "roz": 1.3, "theo": 0.8, "kai": 0.95, "sol": 1.05,
        "wes": 0.7, "bree": 1.4, "vi": 1.1, "rowan": 0.75, "silas": 0.85, "farmer": 1.0, "narrator": 0.9,
    ]

    private static var loggedMissing: Set<String> = []

    /// A frame, or `nil` (logged once) when it's missing: the static face shows instead.
    /// Your farmer's frames are recolored for your look (each has a `-labels` map).
    static func frame(_ name: String, look: FarmerLook? = nil) -> UIImage? {
        if let look, let image = FarmerRenderer.image(named: name, look: look) { return image }
        if let image = UIImage(named: name) { return image }
        if !loggedMissing.contains(name) {
            loggedMissing.insert(name)
            artLog.notice("Missing face frame \(name, privacy: .public); showing the still face")
        }
        return nil
    }
}

/// A character's chat screen: their night-meadow scene with a pixel text box, like a
/// dialog in a cozy RPG. Characters without their own chat image (and custom farmer looks)
/// are placed over a shared meadow scene using their portrait art.
struct ChatScene: View {
    let meadow: Meadow
    let speaker: ChatSpeaker
    let name: String?
    let text: String
    var isItalic = false
    /// Shows a blinking ▼ for "tap to continue".
    var showsMore = false
    /// Picks between identical recordings, like `BESTIE` over `ROMANCE` (see `VoiceLines.clips`).
    var voiceHint: String?
    /// More clips to say after this line, like the question that follows it.
    var voiceAfter: [String] = []
    /// Show a different chat image than the speaker's own (the shop counter's market scene).
    var artOverrideID: String? = nil
    /// False to type the line out with no voice or blips (a date scene says it over its video).
    var speaksAloud = true
    /// The portrait slides in a little from the left when the window opens.
    @State private var bustIn = false
    @State private var voiceToken: Int?
    /// How many letters have typed out so far.
    @State private var typed = Int.max
    /// When the speaker's own mouth moves: their voice clips (not the narrator's), or the typing.
    @State private var talkTimes: [ClosedRange<Date>] = []

    /// The chat buttons: pause the line, skip to its end, say it again, and mute voices.
    @State private var chatPaused = false
    @State private var pausedAt: Date?
    @State private var replayCount = 0
    @State private var skipLine = false
    @AppStorage("voicesMuted") private var voicesMuted = false

    private var voiceKey: String {
        "\(VoiceLines.owner(of: speaker))|\(text)|\(voiceAfter.joined(separator: ","))|\(replayCount)"
    }

    private struct Art {
        let background: UIImage
        let layout: ChatLayout
        /// Portrait art to place over the shared scene.
        let bust: UIImage?
        /// An expression face over the scene, and where it goes (fractions of the image).
        var face: UIImage?
        var faceBox: CGRect?
        /// The chat image's id, for its blinking eyes and talking mouth.
        var animID: String?
        /// Your farmer's look, when this is one of the farmer's drawn scenes: everything on it
        /// is recolored to match.
        var look: FarmerLook?
    }

    /// The speaker's expression for this line. Narration keeps their usual face.
    private var mood: ChatMood {
        if case .narrator = speaker { return .neutral }
        return ChatMood.of(text)
    }

    /// Chat scenes drawn for a farmer look (gender, hairstyle and outfit cut). They're recolored
    /// for your skin, hair, eyes and jacket colors.
    private static let drawnChatArt = [
        "female0": "farmer-female-s0", "female1": "farmer-female", "female1-sundress": "farmer-female-s1-sundress",
        "female2": "farmer-female-s2",
        "male0": "farmer-male-s0", "male1": "farmer-male", "male2": "farmer-male-s2",
        "male0-hoodie": "farmer-male-s0-hoodie", "male1-hoodie": "farmer-male-s1-hoodie", "male2-hoodie": "farmer-male-s2-hoodie",
    ]

    private var art: Art? {
        func own(_ id: String, look: FarmerLook? = nil) -> Art? {
            guard let image = ChatFaceParts.frame("chat-\(id)", look: look), let layout = ChatLayout.all[id] else { return nil }
            var art = Art(background: image, layout: layout, bust: nil)
            art.animID = id
            art.look = look
            if mood != .neutral, let box = ChatLayout.faces["\(id)-\(mood.rawValue)"] {
                art.face = ChatFaceParts.frame("chat-\(id)-\(mood.rawValue)", look: look)
                art.faceBox = box
            }
            return art
        }
        /// Their portrait, with this line's expression when there's one.
        func portrait(_ id: String) -> UIImage? {
            if mood != .neutral, let face = UIImage(named: "person-\(id)-\(mood.rawValue)") { return face }
            return PersonArt.image(for: id)
        }
        func shared(_ bust: UIImage?) -> Art? {
            guard let image = UIImage(named: "chat-generic"), let layout = ChatLayout.all["generic"] else { return nil }
            return Art(background: image, layout: layout, bust: bust)
        }
        if let artOverrideID, let override = own(artOverrideID) { return override }
        switch speaker {
        case .person(let person):
            // Today's outfit has its own chat scene for some people (Sol); otherwise their usual one.
            let outfit = person.spriteID(onDay: meadow.today)
            return (outfit == person.id ? nil : own(outfit)) ?? own(person.id) ?? shared(portrait(person.id))
        case .narrator(let person):
            guard let person else { return shared(nil) }
            return own(person.id) ?? shared(PersonArt.image(for: person.id))
        case .farmer:
            // Your look's drawn chat scene, recolored to your choices; looks without one use
            // your own portrait.
            if let look = meadow.farmerLook, let cut = Outfit.find(look.outfit)?.cut,
               let drawn = Self.drawnChatArt[look.gender.rawValue + "\(look.hairStyle)" + (cut == .jacket ? "" : "-\(cut.rawValue)")],
               let art = own(drawn, look: look) {
                return art
            }
            // Trimmed first: some portraits have empty space above the head, which would push
            // the farmer down behind the text box.
            guard let id = meadow.farmerArtID(), let portrait = PersonArt.image(for: id) else { return shared(nil) }
            return shared(ArtTrim.trimmed(portrait, key: "\(id)|chat"))
        }
    }

    var body: some View {
        GeometryReader { geo in
            if let art {
                let fit = fitted(in: geo.size, aspect: art.background.size.width / max(art.background.size.height, 1))
                ZStack {
                    Image(uiImage: art.background)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geo.size.width, height: geo.size.height)
                        .blur(radius: 16)
                        .overlay(Palette.night.opacity(0.35))
                        .clipped()
                    scene(art, size: fit)
                        .frame(width: fit.width, height: fit.height)
                        .overlay(alignment: .topTrailing) { chatControls(size: fit.height) }
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
        }
        .accessibilityElement(children: .combine)
        .onAppear {
            withAnimation(.easeOut(duration: 0.35)) { bustIn = true }
        }
        // Each line is said once as it appears and types out letter by letter: in time with the
        // voice clip when there is one, otherwise at a steady pace with a little blip per letter.
        // Moving on stops it and starts the next line.
        .task(id: voiceKey) {
            let owner = VoiceLines.owner(of: speaker)
            chatPaused = false
            pausedAt = nil
            skipLine = false
            // Muted, the line just types out (no voice, no blips) with the mouth moving along.
            let clips = voicesMuted || !speaksAloud ? [] : VoiceLines.clips(owner: owner, text: text, prefer: voiceHint, farmer: meadow.farmerGender)
            let lengths = MusicPlayer.shared.clipSeconds(clips)
            let spoken = lengths.reduce(0, +) + MusicPlayer.clipGap * Double(max(clips.count - 1, 0))
            if speaksAloud {
                voiceToken = MusicPlayer.shared.speak(voicesMuted ? [] : clips + voiceAfter)
            }
            let letters = Array(text)
            let perLetter = spoken > 0 ? min(spoken / Double(max(letters.count, 1)), 0.08) : 0.032
            // The mouth only moves for the speaker's own words: the narrator's clips (ending -N)
            // and narration lines leave it closed.
            let now = Date()
            var windows: [ClosedRange<Date>] = []
            if case .narrator = speaker {
            } else if clips.isEmpty {
                windows = [now...now.addingTimeInterval(perLetter * Double(letters.count))]
            } else {
                var at = 0.0
                for (clip, length) in zip(clips, lengths) {
                    if !clip.hasSuffix("-N") {
                        windows.append(now.addingTimeInterval(at)...now.addingTimeInterval(at + length))
                    }
                    at += length + MusicPlayer.clipGap
                }
            }
            talkTimes = windows
            typed = 0
            var index = 0
            while index < letters.count {
                try? await Task.sleep(for: .seconds(perLetter))
                if Task.isCancelled { return }
                if skipLine { break }
                // The pause menu and the chat's pause button hold the typing and the mouth.
                if meadow.isPaused || chatPaused { continue }
                index += 1
                typed = index
                if spoken == 0, !voicesMuted, speaksAloud, index % 2 == 0, !letters[index - 1].isWhitespace {
                    MusicPlayer.shared.playBlip(pitch: ChatFaceParts.blipPitch[owner] ?? 1)
                }
            }
            typed = Int.max
        }
        .onDisappear { if speaksAloud { MusicPlayer.shared.stopVoice(token: voiceToken) } }
    }

    /// Pause / play, skip to the end of the line, replay it, and mute voices.
    private func chatControls(size: CGFloat) -> some View {
        let side = max(28, size * 0.075)
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
        return HStack(spacing: side * 0.2) {
            control(chatPaused ? "play.fill" : "pause.fill", chatPaused ? "Resume" : "Pause") { togglePause() }
            control("forward.end.fill", "Skip to the end of the line") { skipToEnd() }
            control("arrow.counterclockwise", "Replay the line") { replayCount += 1 }
            control(voicesMuted ? "speaker.slash.fill" : "speaker.wave.2.fill", voicesMuted ? "Unmute voices" : "Mute voices") {
                voicesMuted.toggle()
                if voicesMuted { MusicPlayer.shared.stopVoice(token: voiceToken) }
            }
        }
        .padding(side * 0.3)
    }

    private func togglePause() {
        if chatPaused {
            // Pick up where it stopped: the mouth's timing moves later by the time spent paused.
            let held = pausedAt.map { Date().timeIntervalSince($0) } ?? 0
            talkTimes = talkTimes.map { $0.lowerBound.addingTimeInterval(held)...$0.upperBound.addingTimeInterval(held) }
            MusicPlayer.shared.resumeVoice(token: voiceToken)
            chatPaused = false
        } else {
            pausedAt = Date()
            MusicPlayer.shared.pauseVoice(token: voiceToken)
            chatPaused = true
        }
    }

    private func skipToEnd() {
        skipLine = true
        chatPaused = false
        typed = Int.max
        talkTimes = []
        MusicPlayer.shared.stopVoice(token: voiceToken)
    }

    /// The scene at its own shape (most are 2000 × 1136; Theo's is 3:2), as big as fits.
    private func fitted(in size: CGSize, aspect: CGFloat) -> CGSize {
        let width = min(size.width, size.height * aspect)
        return CGSize(width: width, height: width / aspect)
    }

    /// The line with the letters not typed yet still there but invisible, so the words don't
    /// jump around as they appear.
    private var typedText: AttributedString {
        var shown = AttributedString(String(text.prefix(typed)))
        if typed < text.count {
            var rest = AttributedString(String(text.dropFirst(typed)))
            rest.foregroundColor = .clear
            shown += rest
        }
        return shown
    }

    /// Blinking (every few seconds, on each character's own rhythm) and the mouth opening and
    /// closing while they talk, then resting closed. Stops while the game is paused.
    /// A blink or a moving mouth, crossfaded so faces glide instead of popping
    /// between frames (Michelle, 2026-10-30: the old swaps looked choppy).
    private func faceMotion(id: String, parts: ChatFaceParts, look: FarmerLook?, w: CGFloat, h: CGFloat) -> some View {
        let seed = Double(id.unicodeScalars.reduce(0) { ($0 * 31 + Int($1.value)) % 997 })
        let period = 3.4 + seed.truncatingRemainder(dividingBy: 13) / 10
        return TimelineView(.animation(minimumInterval: 1 / 30, paused: meadow.isPaused)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            // The blink as one smooth eyelid sweep: the half-closed frame fades in,
            // the closed frame peaks at the bottom of the sweep, then both fade out.
            let phase = (t + seed).truncatingRemainder(dividingBy: period)
            let blinkAmount: Double = if !parts.blinks.contains(mood) || phase > 0.24 {
                0
            } else {
                sin(.pi * phase / 0.24)
            }
            let halfLid = min(blinkAmount * 1.7, 1) * (1 - smoothstep(0.55, 0.85, blinkAmount))
            let fullLid = smoothstep(0.55, 0.85, blinkAmount)
            // Talking is a smooth open-close wave that rests between phrases;
            // the mouth frame crossfades with it, so it never snaps.
            let talking = !chatPaused && talkTimes.contains { $0.contains(timeline.date) }
            let phrase = smoothstep(0.25, 0.75, 0.5 + 0.5 * sin(t * 2 * .pi * 0.45 + seed * 2))
            let syllable = 0.5 + 0.5 * sin(t * 2 * .pi * 3.1 + seed)
            let openness = talking ? phrase * (0.25 + 0.75 * syllable) : 0.0
            ZStack(alignment: .topLeading) {
                if blinkAmount > 0.01, parts.blinks.contains(mood) {
                    if halfLid > 0.01, let eyes = ChatFaceParts.frame("chat-\(id)-\(mood.rawValue)-blink1", look: look) {
                        Image(uiImage: eyes)
                            .resizable()
                            .frame(width: parts.eyes.width * w, height: parts.eyes.height * h)
                            .offset(x: parts.eyes.minX * w, y: parts.eyes.minY * h)
                            .opacity(halfLid)
                    }
                    if fullLid > 0.01, let eyes = ChatFaceParts.frame("chat-\(id)-\(mood.rawValue)-blink2", look: look) {
                        Image(uiImage: eyes)
                            .resizable()
                            .frame(width: parts.eyes.width * w, height: parts.eyes.height * h)
                            .offset(x: parts.eyes.minX * w, y: parts.eyes.minY * h)
                            .opacity(fullLid)
                    }
                }
                // Whichever mouth frame differs from the face's own mouth
                // crossfades in and out with `openness`. With a half-open frame
                // (`chat-<id>-mouthhalf`), the mouth eases through it on the way:
                // closed → half → open and back, so talking reads smoothly.
                let half = ChatFaceParts.frame("chat-\(id)-mouthhalf", look: look)
                let rest = parts.openMouth.contains(mood) ? 1 - openness : openness
                let halfAmount = half == nil ? 0 : max(0, 1 - abs(rest - 0.5) * 2)
                let fullAmount = half == nil ? rest : smoothstep(0.5, 1, rest)
                if let half, halfAmount > 0.01 {
                    Image(uiImage: half)
                        .resizable()
                        .frame(width: parts.mouth.width * w, height: parts.mouth.height * h)
                        .offset(x: parts.mouth.minX * w, y: parts.mouth.minY * h)
                        .opacity(halfAmount)
                }
                if parts.openMouth.contains(mood) {
                    if fullAmount > 0.01, let image = ChatFaceParts.frame("chat-\(id)-mouthclosed", look: look) {
                        Image(uiImage: image)
                            .resizable()
                            .frame(width: parts.mouth.width * w, height: parts.mouth.height * h)
                            .offset(x: parts.mouth.minX * w, y: parts.mouth.minY * h)
                            .opacity(fullAmount)
                    }
                } else if fullAmount > 0.01, let image = ChatFaceParts.frame("chat-\(id)-mouthopen", look: look) {
                    Image(uiImage: image)
                        .resizable()
                        .frame(width: parts.mouth.width * w, height: parts.mouth.height * h)
                        .offset(x: parts.mouth.minX * w, y: parts.mouth.minY * h)
                        .opacity(fullAmount)
                }
            }
            .frame(width: w, height: h, alignment: .topLeading)
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private func smoothstep(_ edge0: Double, _ edge1: Double, _ x: Double) -> Double {
        let t = min(max((x - edge0) / (edge1 - edge0), 0), 1)
        return t * t * (3 - 2 * t)
    }

    private func scene(_ art: Art, size: CGSize) -> some View {
        let w = size.width, h = size.height
        let layout = art.layout
        let tagFrame = CGRect(x: layout.tag.minX * w, y: layout.tag.minY * h, width: layout.tag.width * w, height: layout.tag.height * h)
        let boxFrame = CGRect(x: layout.box.minX * w, y: layout.box.minY * h, width: layout.box.width * w, height: layout.box.height * h)

        return ZStack(alignment: .topLeading) {
            Image(uiImage: art.background)
                .resizable()
                .frame(width: w, height: h)

            if let face = art.face, let box = art.faceBox {
                Image(uiImage: face)
                    .resizable()
                    .frame(width: box.width * w, height: box.height * h)
                    .offset(x: box.minX * w, y: box.minY * h)
                    .transition(.opacity)
                    .accessibilityHidden(true)
            }

            if let id = art.animID, let parts = ChatFaceParts.all[id] {
                faceMotion(id: id, parts: parts, look: art.look, w: w, h: h)
            }

            if let bust = art.bust {
                // Head and shoulders, standing just behind the text box.
                let visible = h * 0.74
                let full = visible / 0.38
                let width = full * bust.size.width / max(bust.size.height, 1)
                Image(uiImage: bust)
                    .resizable()
                    .frame(width: width, height: full)
                    .frame(width: width, height: visible, alignment: .top)
                    .clipped()
                    .offset(x: w * 0.3 - width / 2 - (bustIn ? 0 : w * 0.06), y: h * 0.04)
                    .opacity(bustIn ? 1 : 0)
                    .accessibilityHidden(true)
                // Put the name tag back in front of the portrait.
                Image(uiImage: art.background)
                    .resizable()
                    .frame(width: w, height: h)
                    .mask(alignment: .topLeading) {
                        Rectangle()
                            .frame(width: tagFrame.width + w * 0.065, height: boxFrame.minY - tagFrame.minY + h * 0.02)
                            .offset(x: tagFrame.minX - w * 0.055, y: tagFrame.minY - h * 0.02)
                    }
            }

            if let name {
                Text(name)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(layout.tagIsLight ? Palette.ink : .white)
                    .shadow(color: layout.tagIsLight ? .white.opacity(0.6) : .black.opacity(0.7), radius: 0, x: 1, y: 1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .frame(width: tagFrame.width * 0.86, height: tagFrame.height)
                    .offset(x: tagFrame.minX + tagFrame.width * 0.07, y: tagFrame.minY)
            }

            Text(typedText)
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .italic(isItalic)
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.75), radius: 0, x: 2, y: 2)
                .lineSpacing(h * 0.008)
                .minimumScaleFactor(0.7)
                .frame(width: boxFrame.width * 0.92, height: boxFrame.height * 0.86, alignment: .topLeading)
                .offset(x: boxFrame.minX + boxFrame.width * 0.035, y: boxFrame.minY + boxFrame.height * 0.1)
                .id(text)
                .transition(.opacity)

            if showsMore {
                TimelineView(.periodic(from: .now, by: 0.5)) { timeline in
                    let on = Int(timeline.date.timeIntervalSinceReferenceDate * 2) % 2 == 0
                    Text("▼")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(.white.opacity(on ? 1 : 0.3))
                }
                .offset(x: boxFrame.maxX - h * 0.06, y: boxFrame.maxY - h * 0.06)
            }
        }
        .frame(width: w, height: h, alignment: .topLeading)
    }
}

/// A full-screen conversation laid out like the rest of the game: the chat scene on top,
/// and the buttons (choices, continue) on the panel below the fold.
struct ChatDialogScreen<Scene: View, Controls: View>: View {
    var onTapScene: (() -> Void)?
    @State private var isShown = false
    @ViewBuilder let scene: () -> Scene
    @ViewBuilder let controls: () -> Controls

    var body: some View {
        GeometryReader { geo in
            // Tall screens (the Duo folded like a laptop, or a portrait iPad) split at the fold.
            let split = geo.size.height > geo.size.width * 0.75
            let gap: CGFloat = split ? 40 : 0
            let sceneHeight = split ? (geo.size.height - gap) / 2 : min(geo.size.width / ChatLayout.aspect, geo.size.height * 0.62)

            VStack(spacing: gap) {
                scene()
                    .frame(height: sceneHeight)
                    .clipShape(.rect(cornerRadius: split ? 24 : 0))
                    .contentShape(.rect)
                    .onTapGesture { onTapScene?() }

                ScrollView {
                    VStack(spacing: 10) {
                        controls()
                    }
                    .frame(maxWidth: 620)
                    .padding(16)
                    .frame(maxWidth: .infinity)
                }
                .scrollIndicators(.hidden)
                .background {
                    if let paper = WorldArt.panel {
                        Image(uiImage: paper).resizable().scaledToFill()
                    } else {
                        Palette.cream
                    }
                }
                .clipShape(.rect(cornerRadius: split ? 24 : 0))
            }
            .padding(split ? 12 : 0)
        }
        .background(Palette.night.ignoresSafeArea())
        .foregroundStyle(Palette.ink)
        .fontDesign(.rounded)
        // Chat windows fade in.
        .opacity(isShown ? 1 : 0)
        .onAppear {
            withAnimation(.easeOut(duration: 0.25)) { isShown = true }
        }
    }
}

/// A big pixel-bordered button for dialog panels.
struct DialogButton: View {
    let label: String
    var pink = true
    var isEnabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 10)
                .pixelPanel(pink ? Palette.pinkCard : Palette.periwinkle, edge: pink ? Palette.pinkEdge : Palette.periwinkleEdge,
                            cornerRadius: 16)
        }
        .buttonStyle(SquishButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }
}

// MARK: - Story chapters

private struct StoryPlayer: View {
    let meadow: Meadow
    let event: StoryEvent
    let close: () -> Void
    @State private var lineIndex = 0
    @State private var chosen: Int?

    private var person: Person? { Person.find(event.personID) }
    private var isReplay: Bool { meadow.relationship(event.personID).seenEvents.contains(event.id) }

    var body: some View {
        let finishedLines = lineIndex >= event.lines.count - 1
        let line = event.lines[min(lineIndex, event.lines.count - 1)]
        let response = chosen.flatMap { index in finishedLines ? event.choice?.options[index].response : nil }
        let speaker: StoryLine.Speaker = response != nil ? .person : line.speaker
        let asks = finishedLines && chosen == nil && !isReplay ? event.choice : nil
        let promptVoice = asks.map { VoiceLines.clips(owner: event.personID, text: $0.prompt) } ?? []

        ChatDialogScreen(onTapScene: advance) {
            ChatScene(meadow: meadow, speaker: chatSpeaker(speaker), name: name(for: speaker),
                      text: response ?? line.text, isItalic: response == nil && speaker == .narrator,
                      showsMore: !finishedLines, voiceAfter: promptVoice)
                .animation(.easeInOut(duration: 0.25), value: lineIndex)
        } controls: {
            Text("\(event.title) · \(event.stage.title(path: meadow.relationship(event.personID).path))")
                .font(.caption.bold())
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .pixelPanel(Palette.periwinkle, edge: Palette.periwinkleEdge, cornerRadius: 12)

            if !finishedLines {
                DialogButton(label: "Continue ▸", action: advance)
                Text("Tap the scene or Continue to keep talking.").font(.caption2).opacity(0.7)
            } else if let choice = event.choice, chosen == nil, !isReplay {
                Text(choice.prompt).font(.subheadline.bold())
                ForEach(Array(choice.options.enumerated()), id: \.offset) { index, option in
                    DialogButton(label: option.text, pink: option.setsPath == .romance) {
                        // You say your choice, then they answer.
                        MusicPlayer.shared.voiceLeadIn = VoiceLines.clips(owner: "farmer", text: option.text,
                                                                          farmer: meadow.farmerGender)
                        withAnimation { chosen = index }
                    }
                }
                if event.isCrossroads {
                    Text("You can change your mind later from their profile.").font(.caption2).opacity(0.7)
                }
            } else {
                if !isReplay && !event.rewards.isEmpty {
                    RewardList(rewards: event.rewards)
                }
                DialogButton(label: isReplay ? "Close" : "💕 Treasure this memory") {
                    if !isReplay {
                        meadow.completeEvent(event.id, choice: chosen)
                    }
                    close()
                }
            }
        }
    }

    private func advance() {
        if lineIndex < event.lines.count - 1 {
            withAnimation { lineIndex += 1 }
        }
    }

    private func chatSpeaker(_ speaker: StoryLine.Speaker) -> ChatSpeaker {
        switch speaker {
        case .you: return .farmer
        case .person: return person.map { ChatSpeaker.person($0) } ?? ChatSpeaker.narrator(nil)
        case .narrator: return .narrator(person)
        }
    }

    private func name(for speaker: StoryLine.Speaker) -> String? {
        switch speaker {
        case .narrator: return "✦"
        case .person: return person?.name
        case .you: return "You"
        }
    }
}

// MARK: - Moments

private struct MomentView: View {
    let meadow: Meadow
    let moment: Moment
    let close: () -> Void

    var body: some View {
        if let video = moment.video, DateSceneView.url(for: video) != nil {
            DateSceneView(meadow: meadow, moment: moment, video: video, close: close)
        } else {
            chat
        }
    }

    private var chat: some View {
        let person = Person.find(moment.personID)

        return ChatDialogScreen {
            ChatScene(meadow: meadow, speaker: person.map { ChatSpeaker.person($0) } ?? ChatSpeaker.narrator(nil),
                      name: person?.name, text: moment.text)
        } controls: {
            Text(moment.title).font(.headline)
            if let person {
                Text("💗 \(meadow.stageTitle(of: person.id))").font(.subheadline.bold())
            }
            DialogButton(label: "💕 Aww", action: close)
        }
    }
}

// MARK: - Bedtime

/// The end of the day: your farmer says goodnight, and you go to bed.
struct BedtimeView: View {
    let meadow: Meadow

    private static let lines = [
        "Whew… what a day. The bunnies are all tucked in, so I should be too.",
        "The moon's up and my boots are muddy. Time for bed. Tomorrow's crops won't plant themselves!",
        "I can barely keep my eyes open. Goodnight, meadow. Goodnight, bunnies.",
        "Another cozy day in the books. Bed sounds perfect right now.",
        "The fireflies are out. That means it's way past my bedtime…",
        "I think I hear the bunnies snoring. Okay, I'm going, I'm going. Night!",
    ]

    var body: some View {
        let line = Self.lines[((meadow.dayNumber % Self.lines.count) + Self.lines.count) % Self.lines.count]

        ChatDialogScreen {
            ChatScene(meadow: meadow, speaker: .farmer, name: "You", text: line)
        } controls: {
            Text("🌙 Day \(meadow.dayCount) is over").font(.headline)
            Text("Your crops keep growing overnight, and everyone's ready to chat again tomorrow.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .opacity(0.8)
            DialogButton(label: "💤 Go to sleep") {
                withAnimation(.easeInOut(duration: 0.8)) { meadow.goToBed() }
            }
        }
        .transition(.opacity)
    }
}

// MARK: - Collection finale

private struct CompletionView: View {
    let meadow: Meadow
    let close: () -> Void

    var body: some View {
        ZStack {
            LinearGradient(colors: [Palette.night, Palette.lilac, Palette.petal], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
            TimelineView(.animation(minimumInterval: 1 / 24)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                GeometryReader { proxy in
                    ForEach(Array(Breed.all.enumerated()), id: \.element.id) { index, breed in
                        let lane = Double(index % 5)
                        let x = (t * 30 + Double(index) * 60).truncatingRemainder(dividingBy: proxy.size.width + 120) - 60
                        BreedBunnyView(breed: breed, size: 44, time: t, phase: Double(index))
                            .position(x: x, y: proxy.size.height * (0.55 + 0.08 * lane))
                    }
                }
            }
            VStack(spacing: 14) {
                Text("🌕").font(.system(size: 60))
                Text("Every Bunny in Moonlit Meadows")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                Text(Self.scene)
                    .multilineTextAlignment(.center)
                    .padding(16)
                    .background(Color.white.opacity(0.85), in: .rect(cornerRadius: 20))
                Text(Self.solLine)
                    .font(.callout.italic())
                    .multilineTextAlignment(.center)
                Spacer()
                PriceButton(label: "👑 Wear the Moonlit Crown", isEnabled: true, action: close)
            }
            .padding(24)
            .foregroundStyle(Palette.cocoa)
            .fontDesign(.rounded)
        }
        .onAppear {
            MusicPlayer.shared.speak(VoiceLines.clips(owner: "narrator", text: Self.scene)
                                     + VoiceLines.clips(owner: "sol", text: Self.solLine))
        }
        .onDisappear { MusicPlayer.shared.stopVoice() }
    }

    private static let scene = "Under the full moon, all fifty breeds gather in the meadow. June, Roz, Theo, Kai, and Sol come out to watch. Seraph and Angel bow to you, Galaxy fills the sky with stars, and the bunnies weave you a crown of moonlight."
    private static let solLine = "“You found every one of them,” Sol whispers. “I'm writing a song about this.”"
}

// MARK: - Hearts

private struct FloatingHearts: View {
    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { proxy in
                ForEach(0..<14, id: \.self) { index in
                    let cycle = (t * 0.08 + hash01(index, 3)).truncatingRemainder(dividingBy: 1)
                    Text(index % 3 == 0 ? "💕" : "🤍")
                        .font(.system(size: 14 + 10 * hash01(index, 4)))
                        .position(x: proxy.size.width * hash01(index, 5) + sin(t + Double(index)) * 12,
                                  y: proxy.size.height * (1.05 - cycle * 1.1))
                        .opacity(0.5)
                }
            }
        }
        .allowsHitTesting(false)
        .ignoresSafeArea()
    }
}

// MARK: - Discovery

/// The bunny-discovery celebration shown after greeting a visitor.
struct DiscoveryOverlay: View {
    let outcome: VisitOutcome
    let dismiss: () -> Void
    @State private var appeared = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: dismiss)

            VStack(spacing: 12) {
                Text(outcome.isNewDiscovery ? "✨ New breed discovered! ✨" : "A familiar friend visited!")
                    .font(.title3.bold())
                ZStack {
                    TimelineView(.animation(minimumInterval: 1 / 24)) { timeline in
                        let t = timeline.date.timeIntervalSinceReferenceDate
                        ZStack {
                            if outcome.isNewDiscovery {
                                ForEach(0..<12, id: \.self) { index in
                                    let angle = Double(index) / 12 * 2 * .pi + t * 0.5
                                    Text(index % 2 == 0 ? "✨" : "🌸")
                                        .font(.system(size: 18))
                                        .offset(x: cos(angle) * (appeared ? 95 : 10), y: sin(angle) * (appeared ? 80 : 10))
                                        .opacity(appeared ? 1 : 0)
                                }
                            }
                            BreedBunnyView(breed: outcome.breed, size: 130, time: t)
                        }
                    }
                }
                .frame(height: 190)
                .scaleEffect(appeared ? 1 : 0.3)

                Text(outcome.breed.name).font(.title2.bold())
                RarityTag(rarity: outcome.breed.rarity, height: 18)
                if outcome.isNewDiscovery {
                    Text(outcome.breed.description)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                }
                if let adopted = outcome.adopted {
                    Text("\(adopted.name) joined your habitat! 🏡").font(.subheadline.bold())
                } else {
                    Text("Your habitat is full, so they left a thank-you gift instead. Expand it in the Shop!")
                        .font(.caption)
                        .multilineTextAlignment(.center)
                }
                RewardList(rewards: outcome.rewards)
                let fans = outcome.breed.favoredBy.compactMap(Person.find).map(\.name)
                if outcome.isNewDiscovery && !fans.isEmpty {
                    Text("💡 Someone in the village might adore this breed…")
                        .font(.caption)
                        .opacity(0.8)
                }
                PriceButton(label: outcome.isNewDiscovery ? "Add to collection 📖" : "Yay! 💕", isEnabled: true, action: dismiss)
            }
            .padding(24)
            .frame(maxWidth: 420)
            .background(Palette.cream, in: .rect(cornerRadius: 28))
            .shadow(color: Color(outcome.breed.rarity.color), radius: 30)
            .padding(24)
            .foregroundStyle(Palette.cocoa)
            .fontDesign(.rounded)
        }
        .onAppear {
            withAnimation(.spring(duration: 0.7, bounce: 0.5)) {
                appeared = true
            }
        }
    }
}
