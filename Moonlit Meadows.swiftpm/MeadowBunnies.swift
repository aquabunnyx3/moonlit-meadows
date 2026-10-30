import Foundation

/// The result of greeting a bunny that came to a lure. Shown by the discovery animation.
struct VisitOutcome: Identifiable {
    let id = UUID()
    let breed: Breed
    let isNewDiscovery: Bool
    /// The bunny that joined your habitat, if there was room.
    let adopted: BunnyInstance?
    let rewards: [Reward]
}

/// What the lure UI can say about a basket before it's placed.
struct LurePreview {
    /// A brand-new breed will come. Its identity stays a surprise.
    var bringsSomethingNew = false
    /// The familiar breed that will come, when nothing new matches.
    var familiarBreed: Breed?
    /// Clues about breeds that almost matched.
    var sniffs: [String] = []
}

extension Meadow {
    static let maxLureItems = 3

    private static let bunnyNames = [
        "Mochi", "Biscuit", "Clover", "Pudding", "Maple", "Bean", "Sprout", "Dumpling", "Waffles", "Pip",
        "Button", "Noodle", "Toffee", "Daisy", "Nibbles", "Marshmallow", "Pebble", "Hazel", "Sugar", "Pancake",
        "Sesame", "Truffle", "Bubbles", "Cinnamon", "Poppy", "Tofu", "Willow", "Luna", "Bramble", "Cocoa",
    ]

    // MARK: Collection

    var discoveredCount: Int { discovered.count }

    func isDiscovered(_ breed: Breed) -> Bool {
        discovered[breed.id] != nil
    }

    /// The collection book shows a breed's lure clue once you've found it, been given a clue,
    /// or reached the level where you can grow everything it wants.
    func isHintVisible(_ breed: Breed) -> Bool {
        isDiscovered(breed) || hints.contains(breed.id) || level >= breed.minLevel
    }

    func ownedCount(of breedID: String) -> Int {
        bunnies.filter { $0.breedID == breedID }.count
    }

    var hasHabitatSpace: Bool {
        bunnies.count < habitatCapacity
    }

    // MARK: Lures

    /// Lure lanterns from the shop make bunnies arrive faster.
    var lureSpeed: Double {
        1 + 0.25 * Double(lureLevel)
    }

    func visitDuration(of breed: Breed) -> TimeInterval {
        breed.rarity.visitSeconds / lureSpeed
    }

    func secondsUntilArrival(_ slot: LureSlot) -> TimeInterval? {
        guard let id = slot.visitorBreedID, let breed = Breed.find(id), slot.progress < 1 else { return nil }
        return (1 - slot.progress) * visitDuration(of: breed)
    }

    /// Breeds whose whole lure is in the basket and whose condition is met right now.
    func matchingBreeds(for items: Set<String>, at date: Date, timeOfDay: TimeOfDay? = nil) -> [Breed] {
        Breed.all.filter { Set($0.lure).isSubset(of: items) && $0.condition.isMet(at: date, timeOfDay: timeOfDay) }
    }

    private func specificity(_ breed: Breed) -> Int {
        breed.lure.count * 10 + breed.condition.weight * 5 + breed.rarity.rawValue
    }

    /// Picks who will visit. New breeds always win over familiar ones, and the most specific
    /// match wins, so following clues reliably leads to new discoveries — no luck needed.
    /// If nothing matches, a familiar starter bunny drops by so a lure is never wasted.
    func chooseVisitor(for items: [String], at date: Date, timeOfDay: TimeOfDay? = nil) -> Breed {
        let matches = matchingBreeds(for: Set(items), at: date, timeOfDay: timeOfDay)
        let fresh = matches.filter { !isDiscovered($0) }
        if let best = fresh.max(by: { specificity($0) < specificity($1) }) {
            return best
        }
        if !matches.isEmpty {
            // Rotate through familiar matches as your habitat grows, so the preview always
            // names the bunny that will actually come.
            return matches[bunnies.count % matches.count]
        }
        let fallbackID = items.contains("clover") ? "snowflakeBunny" : "cloverBunny"
        return Breed.find(fallbackID) ?? Breed.all[0]
    }

