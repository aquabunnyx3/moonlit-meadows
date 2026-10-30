import Foundation

// MARK: - Persisted pieces

/// One patch of soil on the farm.
struct Plot: Codable, Equatable {
    var cropID: String?
    /// `0...1`; the crop is ready to harvest at `1`.
    var progress: Double = 0

    var isReady: Bool { cropID != nil && progress >= 1 }
}

/// A lure basket in the bunny garden. The visitor is decided when the lure is placed,
/// so the player always knows a bunny is coming.
struct LureSlot: Codable, Equatable {
    var items: [String] = []
    var visitorBreedID: String?
    /// `0...1`; the visitor has arrived at `1`.
    var progress: Double = 0

    var isEmpty: Bool { visitorBreedID == nil }
    var hasArrived: Bool { visitorBreedID != nil && progress >= 1 }
}

/// A bunny you own. Separate from the permanent discovery record: gifting a bunny
/// removes the instance but never "undiscovers" its breed.
struct BunnyInstance: Codable, Identifiable, Equatable {
    var id: UUID
    var breedID: String
    var name: String
    var isFavorite = false
    var adoptedAt: Date
    var lastPettedDay: Int?
}

struct GiftRecord: Codable, Identifiable, Equatable {
    enum Reaction: String, Codable {
        case favorite, loved, liked, neutral, disliked
    }

    var id: UUID
    var personID: String
    var itemID: String?
    var bunnyID: UUID?
    var breedID: String?
    var bunnyName: String?
    var reaction: Reaction
    var date: Date
}

/// A moment worth remembering, shown in each character's memory book.
struct Memory: Codable, Equatable {
    var text: String
    var date: Date
}

struct RelationshipState: Codable, Equatable {
    var points = 0
    var path: RelationshipPath = .undecided
    var lastTalkDay: Int?
    var lastGiftDay: Int?
    var lastBunnyGiftDay: Int?
    var lastActivityDay: Int?
    var seenEvents: [String] = []
    /// Story event or question ID → index of the option chosen.
    var choices: [String: Int] = [:]
    var shownBreeds: [String] = []
    var revealedFavorites: [String] = []
    var memories: [Memory] = []
    var hasHadFirstDate = false
    /// How they feel about you right now, in hearts (0–10). `nil` is the starting warmth.
    /// Only disliked gifts and rude answers lower it, and it never decays on its own.
    var warmth: Int?
    var lastApologyDay: Int?
}

// MARK: - Save file

/// Everything that's saved. Decoding is tolerant: missing keys fall back to defaults,
/// so older saves (including Bunny Meadows v1) load without losing progress.
struct SaveData: Codable, Equatable {
    var version = 2
    var coins = 30
    var gems = 3
    var level = 1
    var xp = 0
    var inventory: [String: Int] = [:]
    var plots: [Plot] = Array(repeating: Plot(), count: 4)
    var decor: [String] = []
    var canLevel = 0
    var lastSeen = Date()

    var lureSlots: [LureSlot] = [LureSlot()]
    var lureLevel = 0
    var lureSlotsBought = 0
    /// Breed ID → when it was first discovered. Never shrinks.
    var discovered: [String: Date] = [:]
    var bunnies: [BunnyInstance] = []
    var habitatCapacity = 6
    var habitatUpgradesBought = 0

    var relationships: [String: RelationshipState] = [:]
    var gifts: [GiftRecord] = []

    var learnedRecipes: [String] = []
    var outfits: [String] = Outfit.starterIDs.sorted()
    var equippedOutfit = Outfit.defaultID
    /// Chosen when the game starts. `nil` in older saves, which shows the farmer creator.
    var farmerGender: String?
    var skinTone = 3
    var hairStyle = 0
    var hairColor = "black"
    var eyeColor = "brown"
    var accessories: [String] = []
    var equippedAccessory: String?
    var keepsakes: [String] = []
    var dateScenesSeen: [String] = []
    var hints: [String] = []

