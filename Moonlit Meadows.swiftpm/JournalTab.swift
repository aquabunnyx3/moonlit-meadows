import SwiftUI

/// Quests, the seasonal festival, achievements, wardrobe, keepsakes, and the self-check.
struct JournalTab: View {
    let meadow: Meadow
    @State private var section = JournalSection.quests
    @State private var testResults: [TestResult]?

    enum JournalSection: String, CaseIterable {
        case quests = "Quests"
        case rewards = "Rewards"
        case wardrobe = "Wardrobe"
        case checks = "Self-check"
    }

    var body: some View {
        VStack(spacing: 10) {
            Picker("Journal", selection: $section) {
                ForEach(JournalSection.allCases, id: \.self) { section in
                    Text(section.rawValue)
                }
            }
            .pickerStyle(.segmented)

            ScrollView {
                LazyVStack(spacing: 8) {
                    switch section {
                    case .quests: quests
                    case .rewards: rewards
                    case .wardrobe: wardrobe
                    case .checks: checks
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: Quests

    @ViewBuilder
    private var quests: some View {
        let festival = meadow.currentFestival
        CozyCard(tint: Palette.butter) {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(festival.season.emoji) \(festival.name)").font(.headline)
                Text(festival.description).font(.caption)
                Text("Next season in \(Season.timeRemaining(meadow.now).countdown) — every festival returns each month.")
                    .font(.caption2)
                    .opacity(0.7)
                if meadow.hasJoinedCurrentFestival {
                    Text("You've joined this festival! 🎉").font(.caption.bold())
                }
            }
        }

        let available = meadow.availableQuests
        if available.isEmpty {
            Text("No requests right now. Grow closer to the villagers to unlock more! 💌")
                .font(.caption)
                .padding()
        }
        ForEach(available) { quest in
            CozyCard {
                VStack(alignment: .leading, spacing: 4) {
                    if let id = quest.personID, let person = Person.find(id) {
                        HStack(spacing: 6) {
                            PersonPortrait(look: person.look(onDay: meadow.today), artID: person.id, size: 28)
                            Text("From \(person.name)").font(.caption.bold())
                        }
                    } else {
                        Text("🎪 Festival request").font(.caption.bold())
                    }
                    QuestRow(meadow: meadow, quest: quest)
                }
            }
        }
    }

    // MARK: Rewards

    @ViewBuilder
    private var rewards: some View {
        Text("🏅 \(meadow.claimedAchievements.count) / \(Achievement.all.count) achievements")
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
        ForEach(Achievement.all) { achievement in
            let claimed = meadow.claimedAchievements.contains(achievement.id)
            let earned = meadow.isEarned(achievement)
            CozyCard(tint: earned && !claimed ? Palette.butter : .white) {
                HStack(spacing: 10) {
                    ArtIcon(name: "ach-\(achievement.id)", emoji: achievement.emoji, size: 44)
                        .saturation(earned ? 1 : 0)
                        .opacity(earned ? 1 : 0.45)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(achievement.title).font(.subheadline.bold())
                        Text(achievement.description).font(.caption).opacity(0.75)
                        ProgressView(value: Double(min(meadow.value(of: achievement.metric), achievement.target)),
                                     total: Double(achievement.target))
                            .tint(Palette.rose)
                        RewardList(rewards: achievement.rewards)
                    }
                    Spacer(minLength: 4)
                    if claimed {
                        Text("✓").font(.headline)
                    } else {
                        PriceButton(label: "Claim", isEnabled: earned) {
                            meadow.claimAchievement(achievement.id)
                        }
                    }
                }
            }
        }
    }

    // MARK: Wardrobe & keepsakes

    @ViewBuilder
    private var wardrobe: some View {
        SectionTitle(text: "Your farmer")
        CozyCard {
            HStack(spacing: 10) {
                PersonPortrait(look: .farmer(wearing: Outfit.find(meadow.equippedOutfit) ?? Outfit.all[0]),
                               artID: meadow.farmerArtID(), size: 54)
                VStack(alignment: .leading, spacing: 2) {
                    if let look = meadow.farmerLook {
                        Text(look.gender.hairStyles[safe: look.hairStyle] ?? look.gender.title).font(.subheadline.bold())
                        Text("\(FarmerLook.hair(look.hairColor)?.name ?? "") hair · \(FarmerLook.eyes(look.eyeColor)?.name ?? "") eyes")
                            .font(.caption).opacity(0.7)
                    } else {
                        Text("Not chosen yet").font(.subheadline.bold())
                    }
                }
                Spacer()
                PriceButton(label: "Change look", isEnabled: true, color: Palette.lilac) {
                    meadow.beginCustomizingFarmer()
                }
            }
        }

        SectionTitle(text: "Outfits")
        ForEach(Outfit.all.filter { outfit in meadow.farmerLook.map { outfit.fits($0.gender) } ?? true }) { outfit in
            let owned = meadow.outfits.contains(outfit.id)
            let drawn = meadow.farmerLook?.canWear(outfit) ?? true
            CozyCard {
                HStack(spacing: 10) {
                    PersonPortrait(look: .farmer(wearing: outfit), artID: meadow.farmerArtID(wearing: outfit.id), size: 44)
                        .opacity(owned ? 1 : 0.35)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(outfit.emoji) \(outfit.name)").font(.subheadline.bold())
                        Text(owned ? "Owned" : "From: \(outfit.earnedFrom)").font(.caption).opacity(0.7)
                    }
                    Spacer()
                    if meadow.equippedOutfit == outfit.id {
                        Text("Wearing 💕").font(.caption.bold())
                    } else if owned && !drawn {
                        Text("Not drawn for\nthis hair yet").font(.caption2).multilineTextAlignment(.trailing).opacity(0.7)
                    } else if owned {
                        PriceButton(label: "Wear", isEnabled: true, color: Palette.lilac) {
                            meadow.equipOutfit(outfit.id)
                        }
                    }
                }
            }
        }

        SectionTitle(text: "Date memories")
        ForEach(Person.main) { person in
            ForEach(person.activities.filter { $0.dateScene != nil }, id: \.name) { activity in
                let scene = activity.dateScene ?? ""
                let seen = meadow.dateScenesSeen.contains(scene)
                CozyCard(tint: seen ? Palette.blush : .white) {
                    HStack(spacing: 10) {
                        Text(seen ? activity.emoji : "🔒").font(.title2)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(seen ? "\(person.name): \(activity.name)" : "A date with \(person.name)").font(.subheadline.bold())
                            Text(seen ? "Watch it again any time." : "Date \(person.name), then share \(activity.name.lowercased()) together.")
                                .font(.caption)
                                .opacity(0.75)
                        }
                        Spacer()
                        if seen {
                            PriceButton(label: "▶︎ Watch", isEnabled: true) {
                                meadow.replayDateScene(scene)
                            }
                            .fixedSize()
                        }
                    }
                }
            }
        }

        SectionTitle(text: "Keepsakes")
        ForEach(Keepsake.all) { keepsake in
            let owned = meadow.keepsakes.contains(keepsake.id)
            CozyCard(tint: owned ? Palette.blush : .white) {
                HStack(alignment: .top, spacing: 10) {
                    if owned {
                        ArtIcon(name: "keepsake-\(keepsake.id)", emoji: keepsake.emoji, size: 34)
                    } else {
                        Text("🔒").font(.title2)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text(owned ? keepsake.name : "A keepsake yet to be earned").font(.subheadline.bold())
                        Text(owned ? keepsake.description : "Finish a story — or the whole collection — to earn it.")
                            .font(.caption)
                            .opacity(0.75)
                    }
                }
            }
        }
    }

    // MARK: Self-check

    @ViewBuilder
    private var checks: some View {
        CozyCard {
            VStack(alignment: .leading, spacing: 6) {
                Text("🧪 Game self-check").font(.headline)
                Text("Runs the game-rule tests (discovery, gifting, relationships, saving, all 50 breeds) on a separate test farm. Your real progress isn't touched.")
                    .font(.caption)
                PriceButton(label: "Run tests", isEnabled: true, color: Palette.lilac) {
                    testResults = SelfTests.runAll()
                }
            }
        }
        if let testResults {
            let passed = testResults.filter(\.passed).count
            Text(passed == testResults.count ? "✅ All \(passed) tests passed" : "⚠️ \(passed) of \(testResults.count) passed")
                .font(.headline)
            ForEach(testResults) { result in
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(result.passed ? "✅" : "❌") \(result.name)").font(.caption.bold())
                    ForEach(result.failures, id: \.self) { failure in
                        Text("   • \(failure)").font(.caption2).foregroundStyle(Palette.rose)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }
}
