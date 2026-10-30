import Foundation

/// Farming, the kitchen, selling, and the shop. This is the original Bunny Meadows farm loop,
/// kept intact and extended with more crops and upgrades.
extension Meadow {
    static let growAllGemCost = 2
    static let maxLureLevel = 3
    static let maxLureSlotsBought = 1
    static let maxHabitatUpgrades = 3

    // MARK: Derived

    /// Crops grow faster with a better watering can and in the rain.
    var growthMultiplier: Double {
        (1 + 0.15 * Double(canLevel)) * weather.growthBonus
    }

    /// Every 3 bunnies in your habitat lend a paw on the farm (up to 5 helpers).
    var helperCount: Int {
        min(bunnies.count / 3, 5)
    }

    func salePrice(of itemID: String) -> Int {
        Int((Double(ItemInfo.basePrice(itemID)) * (1 + Double(coziness) / 100)).rounded())
    }

    func isUnlocked(_ crop: Crop) -> Bool { level >= crop.unlockLevel }

    func isUnlocked(_ recipe: Recipe) -> Bool {
        if recipe.taughtBy != nil && !learnedRecipes.contains(recipe.id) {
            return false
        }
        return level >= recipe.unlockLevel
    }

    func canCraft(_ recipe: Recipe) -> Bool {
        isUnlocked(recipe) && recipe.ingredients.allSatisfy { count(of: $0.itemID) >= $0.count }
    }

    var readyPlotCount: Int {
        plots.filter(\.isReady).count
    }

    func secondsLeft(on plot: Plot) -> TimeInterval? {
        guard let id = plot.cropID, let crop = Crop.find(id), plot.progress < 1 else { return nil }
        return (1 - plot.progress) * crop.growSeconds / growthMultiplier
    }

    var nextPlotCost: Int? {
        guard plots.count < Self.maxPlots else { return nil }
        return 60 * Int(pow(2.2, Double(plots.count - Self.startingPlots)))
    }

    var nextCanCost: Int? {
        guard canLevel < Self.maxCanLevel else { return nil }
        return 100 * Int(pow(3.5, Double(canLevel)))
    }

    var nextLureUpgradeCost: Int? {
        guard lureLevel < Self.maxLureLevel else { return nil }
        return 250 * Int(pow(4, Double(lureLevel)))
    }

    var nextLureSlotCost: Int? {
        guard lureSlotsBought < Self.maxLureSlotsBought else { return nil }
        return 2_500
    }

    var nextHabitatCost: Int? {
        guard habitatUpgradesBought < Self.maxHabitatUpgrades else { return nil }
        return 400 * Int(pow(3, Double(habitatUpgradesBought)))
    }

    // MARK: Farm actions

    /// Plants the selected seed in an empty plot, or harvests a ready one.
    func tapPlot(_ index: Int) {
        guard plots.indices.contains(index) else { return }
        if plots[index].isReady {
            harvest(index, replant: false)
        } else if plots[index].cropID == nil {
            plant(selectedSeed, in: index)
        }
    }

    /// Harvests every ready plot and replants the same crop where you can afford it,
    /// then fills empty plots with the selected seed.
    func harvestAndReplantAll() {
        for index in plots.indices where plots[index].isReady {
            harvest(index, replant: true)
        }
        for index in plots.indices where plots[index].cropID == nil {
            plant(selectedSeed, in: index, quietly: true)
        }
    }

    func growAllWithGems() {
        guard gems >= Self.growAllGemCost, plots.contains(where: { $0.cropID != nil && $0.progress < 1 }) else { return }
        gems -= Self.growAllGemCost
        for index in plots.indices where plots[index].cropID != nil {
            plots[index].progress = 1
        }
        spawn(.sparkle, "✨ Grow! ✨", at: Spot(x: 0.23, y: 0.6))
        feedbackCount += 1
    }

    func plant(_ cropID: String, in index: Int, quietly: Bool = false) {
        guard plots.indices.contains(index), let crop = Crop.find(cropID), isUnlocked(crop),
              coins >= crop.seedCost, plots[index].cropID == nil else { return }
        coins -= crop.seedCost
        plots[index] = Plot(cropID: cropID, progress: 0)
        if !quietly {
            spawn(.text, "🌱", at: plotSpot(index))
            feedbackCount += 1
        }
    }