    var claimedMilestones: [Int] = []
    var claimedAchievements: [String] = []
    var completedQuests: [String] = []
    var festivalCycles: [String] = []
    var cropsHarvested: [String] = []
    var favoriteBunnyGifts = 0
    var completionSceneSeen = false
    /// The in-game day, and how many seconds of it you've played. `nil` in older saves.
    var dayNumber: Int?
    var firstDay: Int?
    var dayElapsed: Double = 0
    /// Items kept in the storage chest at home.
    var storage: [String: Int] = [:]
    /// Whether the post-intro "Let's get started" card has been dismissed.
    var introWelcomeSeen = false
    /// Where the new-farmer Tour stands (a `TourStep` raw value).
    var tourStep = "notStarted"
    /// Tutorial Moments already shown (ids). Never repeats.
    var momentsSeen: [String] = []
    /// The First Sale quest is waiting for its first crop sale.
    var firstSalePending = false

    init() {}

    private enum CodingKeys: String, CodingKey {
        case version, coins, gems, level, xp, inventory, plots, decor, canLevel, lastSeen
        case lureSlots, lureLevel, lureSlotsBought, discovered, bunnies, habitatCapacity, habitatUpgradesBought
        case relationships, gifts
        case learnedRecipes, outfits, equippedOutfit, farmerGender, skinTone, hairStyle, hairColor, eyeColor, accessories, equippedAccessory, keepsakes, dateScenesSeen, hints
        case claimedMilestones, claimedAchievements, completedQuests, festivalCycles, cropsHarvested
        case favoriteBunnyGifts, completionSceneSeen, dayNumber, firstDay, dayElapsed, storage, introWelcomeSeen, tourStep, momentsSeen, firstSalePending
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = SaveData()
        version = try c.decodeIfPresent(Int.self, forKey: .version) ?? 1
        coins = try c.decodeIfPresent(Int.self, forKey: .coins) ?? d.coins
        gems = try c.decodeIfPresent(Int.self, forKey: .gems) ?? d.gems
        level = try c.decodeIfPresent(Int.self, forKey: .level) ?? d.level
        xp = try c.decodeIfPresent(Int.self, forKey: .xp) ?? d.xp
        inventory = try c.decodeIfPresent([String: Int].self, forKey: .inventory) ?? d.inventory
        plots = try c.decodeIfPresent([Plot].self, forKey: .plots) ?? d.plots
        decor = try c.decodeIfPresent([String].self, forKey: .decor) ?? d.decor
        canLevel = try c.decodeIfPresent(Int.self, forKey: .canLevel) ?? d.canLevel
        lastSeen = try c.decodeIfPresent(Date.self, forKey: .lastSeen) ?? d.lastSeen

        lureSlots = try c.decodeIfPresent([LureSlot].self, forKey: .lureSlots) ?? d.lureSlots
        lureLevel = try c.decodeIfPresent(Int.self, forKey: .lureLevel) ?? d.lureLevel
        lureSlotsBought = try c.decodeIfPresent(Int.self, forKey: .lureSlotsBought) ?? d.lureSlotsBought
        discovered = try c.decodeIfPresent([String: Date].self, forKey: .discovered) ?? d.discovered
        bunnies = try c.decodeIfPresent([BunnyInstance].self, forKey: .bunnies) ?? d.bunnies
        habitatCapacity = try c.decodeIfPresent(Int.self, forKey: .habitatCapacity) ?? d.habitatCapacity
        habitatUpgradesBought = try c.decodeIfPresent(Int.self, forKey: .habitatUpgradesBought) ?? d.habitatUpgradesBought

        relationships = try c.decodeIfPresent([String: RelationshipState].self, forKey: .relationships) ?? d.relationships
        gifts = try c.decodeIfPresent([GiftRecord].self, forKey: .gifts) ?? d.gifts

