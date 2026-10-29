import SwiftUI

/// The collection book (all 50 breeds), your habitat, and collection milestones.
struct CollectionTab: View {
    let meadow: Meadow
    @State private var section = CollectionSection.book
    @State private var rarityFilter: Rarity?
    @State private var selectedBreed: Breed?
    @State private var giftingBunny: BunnyInstance?
    @State private var renamingBunny: BunnyInstance?
    @State private var newName = ""

    enum CollectionSection: String, CaseIterable {
        case book = "Book"
        case habitat = "Habitat"
        case milestones = "Milestones"
    }

    var body: some View {
        VStack(spacing: 10) {
            Picker("Bunnies", selection: $section) {
                ForEach(CollectionSection.allCases, id: \.self) { section in
                    Text(section == .milestones && !meadow.claimableMilestones.isEmpty ? "Milestones 🎁" : section.rawValue)
                }
            }
            .pickerStyle(.segmented)

            switch section {
            case .book: book
            case .habitat: habitat
            case .milestones: milestones
            }
        }
        .sheet(item: $selectedBreed) { breed in
            BreedDetailView(meadow: meadow, breed: breed)
                .presentationDetents([.medium, .large])
        }
        .sheet(item: $giftingBunny) { bunny in
            GiftBunnyView(meadow: meadow, bunny: bunny)
                .presentationDetents([.medium, .large])
        }
        .alert("Rename bunny", isPresented: Binding(get: { renamingBunny != nil }, set: { if !$0 { renamingBunny = nil } })) {
            TextField("Name", text: $newName)
            Button("Save") {
                if let bunny = renamingBunny {
                    meadow.rename(bunny.id, to: newName)
                }
                renamingBunny = nil
            }
            Button("Cancel", role: .cancel) {
                renamingBunny = nil
            }
        }
    }

    // MARK: Book

