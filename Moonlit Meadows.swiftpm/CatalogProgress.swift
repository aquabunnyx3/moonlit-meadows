import Foundation

/// Something the player can earn. Granting a reward twice never duplicates unlockables.
enum Reward {
    case coins(Int)
    case gems(Int)
    case xp(Int)
    case items(String, Int)
    case decor(String)
    case outfit(String)
    case accessory(String)
    case keepsake(String)
    case recipe(String)
    /// Reveals a breed's lure in the collection book before you reach its level.
    case hint(String)
    case habitatSpace(Int)
    case lureSlot

    var label: String {
        switch self {
        case .coins(let amount): return "🪙 \(amount.cozy)"
        case .gems(let amount): return "💎 \(amount)"
        case .xp(let amount): return "⭐️ \(amount) XP"
        case .items(let id, let count): return "\(ItemInfo.emoji(id)) ×\(count)"
        case .decor(let id): return "\(Decor.find(id)?.emoji ?? "🎀") \(Decor.find(id)?.name ?? "Decoration")"
        case .outfit(let id): return "\(Outfit.find(id)?.emoji ?? "👗") \(Outfit.find(id)?.name ?? "Outfit")"
        case .accessory(let id): return "\(BunnyAccessory.find(id)?.emoji ?? "🎀") \(BunnyAccessory.find(id)?.name ?? "Bunny accessory")"
        case .keepsake(let id): return "\(Keepsake.find(id)?.emoji ?? "💝") \(Keepsake.find(id)?.name ?? "Keepsake")"
        case .recipe(let id): return "\(ItemInfo.emoji(id)) Recipe: \(ItemInfo.name(id))"
        case .hint(let id): return "🔍 Clue: \(Breed.find(id)?.name ?? "a mystery bunny")"
        case .habitatSpace(let count): return "🏡 +\(count) habitat space"
        case .lureSlot: return "🧺 Extra lure basket"
        }
    }
}

/// A point in the world, in unit coordinates (`0...1` on both axes).
struct Spot: Equatable, Codable {
    let x: Double
    let y: Double
}

// MARK: - Decor

/// A decoration that appears in the village and makes everything sell for more.
struct Decor: Identifiable {
    enum Currency {
        case coins
        case gems
    }

    let id: String
    let name: String
    let emoji: String
    let unlockLevel: Int
    /// `0` for decorations that can only be earned.
    let price: Int
    let currency: Currency
    /// Percent added to every sale price.
    let coziness: Int
    let spot: Spot
    /// Size relative to the world's height.
    let scale: Double
    /// Where earned-only decor comes from, for the shop listing.
    var earnedFrom: String?

    var isShopItem: Bool { earnedFrom == nil }

    static func find(_ id: String) -> Decor? {
        all.first { $0.id == id }
    }