    func lurePreview(for items: [String]) -> LurePreview {
        var preview = LurePreview()
        guard !items.isEmpty else { return preview }
        let visitor = chooseVisitor(for: items, at: now, timeOfDay: timeOfDay)
        if isDiscovered(visitor) {
            preview.familiarBreed = visitor
        } else {
            preview.bringsSomethingNew = true
        }
        preview.sniffs = sniffClues(for: items)
        return preview
    }

    /// Gentle clues about undiscovered breeds that almost came.
    func sniffClues(for items: [String]) -> [String] {
        let basket = Set(items)
        var clues: [String] = []
        for breed in Breed.all where !isDiscovered(breed) {
            let wants = Set(breed.lure)
            guard !wants.isDisjoint(with: basket) else { continue }
            let visible = isHintVisible(breed)
            if wants.isSubset(of: basket) {
                guard !breed.condition.isMet(at: now, timeOfDay: timeOfDay) else { continue }
                clues.append(visible
                    ? "A \(breed.name) peeked at your lure, but only visits \(breed.condition.text)."
                    : "Something peeked at your lure… maybe it prefers a different time or weather?")
            } else {
                let missing = breed.lure.filter { !basket.contains($0) }
                let sniffed = breed.lure.filter { basket.contains($0) }.map(ItemInfo.emoji).joined()
                clues.append(visible
                    ? "A \(breed.name) sniffed your \(sniffed)… it also wants \(missing.map(ItemInfo.emoji).joined())."
                    : "Something sniffed your \(sniffed) but wanted something more.")
            }
            if clues.count >= 2 { break }
        }
        return clues
    }

    /// Puts 1–3 different items in an empty basket. The items are used up, and a visitor
    /// starts walking over. Returns `false` (and changes nothing) if anything is invalid.
    @discardableResult
    func placeLure(_ items: [String], inSlot index: Int) -> Bool {
        let unique = Array(Set(items))
        guard lureSlots.indices.contains(index), lureSlots[index].isEmpty,
              !unique.isEmpty, unique.count == items.count, unique.count <= Self.maxLureItems,
              unique.allSatisfy({ ItemInfo.exists($0) && count(of: $0) >= 1 })
        else { return false }

        let visitor = chooseVisitor(for: items, at: now, timeOfDay: timeOfDay)
        for item in items {
            removeItems(item, 1)
        }
        lureSlots[index] = LureSlot(items: items, visitorBreedID: visitor.id, progress: 0)
        spawn(.text, "🧺 \(items.map(ItemInfo.emoji).joined())", at: WorldLayout.lureBasket)
        feedbackCount += 1
        save()
        return true
    }

    /// Takes the lure back before anyone arrives, returning the items.
    func cancelLure(inSlot index: Int) {
        guard lureSlots.indices.contains(index), !lureSlots[index].isEmpty, !lureSlots[index].hasArrived else { return }
        for item in lureSlots[index].items {
            addItems(item, 1)
        }
        lureSlots[index] = LureSlot()
        feedbackCount += 1
    }

    func advanceLures(bySeconds seconds: TimeInterval) {
        for index in lureSlots.indices {
            guard let id = lureSlots[index].visitorBreedID, let breed = Breed.find(id), lureSlots[index].progress < 1 else { continue }
            lureSlots[index].progress = min(lureSlots[index].progress + seconds / visitDuration(of: breed), 1)
            if lureSlots[index].progress >= 1 {
                spawn(.heart, "🐾 A visitor arrived!", at: Spot(x: WorldLayout.lureBasket.x, y: WorldLayout.lureBasket.y - 0.08))
            }
        }
    }