    private var book: some View {
        let shown = Breed.all.filter { rarityFilter == nil || $0.rarity == rarityFilter }

        return VStack(spacing: 8) {
            HStack {
                Text("📖 \(meadow.discoveredCount) / \(Breed.all.count) discovered")
                    .font(.headline)
                Spacer()
                Menu {
                    Button("All rarities") { rarityFilter = nil }
                    ForEach(Rarity.allCases, id: \.self) { rarity in
                        Button("\(rarity.stars) \(rarity.name)") { rarityFilter = rarity }
                    }
                } label: {
                    Label(rarityFilter?.name ?? "All", systemImage: "line.3.horizontal.decrease.circle")
                        .font(.caption.bold())
                }
            }
            ProgressView(value: Double(meadow.discoveredCount), total: Double(Breed.all.count))
                .tint(Palette.rose)

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                    ForEach(shown) { breed in
                        Button {
                            selectedBreed = breed
                        } label: {
                            BookCard(meadow: meadow, breed: breed)
                        }
                        .buttonStyle(SquishButtonStyle())
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: Habitat

    private var habitat: some View {
        let accessories = BunnyAccessory.all.filter { meadow.accessories.contains($0.id) }

        return ScrollView {
            LazyVStack(spacing: 8) {
                HStack {
                    Text("🏡 \(meadow.bunnies.count) / \(meadow.habitatCapacity) bunnies")
                        .font(.headline)
                    Spacer()
                    if meadow.helperCount > 0 {
                        CozyTag(text: "🐾 \(meadow.helperCount) farm helper\(meadow.helperCount == 1 ? "" : "s")")
                    }
                }
                Text("Every 3 bunnies help harvest your farm, even while you're away.")
                    .font(.caption)
                    .opacity(0.7)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if !accessories.isEmpty {
                    ScrollView(.horizontal) {
                        HStack(spacing: 6) {
                            accessoryButton(nil, label: "No accessory")
                            ForEach(accessories) { accessory in
                                accessoryButton(accessory.id, label: "\(accessory.emoji) \(accessory.name)")
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                }

                ForEach(meadow.bunnies.sorted { $0.isFavorite && !$1.isFavorite }) { bunny in
                    habitatRow(bunny)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func accessoryButton(_ id: String?, label: String) -> some View {
        let isOn = meadow.equippedAccessory == id
        return Button(label) {
            meadow.equipAccessory(id)
        }
        .font(.caption.bold())
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(isOn ? Palette.petal : Color.white, in: .capsule)
        .buttonStyle(PlainTapButtonStyle())
    }

    @ViewBuilder
    private func habitatRow(_ bunny: BunnyInstance) -> some View {
        if let breed = Breed.find(bunny.breedID) {
            CozyCard {
                HStack(spacing: 10) {
                    BreedBunnyView(breed: breed, size: 50,
                                   accessory: meadow.equippedAccessory.flatMap { BunnyAccessory.find($0)?.emoji })
                        .frame(width: 50, height: 54)
                        .background(Color(breed.rarity.color).opacity(0.35), in: .rect(cornerRadius: 14))
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text(bunny.name).font(.headline)
                            Button {
                                meadow.toggleFavorite(bunny.id)
                            } label: {
                                Image(systemName: bunny.isFavorite ? "star.fill" : "star")
                                    .foregroundStyle(Palette.rose)
                            }
                            .buttonStyle(PlainTapButtonStyle())
                            .accessibilityLabel(bunny.isFavorite ? "Unfavorite" : "Favorite")
                        }
                        Text("\(breed.name) · \(breed.rarity.name)")
                            .font(.caption)
                            .opacity(0.7)
                        Text(breed.behavior.description)
                            .font(.caption2)
                            .opacity(0.6)
                    }
                    Spacer(minLength: 4)
                    VStack(spacing: 4) {
                        PriceButton(label: meadow.canPet(bunny) ? "Pet 💕" : "Petted ✓", isEnabled: meadow.canPet(bunny), color: Palette.lilac) {
                            meadow.pet(bunny.id)
                        }
                        HStack(spacing: 6) {
                            Button("Rename") {
                                newName = bunny.name
                                renamingBunny = bunny
                            }
                            Button("Gift 🎁") {
                                giftingBunny = bunny
                            }
                        }
                        .font(.caption.bold())
                        .tint(Palette.cocoa)
                    }
                }
            }
        }
    }

    // MARK: Milestones

    private var milestones: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(CollectionMilestone.all) { milestone in
                    let claimed = meadow.claimedMilestones.contains(milestone.count)
                    CozyCard(tint: meadow.isClaimable(milestone) ? Palette.butter : .white) {
                        HStack(spacing: 10) {
                            ArtIcon(name: "badge-\(milestone.count)", emoji: claimed ? "🏆" : "🎁", size: 46)
                                .opacity(claimed || meadow.isClaimable(milestone) ? 1 : 0.5)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(milestone.title) — \(milestone.count) breeds").font(.headline)
                                ProgressView(value: Double(min(meadow.discoveredCount, milestone.count)), total: Double(milestone.count))
                                    .tint(Palette.rose)
                                RewardList(rewards: milestone.rewards)
                            }
                            Spacer(minLength: 4)
                            if claimed {
                                Text("Claimed 💕").font(.caption.bold())
                            } else {
                                PriceButton(label: "Claim", isEnabled: meadow.isClaimable(milestone)) {
                                    meadow.claimMilestone(milestone.count)
                                }
                            }
                        }
                    }
                }
            }
        }
        .scrollIndicators(.hidden)
    }
}

// MARK: - Book card

private struct BookCard: View {
    let meadow: Meadow
    let breed: Breed

    var body: some View {
        let known = meadow.isDiscovered(breed)
        let owned = meadow.ownedCount(of: breed.id)

        VStack(spacing: 3) {
            BreedBunnyView(breed: breed, size: 58, isSilhouette: !known)
                .frame(height: 62)
            Text(known ? breed.name : "???")
                .font(.caption2.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 26)
            RarityTag(rarity: breed.rarity, showsName: false, height: 11)
            if known && owned > 0 {
                Text("Owned ×\(owned)").font(.system(size: 9, weight: .semibold))
            } else if !known {
                Text(meadow.isHintVisible(breed) ? "🔍 Clue" : "Lv \(breed.minLevel)")
                    .font(.system(size: 9, weight: .semibold))
                    .opacity(0.7)
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity)
        .background(Color(breed.rarity.color).opacity(known ? 0.35 : 0.12), in: .rect(cornerRadius: 16))
        .foregroundStyle(Palette.cocoa)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(known ? "\(breed.name), \(breed.rarity.name)" : "Undiscovered \(breed.rarity.name) breed")
    }
}

// MARK: - Breed detail

/// A collection-book page: art, description, clues, and who loves this breed.
struct BreedDetailView: View {
    let meadow: Meadow
    let breed: Breed

    var body: some View {
        let known = meadow.isDiscovered(breed)
        let fans = Person.all.filter { meadow.revealedFavorites(of: $0.id).contains(breed.id) }

        ScrollView {
            VStack(spacing: 12) {
                TimelineView(.animation(minimumInterval: 1 / 24)) { timeline in
                    BreedBunnyView(breed: breed, size: 150, time: known ? timeline.date.timeIntervalSinceReferenceDate : nil,
                                   isSilhouette: !known)
                }
                .frame(height: 170)
                .frame(maxWidth: .infinity)
                .background(Color(breed.rarity.color).opacity(0.3), in: .rect(cornerRadius: 24))

                Text(known ? breed.name : "Undiscovered Breed")
                    .font(.title2.bold())
                RarityTag(rarity: breed.rarity)

                if known {
                    Text(breed.description)
                        .multilineTextAlignment(.center)
                    Text("Habit: \(breed.behavior.description).")
                        .font(.callout)
                        .opacity(0.8)
                    if let date = meadow.discovered[breed.id] {
                        Text("Discovered \(date.formatted(date: .abbreviated, time: .omitted)) · You own \(meadow.ownedCount(of: breed.id))")
                            .font(.caption)
                            .opacity(0.7)
                    }
                }

                CozyCard(tint: Palette.blush) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🔍 Lure clue").font(.headline)
                        if meadow.isHintVisible(breed) {
                            Text(breed.hint)
                            HStack(spacing: 4) {
                                ForEach(breed.lure, id: \.self) { ItemIcon(itemID: $0, size: 22) }
                            }
                        } else {
                            Text("Reach farm level \(breed.minLevel), or befriend the villagers, to learn what this bunny loves.")
                        }
                    }
                }

                if !fans.isEmpty {
                    CozyCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("💕 A favorite of").font(.headline)
                            ForEach(fans) { person in
                                HStack {
                                    PersonPortrait(look: person.look(onDay: meadow.today), artID: person.id, size: 34)
                                    Text(person.name).font(.subheadline.bold())
                                }
                            }
                        }
                    }
                }

                if known {
                    CozyCard {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Show this breed to…").font(.headline)
                            ForEach(Person.all) { person in
                                HStack {
                                    Text(person.name)
                                    Spacer()
                                    if meadow.canShow(breed.id, to: person.id) {
                                        PriceButton(label: "Show 👀", isEnabled: true, color: Palette.lilac) {
                                            meadow.showBreed(breed.id, to: person.id)
                                        }
                                    } else {
                                        Text("Seen ✓").font(.caption).opacity(0.6)
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Palette.cream)
        .foregroundStyle(Palette.cocoa)
        .fontDesign(.rounded)
        .presentsScenes(meadow)
    }
}

// MARK: - Gift a bunny

/// Pick who receives a bunny. The bunny leaves your habitat; the breed stays in your book.
struct GiftBunnyView: View {
    let meadow: Meadow
    let bunny: BunnyInstance
    @Environment(\.dismiss) private var dismiss
    @State private var confirming: Person?

    var body: some View {
        let breed = Breed.find(bunny.breedID)

        ScrollView {
            VStack(spacing: 12) {
                if let breed {
                    BreedBunnyView(breed: breed, size: 90)
                        .frame(height: 100)
                    Text("Gift \(bunny.name) the \(breed.name)?")
                        .font(.title3.bold())
                        .multilineTextAlignment(.center)
                }
                Text("\(bunny.name) will move in with them and leave your habitat. Your collection book keeps the breed forever. Each person accepts one bunny a day.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .opacity(0.75)

                ForEach(Person.all) { person in
                    let isKnownFavorite = meadow.revealedFavorites(of: person.id).contains(bunny.breedID)
                    CozyCard {
                        HStack(spacing: 10) {
                            PersonPortrait(look: person.look(onDay: meadow.today), artID: person.id, size: 44)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(person.name).font(.headline)
                                Text(meadow.stageTitle(of: person.id)).font(.caption).opacity(0.7)
                                if isKnownFavorite {
                                    Text("💖 Favorite breed!").font(.caption.bold()).foregroundStyle(Palette.rose)
                                }
                            }
                            Spacer()
                            if meadow.canGiveBunny(to: person.id) {
                                PriceButton(label: "Give 🎁", isEnabled: true) {
                                    confirming = person
                                }
                            } else {
                                Text("Gifted today").font(.caption).opacity(0.6)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Palette.cream)
        .foregroundStyle(Palette.cocoa)
        .fontDesign(.rounded)
        .confirmationDialog(
            "Give \(bunny.name) to \(confirming?.name ?? "")?",
            isPresented: Binding(get: { confirming != nil }, set: { if !$0 { confirming = nil } }),
            titleVisibility: .visible
        ) {
            Button("Give \(bunny.name) 🎁") {
                if let person = confirming {
                    meadow.giveBunny(bunny.id, to: person.id)
                }
                confirming = nil
                // A favorite-breed gift plays a scene here; otherwise close the sheet.
                if meadow.presentedScene == nil {
                    dismiss()
                }
            }
            Button("Keep \(bunny.name)", role: .cancel) {
                confirming = nil
            }
        } message: {
            Text(bunny.isFavorite ? "\(bunny.name) is one of your starred favorites." : "This can't be undone.")
        }
        .presentsScenes(meadow)
    }
}
