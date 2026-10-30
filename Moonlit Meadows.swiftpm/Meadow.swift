import Foundation
import Observation

/// A little "+6 🪙" or sparkle that floats over the world for a moment.
struct FloatingBit: Identifiable {
    enum Kind {
        case text
        case sparkle
        case heart
        /// A heart lost: a cracked heart and a red number.
        case crack
    }

    let id = UUID()
    let kind: Kind
    let text: String
    /// Where it starts, in unit coordinates of the world.
    let spot: Spot
    let born: Date
}

/// What happened in the meadow while the app was closed.
struct AwayReport: Identifiable {
    let id = UUID()
    let duration: TimeInterval
    let harvested: [String: Int]
    let readyPlots: Int
    let visitorsArrived: Int
}

/// The whole game. State lives in separate stored properties (rather than one big struct)
/// so SwiftUI only redraws the views that read whatever changed.
///
/// Rules are split by topic into extensions:
/// - `MeadowFarm.swift`: planting, harvesting, kitchen, selling, shop
/// - `MeadowBunnies.swift`: lures, discovery, habitat, collection milestones
/// - `MeadowPeople.swift`: talking, gifts, quests, activities, story chapters
/// - `MeadowRewards.swift`: rewards, achievements, festivals
@Observable
final class Meadow {
    static let startingPlots = 4
    static let maxPlots = 12
    static let maxCanLevel = 5
    static let awayLimit: TimeInterval = 8 * 3600

    // MARK: Saved state

    var coins = 30
    var gems = 3
    var level = 1
    var xp = 0
    var inventory: [String: Int] = [:]
    var plots = Array(repeating: Plot(), count: Meadow.startingPlots)
    var decor: Set<String> = []
    var canLevel = 0

    var lureSlots: [LureSlot] = [LureSlot()]
    var lureLevel = 0
    var lureSlotsBought = 0
    var discovered: [String: Date] = [:]
    var bunnies: [BunnyInstance] = []
    var habitatCapacity = 6
    var habitatUpgradesBought = 0

    var relationships: [String: RelationshipState] = [:]
    var gifts: [GiftRecord] = []

    var learnedRecipes: Set<String> = []
    var outfits: Set<String> = Outfit.starterIDs
    var equippedOutfit = Outfit.defaultID
    /// Picked in the farmer creator at the start of the game.
    var farmerGender: FarmerGender?
    /// 1 (lightest) to 4 (deepest).
    var skinTone = 3
    var hairStyle = 0
    var hairColor = "black"
    var eyeColor = "brown"
    /// The farmer creator is showing (on both screens): at the start of a game, or from
    /// Journal → Wardrobe. Not saved.
    var isCustomizingFarmer = false
    /// The character whose profile fills both screens (from the Friends tab). Not saved.
    var focusedPersonID: String?
    /// What they said when you last chatted in the open profile, and their answer to your reply.
    var profileTalk: TalkResult?
    var profileAnswer: String?
    /// The look being edited in the farmer creator.
    var farmerDraft = FarmerLook(gender: .female)
    var accessories: Set<String> = []
    var equippedAccessory: String?
    var keepsakes: Set<String> = []
    var dateScenesSeen: Set<String> = []
    var hints: Set<String> = []

    var claimedMilestones: Set<Int> = []
    var claimedAchievements: Set<String> = []
    var completedQuests: Set<String> = []
    var festivalCycles: Set<String> = []
    var cropsHarvested: Set<String> = []
    var favoriteBunnyGifts = 0
    var completionSceneSeen = false
    /// The in-game day. Daily things (chatting, gifts, activities) reset when you sleep.
    var dayNumber = 0
    /// The day you started, so the HUD can count "Day 1, Day 2…".
    var firstDay = 0
    /// Seconds of play so far today. The day ends at `dayLength`.
    var dayElapsed: TimeInterval = 0
    @ObservationIgnored var lateWarningDay = Int.min
    /// Items in the storage chest at home.
    var storage: [String: Int] = [:]
    /// You're inside the cottage (both screens show the house). Not saved.
    var isAtHome = false
    /// Sitting at the desk chair at home.
    var isSitting = false
    /// Asleep in bed: the room is dark until morning comes.
    var isSleeping = false
    /// The start screen shows when the app opens. Not saved.
    var isAtMainMenu = true
    /// The pause menu is open: the clock, crops, and every animation stop. Not saved.
    var isPaused = false
    /// The sparkle transition after New Game is showing. Not saved.
    var showsStartSparkle = false
    /// The opening story plays once, right after you make your farmer. Not saved.
    var showsIntro = false
    /// The control deck's open tab, by `PanelTab` raw value.
    var panelTabID = "farm"

