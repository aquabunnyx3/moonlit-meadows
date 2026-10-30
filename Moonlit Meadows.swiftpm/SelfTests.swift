import Foundation
import UIKit

/// Game-rule tests that run inside the app (Journal → Self-check), since Swift Playgrounds
/// can't run XCTest. Each test builds its own `Meadow` with an in-memory save, so your real
/// progress is never touched.
struct TestResult: Identifiable {
    let id = UUID()
    let name: String
    let failures: [String]

    var passed: Bool { failures.isEmpty }
}

enum SelfTests {
    private final class Check {
        var failures: [String] = []

        func expect(_ condition: Bool, _ message: @autoclosure () -> String) {
            if !condition { failures.append(message()) }
        }
    }

    private static let tests: [(String, (Check) -> Void)] = [
        ("Catalog: 50 breeds, rarities, starters", catalogBreeds),
        ("Catalog: characters and stories", catalogPeople),
        ("Catalog: every reward and item exists", catalogReferences),
        ("Every breed can be discovered (no romance needed)", everyBreedDiscoverable),
        ("New game starts with exactly 2 starter breeds", starters),
        ("Discovery: new vs repeat visits", discoveryNewVersusRepeat),
        ("Discovery: time-of-day conditions", discoveryConditions),
        ("Lures reject invalid baskets", lureValidation),
        ("Cancelling a lure returns the items", lureCancel),
        ("Bunny gifts remove the bunny but keep the discovery", bunnyGifting),
        ("Favorite bunny gift gives a big boost and a scene", favoriteBunnyGift),
        ("Talking is once a day and never punishes", dailyTalk),
        ("Item gifts: daily limit, no negative points", itemGifts),
        ("Stages, crossroads, and both paths", relationshipStages),
        ("Story chapters reward only once", eventsOnce),
        ("Quests unlock by stage and complete once", questsOnce),
        ("Milestones and achievements claim once", claimsOnce),
        ("Offline: crops and lures progress", offlineProgress),
        ("Save and load round-trip", saveLoadRoundTrip),
        ("Bunny Meadows v1 saves migrate", legacyMigration),
        ("Farmer creator and walking loop", farmerLook),
        ("Day cycle: clock, bedtime, and a new morning", dayCycle),
        ("Home: storage chest and going to bed", homeAndStorage),
        ("Menus: pause stops time, New Game starts fresh", menusAndReset),
        ("Music: the right song for each scene", musicTracks),
        ("Intro: plays once, after a new farmer", introOnce),
        ("Farmer looks: bald and the new outfits", baldAndOutfits),
        ("Voices: every line has its recording", voices),
        ("Chat faces: expressions for each line", chatMoods),
        ("Hearts: dislikes, rude answers, and making up", warmthRules),
    ]

    static func runAll() -> [TestResult] {
        tests.map { name, body in
            let check = Check()
            body(check)
            return TestResult(name: name, failures: check.failures)
        }
    }

    // MARK: Helpers

    /// Noon on a fixed day, in whole seconds so saves round-trip exactly.
    private static func date(hour: Int, dayOffset: Int = 0) -> Date {
        var components = DateComponents()
        components.year = 2026
        components.month = 10
        components.day = 28 + dayOffset
        components.hour = hour
        let date = Calendar.current.date(from: components) ?? Date(timeIntervalSince1970: 1_800_000_000)
        return Date(timeIntervalSince1970: floor(date.timeIntervalSince1970))
    }

    private static func freshMeadow(at date: Date = SelfTests.date(hour: 12)) -> Meadow {
        Meadow(store: MemoryStore(), now: date, seed: 42)
    }

    /// Finds a moment when a lure condition holds, searching ahead up to four weeks.
    private static func date(satisfying condition: LureCondition, from start: Date) -> Date? {
        if condition.isMet(at: start) { return start }
        var date = start
        for _ in 0..<(28 * 24 * 15) {
            date = date.addingTimeInterval(240)
            if condition.isMet(at: date) { return date }
        }
        return nil
    }

    private static func lure(_ meadow: Meadow, _ items: [String], slot: Int = 0) -> VisitOutcome? {
        for item in items {
            meadow.grant(.items(item, 1))
        }
        guard meadow.placeLure(items, inSlot: slot) else { return nil }
        meadow.advanceLures(bySeconds: 100_000)
        return meadow.greetVisitor(inSlot: slot)
    }

    // MARK: Catalog

    private static func catalogBreeds(_ c: Check) {
        c.expect(Breed.all.count == 50, "Expected 50 breeds, found \(Breed.all.count)")
        c.expect(Set(Breed.all.map(\.id)).count == Breed.all.count, "Breed IDs must be unique")
        c.expect(Set(Breed.all.map(\.name)).count == Breed.all.count, "Breed names must be unique")
        let counts = Dictionary(grouping: Breed.all, by: \.rarity).mapValues(\.count)
        c.expect(counts[.common] == 9 && counts[.uncommon] == 13 && counts[.rare] == 13
                 && counts[.epic] == 10 && counts[.legendary] == 5, "Unexpected rarity spread: \(counts)")
        c.expect(Breed.starterIDs.count == 2, "There must be exactly two starters")
        for id in Breed.starterIDs {
            c.expect(Breed.find(id)?.rarity == .common, "Starter \(id) must exist and be common")
        }
        var signatures = Set<String>()
        for breed in Breed.all {
            c.expect(!breed.lure.isEmpty && breed.lure.count <= Meadow.maxLureItems, "\(breed.name) needs 1–3 lure items")
            for item in breed.lure {
                c.expect(ItemInfo.exists(item), "\(breed.name) lure item \(item) doesn't exist")
                c.expect(Recipe.find(item)?.taughtBy == nil, "\(breed.name) must not need a character recipe")
            }
            let signature = breed.lure.sorted().joined(separator: "+") + "|\(breed.condition.time?.rawValue ?? "")|\(breed.condition.weather?.rawValue ?? "")|\(breed.condition.season?.rawValue ?? "")"
            c.expect(!signatures.contains(signature), "\(breed.name) has the same lure and condition as another breed")
            signatures.insert(signature)
        }
        let levels = Set(Crop.all.map(\.unlockLevel))
        for level in 1...20 {
            c.expect(levels.contains(level), "No crop unlocks at level \(level)")
        }
    }