    func harvest(_ index: Int, replant: Bool, byHelper: Bool = false) {
        guard plots.indices.contains(index), plots[index].isReady,
              let id = plots[index].cropID, let crop = Crop.find(id) else { return }
        addItems(id, 1)
        cropsHarvested.insert(id)
        gainXP(crop.xp)
        spawn(.text, byHelper ? "🐾 +1 \(crop.emoji)" : "+1 \(crop.emoji)", at: plotSpot(index))
        if replant && (byHelper || coins >= crop.seedCost) {
            if !byHelper { coins -= crop.seedCost }
            plots[index] = Plot(cropID: id, progress: 0)
        } else {
            plots[index] = Plot()
        }
        if !byHelper { feedbackCount += 1 }
    }

    func growCrops(bySeconds effectiveSeconds: TimeInterval) {
        for index in plots.indices {
            guard let id = plots[index].cropID, let crop = Crop.find(id), plots[index].progress < 1 else { continue }
            plots[index].progress = min(plots[index].progress + effectiveSeconds / crop.growSeconds, 1)
        }
    }

    func runHelpers(_ delta: TimeInterval) {
        guard helperCount > 0 else { return }
        helperTimer += delta
        if helperTimer >= 8 / Double(helperCount) {
            helperTimer = 0
            if let index = plots.firstIndex(where: { $0.isReady }) {
                harvest(index, replant: true, byHelper: true)
            }
        }
    }

    /// Offline growth. With helpers, ready crops are harvested and replanted as many times as fit.
    /// Returns what the helpers harvested.
    func catchUpCrops(seconds: TimeInterval) -> [String: Int] {
        let effective = seconds * (1 + 0.15 * Double(canLevel))
        var harvested: [String: Int] = [:]
        for index in plots.indices {
            guard let id = plots[index].cropID, let crop = Crop.find(id) else { continue }
            let total = plots[index].progress + effective / crop.growSeconds
            if helperCount > 0 && total >= 1 {
                let cycles = Int(total)
                harvested[id, default: 0] += cycles
                addItems(id, cycles)
                cropsHarvested.insert(id)
                gainXP(crop.xp * cycles)
                plots[index].progress = total - Double(cycles)
            } else {
                plots[index].progress = min(total, 1)
            }
        }
        return harvested
    }

    /// Roughly where a plot appears in the world, for floating text.
    func plotSpot(_ index: Int) -> Spot {
        let spot = WorldLayout.plot(index)
        return Spot(x: spot.x, y: spot.y - 0.04)
    }

    // MARK: Kitchen & selling

    func craft(_ recipe: Recipe) {
        guard canCraft(recipe) else { return }
        for ingredient in recipe.ingredients {
            removeItems(ingredient.itemID, ingredient.count)
        }
        addItems(recipe.id, 1)
        gainXP(recipe.xp)
        spawn(.sparkle, "✨ \(recipe.emoji)", at: WorldLayout.cottageDoor)
        feedbackCount += 1
    }

    func sell(_ itemID: String, count amount: Int) {
        let amount = min(amount, count(of: itemID))
        guard amount > 0, removeItems(itemID, amount) else { return }
        let earned = salePrice(of: itemID) * amount
        coins += earned
        spawn(.text, "+\(earned.cozy) 🪙", at: WorldLayout.cottageDoor)
        feedbackCount += 1
    }

    // MARK: Shop

    func buy(_ item: Decor) {
        guard item.isShopItem, !decor.contains(item.id), level >= item.unlockLevel else { return }
        switch item.currency {
        case .coins:
            guard coins >= item.price else { return }
            coins -= item.price
        case .gems:
            guard gems >= item.price else { return }
            gems -= item.price
        }
        decor.insert(item.id)
        spawn(.sparkle, "✨ \(item.emoji) ✨", at: item.spot)
        feedbackCount += 1
        save()
    }

    func buyPlot() {
        guard let cost = nextPlotCost, coins >= cost else { return }
        coins -= cost
        plots.append(Plot())
        spawn(.sparkle, "✨ New plot!", at: plotSpot(plots.count - 1))
        feedbackCount += 1
        save()
    }

    func upgradeCan() {
        guard let cost = nextCanCost, coins >= cost else { return }
        coins -= cost
        canLevel += 1
        spawn(.sparkle, "💧 Faster growing!", at: Spot(x: 0.23, y: 0.6))
        feedbackCount += 1
        save()
    }

