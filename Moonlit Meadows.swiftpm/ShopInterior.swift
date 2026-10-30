import SwiftUI

/// The Village Shop's inside: walk up to the counter and a chat screen opens
/// with the shopkeeper — Bree, who runs the shop — offering Chat, Buy, Sell,
/// or Exit. Buying and selling happen in the deck panel below while the
/// conversation stays on the top screen (Michelle's design).

/// What the counter conversation is doing.
enum ShopMode {
    case options, buy, sell
}

enum ShopLayout {
    /// The long counter across the middle of the shop art (interior-shop-v2):
    /// stand on the rug and face it to talk to the counter.
    static let counterZone = DeckRect(minX: 0.03, minY: 0.50, maxX: 0.97, maxY: 0.665)

    /// The villager who owns and runs the Village Shop. Of everyone in the
    /// village she's the one without a storefront of her own — the bramble
    /// grower — so the general store is hers. One line to change if Michelle
    /// ever wants a different keeper.
    static let ownerID = "bree"

    static var owner: Person? { Person.find(ownerID) }
}

extension Meadow {
    /// Starts a real conversation with the shopkeeper, right at her counter —
    /// the same talk as anywhere else: daily line, friendship points, and
    /// sometimes a question, because she's a person like everyone else.
    func shopStartChat() {
        shopChat = talk(to: ShopLayout.ownerID)
        shopChatAnswer = nil
    }

    /// Answers the shopkeeper's question from the counter panel below.
    func shopAnswer(_ option: Int) {
        guard let question = shopChat?.question, shopChatAnswer == nil else { return }
        if let answer = answer(question.id, option: option, for: ShopLayout.ownerID) {
            shopChatAnswer = answer.response
        }
    }

    /// Ends the counter conversation with the shopkeeper (back to the options).
    func shopEndChat() {
        shopChat = nil
        shopChatAnswer = nil
    }

    /// Leaves the counter entirely and puts the deck back.
    func closeShopCounter() {
        shopEndChat()
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

    private func chatText(_ chat: TalkResult) -> String {
        if let answer = meadow.shopChatAnswer { return answer }
        if let question = chat.question { return "\(chat.line)\n\n\(question.prompt)" }
        return chat.line
    }

    var body: some View {
        if let owner = ShopLayout.owner {
            if let chat = meadow.shopChat {
                // A real chat with the shopkeeper, in the game's own chat scene.
                ChatScene(meadow: meadow, speaker: .person(owner), name: owner.name, text: chatText(chat),
                          voiceHint: meadow.relationship(owner.id).path == .romance ? "ROMANCE" : "BESTIE")
            } else {
                // At her counter in the market: her chat screen in the shop
                // itself, and the buttons live in the panel below
                // (Michelle, 2026-10-30).
                ChatScene(meadow: meadow, speaker: .person(owner), name: owner.name, text: line,
                          artOverrideID: "shop")
            }
        } else {
            options
        }
    }

    private var options: some View {
        let owner = ShopLayout.owner
        return ZStack {
            DialogBackdrop(isRomantic: false)
            VStack(spacing: 12) {
                Spacer()
                HStack(alignment: .bottom, spacing: 12) {
                    if let owner, let art = PersonArt.image(for: owner.id) {
                        // The shopkeeper pops up beside her counter dialog.
                        Image(uiImage: art)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 190)
                            .accessibilityHidden(true)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image("icon-shop")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 22, height: 22)
                            Text(owner.map { "\($0.name) · Village Shop" } ?? "Village Shop")
                                .font(.headline)
                        }
                        Text(line)
                            .font(.callout)
                            .fixedSize(horizontal: false, vertical: true)
                        HStack(spacing: 10) {
                            switch meadow.shopMode {
                            case .options:
                                DialogButton(label: "Chat") { meadow.shopStartChat() }
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
                }
                .padding(16)
            }
        }
        .foregroundStyle(Palette.ink)
        .fontDesign(.rounded)
    }
}

// MARK: - The counter's bottom panel

/// What the deck shows while you're at the counter: the shop shelves for Buy,
/// the sell list for Sell, and the reply buttons while you're chatting.
struct ShopPanel: View {
    let meadow: Meadow

    var body: some View {
        Group {
            if let chat = meadow.shopChat {
                chatPanel(chat)
            } else {
                switch meadow.shopMode {
                case .buy:
                    VStack(spacing: 10) {
                        counterNavRow
                        ShopTab(meadow: meadow)
                    }
                case .sell:
                    VStack(spacing: 10) {
                        counterNavRow
                        ShopSellView(meadow: meadow)
                    }
                case .options: optionsPanel
                }
            }
        }
        .foregroundStyle(Palette.ink)
        .fontDesign(.rounded)
    }

    /// Chat, Buy, Sell and Exit live down here now, under her chat screen.
    private var optionsPanel: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "hand.wave.fill")
                .font(.title2)
                .foregroundStyle(Palette.rose)
            Text("\(ShopLayout.owner?.name ?? "The shopkeeper") is at the counter.")
                .font(.callout)
                .opacity(0.8)
            DialogButton(label: "Chat") { meadow.shopStartChat() }
            DialogButton(label: "Buy") { meadow.shopMode = .buy }
            DialogButton(label: "Sell") { meadow.shopMode = .sell }
            DialogButton(label: "Exit", pink: false) { meadow.closeShopCounter() }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    /// Back to the counter options, or out of the shop entirely.
    private var counterNavRow: some View {
        HStack(spacing: 10) {
            DialogButton(label: "Back") { meadow.shopMode = .options }
            DialogButton(label: "Exit", pink: false) { meadow.closeShopCounter() }
        }
    }

    private func chatPanel(_ chat: TalkResult) -> some View {
        let name = ShopLayout.owner?.name ?? "The shopkeeper"
        return VStack(spacing: 10) {
            if meadow.shopChatAnswer != nil {
                Text("\(name) smiles at your answer.")
                    .font(.callout)
                    .opacity(0.8)
                DialogButton(label: "Done") { meadow.shopEndChat() }
            } else if let question = chat.question {
                Text("\(name) asked you something — your answer:")
                    .font(.caption.bold())
                    .opacity(0.7)
                ForEach(Array(question.answers.enumerated()), id: \.offset) { index, option in
                    DialogButton(label: option.text, pink: !option.isRude) {
                        meadow.shopAnswer(index)
                    }
                }
                Button("End chat") { meadow.shopEndChat() }
                    .font(.caption.bold())
                    .opacity(0.7)
            } else {
                Text("Just good company today.")
                    .font(.callout)
                    .opacity(0.8)
                DialogButton(label: "Done") { meadow.shopEndChat() }
            }
        }
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