    private static func catalogPeople(_ c: Check) {
        c.expect(Person.main.count == 7, "Expected seven main characters")
        c.expect(Person.villagers.count == 3 && Person.villagers.allSatisfy(\.isVillager), "Expected three villagers")
        c.expect(Set(Person.all.map(\.id)).count == Person.all.count, "Character IDs must be unique")
        let genders = Person.main.map(\.gender)
        c.expect(genders.filter { $0 == "Woman" }.count == 2, "Expected two women")
        c.expect(genders.filter { $0 == "Man" }.count == 4, "Expected four men")
        c.expect(genders.filter { $0 == "Gender-fluid" }.count == 1, "Expected one gender-fluid character")
        if let sol = Person.find("sol") {
            c.expect(sol.gender == "Gender-fluid" && sol.pronouns == "they/them", "Sol's profile must say gender-fluid, they/them")
        }
        for person in Person.all {
            let events = StoryEvent.events(for: person.id)
            if person.isVillager {
                c.expect(events.count == 3 && events.allSatisfy { $0.path == .any && $0.stage <= .closeFriend },
                         "\(person.name) should have 3 friendship chapters")
                c.expect(!events.contains { $0.isCrossroads || $0.isFinale }, "\(person.name) has no romance chapters")
            } else {
                c.expect(events.count == 8, "\(person.name) should have 8 chapters")
                c.expect(events.filter(\.isCrossroads).count == 1, "\(person.name) needs one crossroads")
                c.expect(events.filter(\.isFinale).count == 2, "\(person.name) needs a romance and a friendship finale")
            }
            c.expect(person.favoriteBreeds.count == 3, "\(person.name) needs three favorite breeds")
            for id in person.favoriteBreeds {
                c.expect(Breed.find(id) != nil, "\(person.name)'s favorite \(id) doesn't exist")
            }
            c.expect(person.quests.count == 3, "\(person.name) needs three quests")
            c.expect(person.activities.count == 3 && person.schedule.count == 4, "\(person.name) needs activities and a schedule")
        }
    }

    private static func check(_ reward: Reward, _ c: Check, _ source: String) {
        switch reward {
        case .decor(let id): c.expect(Decor.find(id) != nil, "\(source): decor \(id) missing")
        case .outfit(let id): c.expect(Outfit.find(id) != nil, "\(source): outfit \(id) missing")
        case .accessory(let id): c.expect(BunnyAccessory.find(id) != nil, "\(source): accessory \(id) missing")
        case .keepsake(let id): c.expect(Keepsake.find(id) != nil, "\(source): keepsake \(id) missing")
        case .recipe(let id): c.expect(Recipe.find(id) != nil, "\(source): recipe \(id) missing")
        case .hint(let id): c.expect(Breed.find(id) != nil, "\(source): hint breed \(id) missing")
        case .items(let id, _): c.expect(ItemInfo.exists(id), "\(source): item \(id) missing")
        default: break
        }
    }

    private static func catalogReferences(_ c: Check) {
        for event in StoryEvent.all {
            event.rewards.forEach { check($0, c, event.id) }
            c.expect(Person.find(event.personID) != nil, "\(event.id) has no character")
        }
        for quest in Person.all.flatMap(\.quests) + Festival.all.map(\.quest) {
            quest.rewards.forEach { check($0, c, quest.id) }
            for item in quest.items {
                c.expect(ItemInfo.exists(item.itemID), "\(quest.id) needs missing item \(item.itemID)")
            }
        }
        CollectionMilestone.all.forEach { m in m.rewards.forEach { check($0, c, "milestone \(m.count)") } }
        Achievement.all.forEach { a in a.rewards.forEach { check($0, c, a.id) } }
        for person in Person.all {
            for id in person.lovedGifts + person.likedGifts + person.dislikedGifts {
                c.expect(ItemInfo.exists(id), "\(person.name) gift \(id) missing")
            }
        }
        for recipe in Recipe.all {
            for ingredient in recipe.ingredients {
                c.expect(ItemInfo.unlockLevel(ingredient.itemID) <= recipe.unlockLevel || recipe.taughtBy != nil,
                         "\(recipe.name) needs \(ingredient.itemID) before it unlocks")
            }
        }
        let shopDecor = Decor.all.filter(\.isShopItem)
        c.expect(shopDecor.allSatisfy { $0.price > 0 }, "Shop decor needs a price")
    }

    /// Follows only the lure clues — no relationships, no luck — and finds all 50 breeds.
    private static func everyBreedDiscoverable(_ c: Check) {
        let meadow = freshMeadow()
        meadow.habitatCapacity = 200
        var attempts = 0
        while meadow.discoveredCount < Breed.all.count && attempts < 300 {
            attempts += 1
            guard let target = Breed.all.first(where: { !meadow.isDiscovered($0) }) else { break }
            guard let when = date(satisfying: target.condition, from: meadow.now) else {
                c.expect(false, "No date satisfies \(target.name)'s condition")
                return
            }
            meadow.now = when
            meadow.setClock(toMatch: when)
            if lure(meadow, target.lure) == nil {
                c.expect(false, "Couldn't place a lure for \(target.name)")
                return
            }
        }
        let missing = Breed.all.filter { !meadow.isDiscovered($0) }.map(\.name)
        c.expect(missing.isEmpty, "Never discovered: \(missing.joined(separator: ", "))")
        c.expect(meadow.discoveredCount == 50, "Discovered count should be 50, was \(meadow.discoveredCount)")
    }

    // MARK: Discovery

    private static func starters(_ c: Check) {
        let meadow = freshMeadow()
        c.expect(Set(meadow.discovered.keys) == Set(Breed.starterIDs), "Starters should be the only discoveries")
        c.expect(meadow.bunnies.count == 2, "You should own one bunny of each starter")
    }

    private static func discoveryNewVersusRepeat(_ c: Check) {
        let meadow = freshMeadow()
        let first = lure(meadow, ["strawberry"])
        c.expect(first?.breed.id == "strawberryBunny", "Strawberries should bring a Strawberry bunny")
        c.expect(first?.isNewDiscovery == true, "First visit should be new")
        c.expect(meadow.discoveredCount == 3, "Discovered count should be 3")
        let gemsAfterFirst = meadow.gems
        let second = lure(meadow, ["strawberry"])
        c.expect(second?.breed.id == "strawberryBunny", "Repeat lure should bring the same breed")
        c.expect(second?.isNewDiscovery == false, "Repeat visit must not count as new")
        c.expect(meadow.discoveredCount == 3, "Repeat visit must not change the discovered count")
        c.expect(meadow.gems == gemsAfterFirst, "Repeat visits don't give discovery gems")
        c.expect(meadow.ownedCount(of: "strawberryBunny") == 2, "Both visitors should be adopted")
    }

