import Foundation

enum Rarity: Int, CaseIterable, Comparable {
    case common
    case uncommon
    case rare
    case epic
    case legendary

    static func < (lhs: Rarity, rhs: Rarity) -> Bool { lhs.rawValue < rhs.rawValue }

    var name: String {
        switch self {
        case .common: return "Common"
        case .uncommon: return "Uncommon"
        case .rare: return "Rare"
        case .epic: return "Epic"
        case .legendary: return "Legendary"
        }
    }

    var stars: String { String(repeating: "★", count: rawValue + 1) }

    var color: RGB {
        switch self {
        case .common: return RGB(0xB8D8B0)
        case .uncommon: return RGB(0x9CC8F0)
        case .rare: return RGB(0xC3A6F2)
        case .epic: return RGB(0xF59BC4)
        case .legendary: return RGB(0xF5C95B)
        }
    }

    /// How long a bunny of this rarity takes to wander over to a lure.
    var visitSeconds: TimeInterval {
        switch self {
        case .common: return 45
        case .uncommon: return 90
        case .rare: return 180
        case .epic: return 360
        case .legendary: return 720
        }
    }

    var discoveryCoins: Int {
        switch self {
        case .common: return 30
        case .uncommon: return 80
        case .rare: return 250
        case .epic: return 700
        case .legendary: return 2_000
        }
    }

    var discoveryGems: Int {
        switch self {
        case .common: return 1
        case .uncommon: return 1
        case .rare: return 2
        case .epic: return 4
        case .legendary: return 10
        }
    }

    var discoveryXP: Int {
        switch self {
        case .common: return 10
        case .uncommon: return 20
        case .rare: return 45
        case .epic: return 90
        case .legendary: return 200
        }
    }
}

/// Everything needed to draw a breed. `BreedBunnyView` turns this into a picture.
struct BunnyLook {
    enum Pattern {
        case solid, spots, patches, mask, socks, saddle, gradient, speckles, heart, stripe, tuxedo, crescent
    }

    enum Ears {
        case upright, lop, halfLop, tiny, long, tufted
    }

    enum Trait {
        case none, sparkles, glow, flowerCrown, starMark, moonHalo, fairyWings, crystals, leafSprout,
             scarf, bowtie, rainbowTail, cloudPuff, snowflakes, petals, aurora, crown, berryClip, mushroomCap, bell, bubbles
    }

    let fur: RGB
    let accent: RGB
    var eye = RGB(0x5A3E48)
    var pattern: Pattern = .solid
    var ears: Ears = .upright
    var traits: [Trait] = []
    /// Relative body size, about `0.75...1.25`.
    var size: Double = 1
    var isFluffy = false
}

/// What a bunny likes to do while it's sitting in your habitat or visiting a lure.
enum BunnyBehavior: String {
    case hop, nap, nibble, groom, zoomies, float, twirl, dig, flop, sniff, wiggle, stargaze

    var description: String {
        switch self {
        case .hop: return "Bounces happily in little hops"
        case .nap: return "Dozes off in a sunny spot"
        case .nibble: return "Nibbles snacks with tiny crunches"
        case .groom: return "Washes its ears very seriously"
        case .zoomies: return "Gets sudden zoomies"
        case .float: return "Floats a little off the ground"
        case .twirl: return "Does a happy spinning binky"
        case .dig: return "Digs tiny holes everywhere"
        case .flop: return "Flops over in pure contentment"
        case .sniff: return "Sniffs everything curiously"
        case .wiggle: return "Wiggles its nose nonstop"
        case .stargaze: return "Gazes up at the sky"
        }
    }
}

/// Extra conditions for a lure to work: time of day, weather, or season.
struct LureCondition {
    var time: TimeOfDay?
    var weather: Weather?
    var season: Season?

    static let none = LureCondition()

    var isNone: Bool { time == nil && weather == nil && season == nil }

    /// More conditions make a breed more specific.
    var weight: Int {
        (time == nil ? 0 : 1) + (weather == nil ? 0 : 1) + (season == nil ? 0 : 1)
    }

    /// `timeOfDay` overrides the time from `date` (the game uses its own clock).
    func isMet(at date: Date, timeOfDay: TimeOfDay? = nil) -> Bool {
        if let time, (timeOfDay ?? TimeOfDay.at(date)) != time { return false }
        if let weather, Weather.at(date) != weather { return false }
        if let season, Season.at(date) != season { return false }
        return true
    }

