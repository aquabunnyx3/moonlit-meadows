import Foundation

// MARK: - Fishing (added by Merlin, 2026-10-30)

/// One fishing attempt at the Pond, from cast to resolution. The fish is rolled
/// when you cast (the pool follows the time, the weather and the moon); the
/// meter's difficulty comes from its rarity.
struct FishingSession: Equatable {
    enum Phase: Equatable {
        case casting, waiting, bite, meter, caught, escaped
    }

    var phase: Phase = .casting
    var fishID: String = ""
    /// Seconds run in the current phase.
    var elapsed: Double = 0
    /// How long the bobber waits before this fish bites (2–6 s).
    var biteDelay: Double = 3.5
    /// The meter marker, 0…1 along the bar.
    var marker: Double = 0
    var size: Int = 0
    var isNew = false
    var perfect = false

    var fish: Fish? { Fish.find(fishID) }
}

/// The timing meter's shape per rarity (Michelle's design): the marker sweeps
/// back and forth until the player stops it; zones shrink and the sweep speeds
/// up as the fish gets rarer. The gold sliver sits near the top of the bar.
enum FishingMeter {
    static func speed(for rarity: Rarity) -> Double {
        switch rarity {
        case .common: return 0.55
        case .uncommon: return 0.7
        case .rare: return 0.9
        case .epic: return 1.15
        case .legendary: return 1.4
        }
    }

    static func zones(for rarity: Rarity) -> (green: ClosedRange<Double>, gold: ClosedRange<Double>) {
        let (greenWidth, goldWidth): (Double, Double)
        switch rarity {
        case .common: (greenWidth, goldWidth) = (0.34, 0.07)
        case .uncommon: (greenWidth, goldWidth) = (0.28, 0.055)
        case .rare: (greenWidth, goldWidth) = (0.20, 0.04)
        case .epic: (greenWidth, goldWidth) = (0.14, 0.03)
        case .legendary: (greenWidth, goldWidth) = (0.10, 0.022)
        }
        let greenCenter = 0.46, goldCenter = 0.88
        return (greenCenter - greenWidth / 2...greenCenter + greenWidth / 2,
                goldCenter - goldWidth / 2...goldCenter + goldWidth / 2)
    }
}

extension Meadow {
    /// The moon runs on an 8-night cycle; every eighth night is full — the
    /// nights the Moonkoi and Seraphin swim, and the Moon Bunny is strongest.
    var isFullMoonNight: Bool { dayNumber > 0 && dayNumber % 8 == 7 }

    /// Casts a line from the Pond dock. The bite's fish is decided now, from
    /// whatever is swimming at this hour, in this weather, under this moon.
    func beginFishing() {
        guard town == .pond, fishing == nil else { return }
        let pool = Fish.pool(isNight: timeOfDay == .night, isDusk: timeOfDay == .dusk,
                             isRaining: weather == .rainy, isFullMoon: isFullMoonNight,
                             dockmasterCaught: fishBook["old-dockmaster"] != nil)
        guard let fish = Fish.roll(in: pool) else { return }
        fishing = FishingSession(fishID: fish.id,
                                 biteDelay: .random(in: 2...6),
                                 size: .random(in: fish.sizeCM.min...fish.sizeCM.max))

        feedbackCount += 1
    }

    /// Runs the session's clock (called every frame by the fishing view).
    func advanceFishing(dt: Double) {
        guard var session = fishing, dt > 0 else { return }
        session.elapsed += dt
        switch session.phase {
        case .casting where session.elapsed >= 1.4:
            session.phase = .waiting
            session.elapsed = 0

        case .waiting where session.elapsed >= session.biteDelay:
            session.phase = .bite
            session.elapsed = 0

        case .bite where session.elapsed >= 0.9:
            session.phase = .meter
            session.elapsed = 0

        case .meter:
            guard let fish = session.fish else { return }
            let cycle = (session.elapsed * FishingMeter.speed(for: fish.rarity)).truncatingRemainder(dividingBy: 2)
            session.marker = cycle <= 1 ? cycle : 2 - cycle
        default:
            break
        }
        fishing = session
    }

    /// The action button while fishing: in the meter round it stops the marker.
    func fishingTap() {
        guard fishing?.phase == .meter else { return }
        resolveFishing()
    }

    private func resolveFishing() {
        guard var session = fishing, session.phase == .meter, let fish = session.fish else { return }
        let zones = FishingMeter.zones(for: fish.rarity)
        if zones.gold.contains(session.marker) {
            landCatch(&session, fish: fish, perfect: true)
        } else if zones.green.contains(session.marker) {
            landCatch(&session, fish: fish, perfect: false)
        } else {
            session.phase = .escaped

        }
        session.elapsed = 0
        fishing = session
    }

    private func landCatch(_ session: inout FishingSession, fish: Fish, perfect: Bool) {
        session.phase = .caught
        session.perfect = perfect
        session.isNew = fishBook[fish.id] == nil
        if session.isNew { fishBook[fish.id] = now }
        addItems("fish-\(fish.id)", 1)
        if perfect {
            // A Perfect catch pays half again, right there at the pond.
            coins += fish.value / 2

        } else {

        }
        moment("firstFish", "🎣 First catch! Fish wait in your Pantry — sell them at the Shop, and every species fills a page in your Fish book.")
        save()
    }

    /// Casts again from the catch/escape card.
    func fishAgain() {
        fishing = nil
        beginFishing()
    }

    /// Puts the rod away and returns to the Pond.
    func endFishing() {
        fishing = nil
    }
}