        learnedRecipes = try c.decodeIfPresent([String].self, forKey: .learnedRecipes) ?? d.learnedRecipes
        outfits = try c.decodeIfPresent([String].self, forKey: .outfits) ?? d.outfits
        equippedOutfit = try c.decodeIfPresent(String.self, forKey: .equippedOutfit) ?? d.equippedOutfit
        farmerGender = try c.decodeIfPresent(String.self, forKey: .farmerGender)
        skinTone = try c.decodeIfPresent(Int.self, forKey: .skinTone) ?? d.skinTone
        hairStyle = try c.decodeIfPresent(Int.self, forKey: .hairStyle) ?? d.hairStyle
        hairColor = try c.decodeIfPresent(String.self, forKey: .hairColor) ?? d.hairColor
        eyeColor = try c.decodeIfPresent(String.self, forKey: .eyeColor) ?? d.eyeColor
        accessories = try c.decodeIfPresent([String].self, forKey: .accessories) ?? d.accessories
        equippedAccessory = try c.decodeIfPresent(String.self, forKey: .equippedAccessory)
        keepsakes = try c.decodeIfPresent([String].self, forKey: .keepsakes) ?? d.keepsakes
        dateScenesSeen = try c.decodeIfPresent([String].self, forKey: .dateScenesSeen) ?? d.dateScenesSeen
        hints = try c.decodeIfPresent([String].self, forKey: .hints) ?? d.hints

        claimedMilestones = try c.decodeIfPresent([Int].self, forKey: .claimedMilestones) ?? d.claimedMilestones
        claimedAchievements = try c.decodeIfPresent([String].self, forKey: .claimedAchievements) ?? d.claimedAchievements
        completedQuests = try c.decodeIfPresent([String].self, forKey: .completedQuests) ?? d.completedQuests
        festivalCycles = try c.decodeIfPresent([String].self, forKey: .festivalCycles) ?? d.festivalCycles
        cropsHarvested = try c.decodeIfPresent([String].self, forKey: .cropsHarvested) ?? d.cropsHarvested
        favoriteBunnyGifts = try c.decodeIfPresent(Int.self, forKey: .favoriteBunnyGifts) ?? d.favoriteBunnyGifts
        completionSceneSeen = try c.decodeIfPresent(Bool.self, forKey: .completionSceneSeen) ?? d.completionSceneSeen
        dayNumber = try c.decodeIfPresent(Int.self, forKey: .dayNumber)
        firstDay = try c.decodeIfPresent(Int.self, forKey: .firstDay)
        dayElapsed = try c.decodeIfPresent(Double.self, forKey: .dayElapsed) ?? d.dayElapsed
        storage = try c.decodeIfPresent([String: Int].self, forKey: .storage) ?? d.storage
        introWelcomeSeen = try c.decodeIfPresent(Bool.self, forKey: .introWelcomeSeen) ?? d.introWelcomeSeen
        tourStep = try c.decodeIfPresent(String.self, forKey: .tourStep) ?? d.tourStep
        momentsSeen = try c.decodeIfPresent([String].self, forKey: .momentsSeen) ?? d.momentsSeen
        firstSalePending = try c.decodeIfPresent(Bool.self, forKey: .firstSalePending) ?? d.firstSalePending
    }
}

// MARK: - Storage

/// Where the game is saved. The app uses `UserDefaults`; the self-tests use memory.
protocol SaveStore: AnyObject {
    func read() -> Data?
    func write(_ data: Data)
}

final class UserDefaultsStore: SaveStore {
    static let key = "moonlitMeadows.save.v2"
    /// Bunny Meadows saves are picked up and upgraded automatically.
    static let legacyKey = "bunnyMeadows.save.v1"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func read() -> Data? {
        defaults.data(forKey: Self.key) ?? defaults.data(forKey: Self.legacyKey)
    }

    func write(_ data: Data) {
        defaults.set(data, forKey: Self.key)
    }
}

final class MemoryStore: SaveStore {
    var data: Data?

    init(data: Data? = nil) {
        self.data = data
    }

    func read() -> Data? { data }

    func write(_ data: Data) {
        self.data = data
    }
}