    static let all: [Decor] = [
        // Shop decor
        Decor(id: "flowers", name: "Tulip Bed", emoji: "🌷", unlockLevel: 1, price: 40, currency: .coins, coziness: 5, spot: Spot(x: 0.578, y: 0.36), scale: 0.07),
        Decor(id: "mushrooms", name: "Mushroom Ring", emoji: "🍄", unlockLevel: 2, price: 120, currency: .coins, coziness: 5, spot: Spot(x: 0.14, y: 0.77), scale: 0.06),
        Decor(id: "lantern", name: "Lantern Post", emoji: "🏮", unlockLevel: 3, price: 300, currency: .coins, coziness: 8, spot: Spot(x: 0.487, y: 0.545), scale: 0.08),
        Decor(id: "bench", name: "Picnic Basket", emoji: "🧺", unlockLevel: 4, price: 650, currency: .coins, coziness: 8, spot: Spot(x: 0.775, y: 0.50), scale: 0.07),
        Decor(id: "fountain", name: "Wishing Fountain", emoji: "⛲", unlockLevel: 5, price: 1_500, currency: .coins, coziness: 12, spot: Spot(x: 0.29, y: 0.21), scale: 0.1),
        Decor(id: "butterflies", name: "Butterflies", emoji: "🦋", unlockLevel: 5, price: 6, currency: .gems, coziness: 10, spot: Spot(x: 0.605, y: 0.33), scale: 0.06),
        Decor(id: "balloon", name: "Hot Air Balloon", emoji: "🎈", unlockLevel: 6, price: 4_000, currency: .coins, coziness: 12, spot: Spot(x: 0.8, y: 0.05), scale: 0.09),
        Decor(id: "tent", name: "Cozy Tent", emoji: "⛺", unlockLevel: 7, price: 9_000, currency: .coins, coziness: 15, spot: Spot(x: 0.755, y: 0.68), scale: 0.09),
        Decor(id: "rainbow", name: "Pastel Rainbow", emoji: "🌈", unlockLevel: 8, price: 15, currency: .gems, coziness: 20, spot: Spot(x: 0.35, y: 0.07), scale: 0.13),
        // Collection milestones
        Decor(id: "gardenArch", name: "Starter Garden Arch", emoji: "🌿", unlockLevel: 1, price: 0, currency: .coins, coziness: 6, spot: Spot(x: 0.478, y: 0.63), scale: 0.07, earnedFrom: "Discover 5 breeds"),
        Decor(id: "bunnyTopiary", name: "Bunny Topiary", emoji: "🌳", unlockLevel: 1, price: 0, currency: .coins, coziness: 10, spot: Spot(x: 0.60, y: 0.60), scale: 0.09, earnedFrom: "Discover 20 breeds"),
        Decor(id: "moonGate", name: "Moon Gate", emoji: "🌕", unlockLevel: 1, price: 0, currency: .coins, coziness: 25, spot: Spot(x: 0.525, y: 0.42), scale: 0.1, earnedFrom: "Discover all 50 breeds"),
        // Character friendship decor (Friend chapter)
        Decor(id: "herbPlanter", name: "June's Herb Planter", emoji: "🪴", unlockLevel: 1, price: 0, currency: .coins, coziness: 8, spot: Spot(x: 0.2, y: 0.28), scale: 0.07, earnedFrom: "June's story"),
        Decor(id: "cakeStand", name: "Roz's Cake Stand", emoji: "🎂", unlockLevel: 1, price: 0, currency: .coins, coziness: 8, spot: Spot(x: 0.812, y: 0.52), scale: 0.06, earnedFrom: "Roz's story"),
        Decor(id: "telescope", name: "Theo's Telescope", emoji: "🔭", unlockLevel: 1, price: 0, currency: .coins, coziness: 8, spot: Spot(x: 0.35, y: 0.08), scale: 0.07, earnedFrom: "Theo's story"),
        Decor(id: "bunnyHutch", name: "Kai's Bunny Hutch", emoji: "🛖", unlockLevel: 1, price: 0, currency: .coins, coziness: 8, spot: Spot(x: 0.665, y: 0.16), scale: 0.08, earnedFrom: "Kai's story"),
        Decor(id: "musicBox", name: "Sol's Music Box", emoji: "🎵", unlockLevel: 1, price: 0, currency: .coins, coziness: 8, spot: Spot(x: 0.665, y: 0.435), scale: 0.06, earnedFrom: "Sol's story"),
        // Romance date decor (Dating chapter) — bunny-themed
        Decor(id: "pressedFlowerArch", name: "Bunny Blossom Arch", emoji: "💐", unlockLevel: 1, price: 0, currency: .coins, coziness: 12, spot: Spot(x: 0.525, y: 0.895), scale: 0.07, earnedFrom: "A date with June"),
        Decor(id: "loveCake", name: "Bunny Love Cake", emoji: "🍰", unlockLevel: 1, price: 0, currency: .coins, coziness: 12, spot: Spot(x: 0.63, y: 0.895), scale: 0.06, earnedFrom: "A date with Roz"),
        Decor(id: "constellationLights", name: "Bunny Constellation", emoji: "🌠", unlockLevel: 1, price: 0, currency: .coins, coziness: 12, spot: Spot(x: 0.68, y: 0.045), scale: 0.08, earnedFrom: "A date with Theo"),
        Decor(id: "porchSwing", name: "Bunny Porch Swing", emoji: "🪑", unlockLevel: 1, price: 0, currency: .coins, coziness: 12, spot: Spot(x: 0.462, y: 0.305), scale: 0.06, earnedFrom: "A date with Kai"),
        Decor(id: "duetBandstand", name: "Bunny Bandstand", emoji: "🎪", unlockLevel: 1, price: 0, currency: .coins, coziness: 12, spot: Spot(x: 0.72, y: 0.565), scale: 0.08, earnedFrom: "A date with Sol"),
        // Seasonal festivals
        Decor(id: "petalGarland", name: "Petal Garland", emoji: "🎏", unlockLevel: 1, price: 0, currency: .coins, coziness: 8, spot: Spot(x: 0.79, y: 0.42), scale: 0.07, earnedFrom: "Petal Festival"),
        Decor(id: "starLanterns", name: "Starlight Lanterns", emoji: "🎐", unlockLevel: 1, price: 0, currency: .coins, coziness: 8, spot: Spot(x: 0.12, y: 0.68), scale: 0.07, earnedFrom: "Starlight Festival"),
        Decor(id: "harvestWreath", name: "Harvest Wreath", emoji: "🍂", unlockLevel: 1, price: 0, currency: .coins, coziness: 8, spot: Spot(x: 0.497, y: 0.25), scale: 0.06, earnedFrom: "Harvest Moon Festival"),
        Decor(id: "snowBunny", name: "Snow Bunny", emoji: "⛄", unlockLevel: 1, price: 0, currency: .coins, coziness: 8, spot: Spot(x: 0.572, y: 0.925), scale: 0.07, earnedFrom: "Snowglow Festival"),
    ]
}

// MARK: - Wardrobe, accessories, keepsakes

/// Your farmer, chosen at the start of the game. Each has art in four skin tones.
enum FarmerGender: String, Codable, CaseIterable, Identifiable {
    case female, male

    var id: String { rawValue }

    var title: String {
        switch self {
        case .female: return "Female"
        case .male: return "Male"
        }
    }

    /// Skin tones from lightest (1) to deepest (4).
    static let skinTones = [1, 2, 3, 4]

