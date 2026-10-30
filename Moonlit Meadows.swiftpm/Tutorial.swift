import SwiftUI

// MARK: - The Tour (added by Merlin, 2026-10-30, while Claude was rate-limited)

/// The short guided Tour a new farmer takes right after the intro movie and the
/// welcome card (Michelle's design): five locked steps — walk, plant, the watering
/// can, Pantry, Journal. While the Tour runs, only the glowing control answers;
/// anything else gets "Try tapping … again to proceed." Movement is never locked
/// (you have to reach the garden beds), but tabs and the action button are.
///
/// One adaptation from the original sketch: this game's crops grow on timers and
/// the watering can is a gem-paid "grow everything" shortcut, so the water step
/// teaches the can (tap it, learn what it does) instead of spending the player's
/// gems. The farming one-liner stands: plant, water, wait, pick.
enum TourStep: String, Codable, Equatable {
    case notStarted, move, plant, water, pantry, journal, done

    var isActive: Bool { self != .notStarted && self != .done }

    /// The banner line for this step.
    var hint: String {
        switch self {
        case .move: return "👣 Use the D-pad to take a little walk."
        case .plant: return "🌱 Walk to a garden bed, face it, and tap the glowing button to plant a seed."
        case .water: return "💧 Tap the watering can. It grows everything at once for gems — a handy shortcut. Plant, water, wait, pick: that's farming!"
        case .pantry: return "🧺 Tap Pantry to see everything you're carrying."
        case .journal: return "📖 Last one — tap Journal. Your quests and notes live there."
        case .notStarted, .done: return ""
        }
    }

    /// What a wrong tap should point back at, in Michelle's wording.
    var feature: String {
        switch self {
        case .move: return "the D-pad"
        case .plant: return "the glowing button"
        case .water: return "the watering can"
        case .pantry: return "Pantry"
        case .journal: return "Journal"
        case .notStarted, .done: return ""
        }
    }

    /// The tab this step is waiting for, if any.
    var targetTab: PanelTab? {
        switch self {
        case .pantry: return .pantry
        case .journal: return .journal
        default: return nil
        }
    }
}

extension Meadow {
    /// Starts the Tour (called when the welcome card is dismissed on a new save).
    func startTour() {
        guard tourStep == .notStarted else { return }
        tourStep = .move
        tourAnchor = farmerSpot
        tourToast = nil
        save()
    }

    /// Skips the rest of the Tour.
    func tourSkip() {
        tourStep = .done
        tourToast = nil
        save()
    }

    func tourAdvance() {
        tourToast = nil
        switch tourStep {
        case .move: tourStep = .plant
        case .plant: tourStep = .water
        case .water: tourStep = .pantry
        case .pantry: tourStep = .journal
        case .journal:
            tourStep = .done
            tourDidFinish()
        default: return
        }
        feedbackCount += 1
        save()
    }

    /// The Tour's send-off: the "Settle In" quest is waiting in the Journal.
    /// (Quest hook lives with the Moments system; the banner carries the news
    /// until then.)
    func tourDidFinish() {
        tourToast = "🎉 That's the tour — you're a farmer now! Your first quest, Settle In, is in the Journal."
    }

    func tourWrongTap() {
        guard tourStep.isActive else { return }
        tourToast = "Try tapping \(tourStep.feature) again to proceed."
        feedbackCount += 1
    }

    /// The move step completes once you've actually walked a little way.
    func tourNoteMovement(from start: Spot) {
        guard tourStep == .move, let anchor = tourAnchor else { return }
        let dx = (walkerSpot.x - anchor.x) * 1.4, dy = walkerSpot.y - anchor.y
        if (dx * dx + dy * dy).squareRoot() >= 0.05 {
            tourAnchor = nil
            tourAdvance()
        }
    }

    /// Selecting the watering can completes the water step.
    func tourNoteWaterCan() {
        guard tourStep == .water else { return }
        tourAdvance()
    }

    /// Gates the action button during the Tour. Returns true when the press was a
    /// wrong tap and has been swallowed (the toast says what to tap instead).
    /// The plant step lets a real Plant through; its completion advances the Tour
    /// from the end of `deckAction`.
    func tourBlocksAction() -> Bool {
        guard tourStep.isActive else { return false }
        if tourStep == .plant,
           let target = deckTarget(), case .plot = target.kind, target.verb.hasPrefix("Plant") {
            return false
        }
        tourWrongTap()
        return true
    }

    /// Routes a tab-bar tap during the Tour. Returns true when the Tour handled
    /// the tap (opened the wanted tab and advanced, or refused with a toast).
    func tourTapTab(_ tab: PanelTab, isOpen: Bool) -> Bool {
        guard tourStep.isActive else { return false }
        if tourStep.targetTab == tab && !isOpen {
            panelTabID = tab.rawValue
            tourAdvance()
        } else {
            tourWrongTap()
        }
        return true
    }
}

/// The pulsing rose ring drawn around whichever control the Tour is waiting for.
struct TourRing: View {
    var cornerRadius: CGFloat = 16
    @State private var dim = false

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .stroke(Palette.rose, lineWidth: 3)
            .opacity(dim ? 0.3 : 1)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) { dim = true }
            }
    }
}