    var text: String {
        var parts: [String] = []
        if let time { parts.append("\(time.emoji) at \(time.name.lowercased())") }
        if let weather { parts.append("\(weather.emoji) when it's \(weather.name.lowercased())") }
        if let season { parts.append("\(season.emoji) in \(season.name.lowercased())") }
        return parts.joined(separator: ", ")
    }
}

/// One of the 50 bunny breeds.
struct Breed: Identifiable {
    let id: String
    let name: String
    let rarity: Rarity
    let look: BunnyLook
    let behavior: BunnyBehavior
    /// Items that must all be in the lure basket.
    let lure: [String]
    var condition: LureCondition = .none
    let description: String

    /// The farm level at which every lure ingredient can be grown or baked.
    var minLevel: Int {
        lure.map(ItemInfo.unlockLevel).max() ?? 1
    }

    /// A readable clue about what this breed wants.
    var hint: String {
        let items = lure.map { "\(ItemInfo.emoji($0)) \(ItemInfo.name($0))" }.joined(separator: " + ")
        return condition.isNone ? "Loves \(items)" : "Loves \(items) — \(condition.text)"
    }

    /// Characters whose favorite breeds include this one.
    var favoredBy: [String] {
        Person.all.filter { $0.favoriteBreeds.contains(id) }.map(\.id)
    }

    /// Clover and Snowflake are the two common starters you begin with.
    static let starterIDs = ["cloverBunny", "snowflakeBunny"]

    static func find(_ id: String) -> Breed? {
        all.first { $0.id == id }
    }