    /// The two hairstyles for each farmer, in art order (`s0`, `s1`).
    var hairStyles: [String] {
        switch self {
        case .female: return ["Curly Buns", "Long Waves", "Bald", "Twin Braids", "Bob"]
        case .male: return ["Curly Top", "Curly Fade", "Bald", "Low Ponytail", "Side Part"]
        }
    }
}

/// One choice in the farmer creator, like a hair or eye color. `rgb == nil` means "keep
/// the colors drawn in the art" (black hair, brown eyes, the deepest skin tone).
struct LookSwatch: Identifiable, Equatable {
    let id: String
    let name: String
    let rgb: RGB?
    var isFantasy = false
}

/// How your farmer looks. Everything except the outfit is picked in the farmer creator.
struct FarmerLook: Codable, Equatable {
    var gender: FarmerGender
    /// Index into `gender.hairStyles`.
    var hairStyle = 0
    /// 1 (lightest) to 4 (deepest).
    var skinTone = 3
    var hairColor = "black"
    var eyeColor = "brown"
    var outfit = Outfit.defaultID

    static let skinSwatches: [Int: LookSwatch] = [
        1: LookSwatch(id: "1", name: "Fair", rgb: RGB(0xF0C6A8)),
        2: LookSwatch(id: "2", name: "Golden", rgb: RGB(0xD6A078)),
        3: LookSwatch(id: "3", name: "Tan", rgb: RGB(0xA8704C)),
        4: LookSwatch(id: "4", name: "Deep", rgb: nil),
    ]

    static let hairColors: [LookSwatch] = [
        LookSwatch(id: "black", name: "Black", rgb: nil),
        LookSwatch(id: "brown", name: "Brown", rgb: RGB(0x6E4830)),
        LookSwatch(id: "auburn", name: "Auburn", rgb: RGB(0x96462D)),
        LookSwatch(id: "blonde", name: "Blonde", rgb: RGB(0xE1B973)),
        LookSwatch(id: "platinum", name: "Platinum", rgb: RGB(0xE6E1D7)),
        LookSwatch(id: "pink", name: "Pink", rgb: RGB(0xF596BE), isFantasy: true),
        LookSwatch(id: "lilac", name: "Lilac", rgb: RGB(0xBEA0EB), isFantasy: true),
        LookSwatch(id: "mint", name: "Mint", rgb: RGB(0x8CD7B9), isFantasy: true),
        LookSwatch(id: "sky", name: "Sky Blue", rgb: RGB(0x82B4F0), isFantasy: true),
        LookSwatch(id: "peach", name: "Peach", rgb: RGB(0xFAB48C), isFantasy: true),
    ]

    static let eyeColors: [LookSwatch] = [
        LookSwatch(id: "brown", name: "Brown", rgb: nil),
        LookSwatch(id: "blue", name: "Blue", rgb: RGB(0x4682D2)),
        LookSwatch(id: "green", name: "Green", rgb: RGB(0x50A064)),
        LookSwatch(id: "grey", name: "Grey", rgb: RGB(0x8C96A0)),
        LookSwatch(id: "pink", name: "Pink", rgb: RGB(0xE66EA0)),
    ]

    static func hair(_ id: String) -> LookSwatch? { hairColors.first { $0.id == id } }
    static func eyes(_ id: String) -> LookSwatch? { eyeColors.first { $0.id == id } }

    /// A copy with a change applied, for previews.
    func with(_ change: (inout FarmerLook) -> Void) -> FarmerLook {
        var copy = self
        change(&copy)
        return copy
    }

    /// Fixes anything out of range (from an older save or a removed option).
    func validated() -> FarmerLook {
        var look = self
        if !gender.hairStyles.indices.contains(look.hairStyle) { look.hairStyle = 0 }
        if !FarmerGender.skinTones.contains(look.skinTone) { look.skinTone = 3 }
        if Self.hair(look.hairColor) == nil { look.hairColor = "black" }
        if Self.eyes(look.eyeColor) == nil { look.eyeColor = "brown" }
        if Outfit.find(look.outfit) == nil { look.outfit = Outfit.defaultID }
        // Only looks that have art: switch to a starter outfit drawn for this hairstyle.
        if let outfit = Outfit.find(look.outfit), !look.canWear(outfit),
           let drawn = Outfit.all.first(where: { Outfit.starterIDs.contains($0.id) && look.canWear($0) }) {
            look.outfit = drawn.id
        }
        return look
    }

    /// Whether an outfit is made for this body and is drawn with this hairstyle.
    func canWear(_ outfit: Outfit) -> Bool {
        outfit.fits(gender) && FarmerRenderer.hasArt(gender: gender, hairStyle: hairStyle, cut: outfit.cut)
    }
}

/// One moment on a walking route.
struct RouteStep {
    var spot: Spot
    /// Direction of travel (or of the last leg, while standing).
    var dx = 0.0
    var dy = 1.0
    var isWalking = false
    /// How far they've walked this loop, in map heights; drives the step animation.
    var distance = 0.0
    /// The route stop they're standing at, if paused.
    var stop: Int?
}

/// The colors an outfit gives the farmer's clothes. `nil` keeps the art's own color.
struct OutfitColors {
    var jacket: RGB?
    var top: RGB?
    var pants: RGB?
    var boots: RGB?
}