    func upgradeLures() {
        guard let cost = nextLureUpgradeCost, coins >= cost else { return }
        coins -= cost
        lureLevel += 1
        spawn(.sparkle, "🏮 Bunnies come faster!", at: WorldLayout.lureBasket)
        feedbackCount += 1
        save()
    }

    func buyLureSlot() {
        guard let cost = nextLureSlotCost, coins >= cost else { return }
        coins -= cost
        lureSlotsBought += 1
        lureSlots.append(LureSlot())
        spawn(.sparkle, "🧺 New lure basket!", at: WorldLayout.lureBasket)
        feedbackCount += 1
        save()
    }

    func expandHabitat() {
        guard let cost = nextHabitatCost, coins >= cost else { return }
        coins -= cost
        habitatUpgradesBought += 1
        habitatCapacity += 4
        spawn(.sparkle, "🏡 Bigger habitat!", at: WorldLayout.habitatCenter)
        feedbackCount += 1
        save()
    }

    /// Your farmer's saved look, or `nil` before the farmer creator has been finished.
    var farmerLook: FarmerLook? {
        farmerGender.map {
            FarmerLook(gender: $0, hairStyle: hairStyle, skinTone: skinTone,
                       hairColor: hairColor, eyeColor: eyeColor, outfit: equippedOutfit)
        }
    }

    /// The farmer creator shows at the start of a game and whenever it's opened from the Journal.
    var showsFarmerCreator: Bool { farmerGender == nil || isCustomizingFarmer }

    // MARK: Day cycle

    /// Real seconds of play in one in-game day (6:00 AM to midnight).
    static let dayLength: TimeInterval = 15 * 60
    static let dayStartHour = 6.0
    static let dayEndHour = 24.0

    /// The in-game time, in hours (6.0 = 6:00 AM, 23.5 = 11:30 PM).
    var clockHour: Double {
        Self.dayStartHour + (Self.dayEndHour - Self.dayStartHour) * min(dayElapsed / Self.dayLength, 1)
    }

    /// Like "9:40 PM", in 10-minute steps so it doesn't flicker.
    var clockText: String {
        let minutes = Int(clockHour * 60) / 10 * 10
        let hour24 = (minutes / 60) % 24
        let hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12
        return String(format: "%d:%02d %@", hour12, minutes % 60, hour24 < 12 ? "AM" : "PM")
    }

    /// Day 1 is the day you started.
    var dayCount: Int { dayNumber - firstDay + 1 }

    /// The clock has run out, and your farmer is ready for bed.
    var isBedtime: Bool { dayElapsed >= Self.dayLength }

    /// The clock pauses while you read a story, make your farmer, or say goodnight.
    var isClockPaused: Bool { isBedtime || isSleeping || presentedScene != nil || showsFarmerCreator || showsIntro }

    func advanceClock(by seconds: TimeInterval) {
        guard !isClockPaused, seconds > 0 else { return }
        dayElapsed = min(dayElapsed + seconds, Self.dayLength)
        if clockHour >= 22, lateWarningDay != dayNumber {
            lateWarningDay = dayNumber
            showToast("🌙 It's getting late… bedtime is at midnight.")
        }
        if isBedtime {
            // Close anything that would sit on top of the goodnight scene.
            closeProfile()
            isSitting = false
            save()
        }
    }

    /// Goes to bed: the room goes dark, and `wakeUp` starts the next morning.
    func goToBed() {
        closeProfile()
        town = nil
        heldHome = []
        isAtHome = true
        isSitting = false
        isSleeping = true
        feedbackCount += 1
    }

    /// Morning: a new day starts, and daily chats, gifts, and activities reset.
    func wakeUp() {
        isSleeping = false
        // Up and out of bed, standing beside it.
        homeSpot = Spot(x: 0.42, y: 0.68)
        farmerFacing = .front
        deckFacing = DeckVector(x: 0, y: 1)
        sleep()
    }

    /// Starts the next day right away (used by `wakeUp`, and by tests).
    func sleep() {
        startNewDay()
        feedbackCount += 1
        showToast(isFestivalDay ? "🎉 Good morning! Today is the \(Festival.current(at: now).name)!" : "☀️ Good morning! Day \(dayCount)")
        save()
    }