    /// Meets the bunny that came to a lure: records a new discovery (once), adopts it if
    /// there's room, and hands out rewards. Repeat visits never count as new discoveries.
    @discardableResult
    func greetVisitor(inSlot index: Int) -> VisitOutcome? {
        guard lureSlots.indices.contains(index), lureSlots[index].hasArrived,
              let id = lureSlots[index].visitorBreedID, let breed = Breed.find(id) else { return nil }

        let isNew = !isDiscovered(breed)
        var rewards: [Reward]
        if isNew {
            discovered[breed.id] = now
            moment("firstBunny", "🐰 Your first bunny! The Bunnies tab keeps track of every breed you discover.")
            rewards = [.coins(breed.rarity.discoveryCoins), .gems(breed.rarity.discoveryGems), .xp(breed.rarity.discoveryXP)]
        } else {
            rewards = [.coins(max(breed.rarity.discoveryCoins / 3, 5)), .xp(max(breed.rarity.discoveryXP / 3, 2))]
        }

        var adopted: BunnyInstance?
        if hasHabitatSpace {
            let bunny = BunnyInstance(id: UUID(), breedID: breed.id, name: nextBunnyName(), adoptedAt: now)
            bunnies.append(bunny)
            adopted = bunny
        } else {
            // A thank-you instead of a new roommate.
            rewards.append(.coins(breed.rarity.discoveryCoins / 2))
        }

        for reward in rewards {
            grant(reward)
        }
        lureSlots[index] = LureSlot()
        let outcome = VisitOutcome(breed: breed, isNewDiscovery: isNew, adopted: adopted, rewards: rewards)
        pendingVisit = outcome
        feedbackCount += 1
        save()
        return outcome
    }

    private func nextBunnyName() -> String {
        let used = Set(bunnies.map(\.name))
        let available = Self.bunnyNames.filter { !used.contains($0) }
        let pool = available.isEmpty ? Self.bunnyNames : available
        return pool[Int(rng.next() % UInt64(pool.count))]
    }

    // MARK: Habitat

    func bunny(_ id: UUID) -> BunnyInstance? {
        bunnies.first { $0.id == id }
    }

    func rename(_ id: UUID, to name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = bunnies.firstIndex(where: { $0.id == id }) else { return }
        bunnies[index].name = String(trimmed.prefix(20))
    }

    func toggleFavorite(_ id: UUID) {
        guard let index = bunnies.firstIndex(where: { $0.id == id }) else { return }
        bunnies[index].isFavorite.toggle()
        feedbackCount += 1
    }

    func canPet(_ bunny: BunnyInstance) -> Bool {
        bunny.lastPettedDay != today
    }

    /// Petting each bunny once a day gives a little XP and a couple of coins,
    /// floated up as the one coin — no second currency popping up beside it
    /// (Michelle, 2026-10-30). Missing a day costs nothing.
    @discardableResult
    func pet(_ id: UUID) -> Bool {
        guard let index = bunnies.firstIndex(where: { $0.id == id }), canPet(bunnies[index]) else { return false }
        bunnies[index].lastPettedDay = today
        gainXP(2)
        grant(.coins(2))
        spawn(.text, "🪙 +2", at: WorldLayout.habitatCenter)
        feedbackCount += 1
        return true
    }

    // MARK: Collection milestones

    func isClaimable(_ milestone: CollectionMilestone) -> Bool {
        discoveredCount >= milestone.count && !claimedMilestones.contains(milestone.count)
    }

    var claimableMilestones: [CollectionMilestone] {
        CollectionMilestone.all.filter(isClaimable)
    }

    /// Claims a milestone once. Claiming the 50-breed milestone plays the completion scene.
    @discardableResult
    func claimMilestone(_ count: Int) -> Bool {
        guard let milestone = CollectionMilestone.all.first(where: { $0.count == count }), isClaimable(milestone) else { return false }
        claimedMilestones.insert(count)
        for reward in milestone.rewards {
            grant(reward)
        }
        spawn(.sparkle, "🏆 \(milestone.title)!", at: Spot(x: 0.5, y: 0.4))
        if count == 50 && !completionSceneSeen {
            completionSceneSeen = true
            presentedScene = .completion
        }
        feedbackCount += 1
        save()
        return true
    }
}