/// The cut of an outfit, which picks the farmer art it's drawn in. Jacket outfits all share one
/// drawing, recolored; the other cuts are drawn as they are.
enum OutfitCut: String {
    case jacket, hoodie, sundress

    /// Added to art names, like `farmer-male-s2-hoodie-front`. The jacket art has none.
    var artSuffix: String { self == .jacket ? "" : "-\(rawValue)" }
}

/// An outfit for your farmer, shown in the world.
struct Outfit: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let main: RGB
    let accent: RGB
    let earnedFrom: String
    /// How the outfit recolors the farmer art (the art shows one outfit's shapes).
    var colors = OutfitColors()
    var cut = OutfitCut.jacket
    /// Made for one body only (`nil`: either).
    var gender: FarmerGender?

    func fits(_ gender: FarmerGender) -> Bool {
        self.gender == nil || self.gender == gender
    }

    static let defaultID = "meadowBasics"
    /// Outfits every farmer starts with.
    static let starterIDs: Set<String> = ["meadowBasics", "latteWeekend", "stoneAndSand", "lavenderHoodie", "pinkSundress"]

    static func find(_ id: String) -> Outfit? {
        all.first { $0.id == id }
    }

    static let all: [Outfit] = [
        Outfit(id: "meadowBasics", name: "Leather & Denim", emoji: "🖤", main: RGB(0x2E2A2C), accent: RGB(0xFFFFFF), earnedFrom: "Starting outfit"),
        // Casual, neutral starter looks.
        Outfit(id: "latteWeekend", name: "Latte Weekend", emoji: "☕️", main: RGB(0xBE966E), accent: RGB(0xEEE4D2), earnedFrom: "Starting outfit",
               colors: OutfitColors(jacket: RGB(0xBE966E), top: RGB(0xEEE4D2), pants: RGB(0xDCCDAF), boots: RGB(0x5F412D))),
        Outfit(id: "stoneAndSand", name: "Stone & Sand", emoji: "🪨", main: RGB(0x96918A), accent: RGB(0xF5F2EB), earnedFrom: "Starting outfit",
               colors: OutfitColors(jacket: RGB(0x96918A), top: RGB(0xF5F2EB), pants: RGB(0xC4B291), boots: RGB(0x7D695A))),
        Outfit(id: "lavenderHoodie", name: "Lavender Hoodie", emoji: "💜", main: RGB(0xC3B1E8), accent: RGB(0x9A9A9E), earnedFrom: "Starting outfit",
               cut: .hoodie, gender: .male),
        Outfit(id: "pinkSundress", name: "Pink Sundress", emoji: "🌸", main: RGB(0xF6C6D6), accent: RGB(0xD9B48A), earnedFrom: "Starting outfit",
               cut: .sundress, gender: .female),
        Outfit(id: "gardenerCardigan", name: "Gardener's Cardigan", emoji: "🧶", main: RGB(0xBFD8B8), accent: RGB(0xF6E7C1), earnedFrom: "June's story",
               colors: OutfitColors(jacket: RGB(0xA9C7A0), top: RGB(0xF6E7C1), pants: RGB(0xD9CBB0), boots: RGB(0x7A5A44))),
        Outfit(id: "bakerApron", name: "Sweet Burrow Apron", emoji: "🎀", main: RGB(0xF7B6C8), accent: RGB(0xF9D56E), earnedFrom: "Roz's story",
               colors: OutfitColors(jacket: RGB(0xF2A7BC), top: RGB(0xFFF4E4), pants: RGB(0xF3E3D0), boots: RGB(0xB87A6A))),
        Outfit(id: "starrySweater", name: "Starry Sweater", emoji: "🌌", main: RGB(0x8E9AD6), accent: RGB(0xE6E1F5), earnedFrom: "Theo's story",
               colors: OutfitColors(jacket: RGB(0x7E8AC8), top: RGB(0xE6E1F5), pants: RGB(0x4E5584))),
        Outfit(id: "carpenterOveralls", name: "Carpenter Overalls", emoji: "👖", main: RGB(0x9CCBE8), accent: RGB(0xF4D35E), earnedFrom: "Kai's story",
               colors: OutfitColors(jacket: RGB(0x9C7A5A), top: RGB(0xF4E9C8), pants: RGB(0x8CB8D8), boots: RGB(0x6E4E36))),
        Outfit(id: "patchworkJacket", name: "Patchwork Jacket", emoji: "🧥", main: RGB(0xC8B6F2), accent: RGB(0xFFD6A5), earnedFrom: "Sol's story",
               colors: OutfitColors(jacket: RGB(0xC0ACEC), top: RGB(0xFFE7CC), pants: RGB(0xE9D9F2))),
        Outfit(id: "bunnyHoodie", name: "Bunny-Ear Hoodie", emoji: "🐰", main: RGB(0xFFFFFF), accent: RGB(0xF7A8C4), earnedFrom: "Discover 20 breeds",
               colors: OutfitColors(jacket: RGB(0xF7F2F4), top: RGB(0xF7A8C4), pants: RGB(0xF2D7E1), boots: RGB(0xE9B7C8))),
        Outfit(id: "moonlitGown", name: "Moonlit Formalwear", emoji: "🌙", main: RGB(0x6E6AA8), accent: RGB(0xFFE29A), earnedFrom: "Achievement: Heart of the Meadow",
               colors: OutfitColors(jacket: RGB(0x5E5A98), top: RGB(0xFFF1C9), pants: RGB(0x3E3B6A))),
    ]
}