    // MARK: Moment-to-moment state (not saved)

    var bits: [FloatingBit] = []
    var now: Date
    /// Bumps on every action, to trigger haptics.
    var feedbackCount = 0
    var selectedSeed = "carrot"
    var awayReport: AwayReport?
    /// The last change to someone's hearts, for the cracked-heart (or growing-heart) pop.
    var heartChange: HeartChange?
    /// A line to say aloud outside the chat screen (a gift reaction in a toast, say).
    var voiceCue: VoiceCue?
    /// A bunny that just visited, shown with the discovery animation.
    var pendingVisit: VisitOutcome?
    /// A story scene waiting to be shown.
    var presentedScene: ScenePresentation?
    /// A short message for the player, like "Bunny gifted to June".
    var toast: String?

    let store: SaveStore
    @ObservationIgnored var rng: SeededGenerator
    @ObservationIgnored var lastTick: Date
    @ObservationIgnored var lastSave: Date
    @ObservationIgnored var lastSeen: Date
    @ObservationIgnored var helperTimer: TimeInterval = 0

    init(store: SaveStore = UserDefaultsStore(), now: Date = Date(), seed: UInt64 = UInt64.random(in: 1...UInt64.max)) {
        self.store = store
        self.now = now
        rng = SeededGenerator(seed: seed)
        lastTick = now
        lastSave = now
        lastSeen = now
        load()
        prepareNewContent()
    }

    // MARK: Derived values

    var weather: Weather { Weather.at(now) }
    /// Dawn, day, dusk, or night on the in-game clock.
    var timeOfDay: TimeOfDay { TimeOfDay.at(hour: Int(clockHour)) }
    var season: Season { Season.at(now) }
    var today: Int { dayNumber }

    var xpToNextLevel: Int { 10 * level + 5 * level * level }

    var coziness: Int {
        Decor.all.filter { decor.contains($0.id) }.reduce(0) { $0 + $1.coziness }
    }

    func count(of itemID: String) -> Int {
        inventory[itemID, default: 0]
    }

    // MARK: Time

    /// Called several times a second while the app is open.
    func tick(at date: Date = Date()) {
        // Longer gaps (the app was in the background) are handled by `welcomeBack`.
        let delta = min(max(date.timeIntervalSince(lastTick), 0), 1)
        lastTick = date
        now = date
        guard !isAtMainMenu && !isPaused && !showsIntro else { return }

        advanceClock(by: delta)
        growCrops(bySeconds: delta * growthMultiplier)
        runHelpers(delta)
        advanceLures(bySeconds: delta)

        if bits.contains(where: { date.timeIntervalSince($0.born) > 1.8 }) {
            bits.removeAll { date.timeIntervalSince($0.born) > 1.8 }
        }
        if date.timeIntervalSince(lastSave) > 5 {
            save()
        }
    }

    /// Called when the app comes to the foreground: crops kept growing, helper bunnies kept
    /// harvesting (with their own seeds), and lure visitors kept walking over. Capped at 8 hours.
    func welcomeBack(at date: Date = Date()) {
        let away = min(max(date.timeIntervalSince(lastSeen), 0), Self.awayLimit)
        lastTick = date
        lastSeen = date
        now = date
        guard away > 60 else { return }
        // Away for a long while: you slept, and it's a fresh morning.
        if away > 3600 && dayElapsed > 0 {
            startNewDay()
        }

        let harvested = catchUpCrops(seconds: away)
        let arrivedBefore = lureSlots.filter(\.hasArrived).count
        advanceLures(bySeconds: away)
        let arrived = lureSlots.filter(\.hasArrived).count - arrivedBefore

        awayReport = AwayReport(
            duration: away,
            harvested: harvested,
            readyPlots: plots.filter(\.isReady).count,
            visitorsArrived: max(arrived, 0)
        )
        save()
    }

