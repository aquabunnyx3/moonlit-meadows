import SwiftUI
import UIKit

enum PanelTab: String, CaseIterable, Identifiable {
    case farm
    case pantry
    case lures
    case bunnies
    case friends
    case journal
    case shop

    var id: String { rawValue }

    var title: String {
        switch self {
        case .farm: return "Farm"
        case .pantry: return "Pantry"
        case .lures: return "Lures"
        case .bunnies: return "Bunnies"
        case .friends: return "Friends"
        case .journal: return "Journal"
        case .shop: return "Shop"
        }
    }

    /// Pixel-art icon from the asset catalog (`tab-<id>`), used instead of the emoji when present.
    var icon: UIImage? { UIImage(named: "tab-\(rawValue)") }

    var emoji: String {
        switch self {
        case .farm: return "🌱"
        case .pantry: return "🧁"
        case .lures: return "🧺"
        case .bunnies: return "🐰"
        case .friends: return "💌"
        case .journal: return "📖"
        case .shop: return "🎀"
        }
    }
}

extension AnyTransition {
    /// Slides up from the bottom with a fade, and back down on the way out.
    static var panelSlide: AnyTransition {
        .move(edge: .bottom).combined(with: .opacity)
    }
}

/// The bottom screen: a tab rail on the side and the selected tab's content.
struct ControlPanel: View {
    let meadow: Meadow
    /// Tabs across the top (like the design mockup) or down the side.
    var railAxis: Axis = .horizontal
    private var tab: PanelTab {
        get { PanelTab(rawValue: meadow.panelTabID) ?? .farm }
        nonmutating set { meadow.panelTabID = newValue.rawValue }
    }

    var body: some View {
        let layout = railAxis == .vertical
            ? AnyLayout(HStackLayout(spacing: 10))
            : AnyLayout(VStackLayout(spacing: 10))

        let hasPaper = WorldArt.panel != nil

        layout {
            if meadow.showsFarmerCreator {
                // The farmer creator takes over the deck: tap a category, then a choice.
                FarmerOptionsPanel(meadow: meadow)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(12)
                    .background(hasPaper ? Palette.cream.opacity(0.35) : Palette.cream, in: .rect(cornerRadius: 26))
                    .transition(.panelSlide)
            } else if let person = meadow.focusedPersonID.flatMap(Person.find) {
                PersonActionsPanel(meadow: meadow, person: person)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(12)
                    .background(hasPaper ? Palette.cream.opacity(0.35) : Palette.cream, in: .rect(cornerRadius: 26))
                    .transition(.panelSlide)
            } else if meadow.isAtHome {
                HomePanel(meadow: meadow)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(12)
                    .background(hasPaper ? Palette.cream.opacity(0.35) : Palette.cream, in: .rect(cornerRadius: 26))
                    .transition(.panelSlide)
            } else {
                rail
                content
                    .id(tab)
                    .transition(.panelSlide)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(12)
                    .background(hasPaper ? Palette.cream.opacity(0.35) : Palette.cream, in: .rect(cornerRadius: 26))
            }
        }
        // Panels slide up and fade in, and slide down and fade out (0.25 s, ease-out).
        .animation(.easeOut(duration: 0.25), value: panelMode)
        .animation(.easeOut(duration: 0.25), value: meadow.panelTabID)
        .padding(hasPaper ? 10 : 0)
        .background {
            // Watercolor paper with a flowery border, from the design art.
            if let paper = WorldArt.panel {
                Image(uiImage: paper)
                    .resizable()
                    .scaledToFill()
            }
        }
        .clipShape(.rect(cornerRadius: hasPaper ? 28 : 0))
        .sensoryFeedback(.impact(weight: .light), trigger: meadow.feedbackCount)
    }

    /// Which panel the deck shows, so switching between them animates.
    private var panelMode: String {
        if meadow.showsFarmerCreator { return "creator" }
        if let id = meadow.focusedPersonID { return "person-\(id)" }
        if meadow.isAtHome { return "home" }
        return "tabs"
    }

    private var rail: some View {
        ScrollView(railAxis == .vertical ? .vertical : .horizontal) {
            let layout = railAxis == .vertical
                ? AnyLayout(VStackLayout(spacing: 6))
                : AnyLayout(HStackLayout(spacing: 6))
            layout {
                ForEach(PanelTab.allCases) { item in
                    Button {
                        withAnimation(.easeOut(duration: 0.25)) { tab = item }
                    } label: {
                        VStack(spacing: 2) {
                            if let icon = item.icon {
                                Image(uiImage: icon)
                                    .resizable()
                                    .interpolation(.none)
                                    .scaledToFit()
                                    .frame(height: 24)
                            } else {
                                Text(item.emoji)
                                    .font(.title3)
                            }
                            Text(item.title)
                                .font(.caption.weight(.bold))
                        }
                        .foregroundStyle(Palette.ink)
                        .frame(width: 72, height: 56)
                        .pixelPanel(tileColors(item).fill, edge: tileColors(item).edge, cornerRadius: 14)
                        .overlay {
                            if tab == item {
                                RoundedRectangle(cornerRadius: 16)
                                    .strokeBorder(Palette.rose, lineWidth: 3)
                                    .padding(-3)
                            }
                        }
                        .offset(y: tab == item ? -2 : 0)
                        .overlay(alignment: .topTrailing) {
                            if hasBadge(item) {
                                Circle()
                                    .fill(Palette.rose)
                                    .frame(width: 10, height: 10)
                                    .padding(5)
                            }
                        }
                    }
                    .buttonStyle(SquishButtonStyle())
                    .accessibilityAddTraits(tab == item ? .isSelected : [])
                }
            }
            .padding(8)
        }
        .scrollIndicators(.hidden)
        .frame(width: railAxis == .vertical ? 90 : nil, height: railAxis == .horizontal ? 74 : nil)
    }

    @ViewBuilder
    private var content: some View {
        switch tab {
        case .farm: FarmTab(meadow: meadow)
        case .pantry: PantryTab(meadow: meadow)
        case .lures: LureTab(meadow: meadow)
        case .bunnies: CollectionTab(meadow: meadow)
        case .friends: FriendsTab(meadow: meadow)
        case .journal: JournalTab(meadow: meadow)
        case .shop: ShopTab(meadow: meadow)
        }
    }

    /// Lavender tiles, with Lures in blue and Friends in pink, like the panel mockup.
    private func tileColors(_ item: PanelTab) -> (fill: Color, edge: Color) {
        switch item {
        case .lures: return (Palette.periwinkle, Palette.periwinkleEdge)
        case .friends: return (Palette.pinkCard, Palette.pinkEdge)
        default: return (Palette.lilacCard, Palette.lilacEdge)
        }
    }

    private func hasBadge(_ item: PanelTab) -> Bool {
        switch item {
        case .farm: return meadow.readyPlotCount > 0
        case .pantry: return Recipe.all.contains(where: meadow.canCraft)
        case .lures: return meadow.lureSlots.contains(where: \.hasArrived)
        case .bunnies: return !meadow.claimableMilestones.isEmpty
        case .friends: return Person.all.contains { !meadow.unseenEvents(for: $0.id).isEmpty || meadow.canTalk(to: $0.id) }
        case .journal: return meadow.pendingRewardCount > 0 || meadow.availableQuests.contains(where: meadow.canComplete)
        case .shop: return false
        }
    }
}