/// Something your habitat bunnies can wear.
struct BunnyAccessory: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let earnedFrom: String

    static func find(_ id: String) -> BunnyAccessory? {
        all.first { $0.id == id }
    }

    static let all: [BunnyAccessory] = [
        BunnyAccessory(id: "lavenderSprig", name: "Lavender Sprig", emoji: "🪻", earnedFrom: "June's story"),
        BunnyAccessory(id: "strawberryBow", name: "Strawberry Bow", emoji: "🍓", earnedFrom: "Roz's story"),
        BunnyAccessory(id: "starPin", name: "Star Pin", emoji: "⭐️", earnedFrom: "Theo's story"),
        BunnyAccessory(id: "tinyHardHat", name: "Tiny Hard Hat", emoji: "⛑️", earnedFrom: "Kai's story"),
        BunnyAccessory(id: "ribbonBow", name: "Ribbon Bow", emoji: "🎀", earnedFrom: "Sol's story"),
        BunnyAccessory(id: "moonlitRibbon", name: "Moonlit Ribbon", emoji: "🌙", earnedFrom: "Discover 35 breeds"),
        BunnyAccessory(id: "moonCrown", name: "Moon Crown", emoji: "👑", earnedFrom: "Discover all 50 breeds"),
    ]
}

/// A memento from a finished storyline or the full collection.
struct Keepsake: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let description: String

    static func find(_ id: String) -> Keepsake? {
        all.first { $0.id == id }
    }

    static let all: [Keepsake] = [
        Keepsake(id: "flowerLetter", name: "Pressed-Flower Letter", emoji: "💌", description: "June's letter, sealed with a lavender sprig. You've read it a hundred times."),
        Keepsake(id: "seedLocket", name: "Seed Locket", emoji: "🌱", description: "A locket holding seeds from June's grandmother's garden. “To grow wherever you go.”"),
        Keepsake(id: "heartWhisk", name: "Heart Whisk", emoji: "🥄", description: "Roz bent the handle into a heart. “Now we have to bake together forever.”"),
        Keepsake(id: "recipeBook", name: "Family Recipe Book", emoji: "📖", description: "Roz's family recipes, with a new page added: yours."),
        Keepsake(id: "namedStar", name: "A Star With Your Name", emoji: "⭐️", description: "Theo's certificate naming a star after you, signed under Nonno's name too."),
        Keepsake(id: "starChart", name: "Nonno's Star Chart", emoji: "🗺️", description: "Theo trusted you with his grandfather's chart. Your favorite stars are circled."),
        Keepsake(id: "carvedHeart", name: "Carved Wooden Heart", emoji: "🪵", description: "Kai carved it from the first beam of the house he built for himself — for both of you."),
        Keepsake(id: "toolBelt", name: "Matching Tool Belt", emoji: "🧰", description: "“Partners need matching gear,” Kai said. Yours has a bunny patch."),
        Keepsake(id: "songForYou", name: "A Song For You", emoji: "🎼", description: "Sol's finished meadow song. The last verse has your name in it."),
        Keepsake(id: "friendshipBracelet", name: "Friendship Bracelet", emoji: "📿", description: "Sol wove it from scraps of every outfit they've made you."),
        Keepsake(id: "starCharm", name: "Iron Star Charm", emoji: "⭐️", description: "Rowan's star charm, kept in the iron box he forged for every note you ever left him."),
        Keepsake(id: "mendedLantern", name: "The Mended Lantern", emoji: "🏮", description: "Rowan's mother's forge lantern, every seam mended. “For whoever keeps others warm.”"),
        Keepsake(id: "honeyDipper", name: "Golden Honey Dipper", emoji: "🍯", description: "Silas's grandfather's honey dipper, on a chain. Given the morning he asked you to share forty hives."),
        Keepsake(id: "beeCharm", name: "Honeybee Charm", emoji: "🐝", description: "A single honeybee wing sealed in gold glass. “Bees remember the people who are kind to them. So do I.”"),
        Keepsake(id: "hookPendant", name: "Silver Hook Pendant", emoji: "🪝", description: "Imani's own pendant, pressed into your palm at dawn. “Now we match. Don't lose it — I file losses.”"),
        Keepsake(id: "keeperLog", name: "Pond Keeper's Log", emoji: "📓", description: "Your own keeper's log, your name on the cover in Imani's careful hand. The first page is Gerald's file. Handle with care."),
        Keepsake(id: "moonlitCrown", name: "Moonlit Crown", emoji: "👑", description: "Woven by every bunny in the meadow for the one who found them all."),
        Keepsake(id: "kidRibbon", name: "A Faded Ribbon", emoji: "🎀", description: "Small, sun-faded, tied a hundred times by small hands. It was left for you under the moon."),
        Keepsake(id: "smoothStone", name: "A Smooth Stone", emoji: "🪨", description: "Pond-smooth and warm from a pocket. Somebody carried this a long time, waiting."),
        Keepsake(id: "pressedFlower", name: "A Pressed Flower", emoji: "🌸", description: "A moonflower, pressed flat years ago and still faintly glowing at the edges."),
        Keepsake(id: "theoCharmHalf", name: "Half a Carved Moon — His", emoji: "🌙", description: "Half of a pair of wooden moon charms, whittled by a boy one long-ago summer. The other half was lost the night of the storm."),
        Keepsake(id: "mochiCharmHalf", name: "Half a Carved Moon — Hers", emoji: "🌙", description: "Your half of the carved moon charms, lost in the pond the night of the storm — and kept safe ever since by a bunny. The pair is whole again."),
        Keepsake(id: "capsulePhoto", name: "A Blurred Photo", emoji: "🖼️", description: "Two children and a white bunny, faces softened by time and water. You know them. You almost know them."),
        Keepsake(id: "capsulePhotoClear", name: "The Photo, Clear", emoji: "🖼️", description: "Two children and a white bunny, laughing in the sun: Theo, and you, and Mochi. Framed for the farmhouse wall, where it always belonged."),
    ]
}