    // MARK: Saving

    func makeSaveData() -> SaveData {
        var data = SaveData()
        data.coins = coins
        data.gems = gems
        data.level = level
        data.xp = xp
        data.inventory = inventory
        data.plots = plots
        data.decor = decor.sorted()
        data.canLevel = canLevel
        data.lastSeen = lastSeen
        data.lureSlots = lureSlots
        data.lureLevel = lureLevel
        data.lureSlotsBought = lureSlotsBought
        data.discovered = discovered
        data.bunnies = bunnies
        data.habitatCapacity = habitatCapacity
        data.habitatUpgradesBought = habitatUpgradesBought
        data.relationships = relationships
        data.gifts = gifts
        data.learnedRecipes = learnedRecipes.sorted()
        data.outfits = outfits.sorted()
        data.equippedOutfit = equippedOutfit
        data.farmerGender = farmerGender?.rawValue
        data.skinTone = skinTone
        data.hairStyle = hairStyle
        data.hairColor = hairColor
        data.eyeColor = eyeColor
        data.accessories = accessories.sorted()
        data.equippedAccessory = equippedAccessory
        data.keepsakes = keepsakes.sorted()
        data.dateScenesSeen = dateScenesSeen.sorted()
        data.hints = hints.sorted()
        data.claimedMilestones = claimedMilestones.sorted()
        data.claimedAchievements = claimedAchievements.sorted()
        data.completedQuests = completedQuests.sorted()
        data.festivalCycles = festivalCycles.sorted()
        data.cropsHarvested = cropsHarvested.sorted()
        data.favoriteBunnyGifts = favoriteBunnyGifts
        data.completionSceneSeen = completionSceneSeen
        data.dayNumber = dayNumber
        data.firstDay = firstDay
        data.dayElapsed = dayElapsed
        data.storage = storage
        return data
    }

    func save() {
        lastSave = now
        lastSeen = now
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .secondsSince1970
        if let encoded = try? encoder.encode(makeSaveData()) {
            store.write(encoded)
        }
    }

    private func load() {
        guard let encoded = store.read() else { return }
        let decoder = JSONDecoder()
        // Bunny Meadows v1 used the default date format; v2 uses seconds since 1970.
        decoder.dateDecodingStrategy = .secondsSince1970
        let data: SaveData
        if let decoded = try? decoder.decode(SaveData.self, from: encoded), decoded.version >= 2 {
            data = decoded
        } else if let legacy = try? JSONDecoder().decode(SaveData.self, from: encoded) {
            data = legacy
        } else {
            return
        }
        apply(data)
    }

    /// Whether there's a saved game to load from the main menu.
    var hasSavedGame: Bool { farmerGender != nil || store.read() != nil }

    /// Starts over with a brand-new farm (the farmer creator opens next).
    func resetGame() {
        apply(SaveData())
        prepareNewContent()
        showsIntro = false
        isAtHome = false
        isSitting = false
        isSleeping = false
        isCustomizingFarmer = false
        focusedPersonID = nil
        presentedScene = nil
        pendingVisit = nil
        awayReport = nil
        panelTabID = PanelTab.farm.rawValue
        bits = []
        save()
    }