    private static func discoveryConditions(_ c: Check) {
        let meadow = freshMeadow(at: date(hour: 12))
        c.expect(meadow.chooseVisitor(for: ["moonflower"], at: meadow.now).condition.time != .night, "Night bunnies must not visit at noon")
        let night = date(hour: 23)
        let nightVisitor = meadow.chooseVisitor(for: ["moonflower"], at: night).id
        c.expect(nightVisitor == "midnightBunny" || nightVisitor == "galaxyBunny", "A night bunny should visit at night, got \(nightVisitor)")
    }

    private static func lureValidation(_ c: Check) {
        let meadow = freshMeadow()
        meadow.grant(.items("carrot", 2))
        let before = meadow.inventory
        c.expect(!meadow.placeLure(["carrot", "carrot"], inSlot: 0), "Duplicate items must be rejected")
        c.expect(!meadow.placeLure(["pumpkin"], inSlot: 0), "Items you don't have must be rejected")
        c.expect(!meadow.placeLure([], inSlot: 0), "Empty baskets must be rejected")
        c.expect(!meadow.placeLure(["carrot"], inSlot: 5), "Missing slots must be rejected")
        c.expect(meadow.inventory == before, "Rejected lures must not change inventory")
        c.expect(meadow.placeLure(["carrot"], inSlot: 0), "A valid lure should be placed")
        c.expect(!meadow.placeLure(["carrot"], inSlot: 0), "A busy basket must be rejected")
        c.expect(meadow.count(of: "carrot") == 1, "Placing a lure uses one of each item")
    }

    private static func lureCancel(_ c: Check) {
        let meadow = freshMeadow()
        meadow.grant(.items("lettuce", 1))
        meadow.placeLure(["lettuce"], inSlot: 0)
        meadow.cancelLure(inSlot: 0)
        c.expect(meadow.count(of: "lettuce") == 1, "Cancelling should return the lettuce")
        c.expect(meadow.lureSlots[0].isEmpty, "Cancelling should empty the basket")
    }

    // MARK: Relationships

    private static func bunnyGifting(_ c: Check) {
        let meadow = freshMeadow()
        guard let bunny = meadow.bunnies.first else {
            c.expect(false, "No starter bunny")
            return
        }
        let result = meadow.giveBunny(bunny.id, to: "kai")
        if case .given = result {} else { c.expect(false, "Gift should succeed, got \(result)") }
        c.expect(meadow.bunny(bunny.id) == nil, "Gifted bunny must leave your habitat")
        c.expect(meadow.discovered[bunny.breedID] != nil, "Gifting must not undiscover the breed")
        c.expect(meadow.gifts.count == 1 && meadow.gifts[0].bunnyID == bunny.id, "Gift must be recorded")
        c.expect(meadow.giveBunny(bunny.id, to: "roz") == .notAvailable, "The same bunny can't be gifted twice")
        if let other = meadow.bunnies.first {
            c.expect(meadow.giveBunny(other.id, to: "kai") == .alreadyGiftedToday, "One bunny gift per person per day")
            meadow.sleep()
            if case .given = meadow.giveBunny(other.id, to: "kai") {} else { c.expect(false, "Next day's gift should work") }
        }
        c.expect(meadow.gifts.count == 2, "Two gifts should be recorded")
    }

    private static func favoriteBunnyGift(_ c: Check) {
        let meadow = freshMeadow()
        let bunny = BunnyInstance(id: UUID(), breedID: "lavenderBunny", name: "Sprout", adoptedAt: meadow.now)
        meadow.bunnies.append(bunny)
        meadow.discovered["lavenderBunny"] = meadow.now
        let result = meadow.giveBunny(bunny.id, to: "june")
        c.expect(result == .given(.favorite, points: 80), "Favorite breed should be worth 80 points, got \(result)")
        c.expect(meadow.favoriteBunnyGifts == 1, "Favorite gift should be counted")
        c.expect(meadow.revealedFavorites(of: "june").contains("lavenderBunny"), "Favorite should be revealed")
        if case .moment = meadow.presentedScene {} else { c.expect(false, "A special scene should play") }
        c.expect(!meadow.relationship("june").memories.isEmpty, "The gift should be remembered")
    }

    private static func dailyTalk(_ c: Check) {
        let meadow = freshMeadow()
        c.expect(meadow.talk(to: "theo")?.points == 10, "First talk gives 10")
        c.expect(meadow.talk(to: "theo")?.points == 0, "Second talk the same day gives 0")
        c.expect(meadow.relationship("theo").points == 10, "Points should be 10")
        for _ in 0..<5 { meadow.sleep() }
        c.expect(meadow.talk(to: "theo")?.points == 10, "Talking after missed days works normally")
        c.expect(meadow.relationship("theo").points == 20, "Missed days must not reduce points")
    }

    private static func itemGifts(_ c: Check) {
        let meadow = freshMeadow()
        meadow.grant(.items("lettuce", 2))
        c.expect(meadow.giveItem("lettuce", to: "theo") == .given(.disliked, points: 0), "Disliked gift gives no points")
        c.expect(meadow.giveItem("lettuce", to: "theo") == .alreadyGiftedToday, "One item gift per day")
        c.expect(meadow.count(of: "lettuce") == 1, "Only the given item is used up")
        c.expect(meadow.giveItem("pumpkin", to: "theo") == .notAvailable, "Can't give what you don't have")
    }

