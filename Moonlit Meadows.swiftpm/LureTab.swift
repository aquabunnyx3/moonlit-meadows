import SwiftUI

/// Build a lure basket from your harvest, place it in the bunny garden, and greet whoever comes.
struct LureTab: View {
    let meadow: Meadow
    @State private var selection: [String] = []

    var body: some View {
        ScrollView {
            VStack(spacing: 10) {
                conditions

                ForEach(meadow.lureSlots.indices, id: \.self) { index in
                    slotCard(index)
                }

                if meadow.lureSlots.contains(where: \.isEmpty) {
                    basketBuilder
                }

                clueBoard
            }
        }
        .scrollIndicators(.hidden)
    }

    // MARK: Conditions

    private var conditions: some View {
        HStack(spacing: 6) {
            CozyTag(text: "\(meadow.timeOfDay.emoji) \(meadow.timeOfDay.name)", color: Palette.lavender)
            CozyTag(text: "\(meadow.weather.emoji) \(meadow.weather.name)", color: Palette.sky)
            CozyTag(text: "\(meadow.season.emoji) \(meadow.season.name)", color: Palette.peach)
            Spacer()
            if meadow.lureLevel > 0 {
                CozyTag(text: "🏮 +\(meadow.lureLevel * 25)% speed", color: Palette.butter)
            }
        }
    }

    // MARK: Slots

    @ViewBuilder
    private func slotCard(_ index: Int) -> some View {
        let slot = meadow.lureSlots[index]
        CozyCard(tint: slot.hasArrived ? Palette.butter : .white) {
            if slot.isEmpty {
                HStack {
                    Text("🧺").font(.title)
                    VStack(alignment: .leading) {
                        Text("Basket \(index + 1) is empty").font(.headline)
                        Text("Choose up to 3 items below to lure a bunny.").font(.caption).opacity(0.7)
                    }
                }
            } else if let id = slot.visitorBreedID, let breed = Breed.find(id) {
                let known = meadow.isDiscovered(breed)
                HStack(spacing: 10) {
                    // New breeds stay a surprise until you greet them.
                    BreedBunnyView(breed: breed, size: 52, isSilhouette: !known || !slot.hasArrived)
                        .frame(width: 52, height: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 2) {
                            ForEach(slot.items, id: \.self) { ItemIcon(itemID: $0, size: 16) }
                        }
                        if slot.hasArrived {
                            Text(known ? "\(breed.name) came back to visit!" : "A mystery bunny is waiting! ❗️")
                                .font(.headline)
                        } else {
                            Text(slot.progress >= 0.5 ? "🐾 Something is approaching…" : "Waiting for a visitor…")
                                .font(.subheadline.bold())
                            ProgressView(value: slot.progress)
                                .tint(Palette.rose)
                            if let seconds = meadow.secondsUntilArrival(slot) {
                                Text("Arrives in about \(seconds.countdown)")
                                    .font(.caption2)
                                    .opacity(0.7)
                            }
                        }
                    }
                    Spacer(minLength: 4)
                    if slot.hasArrived {
                        PriceButton(label: "Greet 👋", isEnabled: true) {
                            withAnimation(.bouncy) {
                                _ = meadow.greetVisitor(inSlot: index)
                            }
                        }
                    } else {
                        Button("Cancel") {
                            meadow.cancelLure(inSlot: index)
                        }
                        .font(.caption.bold())
                        .tint(Palette.cocoa)
                    }
                }
            }
        }
    }

    // MARK: Basket builder

    private var basketBuilder: some View {
        let owned = ItemInfo.allIDs.filter { meadow.count(of: $0) > 0 }
        let preview = meadow.lurePreview(for: selection)

        return CozyCard(tint: Palette.blush) {
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle(text: "Fill a lure basket")
                if owned.isEmpty {
                    Text("Harvest crops or bake treats first — bunnies follow their noses! 🥕")
                        .font(.caption)
                } else {
                    ScrollView(.horizontal) {
                        HStack(spacing: 6) {
                            ForEach(owned, id: \.self) { id in
                                let isSelected = selection.contains(id)
                                Button {
                                    toggle(id)
                                } label: {
                                    VStack(spacing: 0) {
                                        ItemIcon(itemID: id, size: 24)
                                        Text("×\(meadow.count(of: id))").font(.caption2.bold())
                                    }
                                    .frame(width: 50, height: 52)
                                    .background(isSelected ? Palette.petal : Color.white, in: .rect(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(isSelected ? Palette.rose : .clear, lineWidth: 2))
                                }
                                .buttonStyle(SquishButtonStyle())
                                .accessibilityLabel("\(ItemInfo.name(id)), \(isSelected ? "selected" : "not selected")")
                            }
                        }
                    }
                    .scrollIndicators(.hidden)

                    if !selection.isEmpty {
                        HStack(spacing: 4) {
                            Text("Current lure:").font(.caption.bold())
                            ForEach(selection, id: \.self) { ItemIcon(itemID: $0, size: 18) }
                        }
                        if preview.bringsSomethingNew {
                            Text("✨ Something new is sniffing the air…").font(.caption.bold()).foregroundStyle(Palette.rose)
                        } else if let familiar = preview.familiarBreed {
                            Text("A familiar friend will visit: \(familiar.name)").font(.caption)
                        }
                        ForEach(preview.sniffs, id: \.self) { clue in
                            Text("👃 \(clue)").font(.caption2).opacity(0.8)
                        }
                    }

                    HStack {
                        Spacer()
                        PriceButton(label: "Place lure 🧺", isEnabled: !selection.isEmpty) {
                            if let slot = meadow.lureSlots.firstIndex(where: \.isEmpty), meadow.placeLure(selection, inSlot: slot) {
                                selection = []
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: meadow.inventory) { _, inventory in
            selection.removeAll { inventory[$0, default: 0] == 0 }
        }
    }

    private func toggle(_ id: String) {
        if let index = selection.firstIndex(of: id) {
            selection.remove(at: index)
        } else if selection.count < Meadow.maxLureItems {
            selection.append(id)
        }
    }

    // MARK: Clue board

    private var clueBoard: some View {
        let clues = Breed.all
            .filter { !meadow.isDiscovered($0) && meadow.isHintVisible($0) }
            .sorted { ($0.minLevel, $0.rarity.rawValue) < ($1.minLevel, $1.rarity.rawValue) }
            .prefix(4)

        return CozyCard {
            VStack(alignment: .leading, spacing: 8) {
                SectionTitle(text: "Bunny clues")
                if clues.isEmpty {
                    Text("No clues right now. Level up your farm, befriend the villagers, or check the collection book! 🔍")
                        .font(.caption)
                }
                ForEach(Array(clues)) { breed in
                    let ready = breed.lure.allSatisfy { meadow.count(of: $0) > 0 }
                    HStack(spacing: 8) {
                        BreedBunnyView(breed: breed, size: 36, isSilhouette: true)
                            .frame(width: 36, height: 40)
                        VStack(alignment: .leading, spacing: 2) {
                            RarityTag(rarity: breed.rarity)
                            Text(breed.hint).font(.caption)
                        }
                        Spacer(minLength: 4)
                        if ready && meadow.lureSlots.contains(where: \.isEmpty) {
                            Button("Use") {
                                selection = breed.lure
                            }
                            .font(.caption.bold())
                            .tint(Palette.rose)
                        }
                    }
                }
            }
        }
    }
}