    /// Ends the day early from the bed at home.
    func restForTheNight() {
        dayElapsed = Self.dayLength
        save()
    }

    // MARK: Home

    func enterHome() {
        closeProfile()
        isAtHome = true
        isSitting = false
        panelTabID = PanelTab.farm.rawValue
        homeSpot = Self.homeEntrance
        farmerFacing = .back
        deckFacing = DeckVector(x: 0, y: -1)
        deckDirection = .zero
    }

    func leaveHome(toTab tabID: String? = nil) {
        guard !isSleeping else { return }
        isAtHome = false
        isSitting = false
        deckDirection = .zero
        // Back out the front door, facing the farm.
        farmerSpot = Self.cottageDoorstep
        farmerFacing = .front
        deckFacing = DeckVector(x: 0, y: 1)
        panelTabID = tabID ?? PanelTab.farm.rawValue
    }

    func toggleSitting() {
        isSitting.toggle()
        feedbackCount += 1
        if isSitting { showToast("🪑 You sit down and put your feet up for a bit.") }
    }

    func count(inStorage itemID: String) -> Int { storage[itemID, default: 0] }

    /// Moves a whole stack from your backpack into the chest.
    func putInStorage(_ itemID: String) {
        let amount = count(of: itemID)
        guard amount > 0, removeItems(itemID, amount) else { return }
        storage[itemID, default: 0] += amount
        feedbackCount += 1
        save()
    }

    /// Moves a whole stack from the chest back into your backpack.
    func takeFromStorage(_ itemID: String) {
        let amount = count(inStorage: itemID)
        guard amount > 0 else { return }
        storage[itemID] = nil
        addItems(itemID, amount)
        feedbackCount += 1
        save()
    }

    func startNewDay() {
        dayNumber += 1
        dayElapsed = 0
    }

    /// Sets the clock to the same time of day as `date` (for tests). Hours before 5 AM count
    /// as late night, since the in-game day runs from 6 AM to midnight.
    func setClock(toMatch date: Date, calendar: Calendar = .current) {
        var hour = Double(calendar.component(.hour, from: date)) + 0.5
        if hour < 5 { hour = 23.5 } else if hour < Self.dayStartHour { hour = Self.dayStartHour + 0.5 }
        dayElapsed = (hour - Self.dayStartHour) / (Self.dayEndHour - Self.dayStartHour) * Self.dayLength
    }

    /// Opens a character's profile across both screens.
    func openProfile(_ personID: String) {
        focusedPersonID = personID
        profileTalk = nil
        profileAnswer = nil
    }

    func closeProfile() {
        focusedPersonID = nil
        profileTalk = nil
        profileAnswer = nil
    }

    /// Opens the farmer creator with your current look.
    func beginCustomizingFarmer() {
        farmerDraft = farmerLook ?? FarmerLook(gender: .female)
        isCustomizingFarmer = true
    }

    /// Saves a look (from the creator) and closes the creator.
    func setFarmer(_ look: FarmerLook) {
        let look = look.validated()
        // "Start farming" on a brand-new farmer plays the opening story.
        if farmerGender == nil { showsIntro = true }
        farmerGender = look.gender
        skinTone = look.skinTone
        hairStyle = look.hairStyle
        hairColor = look.hairColor
        eyeColor = look.eyeColor
        if outfits.contains(look.outfit) { equippedOutfit = look.outfit }
        isCustomizingFarmer = false
        feedbackCount += 1
        save()
    }

    func finishIntro() {
        showsIntro = false
        // The movie hands over to the welcome card on the farm, once per save.
        if !introWelcomeSeen { showsWelcome = true }
    }

    /// Saying okay to the "Let's get started" card (its button, or the deck's
    /// action button while it's up).
    func dismissWelcome() {
        guard showsWelcome else { return }
        showsWelcome = false
        introWelcomeSeen = true
        save()
    }

    func equipOutfit(_ id: String) {
        guard outfits.contains(id), let outfit = Outfit.find(id) else { return }
        if let look = farmerLook, !look.canWear(outfit) { return }
        equippedOutfit = id
        feedbackCount += 1
    }

    func equipAccessory(_ id: String?) {
        if let id, !accessories.contains(id) { return }
        equippedAccessory = id
        feedbackCount += 1
    }
}