    private static func relationshipStages(_ c: Check) {
        let meadow = freshMeadow()
        meadow.relationships["june"]?.points = 500
        c.expect(meadow.stage(of: "june") == .closeFriend, "Undecided relationships pause at Close Friend")
        c.expect(meadow.isAwaitingCrossroads("june"), "June's crossroads should be waiting")
        c.expect(meadow.completeEvent("june-3", choice: 0), "Crossroads should complete")
        c.expect(meadow.relationship("june").path == .romance, "Option 0 chooses romance")
        c.expect(meadow.stage(of: "june") == .romanticInterest, "Romance continues past Close Friend")
        c.expect(meadow.stageTitle(of: "june") == "Romantic Interest", "Romance title")
        c.expect(meadow.unseenEvents(for: "june").contains { $0.id == "june-r4" }, "Romance chapter should unlock")
        c.expect(!meadow.unseenEvents(for: "june").contains { $0.id == "june-f4" }, "Friendship chapter stays hidden on romance")

        meadow.relationships["kai"]?.points = 900
        meadow.completeEvent("kai-3", choice: 1)
        c.expect(meadow.relationship("kai").path == .friendship, "Option 1 chooses friendship")
        c.expect(meadow.stageTitle(of: "kai") == "Lifelong Friend", "Friendship title at the top stage")
        meadow.setPath(.romance, for: "kai")
        c.expect(meadow.stageTitle(of: "kai") == "Committed", "You can change your mind after the crossroads")

        meadow.addPoints(5000, to: "wes")
        c.expect(meadow.stage(of: "wes") == .closeFriend, "Villagers top out at Close Friend")
        c.expect(!meadow.isAwaitingCrossroads("wes"), "Villagers have no crossroads")
        c.expect(meadow.stageProgress(of: "wes") == 1, "A villager's meter is full at Close Friend")
        c.expect(meadow.unseenEvents(for: "wes").count == 3, "All three villager chapters unlock")
    }

    private static func eventsOnce(_ c: Check) {
        let meadow = freshMeadow()
        meadow.relationships["roz"]?.points = 40
        let gems = meadow.gems
        c.expect(meadow.completeEvent("roz-1", choice: 0), "Chapter should complete")
        c.expect(meadow.learnedRecipes.contains("sunriseShortcake"), "Chapter reward should be granted")
        c.expect(!meadow.completeEvent("roz-1", choice: 0), "A chapter can't be completed twice")
        c.expect(meadow.gems == gems, "No duplicate rewards")
        c.expect(!meadow.completeEvent("roz-r6", choice: 0), "Locked chapters can't be completed")
    }

    private static func questsOnce(_ c: Check) {
        let meadow = freshMeadow()
        c.expect(!meadow.availableQuests.contains { $0.id == "june-1" }, "June's first quest needs Acquaintance")
        meadow.relationships["june"]?.points = 30
        c.expect(meadow.availableQuests.contains { $0.id == "june-1" }, "June's first quest should appear")
        c.expect(!meadow.completeQuest("june-1"), "Can't complete without the clover")
        meadow.grant(.items("clover", 6))
        c.expect(meadow.completeQuest("june-1"), "Quest should complete with 6 clover")
        c.expect(meadow.count(of: "clover") == 0, "Quest items are used up")
        meadow.grant(.items("clover", 6))
        c.expect(!meadow.completeQuest("june-1"), "A quest can't be completed twice")
    }

    private static func claimsOnce(_ c: Check) {
        let meadow = freshMeadow()
        c.expect(!meadow.claimMilestone(5), "Can't claim 5 breeds with 2")
        for breed in Breed.all.prefix(5) {
            meadow.discovered[breed.id] = meadow.now
        }
        c.expect(meadow.claimMilestone(5), "Should claim the 5-breed milestone")
        c.expect(meadow.decor.contains("gardenArch"), "Milestone decor granted")
        let coins = meadow.coins
        c.expect(!meadow.claimMilestone(5), "Milestones claim once")
        c.expect(meadow.coins == coins, "No duplicate milestone rewards")
        c.expect(meadow.claimAchievement("discover1"), "First Hello should be claimable")
        c.expect(!meadow.claimAchievement("discover1"), "Achievements claim once")
    }

    private static func offlineProgress(_ c: Check) {
        let start = date(hour: 12)
        let meadow = freshMeadow(at: start)
        meadow.plant("carrot", in: 0)
        meadow.grant(.items("carrot", 1))
        meadow.placeLure(["carrot"], inSlot: 0)
        meadow.lastSeen = start
        meadow.welcomeBack(at: start.addingTimeInterval(600))
        c.expect(meadow.plots[0].isReady, "Carrots should finish growing while away")
        c.expect(meadow.lureSlots[0].hasArrived, "The lure visitor should arrive while away")
        c.expect(meadow.awayReport != nil, "A welcome-back report should be prepared")
        meadow.lastSeen = start
        meadow.welcomeBack(at: start.addingTimeInterval(30))
        c.expect(meadow.lureSlots[0].hasArrived, "Short gaps don't undo progress")
    }

    // MARK: Saving

    private static func saveLoadRoundTrip(_ c: Check) {
        let store = MemoryStore()
        let start = date(hour: 12)
        let meadow = Meadow(store: store, now: start, seed: 7)
        meadow.grant(.items("strawberry", 3))
        _ = lure(meadow, ["strawberry"])
        if let bunny = meadow.bunnies.first {
            meadow.rename(bunny.id, to: "Sir Hops")
            meadow.toggleFavorite(bunny.id)
        }
        meadow.talk(to: "sol")
        meadow.relationships["roz"]?.points = 40
        meadow.completeEvent("roz-1", choice: 1)
        meadow.decor.insert("flowers")
        meadow.setFarmer(FarmerLook(gender: .male, hairStyle: 1, skinTone: 2, hairColor: "mint", eyeColor: "green", outfit: "latteWeekend"))
        meadow.save()

        let reloaded = Meadow(store: store, now: start, seed: 7)
        c.expect(reloaded.makeSaveData() == meadow.makeSaveData(), "Reloaded game should match the saved game")
        c.expect(reloaded.bunnies.contains { $0.name == "Sir Hops" && $0.isFavorite }, "Bunny names and favorites persist")
        c.expect(reloaded.relationship("roz").choices["roz-1"] == 1, "Dialogue choices persist")
        c.expect(reloaded.discovered["strawberryBunny"] != nil, "Discoveries persist")
        c.expect(reloaded.farmerLook == FarmerLook(gender: .male, hairStyle: 1, skinTone: 2, hairColor: "mint", eyeColor: "green", outfit: "latteWeekend"),
                 "Your farmer's look persists")
    }