// MARK: - Collection milestones

struct CollectionMilestone: Identifiable {
    let count: Int
    let title: String
    let rewards: [Reward]

    var id: Int { count }

    static let all: [CollectionMilestone] = [
        CollectionMilestone(count: 5, title: "Budding Collector", rewards: [.decor("gardenArch"), .coins(200)]),
        CollectionMilestone(count: 10, title: "Bunny Friend", rewards: [.habitatSpace(6), .lureSlot, .gems(5)]),
        CollectionMilestone(count: 20, title: "Bunny Whisperer", rewards: [.outfit("bunnyHoodie"), .decor("bunnyTopiary"), .gems(8)]),
        CollectionMilestone(count: 35, title: "Meadow Keeper", rewards: [.accessory("moonlitRibbon"), .habitatSpace(6), .gems(12)]),
        CollectionMilestone(count: 50, title: "Moonlit Legend", rewards: [.keepsake("moonlitCrown"), .accessory("moonCrown"), .decor("moonGate"), .gems(50)]),
    ]
}

// MARK: - Achievements

struct Achievement: Identifiable {
    enum Metric {
        case breedsDiscovered
        case rareDiscovered
        case epicDiscovered
        case legendaryDiscovered
        case milestonesClaimed
        case cropsGrown
        case farmLevel
        case favoriteBunnyGifts
        case bestStage
        case storylinesCompleted
        case festivalsJoined
    }

    let id: String
    let title: String
    let emoji: String
    let description: String
    let metric: Metric
    let target: Int
    let rewards: [Reward]

    static let all: [Achievement] = [
        Achievement(id: "discover1", title: "First Hello", emoji: "🐾", description: "Discover a new bunny breed.", metric: .breedsDiscovered, target: 3, rewards: [.coins(50)]),
        Achievement(id: "discover10", title: "Bunny Spotter", emoji: "🔍", description: "Discover 10 breeds.", metric: .breedsDiscovered, target: 10, rewards: [.gems(3)]),
        Achievement(id: "discover25", title: "Halfway Hop", emoji: "🐇", description: "Discover 25 breeds.", metric: .breedsDiscovered, target: 25, rewards: [.gems(5)]),
        Achievement(id: "discover50", title: "Every Bunny", emoji: "🌕", description: "Discover all 50 breeds.", metric: .breedsDiscovered, target: 50, rewards: [.gems(20)]),
        Achievement(id: "rare1", title: "Rare Find", emoji: "💜", description: "Discover a Rare breed.", metric: .rareDiscovered, target: 1, rewards: [.gems(2)]),
        Achievement(id: "epic1", title: "Epic Encounter", emoji: "💗", description: "Discover an Epic breed.", metric: .epicDiscovered, target: 1, rewards: [.gems(3)]),
        Achievement(id: "legendary1", title: "Living Legend", emoji: "🌟", description: "Discover a Legendary breed.", metric: .legendaryDiscovered, target: 1, rewards: [.gems(5)]),
        Achievement(id: "legendary4", title: "Myths Made Real", emoji: "👑", description: "Discover all five Legendary breeds.", metric: .legendaryDiscovered, target: 5, rewards: [.gems(10)]),
        Achievement(id: "milestones3", title: "Collector's Ribbon", emoji: "🎀", description: "Claim 3 collection milestones.", metric: .milestonesClaimed, target: 3, rewards: [.gems(3)]),
        Achievement(id: "milestones5", title: "Collector's Crown", emoji: "🏆", description: "Claim every collection milestone.", metric: .milestonesClaimed, target: 5, rewards: [.gems(10)]),
        Achievement(id: "crops10", title: "Green Thumb", emoji: "🌱", description: "Harvest 10 different crops.", metric: .cropsGrown, target: 10, rewards: [.coins(200)]),
        Achievement(id: "cropsAll", title: "Master Gardener", emoji: "🌻", description: "Harvest every crop at least once.", metric: .cropsGrown, target: Crop.all.count, rewards: [.gems(10)]),
        Achievement(id: "level5", title: "Growing Farm", emoji: "🏡", description: "Reach farm level 5.", metric: .farmLevel, target: 5, rewards: [.coins(300)]),
        Achievement(id: "level10", title: "Moonlit Farm", emoji: "🌙", description: "Reach farm level 10.", metric: .farmLevel, target: 10, rewards: [.gems(5)]),
        Achievement(id: "level15", title: "Magical Farm", emoji: "✨", description: "Reach farm level 15.", metric: .farmLevel, target: 15, rewards: [.gems(10)]),
        Achievement(id: "favGift1", title: "Perfect Present", emoji: "🎁", description: "Give someone their favorite bunny breed.", metric: .favoriteBunnyGifts, target: 1, rewards: [.gems(2)]),
        Achievement(id: "favGift5", title: "Matchmaker", emoji: "💝", description: "Give 5 favorite-breed bunnies.", metric: .favoriteBunnyGifts, target: 5, rewards: [.gems(5)]),
        Achievement(id: "stage3", title: "Making Friends", emoji: "🤝", description: "Become Friends with someone.", metric: .bestStage, target: 3, rewards: [.coins(200)]),
        Achievement(id: "stage6", title: "Something Special", emoji: "💞", description: "Reach Dating or Kindred Spirit with someone.", metric: .bestStage, target: 6, rewards: [.gems(5)]),
        Achievement(id: "stage7", title: "Heart of the Meadow", emoji: "💖", description: "Reach Committed or Lifelong Friend with someone.", metric: .bestStage, target: 7, rewards: [.outfit("moonlitGown"), .gems(8)]),
        Achievement(id: "story1", title: "Happily Ever After", emoji: "📖", description: "Complete a character's storyline.", metric: .storylinesCompleted, target: 1, rewards: [.gems(5)]),
        Achievement(id: "story5", title: "Beloved by All", emoji: "🏘️", description: "Complete five storylines.", metric: .storylinesCompleted, target: 5, rewards: [.gems(20)]),
        Achievement(id: "festival1", title: "Festival Goer", emoji: "🎉", description: "Complete a seasonal festival request.", metric: .festivalsJoined, target: 1, rewards: [.gems(2)]),
        Achievement(id: "festival4", title: "All Seasons", emoji: "🗓️", description: "Complete 4 festival requests.", metric: .festivalsJoined, target: 4, rewards: [.gems(8)]),
    ]
}

