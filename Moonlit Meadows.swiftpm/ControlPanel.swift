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

/// The bottom screen. In the world it's the control deck (tabs, D-pad, quick inventory and
/// action buttons); the farmer creator and a character's profile bring their own panels.
struct ControlPanel: View {
    let meadow: Meadow

    var body: some View {
        let hasPaper = WorldArt.panel != nil

        Group {
            if meadow.showsFarmerCreator {
                // The farmer creator takes over the deck: tap a category, then a choice.
                FarmerOptionsPanel(meadow: meadow)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(12)
                    .background(hasPaper ? Palette.cream.opacity(0.35) : Palette.cream, in: .rect(cornerRadius: 26))
                    .transition(.panelSlide)
            } else if meadow.shopCounterOpen {
                // At the shop counter: buying, selling, or the chat's reply buttons.
                ShopPanel(meadow: meadow)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(12)
                    .background(hasPaper ? Palette.cream.opacity(0.35) : Palette.cream, in: .rect(cornerRadius: 26))
                    .transition(.panelSlide)
            } else if let person = meadow.focusedPersonID.flatMap(Person.find) {
                if let talk = meadow.profileTalk, let question = talk.question, meadow.profileAnswer == nil {
                    // They asked you something: the answer buttons live here,
                    // under their chat scene, until you pick one.
                    ProfileAnswerPanel(meadow: meadow, person: person, question: question)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(12)
                        .background(hasPaper ? Palette.cream.opacity(0.35) : Palette.cream, in: .rect(cornerRadius: 26))
                        .transition(.panelSlide)
                } else {
                    PersonInfoCard(meadow: meadow, person: person)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(12)
                        .background(hasPaper ? Palette.cream.opacity(0.35) : Palette.cream, in: .rect(cornerRadius: 26))
                        .transition(.panelSlide)
                }
            } else {
                ControlDeck(meadow: meadow)
                    .padding(12)
                    .background(Palette.deck, in: .rect(cornerRadius: 26))
                    .overlay(RoundedRectangle(cornerRadius: 26).strokeBorder(Palette.lilacEdge, lineWidth: 3))
                    .transition(.panelSlide)
            }
        }
        // Panels slide up and fade in, and slide down and fade out (0.25 s, ease-out).
        .animation(.easeOut(duration: 0.25), value: panelMode)
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
        return "deck"
    }
}