    private static func farmerLook(_ c: Check) {
        let meadow = freshMeadow()
        c.expect(meadow.farmerGender == nil && meadow.showsFarmerCreator, "A new game opens the farmer creator")
        c.expect(Outfit.starterIDs.isSubset(of: meadow.outfits), "Starter outfits are owned from the start")
        meadow.setFarmer(FarmerLook(gender: .female, hairStyle: 5, skinTone: 9, hairColor: "plaid", eyeColor: "gold", outfit: "nope"))
        c.expect(meadow.farmerLook == FarmerLook(gender: .female), "Out-of-range choices fall back to defaults")
        c.expect(!meadow.showsFarmerCreator, "Saving closes the creator")
        meadow.setFarmer(FarmerLook(gender: .female, hairStyle: 1, skinTone: 1, hairColor: "pink", eyeColor: "blue", outfit: "stoneAndSand"))
        c.expect(meadow.skinTone == 1 && meadow.hairColor == "pink" && meadow.equippedOutfit == "stoneAndSand", "Every option can be picked")
        meadow.beginCustomizingFarmer()
        c.expect(meadow.showsFarmerCreator && meadow.farmerDraft == meadow.farmerLook, "Changing your look starts from your current look")
        c.expect(FarmerLook.hairColors.filter(\.isFantasy).count == 5 && FarmerLook.hairColors.count == 10, "5 natural and 5 fantasy hair colors")
        c.expect(FarmerLook.eyeColors.count == 5, "5 eye colors")

        var lastSpot: Spot?
        for second in stride(from: 0.0, to: 200, by: 0.5) {
            let step = WorldLayout.farmerStep(at: second, aspect: 2096.0 / 1184.0)
            c.expect((0...1).contains(step.spot.x) && (0...1).contains(step.spot.y), "Farmer stays on the map at t=\(second)")
            if let lastSpot {
                c.expect(abs(step.spot.x - lastSpot.x) < 0.05 && abs(step.spot.y - lastSpot.y) < 0.05,
                         "Farmer never teleports (t=\(second))")
            }
            lastSpot = step.spot
        }

        // Villager strolls: steady pace, real stops, and steps that keep up with the ground.
        let route = WorldLayout.strollRoute(lane: 1, visitsBunnies: true)
        var stopped = false, lastDistance = -1.0
        for tenth in 0..<350 { // less than one loop (~40 s)
            let step = WorldLayout.routeStep(route, at: Double(tenth) / 10, aspect: 2096.0 / 1184.0)
            if !step.isWalking { stopped = true }
            if step.isWalking {
                c.expect(step.distance >= lastDistance, "Walked distance only grows within a loop")
                lastDistance = step.distance
            }
        }
        c.expect(stopped, "Villagers stop at the ends of their stroll")
    }

    private static func dayCycle(_ c: Check) {
        let meadow = freshMeadow()
        meadow.setFarmer(FarmerLook(gender: .female))
        meadow.finishIntro()
        c.expect(meadow.clockText == "6:00 AM" && meadow.timeOfDay == .dawn, "Days start at 6:00 AM")
        let day = meadow.dayCount
        meadow.advanceClock(by: Meadow.dayLength / 2)
        c.expect(meadow.clockText == "3:00 PM" && meadow.timeOfDay == .day, "Halfway through is 3 PM, got \(meadow.clockText)")
        c.expect(!meadow.isBedtime, "Not bedtime yet")
        meadow.talk(to: "june")
        c.expect(!meadow.canTalk(to: "june"), "One chat per day")
        meadow.advanceClock(by: Meadow.dayLength)
        c.expect(meadow.isBedtime && meadow.timeOfDay == .night, "The day ends at midnight")
        let before = meadow.dayElapsed
        meadow.advanceClock(by: 60)
        c.expect(meadow.dayElapsed == before, "The clock stops at bedtime")
        meadow.sleep()
        c.expect(meadow.dayCount == day + 1 && meadow.dayElapsed == 0 && !meadow.isBedtime, "Sleeping starts the next day")
        c.expect(meadow.canTalk(to: "june"), "Chats reset after sleeping")

        meadow.presentedScene = .completion
        meadow.advanceClock(by: 120)
        c.expect(meadow.dayElapsed == 0, "The clock pauses during scenes")
        meadow.presentedScene = nil

        let night = date(hour: 22)
        meadow.setClock(toMatch: night)
        c.expect(meadow.timeOfDay == .night, "Clock can be set to night for lure tests")
    }

    private static func homeAndStorage(_ c: Check) {
        let meadow = freshMeadow()
        meadow.setFarmer(FarmerLook(gender: .male))
        meadow.finishIntro()
        meadow.grant(.items("strawberry", 5))
        meadow.enterHome()
        c.expect(meadow.isAtHome, "The home button takes you inside")
        meadow.putInStorage("strawberry")
        c.expect(meadow.count(of: "strawberry") == 0 && meadow.count(inStorage: "strawberry") == 5, "Storing moves the whole stack")
        meadow.save()
        let reloaded = Meadow(store: meadow.store, now: meadow.now, seed: 3)
        c.expect(reloaded.count(inStorage: "strawberry") == 5, "The chest is saved")
        meadow.takeFromStorage("strawberry")
        c.expect(meadow.count(of: "strawberry") == 5 && meadow.count(inStorage: "strawberry") == 0, "Taking out moves it back")

        let day = meadow.dayCount
        meadow.restForTheNight()
        c.expect(meadow.isBedtime, "Resting ends the day")
        meadow.goToBed()
        c.expect(meadow.isSleeping && meadow.isAtHome && meadow.isClockPaused, "Going to bed puts you to sleep at home")
        meadow.wakeUp()
        c.expect(!meadow.isSleeping && meadow.dayCount == day + 1 && !meadow.isBedtime, "Morning starts the next day")
        meadow.leaveHome(toTab: "friends")
        c.expect(!meadow.isAtHome && meadow.panelTabID == "friends", "Tab shortcuts leave the house")
    }

