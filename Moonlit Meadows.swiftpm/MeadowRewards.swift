import Foundation

extension Meadow {
    // MARK: Rewards

    /// Grants a reward. Unlockables (decor, outfits, recipes…) are sets, so granting one twice
    /// never duplicates it. Callers guard one-time rewards (milestones, quests, chapters).
    func grant(_ reward: Reward) {
        switch reward {
        case .coins(let amount):
            coins += max(amount, 0)
        case .gems(let amount):
            gems += max(amount, 0)
        case .xp(let amount):
            gainXP(max(amount, 0))
        case .items(let id, let amount):
            if ItemInfo.exists(id) { addItems(id, amount) }
        case .decor(let id):
            if Decor.find(id) != nil { decor.insert(id) }
        case .outfit(let id):
            if Outfit.find(id) != nil { outfits.insert(id) }
        case .accessory(let id):
            if BunnyAccessory.find(id) != nil { accessories.insert(id) }
        case .keepsake(let id):
            if Keepsake.find(id) != nil { keepsakes.insert(id) }
        case .recipe(let id):
            if Recipe.find(id) != nil { learnedRecipes.insert(id) }
        case .hint(let id):
            if Breed.find(id) != nil { hints.insert(id) }
        case .habitatSpace(let amount):
            habitatCapacity += max(amount, 0)
        case .lureSlot:
            lureSlots.append(LureSlot())
        }
    }

    // MARK: Achievements

    func value(of metric: Achievement.Metric) -> Int {
        switch metric {
        case .breedsDiscovered:
            return discoveredCount
        case .rareDiscovered:
            return Breed.all.filter { $0.rarity == .rare && isDiscovered($0) }.count
        case .epicDiscovered:
            return Breed.all.filter { $0.rarity == .epic && isDiscovered($0) }.count
        case .legendaryDiscovered:
            return Breed.all.filter { $0.rarity == .legendary && isDiscovered($0) }.count
        case .milestonesClaimed:
            return claimedMilestones.count
        case .cropsGrown:
            return cropsHarvested.count
        case .farmLevel:
            return level
        case .favoriteBunnyGifts:
            return favoriteBunnyGifts
        case .bestStage:
            return bestStage
        case .storylinesCompleted:
            return storylinesCompleted
        case .festivalsJoined:
            return festivalCycles.count
        }
    }

    func isEarned(_ achievement: Achievement) -> Bool {
        value(of: achievement.metric) >= achievement.target
    }

    var claimableAchievements: [Achievement] {
        Achievement.all.filter { isEarned($0) && !claimedAchievements.contains($0.id) }
    }

    /// Claims an earned achievement once.
    @discardableResult
    func claimAchievement(_ id: String) -> Bool {
        guard let achievement = Achievement.all.first(where: { $0.id == id }),
              isEarned(achievement), !claimedAchievements.contains(id) else { return false }
        claimedAchievements.insert(id)
        for reward in achievement.rewards {
            grant(reward)
        }
        spawn(.sparkle, "\(achievement.emoji) \(achievement.title)!", at: Spot(x: 0.5, y: 0.4))
        feedbackCount += 1
        save()
        return true
    }

    /// How many rewards are waiting, for the Journal badge.
    var pendingRewardCount: Int {
        claimableAchievements.count + claimableMilestones.count
    }

    // MARK: Festivals

    var currentFestival: Festival {
        Festival.current(at: now)
    }

    var hasJoinedCurrentFestival: Bool {
        festivalCycles.contains(Season.cycleID(now))
    }
}