    /// The full roster, in collection-book order (matching the Bunny Collection sheet).
    static let all: [Breed] = [
        // 1–10
        Breed(id: "cloverBunny", name: "Clover", rarity: .common,
              look: BunnyLook(fur: RGB(0xFFF8F0), accent: RGB(0xF3D9C8), pattern: .solid, ears: .upright, traits: [.leafSprout]),
              behavior: .hop, lure: ["carrot"],
              description: "A cream-white bunny who always seems to find four-leaf clovers. One of your first friends."),
        Breed(id: "snowflakeBunny", name: "Snowflake", rarity: .common,
              look: BunnyLook(fur: RGB(0xFFFFFF), accent: RGB(0xDCE8FF), eye: RGB(0x5C8FD6), pattern: .solid, ears: .upright, traits: [.cloudPuff]),
              behavior: .groom, lure: ["clover"],
              description: "Soft as fresh snow, with sky-blue eyes. One of your first friends."),
        Breed(id: "mapleBunny", name: "Maple", rarity: .common,
              look: BunnyLook(fur: RGB(0xFFFFFF), accent: RGB(0x9B6447), pattern: .patches, ears: .upright),
              behavior: .dig, lure: ["lettuce"],
              description: "Classic brown-and-white patches, like maple syrup on pancakes."),
        Breed(id: "cocoaBunny", name: "Cocoa", rarity: .uncommon,
              look: BunnyLook(fur: RGB(0x7A4E3C), accent: RGB(0xC79A7A), pattern: .solid, ears: .lop),
              behavior: .flop, lure: ["wheat"],
              description: "A cuddly chocolate lop who naps in the wheat field."),
        Breed(id: "lavenderBunny", name: "Lavender", rarity: .uncommon,
              look: BunnyLook(fur: RGB(0xDCCFF5), accent: RGB(0xB9A3EE), pattern: .gradient, ears: .lop, traits: [.flowerCrown]),
              behavior: .nap, lure: ["lavender"],
              description: "Lilac lop ears and a crown of tiny flowers. Smells like a calm afternoon."),
        Breed(id: "strawberryBunny", name: "Strawberry", rarity: .uncommon,
              look: BunnyLook(fur: RGB(0xFFF3F3), accent: RGB(0xF7B6C0), pattern: .solid, ears: .upright, traits: [.berryClip]),
              behavior: .nibble, lure: ["strawberry"],
              description: "Rosy-cheeked and never far from a strawberry patch."),
        Breed(id: "butterscotchBunny", name: "Butterscotch", rarity: .uncommon,
              look: BunnyLook(fur: RGB(0xF6CC8E), accent: RGB(0xFFF1DC), pattern: .patches, ears: .lop),
              behavior: .nibble, lure: ["blueberry"],
              description: "Caramel-and-cream fur and a big appetite for blueberries."),
        Breed(id: "pepperBunny", name: "Pepper", rarity: .uncommon,
              look: BunnyLook(fur: RGB(0x3B3438), accent: RGB(0xFFFFFF), pattern: .patches, ears: .lop),
              behavior: .zoomies, lure: ["radish"],
              description: "A peppy black-and-white lop who zooms whenever radishes are around."),
        Breed(id: "mintBunny", name: "Mint", rarity: .common,
              look: BunnyLook(fur: RGB(0xDFF2EA), accent: RGB(0xBFE3D3), pattern: .solid, ears: .upright),
              behavior: .wiggle, lure: ["mint"],
              description: "Pale mint fur and a nose that never stops wiggling."),
        Breed(id: "hazelBunny", name: "Hazel", rarity: .common,
              look: BunnyLook(fur: RGB(0xD6A57C), accent: RGB(0xF0D2B4), pattern: .saddle, ears: .upright),
              behavior: .sniff, lure: ["sunflower"],
              description: "Warm hazelnut fur. Follows the sunflowers as they turn toward the sun."),
        // 11–20
        Breed(id: "roseBunny", name: "Rose", rarity: .uncommon,
              look: BunnyLook(fur: RGB(0xFBD9E0), accent: RGB(0xF4A7B9), pattern: .solid, ears: .upright, traits: [.flowerCrown]),
              behavior: .groom, lure: ["rose"],
              description: "Blush-pink and always wearing a crown of roses."),
        Breed(id: "thistleBunny", name: "Thistle", rarity: .uncommon,
              look: BunnyLook(fur: RGB(0x9E96A3), accent: RGB(0xFFFFFF), pattern: .patches, ears: .upright, traits: [.petals]),
              behavior: .sniff, lure: ["thistle"],
              description: "Gray and white with a purple thistle tucked behind one ear. Tougher than it looks."),
        Breed(id: "goldenBunny", name: "Golden", rarity: .rare,
              look: BunnyLook(fur: RGB(0xF6C46E), accent: RGB(0xFFF1D0), pattern: .saddle, ears: .upright, traits: [.sparkles]),
              behavior: .twirl, lure: ["corn"],
              description: "Shines like a field of ripe corn at sunset."),
        Breed(id: "marbleBunny", name: "Marble", rarity: .rare,
              look: BunnyLook(fur: RGB(0xF2F0F2), accent: RGB(0xA7A0AA), pattern: .spots, ears: .upright),
              behavior: .groom, lure: ["eggplant"],
              description: "Swirled gray-and-white fur, like polished marble."),
        Breed(id: "midnightBunny", name: "Midnight", rarity: .rare,
              look: BunnyLook(fur: RGB(0x2E2E52), accent: RGB(0xF6E7A8), pattern: .speckles, ears: .upright, traits: [.starMark]),
              behavior: .stargaze, lure: ["moonflower"], condition: LureCondition(time: .night),
              description: "Navy fur dotted with tiny stars and a crescent moon. Only visits at night."),
        Breed(id: "peachBunny", name: "Peach", rarity: .rare,
              look: BunnyLook(fur: RGB(0xF7B49A), accent: RGB(0xFFE3D6), pattern: .gradient, ears: .upright),
              behavior: .flop, lure: ["peach"],
              description: "Soft coral fur, sweet and fuzzy like a ripe peach."),
        Breed(id: "willowBunny", name: "Willow", rarity: .rare,
              look: BunnyLook(fur: RGB(0xA9C48E), accent: RGB(0xF3EEDC), pattern: .patches, ears: .lop, traits: [.leafSprout]),
              behavior: .nap, lure: ["basil"],
              description: "Sage-green with a crown of leaves. Naps in the herb garden."),
        Breed(id: "cherryBlossomBunny", name: "Cherry Blossom", rarity: .rare,
              look: BunnyLook(fur: RGB(0xFFF4F7), accent: RGB(0xF7B6CB), pattern: .solid, ears: .upright, traits: [.petals]),
              behavior: .twirl, lure: ["cherry"],
              description: "White with pink blossoms that drift wherever it hops."),
        Breed(id: "oceanBunny", name: "Ocean", rarity: .epic,
              look: BunnyLook(fur: RGB(0xBFE0FA), accent: RGB(0xFFFFFF), pattern: .gradient, ears: .upright, traits: [.bubbles]),
              behavior: .float, lure: ["seaweed"], condition: LureCondition(weather: .rainy),
              description: "Sea-glass blue with waves in its fur. Comes ashore with the rain."),
        Breed(id: "tuxedoBunny", name: "Tuxedo", rarity: .epic,
              look: BunnyLook(fur: RGB(0x2A2629), accent: RGB(0xFFFFFF), pattern: .tuxedo, ears: .upright, traits: [.bowtie]),
              behavior: .groom, lure: ["turnip"], condition: LureCondition(time: .dusk),
              description: "Dressed for a fancy evening, red bowtie and all. Arrives at dusk."),
        // 21–30
        Breed(id: "honeybunBunny", name: "Honeybun", rarity: .common,
              look: BunnyLook(fur: RGB(0xF2B66E), accent: RGB(0xFFF1DC), pattern: .saddle, ears: .upright),
              behavior: .nibble, lure: ["honey"],
              description: "Golden as a warm bun, and sticky-pawed from honeycomb."),
        Breed(id: "crystalBunny", name: "Crystal", rarity: .uncommon,
              look: BunnyLook(fur: RGB(0xCFE6FF), accent: RGB(0x9CC8F5), pattern: .gradient, ears: .upright, traits: [.crystals, .glow]),
              behavior: .twirl, lure: ["crystalCarrot"],
              description: "Icy-blue and slightly see-through, with crystals that chime when it hops."),
        Breed(id: "pumpkinBunny", name: "Pumpkin", rarity: .uncommon,
              look: BunnyLook(fur: RGB(0xF59B4C), accent: RGB(0xFFF0E0), pattern: .saddle, ears: .upright, traits: [.leafSprout]),
              behavior: .flop, lure: ["pumpkin"],
              description: "Bright orange with a little pumpkin vine. Loves crunchy autumn leaves."),
        Breed(id: "lilacBunny", name: "Lilac", rarity: .rare,
              look: BunnyLook(fur: RGB(0xD9C5EE), accent: RGB(0xFFFFFF), pattern: .patches, ears: .upright, traits: [.flowerCrown]),
              behavior: .nap, lure: ["lilac"],
              description: "Lilac and white, with a sprig of lilacs behind one ear."),
        Breed(id: "spottedBunny", name: "Spotted", rarity: .rare,
              look: BunnyLook(fur: RGB(0xFFFFFF), accent: RGB(0x4A4248), pattern: .spots, ears: .upright, traits: [.leafSprout]),
              behavior: .dig, lure: ["cabbage"],
              description: "White with bold dark spots. Hides in the cabbage patch."),
        Breed(id: "faunBunny", name: "Faun", rarity: .epic,
              look: BunnyLook(fur: RGB(0xB9764F), accent: RGB(0xF3E1CC), pattern: .saddle, ears: .upright, traits: [.flowerCrown]),
              behavior: .sniff, lure: ["mushroom"], condition: LureCondition(time: .dawn),
              description: "A forest bunny with tiny antlers and flowers. Steps out of the woods at dawn."),
        Breed(id: "iceBunny", name: "Ice", rarity: .epic,
              look: BunnyLook(fur: RGB(0xF4F8FF), accent: RGB(0xC9DFF7), eye: RGB(0x4C7CC8), pattern: .solid, ears: .upright, traits: [.snowflakes, .glow]),
              behavior: .groom, lure: ["frostBerry"], condition: LureCondition(season: .winter),
              description: "Frosty white with sparkling snowflakes. Only visits in winter."),
        Breed(id: "emberBunny", name: "Ember", rarity: .epic,
              look: BunnyLook(fur: RGB(0x2C2224), accent: RGB(0xF28C38), eye: RGB(0xF59B2E), pattern: .gradient, ears: .upright, traits: [.glow, .sparkles]),
              behavior: .zoomies, lure: ["chili"], condition: LureCondition(season: .summer),
              description: "Dark fur with glowing embers and orange eyes. Warmest in the summer."),
        Breed(id: "angelBunny", name: "Angel", rarity: .legendary,
              look: BunnyLook(fur: RGB(0xFFFFFF), accent: RGB(0xFFE6A8), pattern: .solid, ears: .upright, traits: [.moonHalo, .fairyWings]),
              behavior: .float, lure: ["goldenClover"], condition: LureCondition(weather: .sunny),
              description: "A halo and tiny wings. Floats down on sunny days to bring good luck."),
        Breed(id: "shadowBunny", name: "Shadow", rarity: .legendary,
              look: BunnyLook(fur: RGB(0x3B2B4F), accent: RGB(0x8E6CC2), pattern: .speckles, ears: .upright, traits: [.glow]),
              behavior: .stargaze, lure: ["nightshade"], condition: LureCondition(time: .night),
              description: "Dusky purple and mysterious. Only seen in the deepest part of the night."),
        // 31–40
        Breed(id: "blossomBunny", name: "Blossom", rarity: .common,
              look: BunnyLook(fur: RGB(0xF8C6D8), accent: RGB(0xFFFFFF), pattern: .patches, ears: .upright, traits: [.flowerCrown]),
              behavior: .twirl, lure: ["dandelion"],
              description: "Pink as a spring blossom, with a flower clip it picked itself."),
        Breed(id: "fernBunny", name: "Fern", rarity: .common,
              look: BunnyLook(fur: RGB(0xB9CBA9), accent: RGB(0xE9F0DF), pattern: .saddle, ears: .upright, traits: [.leafSprout]),
              behavior: .nap, lure: ["greens"],
              description: "Soft sage-green, happiest in a bed of fresh greens."),
        Breed(id: "sodaBunny", name: "Soda", rarity: .uncommon,
              look: BunnyLook(fur: RGB(0x9CC6F0), accent: RGB(0xFFFFFF), pattern: .patches, ears: .upright, traits: [.bowtie, .bubbles]),
              behavior: .zoomies, lure: ["coconut"],
              description: "Fizzy blue and white with a sunny yellow bow."),
        Breed(id: "cometBunny", name: "Comet", rarity: .uncommon,
              look: BunnyLook(fur: RGB(0x3A3550), accent: RGB(0xF6D58A), pattern: .speckles, ears: .upright, traits: [.sparkles]),
              behavior: .zoomies, lure: ["starberry"],
              description: "Dark as the night sky, flecked with shooting stars."),
        Breed(id: "willowbarkBunny", name: "Willowbark", rarity: .rare,
              look: BunnyLook(fur: RGB(0x8C6247), accent: RGB(0xFFF8EE), pattern: .patches, ears: .lop, traits: [.leafSprout]),
              behavior: .dig, lure: ["willowBark"],
              description: "Bark-brown and white with clover leaves. Gnaws willow twigs into tiny sculptures."),
        Breed(id: "sugarplumBunny", name: "Sugarplum", rarity: .rare,
              look: BunnyLook(fur: RGB(0xF8C9E4), accent: RGB(0xD7C3F2), pattern: .gradient, ears: .upright, traits: [.bell]),
              behavior: .nibble, lure: ["sugarcane"],
              description: "Pink and lilac like candied sugarplums. Has a serious sweet tooth."),
        Breed(id: "stormBunny", name: "Storm", rarity: .rare,
              look: BunnyLook(fur: RGB(0x5C5A66), accent: RGB(0xF6D36B), pattern: .speckles, ears: .upright, traits: [.starMark]),
              behavior: .sniff, lure: ["thunderRoot"], condition: LureCondition(weather: .rainy),
              description: "Storm-cloud gray with a lightning-bolt mark. Rolls in with the rain."),
        Breed(id: "poppyBunny", name: "Poppy", rarity: .epic,
              look: BunnyLook(fur: RGB(0xFFFFFF), accent: RGB(0xE2483F), pattern: .patches, ears: .upright, traits: [.flowerCrown]),
              behavior: .twirl, lure: ["poppy"], condition: LureCondition(weather: .breezy),
              description: "Bright red and white with poppies in its fur. Dances in the petal breeze."),
        Breed(id: "jinxBunny", name: "Jinx", rarity: .epic,
              look: BunnyLook(fur: RGB(0x3A2E4A), accent: RGB(0x9B7CD6), pattern: .patches, ears: .upright, traits: [.sparkles]),
              behavior: .sniff, lure: ["bamboo"], condition: LureCondition(time: .night),
              description: "A mischievous purple bunny who knocks things over — always at night."),
        Breed(id: "auroraBunny", name: "Aurora", rarity: .epic,
              look: BunnyLook(fur: RGB(0xFFFFFF), accent: RGB(0xBFE6FF), pattern: .solid, ears: .upright, traits: [.aurora, .fairyWings, .moonHalo]),
              behavior: .float, lure: ["rainbowBerry"], condition: LureCondition(time: .night),
              description: "White with shimmering wings and a halo of northern lights."),
        // 41–50
        Breed(id: "velvetBunny", name: "Velvet", rarity: .common,
              look: BunnyLook(fur: RGB(0x3A3640), accent: RGB(0x5C5566), pattern: .solid, ears: .tiny, size: 0.9),
              behavior: .nap, lure: ["blackberry"],
              description: "Small, soft, and velvety dark. Curls up like a sleepy blackberry."),
        Breed(id: "daffodilBunny", name: "Daffodil", rarity: .uncommon,
              look: BunnyLook(fur: RGB(0xFFF0A8), accent: RGB(0xFFFFFF), pattern: .gradient, ears: .upright, traits: [.flowerCrown]),
              behavior: .twirl, lure: ["daffodil"],
              description: "Sunshine yellow with a daffodil tucked in its fur. Brightens any day."),
        Breed(id: "nutmegBunny", name: "Nutmeg", rarity: .uncommon,
              look: BunnyLook(fur: RGB(0xA8714E), accent: RGB(0xD9B08C), pattern: .saddle, ears: .upright, traits: [.leafSprout]),
              behavior: .nibble, lure: ["nutmeg"],
              description: "Spice-brown and cozy, like a warm cup of cocoa."),
        Breed(id: "wisteriaBunny", name: "Wisteria", rarity: .rare,
              look: BunnyLook(fur: RGB(0xD4C2F2), accent: RGB(0xA78BE0), pattern: .gradient, ears: .lop, traits: [.flowerCrown, .petals]),
              behavior: .float, lure: ["wisteria"],
              description: "Draped in wisteria blossoms that sway as it floats along."),
        Breed(id: "pixelBunny", name: "Pixel", rarity: .rare,
              look: BunnyLook(fur: RGB(0xFFFFFF), accent: RGB(0xF5B8E6), pattern: .speckles, ears: .upright, traits: [.sparkles]),
              behavior: .zoomies, lure: ["pixelBerry"],
              description: "Shimmers in pastel rainbow pixels. Sometimes seems to glitch out of sight."),
        Breed(id: "solsticeBunny", name: "Solstice", rarity: .epic,
              look: BunnyLook(fur: RGB(0x3D3046), accent: RGB(0xF6B65C), pattern: .speckles, ears: .upright, traits: [.flowerCrown, .glow]),
              behavior: .stargaze, lure: ["sunflower"], condition: LureCondition(weather: .sunny, season: .summer),
              description: "Midnight fur with sun-bright flowers. Appears on the sunniest summer days."),
        Breed(id: "eucalyptusBunny", name: "Eucalyptus", rarity: .epic,
              look: BunnyLook(fur: RGB(0x9FA8A0), accent: RGB(0xFFFFFF), pattern: .patches, ears: .upright, traits: [.leafSprout]),
              behavior: .groom, lure: ["eucalyptus"], condition: LureCondition(weather: .cloudy),
              description: "Silvery gray-green with a eucalyptus sprig. Loves cool, cloudy days."),
        Breed(id: "marshmallowBunny", name: "Marshmallow", rarity: .legendary,
              look: BunnyLook(fur: RGB(0xFFFFFF), accent: RGB(0xF5E9FF), pattern: .solid, ears: .upright, traits: [.cloudPuff, .fairyWings]),
              behavior: .flop, lure: ["cotton"], condition: LureCondition(season: .winter),
              description: "The fluffiest bunny in the world, light as a toasted marshmallow. Comes out in winter."),
        Breed(id: "galaxyBunny", name: "Galaxy", rarity: .legendary,
              look: BunnyLook(fur: RGB(0x2E2A6B), accent: RGB(0xC9A8FF), pattern: .speckles, ears: .upright, traits: [.sparkles, .glow]),
              behavior: .stargaze, lure: ["moonflower"], condition: LureCondition(time: .night, weather: .sunny),
              description: "A whole galaxy swirls in its fur. Only appears on clear, starry nights."),
        Breed(id: "seraphBunny", name: "Seraph", rarity: .legendary,
              look: BunnyLook(fur: RGB(0xFFFFFF), accent: RGB(0xFFE7B0), pattern: .solid, ears: .upright, traits: [.moonHalo, .fairyWings, .glow]),
              behavior: .float, lure: ["starlightFlower"], condition: LureCondition(time: .dawn),
              description: "Radiant wings and a golden halo. Descends at dawn for the most devoted gardeners."),
    ]
}