    private static func menusAndReset(_ c: Check) {
        let meadow = freshMeadow()
        c.expect(meadow.isAtMainMenu, "The game opens on the main menu")
        meadow.isAtMainMenu = false
        meadow.setFarmer(FarmerLook(gender: .female))
        meadow.finishIntro()
        meadow.isPaused = true
        let start = meadow.now
        meadow.tick(at: start.addingTimeInterval(0.5))
        c.expect(meadow.dayElapsed == 0, "The clock stops while paused")
        meadow.isPaused = false
        meadow.tick(at: start.addingTimeInterval(1))
        c.expect(meadow.dayElapsed > 0, "The clock runs again after Resume")

        meadow.grant(.coins(500))
        meadow.decor.insert("flowers")
        meadow.resetGame()
        c.expect(meadow.coins == SaveData().coins && meadow.decor.isEmpty, "New Game resets your farm")
        c.expect(meadow.farmerGender == nil && meadow.showsFarmerCreator, "New Game opens the farmer creator")
        c.expect(meadow.bunnies.count == Breed.starterIDs.count, "New Game gives the starter bunnies")
    }

    private static func musicTracks(_ c: Check) {
        let meadow = freshMeadow()
        c.expect(meadow.musicTrack == "music-menu", "Title screen plays music-menu")
        meadow.isAtMainMenu = false
        meadow.setFarmer(FarmerLook(gender: .male))
        meadow.finishIntro()
        c.expect(meadow.musicTrack == "music-day", "Morning plays music-day, got \(meadow.musicTrack)")
        meadow.setClock(toMatch: date(hour: 18))
        c.expect(meadow.musicTrack == "music-dusk", "Evening plays music-dusk")
        meadow.setClock(toMatch: date(hour: 22))
        c.expect(meadow.musicTrack == "music-night", "Night plays music-night")
        meadow.enterHome()
        c.expect(meadow.musicTrack == "music-home", "Inside the cottage plays music-home")
        meadow.goToBed()
        c.expect(meadow.musicTrack == "music-sleep", "Sleeping plays music-sleep")
        meadow.wakeUp()
        meadow.leaveHome()
        if let event = StoryEvent.find("june-1") {
            meadow.presentedScene = .story(event)
            c.expect(meadow.musicTrack == "music-story" && meadow.isDialogueShowing, "Story chats play music-story, quietly")
        }
        if let event = StoryEvent.find("june-r5") {
            meadow.presentedScene = .story(event)
            c.expect(meadow.musicTrack == "music-romance", "Dates play music-romance")
        }
        meadow.presentedScene = nil
        while !meadow.isFestivalDay { meadow.sleep() }
        c.expect(meadow.musicTrack == "music-festival-\(meadow.season.rawValue)", "Festival days play the season's festival song")
        let names = ["menu", "day", "dusk", "night", "home", "story", "romance", "sleep",
                     "festival-spring", "festival-summer", "festival-autumn", "festival-winter"]
        for name in names {
            c.expect(NSDataAsset(name: "music-\(name)") != nil, "music-\(name) is in the assets")
        }
        for effect in SoundEffect.allCases {
            c.expect(NSDataAsset(name: effect.rawValue) != nil, "\(effect.rawValue) is in the assets")
        }
        meadow.setClock(toMatch: date(hour: 22))
        c.expect(meadow.isNightBell, "Night rings the night bell")
        meadow.setClock(toMatch: date(hour: 9))
        c.expect(!meadow.isNightBell, "Morning rings the day bell")
    }

    private static func introOnce(_ c: Check) {
        let meadow = freshMeadow()
        meadow.isAtMainMenu = false
        c.expect(!meadow.showsIntro, "No intro before the farmer is made")
        meadow.setFarmer(FarmerLook(gender: .female))
        c.expect(meadow.showsIntro && meadow.isClockPaused, "Start farming plays the intro, with the clock stopped")
        c.expect(meadow.musicTrack == "music-story", "The intro plays music-story")
        let start = meadow.now
        meadow.tick(at: start.addingTimeInterval(0.5))
        c.expect(meadow.dayElapsed == 0, "The day doesn't start during the intro")
        meadow.finishIntro()
        c.expect(!meadow.showsIntro && !meadow.isClockPaused, "Skipping or finishing starts the day")
        meadow.beginCustomizingFarmer()
        meadow.setFarmer(FarmerLook(gender: .male))
        c.expect(!meadow.showsIntro, "Changing your look later doesn't replay the intro")
        c.expect(FarmerRenderer.image(named: "intro-fashionista-holding-suitcase",
                                      look: FarmerLook(gender: .female, hairStyle: 1, skinTone: 1, hairColor: "pink")) != nil,
                 "The fashionista's suitcase picture recolors for your look")
        c.expect(UIImage(named: "intro-fashionista-holding-suitcase-labels") != nil, "Her suitcase picture has a labels map")
        c.expect(FarmerRenderer.image(named: "intro-4-hand", look: FarmerLook(gender: .male, skinTone: 1), drawnSkin: RGB(0xA66D4C)) != nil,
                 "The hand taking the key recolors to your skin tone")
        c.expect(UIImage(named: "chat-farmer-female-s0") != nil, "The curly-buns farmer has their own chat scene")
        for id in ["farmer-female-s1-sundress", "farmer-female-s2", "farmer-male-s0", "farmer-male-s2", "farmer-male-s0-hoodie", "farmer-male-s1-hoodie", "farmer-male-s2-hoodie"] {
            c.expect(UIImage(named: "chat-\(id)") != nil && ChatLayout.all[id] != nil, "chat-\(id) is in with its text box")
        }
        for name in IntroView.artNames {
            c.expect(UIImage(named: name) != nil, "\(name) is in the assets")
        }
    }

