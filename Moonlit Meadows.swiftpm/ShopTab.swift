import SwiftUI

/// Decor for the village, farm upgrades, and bunny-garden upgrades.
struct ShopTab: View {
    let meadow: Meadow
    @State private var section = ShopSection.decor

    enum ShopSection: String, CaseIterable {
        case decor = "Decor"
        case farm = "Farm"
        case garden = "Bunny Garden"
    }

    var body: some View {
        VStack(spacing: 10) {
            Picker("Shop", selection: $section) {
                ForEach(ShopSection.allCases, id: \.self) { section in
                    Text(section.rawValue)
                }
            }
            .pickerStyle(.segmented)

            ScrollView {
                LazyVStack(spacing: 8) {
                    switch section {
                    case .decor:
                        Text("Each decoration adds coziness, so everything sells for more. 🌷")
                            .font(.caption)
                            .opacity(0.7)
                        ForEach(Decor.all) { item in
                            decorRow(item)
                        }
                    case .farm:
                        upgradeRow(emoji: "🟫", title: "New Plot", detail: "\(meadow.plots.count) of \(Meadow.maxPlots) plots",
                                   cost: meadow.nextPlotCost, action: meadow.buyPlot)
                        upgradeRow(emoji: "💧", title: meadow.canLevel > 0 ? "Watering Can · Lv \(meadow.canLevel)" : "Watering Can",
                                   detail: "Crops grow \(15 * meadow.canLevel)% faster → \(15 * (meadow.canLevel + 1))%",
                                   cost: meadow.nextCanCost, action: meadow.upgradeCan)
                        Text("Tip: rainy weather makes crops grow 25% faster 🌧️")
                            .font(.caption)
                            .opacity(0.7)
                    case .garden:
                        upgradeRow(emoji: "🏮", title: meadow.lureLevel > 0 ? "Lure Lantern · Lv \(meadow.lureLevel)" : "Lure Lantern",
                                   detail: "Bunnies arrive \(meadow.lureLevel * 25)% faster → \((meadow.lureLevel + 1) * 25)%",
                                   cost: meadow.nextLureUpgradeCost, action: meadow.upgradeLures)
                        upgradeRow(emoji: "🧺", title: "Extra Lure Basket",
                                   detail: "\(meadow.lureSlots.count) basket\(meadow.lureSlots.count == 1 ? "" : "s") — attract more bunnies at once",
                                   cost: meadow.nextLureSlotCost, action: meadow.buyLureSlot)
                        upgradeRow(emoji: "🏡", title: "Habitat Expansion",
                                   detail: "Room for \(meadow.habitatCapacity) bunnies → \(meadow.habitatCapacity + 4)",
                                   cost: meadow.nextHabitatCost, action: meadow.expandHabitat)
                        Text("Collection milestones also give free baskets and habitat space. 🐰")
                            .font(.caption)
                            .opacity(0.7)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
    }

    private func decorRow(_ item: Decor) -> some View {
        let isOwned = meadow.decor.contains(item.id)
        let isUnlocked = meadow.level >= item.unlockLevel
        let balance = item.currency == .coins ? meadow.coins : meadow.gems
        let icon = item.currency == .coins ? "🪙" : "💎"

        return CozyCard {
            HStack(spacing: 10) {
                Group {
                    if isOwned || (isUnlocked && item.isShopItem) {
                        DecorIcon(item: item, size: 36)
                    } else {
                        Text("🔒").font(.title)
                    }
                }
                    .frame(width: 46, height: 46)
                    .background(Palette.lavender.opacity(0.7), in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.headline)
                    if let source = item.earnedFrom, !isOwned {
                        Text("Earned from: \(source)").font(.caption).opacity(0.7)
                    } else {
                        Text(isUnlocked ? "+\(item.coziness)% coziness" : "Unlocks at Lv \(item.unlockLevel)")
                            .font(.caption)
                            .opacity(0.7)
                    }
                }
                Spacer(minLength: 6)
                if isOwned {
                    Text("Placed 💕")
                        .font(.caption.bold())
                } else if isUnlocked && item.isShopItem {
                    PriceButton(label: "\(icon) \(item.price.cozy)", isEnabled: balance >= item.price) {
                        meadow.buy(item)
                    }
                }
            }
        }
        .opacity(isUnlocked || isOwned ? 1 : 0.6)
    }

    private func upgradeRow(emoji: String, title: String, detail: String, cost: Int?, action: @escaping () -> Void) -> some View {
        CozyCard {
            HStack(spacing: 10) {
                Text(emoji)
                    .font(.title)
                    .frame(width: 46, height: 46)
                    .background(Palette.peach.opacity(0.7), in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.headline)
                    Text(detail).font(.caption).opacity(0.7)
                }
                Spacer(minLength: 6)
                if let cost {
                    PriceButton(label: "🪙 \(cost.cozy)", isEnabled: meadow.coins >= cost, action: action)
                } else {
                    Text("All done 💕").font(.caption.bold())
                }
            }
        }
    }
}