// MARK: - Seasonal festivals

/// Each season has a festival with a request. It comes back every month, so nothing is missable.
struct Festival {
    let season: Season
    let name: String
    let description: String
    let quest: Quest
    let decorID: String

    static func current(at date: Date) -> Festival {
        let season = Season.at(date)
        return all.first { $0.season == season } ?? all[0]
    }

    static let all: [Festival] = [
        Festival(season: .spring, name: "Petal Festival",
                 description: "The meadow celebrates the first blossoms, and Blossom and Cherry Blossom bunnies hop through the petals.",
                 quest: Quest(id: "festival-spring", personID: nil, season: .spring, title: "Petal Festival Picnic",
                              description: "Bring strawberries for the festival picnic.", requiredStage: .stranger,
                              items: [ItemCount(itemID: "strawberry", count: 6)], points: 0,
                              rewards: [.decor("petalGarland"), .gems(3)]),
                 decorID: "petalGarland"),
        Festival(season: .summer, name: "Starlight Festival",
                 description: "Lanterns float over the meadow. Ember and Solstice bunnies only come out in summer.",
                 quest: Quest(id: "festival-summer", personID: nil, season: .summer, title: "Lantern Tea",
                              description: "Brew chamomile tea for the lantern-lighters.", requiredStage: .stranger,
                              items: [ItemCount(itemID: "chamomileTea", count: 2)], points: 0,
                              rewards: [.decor("starLanterns"), .gems(3)]),
                 decorID: "starLanterns"),
        Festival(season: .autumn, name: "Harvest Moon Festival",
                 description: "Everyone shares their harvest under a giant orange moon.",
                 quest: Quest(id: "festival-autumn", personID: nil, season: .autumn, title: "Harvest Feast",
                              description: "Bring carrot cake to the village feast.", requiredStage: .stranger,
                              items: [ItemCount(itemID: "carrotCake", count: 2)], points: 0,
                              rewards: [.decor("harvestWreath"), .gems(3)]),
                 decorID: "harvestWreath"),
        Festival(season: .winter, name: "Snowglow Festival",
                 description: "Snow glitters on the meadow, and Ice and Marshmallow bunnies come out to play.",
                 quest: Quest(id: "festival-winter", personID: nil, season: .winter, title: "Cozy Cookies",
                              description: "Bake clover cookies to hand out by the bonfire.", requiredStage: .stranger,
                              items: [ItemCount(itemID: "cloverCookie", count: 4)], points: 0,
                              rewards: [.decor("snowBunny"), .gems(3)]),
                 decorID: "snowBunny"),
    ]
}

// MARK: - World layout