    private static func baldAndOutfits(_ c: Check) {
        for gender in FarmerGender.allCases {
            c.expect(gender.hairStyles[safe: 2] == "Bald", "\(gender.title) can be bald")
        }
        let baldMan = FarmerLook(gender: .male, hairStyle: 2).validated()
        let baldWoman = FarmerLook(gender: .female, hairStyle: 2).validated()
        c.expect(baldMan.outfit == Outfit.defaultID && baldWoman.outfit == Outfit.defaultID,
                 "Bald looks keep the jacket now that it's drawn, got \(baldMan.outfit), \(baldWoman.outfit)")
        let hoodie = Outfit.find("lavenderHoodie")!, sundress = Outfit.find("pinkSundress")!
        c.expect(!hoodie.fits(.female) && !sundress.fits(.male), "The hoodie and sundress are made for one body each")
        c.expect(FarmerLook(gender: .male, hairStyle: 1).canWear(hoodie), "Curly Fade is drawn in the hoodie")
        c.expect(FarmerLook(gender: .female, hairStyle: 1).canWear(sundress), "Long Waves is drawn in the sundress")
        for gender in FarmerGender.allCases {
            for style in gender.hairStyles.indices {
                for outfit in Outfit.all where outfit.fits(gender) {
                    c.expect(FarmerLook(gender: gender, hairStyle: style).canWear(outfit),
                             "\(gender.hairStyles[style]) (\(gender.title)) can wear \(outfit.name)")
                }
            }
        }
        for look in [baldMan, baldWoman] {
            for part in [FarmerRenderer.Part.person, .face, .front, .left, .right, .back] {
                c.expect(FarmerRenderer.image(part, look: look) != nil, "\(FarmerRenderer.artName(part, look: look)) is in the assets")
            }
        }
        var curlyHoodie = FarmerLook(gender: .male, hairStyle: 1); curlyHoodie.outfit = "lavenderHoodie"
        c.expect(PersonArt.walking(for: FarmerRenderer.artID(for: curlyHoodie), facing: .left) != nil,
                 "A look without side frames walks on its own front sprite")
        let waves = FarmerRenderer.artID(for: FarmerLook(gender: .female, hairStyle: 1, skinTone: 2, hairColor: "pink"))
        let first = PersonArt.cycleFrame(for: waves, facing: .right, time: 0)
        let later = PersonArt.cycleFrame(for: waves, facing: .right, time: 0.5)
        c.expect(first != nil && later != nil && first?.image !== later?.image, "Long Waves walks right with her video cycle")
        c.expect(PersonArt.cycleFrame(for: waves, facing: .left, time: 0)?.isFlipped == true, "Walking left mirrors the right cycle")
        for person in Person.all where person.id != "rowan" {
            c.expect(PersonArt.hasWalkCycle(for: person.id, facing: .right), "\(person.name) walks with a video cycle")
        }
        let curlyFade = FarmerRenderer.artID(for: FarmerLook(gender: .male, hairStyle: 1))
        c.expect(PersonArt.hasWalkCycle(for: curlyFade, facing: .left), "Curly Fade walks with a video cycle")
        var upward = RouteStep(spot: Spot(x: 0.5, y: 0.5)); upward.dx = 0.01; upward.dy = -0.2; upward.isWalking = true
        c.expect(WalkFacing.facing(for: upward, id: "june") == .right, "Walking up the screen uses the side walk, not a sliding back sprite")
        let padded = FarmerRenderer.image(.person, look: FarmerLook(gender: .female))
        if let padded {
            let trimmed = ArtTrim.trimmed(padded, key: "selftest")
            c.expect(trimmed.size.height < padded.size.height, "Chat busts trim the empty space above the head")
        }
    }

    private static func voices(_ c: Check) {
        let all = VoiceLines.allClipIDs
        c.expect(Set(all).count == all.count, "Every voice clip is listed once")
        // Rowan and Silas talk in blips until their recordings arrive.
        let missing = all.filter { id in NSDataAsset(name: id) == nil && !VoiceLines.notRecordedYet.contains { id.contains($0) } }
        c.expect(missing.isEmpty, "Every voice clip is in the assets, missing \(missing.prefix(5))")

        // Every line the game can show finds its own clips.
        var silent: [String] = []
        func check(_ owner: String, _ text: String) {
            if VoiceLines.clips(owner: owner, text: text).isEmpty { silent.append("\(owner): \(text.prefix(40))") }
        }
        for person in Person.all {
            for line in person.lines.early + person.lines.friend + person.lines.romance + person.lines.bestie { check(person.id, line) }
            for question in person.questions {
                check(person.id, question.prompt)
                for answer in question.answers { check("farmer", answer.text); check(person.id, answer.response) }
            }
            for activity in person.activities { check(person.id, activity.friendLine); check(person.id, activity.dateLine) }
            for reaction in [person.favoriteBunnyReaction, person.bunnyReaction, person.showFavoriteReaction,
                             person.lovedGiftReaction, person.likedGiftReaction, person.neutralGiftReaction,
                             person.dislikedGiftReaction] {
                check(person.id, reaction.replacingOccurrences(of: "{bunny}", with: "Mochi")
                    .replacingOccurrences(of: "{breed}", with: "Moon Lop"))
            }
        }
        for event in StoryEvent.all {
            for line in event.lines {
                switch line.speaker {
                case .narrator: check("narrator", line.text)
                case .person: check(event.personID, line.text)
                case .you: check("farmer", line.text)
                }
            }
            if let choice = event.choice {
                check(event.personID, choice.prompt)
                for option in choice.options { check("farmer", option.text); check(event.personID, option.response) }
            }
        }
        c.expect(silent.isEmpty, "\(silent.count) lines have no voice: \(silent.prefix(3))")

        if let june = Person.find("june") {
            c.expect(VoiceLines.clips(owner: "june", text: june.lines.early[0]) == ["JUNE-DAILY-EARLY-1"], "June's first line plays JUNE-DAILY-EARLY-1")
        }
        let goodnight = "Whew… what a day. The bunnies are all tucked in, so I should be too."
        c.expect(VoiceLines.clips(owner: "farmer", text: goodnight, farmer: .male) == ["FARMER-BEDTIME-1-M"]
                 && VoiceLines.clips(owner: "farmer", text: goodnight, farmer: .female) == ["FARMER-BEDTIME-1-F"],
                 "The farmer's lines use -M or -F for their body")
        if let wes = Person.find("wes"), let line = wes.lines.bestie.first {
            c.expect(VoiceLines.clips(owner: "wes", text: line, prefer: "BESTIE") == ["WES-DAILY-BESTIE-1"]
                     && VoiceLines.clips(owner: "wes", text: line, prefer: "ROMANCE") == ["WES-DAILY-ROMANCE-1"],
                     "Identical lines pick the recording for your path")
        }
        c.expect(VoiceLines.clips(owner: "theo", text: "Not a line anyone says").isEmpty, "Unknown lines stay silent")
        c.expect(VoiceLines.clips(owner: "kai", text: Person.find("june")?.lines.early[0] ?? "").isEmpty,
                 "Never another character's voice")
        c.expect(VoiceLines.intro.allSatisfy { NSDataAsset(name: $0) != nil }, "The opening story's clips are in")
    }

