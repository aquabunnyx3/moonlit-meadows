import SwiftUI

/// The Village Shop's inside: walk up to the counter and a chat screen opens
/// with Buy, Sell, or Exit — buying and selling happen in the deck panel below
/// while the conversation stays on the top screen (Michelle's design).

/// What the counter conversation is doing.
enum ShopMode {
    case options, buy, sell
}

enum ShopLayout {
    /// The long counter across the middle of the shop art (interior-shop-v2):
    /// stand on the rug and face it to talk to the counter.
    static let counterZone = DeckRect(minX: 0.03, minY: 0.50, maxX: 0.97, maxY: 0.665)
}

extension Meadow {
    /// Leaves the counter conversation and puts the deck back.
    func closeShopCounter() {
        shopCounterOpen = false
        shopMode = .options
    }
}

// MARK: - The counter chat screen (top screen)

struct ShopCounterScene: View {
    let meadow: Meadow

    private var greeting: String {
        let lines = [
            "Welcome to the Village Shop! Seeds, decor, and a bit of everything.",
            "Well, hello! Come to browse, or to sell me something lovely?",
            "Everything's freshly stocked today. What'll it be?",
        ]
        return lines[((meadow.dayNumber % lines.count) + lines.count) % lines.count]
    }

    private var line: String {
        switch meadow.shopMode {
        case .options: return greeting
        case .buy: return "Here's what's on the shelves — it's all in the panel below. Take your time."
        case .sell: return "Show me what you've brought — tap Sell in the panel below, and I'll make it worth your while."
        }
    }

    var body: some View {
        ZStack {
            DialogBackdrop(isRomantic: false)
            VStack(spacing: 12) {
                Spacer()
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 6) {
                        Image("icon-shop")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                        Text("Village Shop")
                            .font(.headline)
                    }
                    Text(line)
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                    HStack(spacing: 10) {
                        switch meadow.shopMode {
                        case .options:
                            DialogButton(label: "Buy") { meadow.shopMode = .buy }
                            DialogButton(label: "Sell") { meadow.shopMode = .sell }
                            DialogButton(label: "Exit", pink: false) { meadow.closeShopCounter() }
                        case .buy, .sell:
                            DialogButton(label: "Back") { meadow.shopMode = .options }
                            DialogButton(label: "Exit", pink: false) { meadow.closeShopCounter() }
                        }
                    }
                }
                .padding(16)
                .frame(maxWidth: 560, alignment: .leading)
                .pixelPanel(Palette.cream.opacity(0.97), edge: Palette.lilacEdge, cornerRadius: 18)
                .padding(16)
            }
        }
        .foregroundStyle(Palette.ink)
        .fontDesign(.rounded)
    }
}

// MARK: - Selling at the counter (bottom panel)

/// Everything you're carrying, with prices — the counter's Sell list.
struct ShopSellView: View {
    let meadow: Meadow

    var body: some View {
        let items = ItemInfo.allIDs.filter { meadow.count(of: $0) > 0 }
        VStack(spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "basket.fill").foregroundStyle(Palette.rose)
                Text("Sell to the shop").font(.headline)
                Spacer()
            }
            if items.isEmpty {
                ContentUnavailableView {
                    Label("Nothing to sell", systemImage: "basket")
                } description: {
                    Text("Harvest, fish, or bake something first.")
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(items, id: \.self) { id in
                            sellRow(id)
                        }
                    }
                }
                .scrollIndicators(.hidden)
            }
        }
        .foregroundStyle(Palette.ink)
        .fontDesign(.rounded)
    }

    private func sellRow(_ id: String) -> some View {
        let count = meadow.count(of: id)
        let price = meadow.salePrice(of: id)

        return CozyCard {
            HStack(spacing: 10) {
                ItemIcon(itemID: id, size: 28)
                    .frame(width: 46, height: 46)
                    .background(Palette.blush, in: .circle)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(ItemInfo.name(id)) ×\(count)")
                        .font(.headline)
                    coinText("🪙 \(price) each")
                        .font(.caption)
                        .opacity(0.7)
                }
                Spacer(minLength: 6)
                PriceButton(label: "Sell 1", isEnabled: true, color: Palette.lilac) {
                    meadow.sell(id, count: 1)
                }
                PriceButton(label: "All · 🪙 \((price * count).cozy)", isEnabled: true) {
                    meadow.sell(id, count: count)
                }
            }
        }
    }
}