/// Where things are in the world, in unit coordinates of the pixel-art meadow (`world-meadow`,
/// 2096×1184): x runs across its width and y down its height. Overlays, floating text, and
/// the drawn fallback scene all use these, so crops, bunnies, and characters line up with it.
enum WorldLayout {
    /// The one garden: a 5×5 grid of plots on the left of the farm, unlocked one plot
    /// at a time. The third row and column sit a little further over — the wider gap
    /// after the second row and column is the cross lane through the middle.
    static let plotColumns = 5
    static let plotRows = 5
    /// The top-left corner of the first plot's cell.
    static let plotOrigin = Spot(x: 0.150, y: 0.340)
    /// One plot's patch of soil.
    static let plotCell = (width: 0.050, height: 0.088)
    /// Centre-to-centre spacing of neighbouring plots.
    static let plotPitch = (x: 0.062, y: 0.112)
    /// The cross lane's extra width, added from the third row and column on.
    static let plotLane = (x: 0.018, y: 0.015)

    static func plotColumn(_ index: Int) -> Int { index % plotColumns }
    static func plotRow(_ index: Int) -> Int { index / plotColumns }

    /// The cell a plot sits in, in unit coordinates.
    static func plotCellRect(_ index: Int) -> (minX: Double, minY: Double, maxX: Double, maxY: Double) {
        let column = Double(plotColumn(index)), row = Double(plotRow(index))
        let minX = plotOrigin.x + column * plotPitch.x + (column >= 2 ? plotLane.x : 0)
        let minY = plotOrigin.y + row * plotPitch.y + (row >= 2 ? plotLane.y : 0)
        return (minX, minY, minX + plotCell.width, minY + plotCell.height)
    }
    static let lureBasket = Spot(x: 0.70, y: 0.85)
    static let lureGarden = (minX: 0.23, minY: 0.775, maxX: 0.36, maxY: 0.895)
    /// The open grass beside the cottage, where your bunnies play.
    static let habitat = (minX: 0.60, minY: 0.14, maxX: 0.73, maxY: 0.42)
    static let cottageDoor = Spot(x: 0.497, y: 0.26)
    /// Characters stroll along this line, across the stone path below the cottage.
    static let walkY = 0.53
    static let walkX = (minX: 0.40, maxX: 0.58)

    /// A villager's stroll: back and forth along their lane of the stone path, stopping at
    /// each end, with a detour to coo at your bunnies if you own one of their favorites.
    static func strollRoute(lane: Int, visitsBunnies: Bool) -> [(spot: Spot, pause: Double)] {
        let y = walkY + 0.03 * Double(lane % 3)
        var route: [(spot: Spot, pause: Double)] = [
            (Spot(x: walkX.minX, y: y), 0.8),
            (Spot(x: walkX.maxX, y: y), 0.8),
        ]
        if visitsBunnies {
            route.append((Spot(x: habitat.maxX + 0.02, y: habitatCenter.y + 0.06), 2.5))
            route.append((Spot(x: walkX.maxX, y: y), 0))
        }
        return route
    }

    /// Where someone is on a looping route at time `t`. Walking is at a steady pace, so the
    /// step animation (from `distance`) matches how far they've actually moved.
    static func routeStep(_ route: [(spot: Spot, pause: Double)], at t: Double, aspect: Double, speed: Double = 0.05) -> RouteStep {
        var legs: [(from: Spot, to: Spot, length: Double, walk: Double, pause: Double)] = []
        for (index, stop) in route.enumerated() {
            let next = route[(index + 1) % route.count].spot
            let length = hypot((next.x - stop.spot.x) * aspect, next.y - stop.spot.y)
            legs.append((stop.spot, next, length, length / speed, stop.pause))
        }
        let total = legs.reduce(0) { $0 + $1.walk + $1.pause }
        guard total > 0 else { return RouteStep(spot: route.first?.spot ?? Spot(x: 0.5, y: 0.5)) }
        var clock = t.truncatingRemainder(dividingBy: total)
        if clock < 0 { clock += total }
        var walked = 0.0
        // Standing still faces the way they were last walking.
        var last = legs.last.map { ($0.to.x - $0.from.x) * aspect } ?? 0
        var lastY = legs.last.map { $0.to.y - $0.from.y } ?? 1
        for (index, leg) in legs.enumerated() {
            if clock < leg.pause {
                return RouteStep(spot: leg.from, dx: last, dy: lastY, isWalking: false, distance: walked, stop: index)
            }
            clock -= leg.pause
            let dx = (leg.to.x - leg.from.x) * aspect, dy = leg.to.y - leg.from.y
            if clock < leg.walk {
                let f = clock / leg.walk
                let spot = Spot(x: leg.from.x + (leg.to.x - leg.from.x) * f, y: leg.from.y + (leg.to.y - leg.from.y) * f)
                return RouteStep(spot: spot, dx: dx, dy: dy, isWalking: true, distance: walked + leg.length * f)
            }
            clock -= leg.walk
            walked += leg.length
            if leg.length > 0 { last = dx; lastY = dy }
        }
        return RouteStep(spot: route[0].spot)
    }

    /// A plot's centre, from the one grid geometry above.
    static func plot(_ index: Int) -> Spot {
        let cell = plotCellRect(index)
        return Spot(x: (cell.minX + cell.maxX) / 2, y: (cell.minY + cell.maxY) / 2)
    }

    static var habitatCenter: Spot {
        Spot(x: (habitat.minX + habitat.maxX) / 2, y: (habitat.minY + habitat.maxY) / 2)
    }
}