    private static func chatMoods(_ c: Check) {
        c.expect(ChatMood.of("No way! This is my absolute favorite!") == .surprised, "“No way!” looks surprised")
        c.expect(ChatMood.of("Someone I lost. Like you miss Nonno.") == .sad, "Missing someone looks sad")
        c.expect(ChatMood.of("Thank you. This helps.") == .happy, "Thanks looks happy")
        c.expect(ChatMood.of("Plant your carrots a finger apart.") == .neutral, "Plain lines keep the usual face")
        c.expect(ChatMood.of("Clover, then.") == .neutral, "Words inside other words don't count (love in Clover)")
        c.expect(ChatMood.of("June presses a clover you found together. “Oh,” she says, cheeks pink.") == .blush, "Pink cheeks blush")
        for (id, parts) in ChatFaceParts.all {
            for mood in parts.blinks {
                c.expect(UIImage(named: "chat-\(id)-\(mood.rawValue)-blink1") != nil && UIImage(named: "chat-\(id)-\(mood.rawValue)-blink2") != nil,
                         "\(id) can blink while \(mood.rawValue)")
            }
            c.expect(UIImage(named: "chat-\(id)-mouthopen") != nil && UIImage(named: "chat-\(id)-mouthclosed") != nil, "\(id) has talking mouths")
        }
        c.expect(NSDataAsset(name: "sfx-talk-blip") != nil, "The talk blip is in the assets")
        for id in ChatFaceParts.all.keys where id.hasPrefix("farmer") {
            c.expect(UIImage(named: "chat-\(id)-labels") != nil, "chat-\(id) recolors for your look")
        }
        let pinkHair = FarmerLook(gender: .female, hairStyle: 0, skinTone: 1, hairColor: "pink", eyeColor: "blue")
        c.expect(ChatFaceParts.frame("chat-farmer-female-s0", look: pinkHair) !== UIImage(named: "chat-farmer-female-s0"),
                 "The Curly Buns chat scene is recolored for a pink-haired, fair farmer")
        for keepsake in Keepsake.all {
            c.expect(UIImage(named: "keepsake-\(keepsake.id)") != nil, "\(keepsake.name) has its icon")
        }
        for accessory in BunnyAccessory.all {
            c.expect(UIImage(named: "accessory-\(accessory.id)") != nil, "\(accessory.name) has its icon")
        }
        for id in ["june", "roz", "sol", "wes", "bree", "vi", "rowan", "silas"] {
            c.expect(PersonArt.hasFrontSprite(id), "\(id) faces you when standing still")
        }
        for id in ["june", "roz", "theo", "kai", "sol", "silas", "wes", "bree", "vi", "farmer-male", "farmer-female", "farmer-female-s0", "farmer-female-s2",
                   "farmer-male-s0", "farmer-male-s0-hoodie", "farmer-male-s2", "farmer-male-s2-hoodie"] {
            for mood in ["happy", "sad", "surprised", "blush"] {
                c.expect(UIImage(named: "chat-\(id)-\(mood)") != nil && ChatLayout.faces["\(id)-\(mood)"] != nil,
                         "chat-\(id)-\(mood) is in the assets with its place")
            }
        }
        for mood in ["happy", "sad", "surprised"] {
            c.expect(UIImage(named: "person-theo-\(mood)") != nil, "Theo's \(mood) portrait is in the assets")
        }
    }

    private static func warmthRules(_ c: Check) {
        let meadow = freshMeadow()
        meadow.isAtMainMenu = false
        meadow.setFarmer(FarmerLook(gender: .female))
        meadow.finishIntro()
        let id = "kai"
        c.expect(meadow.warmth(of: id) == Meadow.startingWarmth && meadow.warmthLevel(of: id) == .warm, "Everyone starts warm")
        meadow.changeWarmth(-2, for: id)
        c.expect(meadow.warmthLevel(of: id) == .strained, "Two hearts lost is Strained")
        meadow.changeWarmth(-2, for: id)
        c.expect(meadow.warmthLevel(of: id) == .distant, "Two more is Distant")
        if let kai = Person.find(id) {
            c.expect(kai.lines.early.contains(meadow.dailyLine(for: kai)), "Distant villagers talk like strangers")
        }
        meadow.addPoints(RelationshipStage.friend.threshold, to: id)
        c.expect(!meadow.canDoActivity(with: id), "Activities pause while Distant")
        c.expect(!meadow.availableQuests.contains { $0.personID == id }, "Requests pause while Distant")
        c.expect(meadow.stage(of: id) >= .friend, "The friendship stage itself is kept")
        meadow.apologize(to: id)
        c.expect(meadow.warmth(of: id) == 3 && !meadow.canApologize(to: id), "Apologizing gives a heart, once a day")
        meadow.changeWarmth(20, for: id)
        c.expect(meadow.warmth(of: id) == Meadow.maxWarmth, "Hearts top out at ten")
        meadow.changeWarmth(-20, for: id)
        c.expect(meadow.warmth(of: id) == 0, "Hearts never go below zero")
        for person in Person.all {
            for question in person.questions {
                c.expect(question.answers.filter(\.isRude).count == 1, "\(question.id) has one rude answer")
                c.expect(question.answers.last?.isRude == true, "\(question.id): the rude answer comes last")
            }
        }
    }

    private static func legacyMigration(_ c: Check) {
        let legacy: [String: Any] = [
            "coins": 1234, "gems": 9, "level": 4, "xp": 7,
            "inventory": ["carrot": 5, "jam": 1],
            "plots": [["cropID": "carrot", "progress": 0.5], ["progress": 0]],
            "decor": ["flowers"],
            "friends": ["mochi": ["hearts": 2]],
            "canLevel": 1,
            "lastSeen": 800_000_000.0,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: legacy) else {
            c.expect(false, "Couldn't build legacy save")
            return
        }
        let meadow = Meadow(store: MemoryStore(data: data), now: date(hour: 12), seed: 1)
        c.expect(meadow.coins == 1234 && meadow.gems == 9 && meadow.level == 4, "Legacy currencies and level kept")
        c.expect(meadow.count(of: "carrot") == 5 && meadow.count(of: "jam") == 1, "Legacy inventory kept")
        c.expect(meadow.plots.count == 2 && meadow.plots[0].cropID == "carrot", "Legacy plots kept")
        c.expect(meadow.decor.contains("flowers") && meadow.canLevel == 1, "Legacy decor and upgrades kept")
        c.expect(Set(meadow.discovered.keys) == Set(Breed.starterIDs), "Legacy players get the two starters")
    }
}