    private func apply(_ data: SaveData) {
        coins = data.coins
        gems = data.gems
        level = data.level
        xp = data.xp
        inventory = data.inventory.filter { $0.value > 0 && ItemInfo.exists($0.key) }
        plots = data.plots.isEmpty ? Array(repeating: Plot(), count: Self.startingPlots) : data.plots
        decor = Set(data.decor)
        canLevel = data.canLevel
        lastSeen = data.lastSeen
        lureSlots = data.lureSlots.isEmpty ? [LureSlot()] : data.lureSlots
        lureLevel = data.lureLevel
        lureSlotsBought = data.lureSlotsBought
        discovered = data.discovered.filter { Breed.find($0.key) != nil }
        bunnies = data.bunnies.filter { Breed.find($0.breedID) != nil }
        habitatCapacity = data.habitatCapacity
        habitatUpgradesBought = data.habitatUpgradesBought
        relationships = data.relationships
        gifts = data.gifts
        learnedRecipes = Set(data.learnedRecipes)
        outfits = Set(data.outfits).union(Outfit.starterIDs)
        equippedOutfit = outfits.contains(data.equippedOutfit) ? data.equippedOutfit : Outfit.defaultID
        farmerGender = data.farmerGender.flatMap(FarmerGender.init(rawValue:))
        skinTone = FarmerGender.skinTones.contains(data.skinTone) ? data.skinTone : 3
        hairStyle = data.hairStyle
        hairColor = data.hairColor
        eyeColor = data.eyeColor
        if let look = farmerLook?.validated() {
            hairStyle = look.hairStyle
            hairColor = look.hairColor
            eyeColor = look.eyeColor
        }
        accessories = Set(data.accessories)
        equippedAccessory = data.equippedAccessory.flatMap { accessories.contains($0) ? $0 : nil }
        keepsakes = Set(data.keepsakes)
        dateScenesSeen = Set(data.dateScenesSeen)
        hints = Set(data.hints)
        claimedMilestones = Set(data.claimedMilestones)
        claimedAchievements = Set(data.claimedAchievements)
        completedQuests = Set(data.completedQuests)
        festivalCycles = Set(data.festivalCycles)
        cropsHarvested = Set(data.cropsHarvested)
        favoriteBunnyGifts = data.favoriteBunnyGifts
        completionSceneSeen = data.completionSceneSeen
        // Older saves start counting days from today.
        dayNumber = data.dayNumber ?? GameDay.index(now)
        firstDay = data.firstDay ?? dayNumber
        dayElapsed = min(max(data.dayElapsed, 0), Self.dayLength)
        storage = data.storage.filter { ItemInfo.exists($0.key) && $0.value > 0 }
    }

    /// Fills in anything new: the two starter breeds and a relationship for every character.
    private func prepareNewContent() {
        if !Breed.starterIDs.allSatisfy({ discovered[$0] != nil }) {
            let names = ["cloverBunny": "Lucky", "snowflakeBunny": "Snowy"]
            for id in Breed.starterIDs where discovered[id] == nil {
                discovered[id] = now
                if !bunnies.contains(where: { $0.breedID == id }) {
                    bunnies.append(BunnyInstance(id: UUID(), breedID: id, name: names[id] ?? "Bunny", adoptedAt: now))
                }
            }
        }
        for person in Person.all where relationships[person.id] == nil {
            relationships[person.id] = RelationshipState()
        }
        if let crop = Crop.find(selectedSeed), crop.unlockLevel > level {
            selectedSeed = "carrot"
        }
    }

    // MARK: Helpers shared by the extensions

    func addItems(_ itemID: String, _ amount: Int) {
        guard amount > 0 else { return }
        inventory[itemID, default: 0] += amount
    }

    /// Removes items only if there are enough. Returns whether it succeeded.
    @discardableResult
    func removeItems(_ itemID: String, _ amount: Int) -> Bool {
        guard amount > 0, count(of: itemID) >= amount else { return false }
        inventory[itemID, default: 0] -= amount
        if inventory[itemID] == 0 { inventory[itemID] = nil }
        return true
    }

    func gainXP(_ amount: Int) {
        xp += amount
        while xp >= xpToNextLevel {
            xp -= xpToNextLevel
            level += 1
            gems += 2
            let newCrops = Crop.all.filter { $0.unlockLevel == level }.map(\.emoji).joined()
            spawn(.sparkle, newCrops.isEmpty ? "🎉 Level \(level)!" : "🎉 Level \(level)! New seeds \(newCrops)",
                  at: Spot(x: 0.5, y: 0.35))
        }
    }

    func spawn(_ kind: FloatingBit.Kind, _ text: String, at spot: Spot) {
        bits.append(FloatingBit(kind: kind, text: text, spot: spot, born: now))
    }

    func showToast(_ text: String) {
        toast = text
    }
}
