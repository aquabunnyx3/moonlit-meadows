import SwiftUI
import UIKit

// MARK: - Control deck: walking and doing

/// A direction on the D-pad, or how far to step: x across, y down the screen.
struct DeckVector: Equatable {
    var x: Double
    var y: Double

    static let zero = DeckVector(x: 0, y: 0)
    var isZero: Bool { x == 0 && y == 0 }
}

/// The quick inventory: what's in your farmer's hands, from left to right.
enum QuickSlot: Equatable {
    /// Harvests everything that's ready and replants it (the old "Harvest all").
    case harvest
    /// The seed you picked: plants empty plots, and harvests a ready one.
    case seeds
    /// Grows every crop at once for gems (the old "Grow all").
    case water
    /// A seed picked lately, one tap away. Picking it puts it in the seeds slot.
    case spareSeed(String)
    /// Something from your carried inventory, picked in the main grid. A crop in hand plants
    /// that crop; anything else works plots like the seed in hand.
    case item(String)
}

/// What the action button would do right now, and where.
struct DeckTarget: Equatable {
    enum Kind: Equatable {
        case person(String)
        case cottageDoor
        case lureBasket
        case plot(Int)
        case bed, chair, chest, petBed, homeDoor
        case goToTown, goToFarm, goToPond, leavePond, fish, moonBunny, digCapsule, enterHouse(String), leaveHouse, shop, stall, shopCounter
        /// Something to look at: the action button shows its line.
        case look(String)
    }

    enum Icon: Equatable {
        /// A drawn icon from the assets, like `icon-seed-packet`.
        case asset(String)
        /// An item's own icon (a crop for Harvest).
        case item(String)
        case emoji(String)
    }

    let kind: Kind
    /// The button's verb, for the context chip.
    let verb: String
    let icon: Icon
    var canAct = true
    /// Where it is, to mark it in the world (world or room fractions).
    let spot: Spot
    /// What the blue button does here, if anything besides Back.
    var secondary: String?
}

/// A rectangle in world (or room) fractions.
struct DeckRect {
    let minX, minY, maxX, maxY: Double

    func contains(_ x: Double, _ y: Double) -> Bool {
        x >= minX && x <= maxX && y >= minY && y <= maxY
    }

    /// How far a point is from the rectangle (0 inside), with x stretched by the art's aspect.
    func distance(_ x: Double, _ y: Double, aspect: Double) -> Double {
        let dx = max(minX - x, 0, x - maxX) * aspect
        let dy = max(minY - y, 0, y - maxY)
        return (dx * dx + dy * dy).squareRoot()
    }

    var center: Spot { Spot(x: (minX + maxX) / 2, y: (minY + maxY) / 2) }
}

/// A solid thing your farmer can't walk into, named so the collision overlay can label it:
/// a rectangle, or a simple outline (like a gable roof) where a rectangle can't fit.
struct BlockZone {
    let label: String
    /// Its outline, in order around the edge.
    let points: [Spot]

    init(label: String, rect: DeckRect) {
        self.label = label
        points = [Spot(x: rect.minX, y: rect.minY), Spot(x: rect.maxX, y: rect.minY),
                  Spot(x: rect.maxX, y: rect.maxY), Spot(x: rect.minX, y: rect.maxY)]
    }

    init(label: String, outline: [Spot]) {
        self.label = label
        points = outline
    }

    var bounds: DeckRect {
        DeckRect(minX: points.map(\.x).min() ?? 0, minY: points.map(\.y).min() ?? 0,
                 maxX: points.map(\.x).max() ?? 0, maxY: points.map(\.y).max() ?? 0)
    }

    /// Whether a point is inside the outline.
    func contains(_ spot: Spot) -> Bool {
        var inside = false
        var j = points.count - 1
        for i in points.indices {
            let a = points[i], b = points[j]
            if (a.y > spot.y) != (b.y > spot.y),
               spot.x < (b.x - a.x) * (spot.y - a.y) / (b.y - a.y) + a.x {
                inside.toggle()
            }
            j = i
        }
        return inside
    }

    /// Whether it overlaps a (small) box: any of the box's corners, edge middles or center
    /// inside the outline, or any outline corner inside the box.
    func overlaps(_ box: DeckRect) -> Bool {
        guard bounds.intersects(box) else { return false }
        let xs = [box.minX, (box.minX + box.maxX) / 2, box.maxX]
        let ys = [box.minY, (box.minY + box.maxY) / 2, box.maxY]
        for x in xs { for y in ys where contains(Spot(x: x, y: y)) { return true } }
        return points.contains { box.contains($0.x, $0.y) }
    }
}

/// Where your farmer can walk in one scene, measured from that scene's own picture (as
/// fractions of it, like `farmerSpot`): the walkable area, a backstop at the edges of the
/// world, and every solid thing in it. Doors, gates and exits are never in here; they're
/// separate trigger zones.
struct SceneCollision {
    let name: String
    let bounds: DeckRect
    let blocks: [BlockZone]
    /// Your farmer's height here, in art heights. Her foot box and pace scale with it.
    let figure: Double
    /// How far ahead of her feet the action button reaches, in art heights.
    let reach: Double

    /// Every scene's picture is 2096 × 1184 and shown at that shape.
    static let aspect = 2096.0 / 1184.0

    /// Only her feet collide: a small box across the bottom of the sprite, so her head and
    /// body can pass in front of tree tops, awnings and roofs.
    func footBox(at spot: Spot) -> DeckRect {
        let halfWidth = figure * 0.1 / Self.aspect
        return DeckRect(minX: spot.x - halfWidth, minY: spot.y - figure * 0.12, maxX: spot.x + halfWidth, maxY: spot.y)
    }

    func isFree(_ spot: Spot) -> Bool {
        guard bounds.contains(spot.x, spot.y) else { return false }
        let feet = footBox(at: spot)
        return !blocks.contains { $0.overlaps(feet) }
    }
}

extension DeckRect {
    func intersects(_ other: DeckRect) -> Bool {
        minX < other.maxX && other.minX < maxX && minY < other.maxY && other.minY < maxY
    }
}

extension Meadow {
    /// Walking pace, in your farmer's own heights per second (so she crosses a room and the
    /// farm at the same brisk pace, whatever size she's drawn).
    static let pace = 1.1
    /// How far one walk cycle (two steps) carries her, in her own heights. The walk cycle is
    /// driven by distance walked, so her feet keep up with the ground.
    static let stride = 0.75
    /// Things this close to your farmer's feet count as in reach even when not faced.
    static let nearReach = 0.07

    /// Where you start on the farm: on the stone path below the cottage steps.
    static let farmStart = Spot(x: 0.497, y: 0.40)

    /// The farm (`world-meadow`), item by item from the picture. Bushes, flowers, grass and the
    /// stone paths are walkable; trees block only at the trunk.
    static let farmCollision = SceneCollision(
        name: "Farm",
        bounds: DeckRect(minX: 0.135, minY: 0.04, maxX: 0.95, maxY: 0.95),
        blocks: [
            BlockZone(label: "farm: cottage", rect: DeckRect(minX: 0.425, minY: 0, maxX: 0.575, maxY: 0.295)),
            BlockZone(label: "farm: cottage window box", rect: DeckRect(minX: 0.52, minY: 0.27, maxX: 0.572, maxY: 0.322)),
            BlockZone(label: "farm: shed door", rect: DeckRect(minX: 0.363, minY: 0.175, maxX: 0.395, maxY: 0.262)),
            BlockZone(label: "farm: rock by the bush", rect: DeckRect(minX: 0.185, minY: 0.155, maxX: 0.215, maxY: 0.19)),
            BlockZone(label: "farm: rock (north)", rect: DeckRect(minX: 0.722, minY: 0.115, maxX: 0.745, maxY: 0.15)),
            BlockZone(label: "farm: rock (middle)", rect: DeckRect(minX: 0.7, minY: 0.185, maxX: 0.725, maxY: 0.22)),
            BlockZone(label: "farm: rocks (top edge)", rect: DeckRect(minX: 0.79, minY: 0.02, maxX: 0.82, maxY: 0.06)),
            BlockZone(label: "farm: pink tree trunk (northeast)", rect: DeckRect(minX: 0.885, minY: 0.205, maxX: 0.915, maxY: 0.25)),
            BlockZone(label: "farm: pink tree trunk (east)", rect: DeckRect(minX: 0.745, minY: 0.4, maxX: 0.775, maxY: 0.445)),
            BlockZone(label: "farm: pink tree trunk (southeast)", rect: DeckRect(minX: 0.825, minY: 0.645, maxX: 0.87, maxY: 0.7)),
            BlockZone(label: "farm: pine trunk (south)", rect: DeckRect(minX: 0.845, minY: 0.86, maxX: 0.872, maxY: 0.9)),
            BlockZone(label: "farm: pine trunk (far south)", rect: DeckRect(minX: 0.945, minY: 0.88, maxX: 0.975, maxY: 0.92)),
            BlockZone(label: "farm: rocks (south)", rect: DeckRect(minX: 0.67, minY: 0.915, maxX: 0.75, maxY: 0.99)),
            // The fenced beds on the left: you plant them over the fence.
            BlockZone(label: "farm: bed fence (north)", rect: DeckRect(minX: 0.168, minY: 0.335, maxX: 0.368, maxY: 0.372)),
            BlockZone(label: "farm: bed fence (south)", rect: DeckRect(minX: 0.168, minY: 0.715, maxX: 0.368, maxY: 0.76)),
            BlockZone(label: "farm: bed fence (west)", rect: DeckRect(minX: 0.168, minY: 0.335, maxX: 0.18, maxY: 0.76)),
            BlockZone(label: "farm: bed fence (east)", rect: DeckRect(minX: 0.356, minY: 0.335, maxX: 0.368, maxY: 0.76)),
            BlockZone(label: "farm: bed 1", rect: DeckRect(minX: 0.19, minY: 0.395, maxX: 0.258, maxY: 0.525)),
            BlockZone(label: "farm: bed 2", rect: DeckRect(minX: 0.277, minY: 0.395, maxX: 0.345, maxY: 0.525)),
            BlockZone(label: "farm: bed 3", rect: DeckRect(minX: 0.19, minY: 0.572, maxX: 0.258, maxY: 0.702)),
            BlockZone(label: "farm: bed 4", rect: DeckRect(minX: 0.277, minY: 0.572, maxX: 0.345, maxY: 0.702)),
            // The big field on the right: worked over its fence too.
            BlockZone(label: "farm: field fence (north)", rect: DeckRect(minX: 0.598, minY: 0.522, maxX: 0.838, maxY: 0.555)),
            BlockZone(label: "farm: field fence (west)", rect: DeckRect(minX: 0.598, minY: 0.522, maxX: 0.615, maxY: 0.868)),
            BlockZone(label: "farm: field fence (east)", rect: DeckRect(minX: 0.826, minY: 0.522, maxX: 0.838, maxY: 0.868)),
            BlockZone(label: "farm: field fence (south)", rect: DeckRect(minX: 0.598, minY: 0.83, maxX: 0.838, maxY: 0.868)),
            BlockZone(label: "farm: field plots", rect: DeckRect(minX: 0.615, minY: 0.555, maxX: 0.826, maxY: 0.83)),
        ],
        figure: 0.13, reach: 0.09)

    static let cottageDoorstep = Spot(x: 0.497, y: 0.33)
    private static let cottageDoorZone = DeckRect(minX: 0.465, minY: 0.22, maxX: 0.53, maxY: 0.30)
    /// The lure basket's patch below the crop beds — no fence anymore, walk right up.
    private static let lureBasketZone = DeckRect(minX: 0.235, minY: 0.78, maxX: 0.355, maxY: 0.89)

    /// Inside your cottage (fractions of the room art).
    static let homeEntrance = Spot(x: 0.5, y: 0.86)
    private static let homeBed = DeckRect(minX: 0.10, minY: 0.30, maxX: 0.37, maxY: 0.63)
    private static let homeDesk = DeckRect(minX: 0.70, minY: 0.30, maxX: 0.88, maxY: 0.58)
    private static let homeChest = DeckRect(minX: 0.79, minY: 0.67, maxX: 0.90, maxY: 0.95)
    private static let homePetBed = DeckRect(minX: 0.10, minY: 0.77, maxX: 0.225, maxY: 0.95)
    private static let homeDoorZone = DeckRect(minX: 0.40, minY: 0.92, maxX: 0.60, maxY: 1.0)
    static let homeCollision = SceneCollision(
        name: "Your cottage",
        bounds: DeckRect(minX: 0.12, minY: 0.48, maxX: 0.88, maxY: 0.93),
        blocks: [
            BlockZone(label: "home: bed", rect: homeBed),
            BlockZone(label: "home: desk and chair", rect: homeDesk),
            BlockZone(label: "home: wardrobe", rect: homeChest),
            BlockZone(label: "home: pet bed", rect: homePetBed),
        ],
        figure: 0.36, reach: 0.06)

    /// The walking rules for wherever you are right now.
    var currentCollision: SceneCollision {
        switch town {
        case .hub?: return TownLayout.hubCollision
        case .house(let id)?: return TownLayout.interiors[id]?.collision ?? TownLayout.hubCollision
        case .pond?: return PondLayout.collision
        case nil: return isAtHome ? Self.homeCollision : Self.farmCollision
        }
    }

    /// Where your farmer's feet are in the scene you're in.
    var walkerSpot: Spot {
        get { town != nil ? townSpot : isAtHome ? homeSpot : farmerSpot }
        set {
            if town != nil { townSpot = newValue } else if isAtHome { homeSpot = newValue } else { farmerSpot = newValue }
        }
    }

    private var deckAspect: Double { SceneCollision.aspect }

    var isDeckMoving: Bool { !deckDirection.isZero }

    /// Holds a D-pad direction, or lets go with zero. Your farmer only ever moves while a
    /// direction is held, and stops the moment it's let go.
    func holdDirection(_ direction: DeckVector) {
        guard !isSleeping else { return }
        if !direction.isZero, isAtHome, isSitting {
            // Stand up from the chair first, in front of it.
            isSitting = false
            homeSpot = Spot(x: 0.79, y: 0.66)
        }
        deckDirection = direction
    }

    /// Moves your farmer by however much time passed (called every screen frame while the
    /// D-pad is held), at a constant pace. Anything solid stops her; she slides along it,
    /// trying across and up-and-down separately so diagonals glide along walls.
    func deckStep(dt: Double) {
        if fishing != nil { return }
        if shopCounterOpen { deckDirection = .zero; return }
        guard !deckDirection.isZero, !isPaused, !isAtMainMenu, !isSleeping, dt > 0 else { return }
        let scene = currentCollision
        let d = deckDirection
        let length = (d.x * d.x + d.y * d.y).squareRoot()
        let step = scene.figure * Self.pace * min(dt, 0.05) / max(length, 1)
        deckFacing = d
        // Keep facing the way she already faces if she's still going that way, so turning
        // onto a diagonal doesn't snap her around; otherwise face across, then up or down.
        let across: PersonArt.Facing? = d.x > 0 ? .right : d.x < 0 ? .left : nil
        let upDown: PersonArt.Facing? = d.y > 0 ? .front : d.y < 0 ? .back : nil
        if farmerFacing != across && farmerFacing != upDown {
            farmerFacing = across ?? upDown ?? farmerFacing
        }
        let from = walkerSpot
        var x = from.x, y = from.y
        let nx = x + d.x * step / SceneCollision.aspect
        if scene.isFree(Spot(x: nx, y: y)) { x = nx }
        let ny = y + d.y * step
        if scene.isFree(Spot(x: x, y: ny)) { y = ny }
        let moved = (((x - from.x) * SceneCollision.aspect) * ((x - from.x) * SceneCollision.aspect) + (y - from.y) * (y - from.y)).squareRoot()
        walkerSpot = Spot(x: x, y: y)
        walkedFigures += moved / scene.figure
        tourNoteMovement(from: from)
        // Glass doors slide open while you're by them, and shut when you walk away.
        if case .house(let id)? = town, let door = TownLayout.interiors[id]?.glassDoor {
            let near = door.approach.contains(x, y)
            if near != glassDoorOpen { glassDoorOpen = near }
        }
        // Walking down off the end of the path between the farm and the village takes you there.
        if d.y > 0 {
            if town == .hub, TownLayout.farmExitPath.contains(x, y) {
                goToFarm()
            } else if town == nil, !isAtHome, Self.villagePath.contains(x, y) {
                goToTown()
            } else if town == .pond, PondLayout.exitZone.contains(x, y) {
                goToFarmFromPond()
            }
        }
        // Walking up the footpath off the farm's north edge takes you to the Pond.
        if d.y < 0, town == nil, !isAtHome, Self.farmPondZone.contains(x, y) {
            goToPond()
        }
    }

    /// The very end of the farm's bottom path: walking into it goes to the village.
    static let villagePath = DeckRect(minX: 0.44, minY: 0.94, maxX: 0.56, maxY: 1)

    /// The footpath off the farm's north edge: walking up into it goes to the Pond.
    static let farmPondZone = DeckRect(minX: 0.26, minY: 0.0, maxX: 0.34, maxY: 0.075)

    /// The walk cycle's clock: one cycle per stride walked, so the steps match the ground.
    var walkCycleTime: Double { walkedFigures / Self.stride }

    /// The point just in front of your farmer, where the faced thing is.
    private func facedPoint(from spot: Spot) -> Spot {
        let d = deckFacing
        let length = max((d.x * d.x + d.y * d.y).squareRoot(), 0.001)
        let reach = currentCollision.reach
        return Spot(x: spot.x + d.x / length * reach / deckAspect,
                    y: spot.y + d.y / length * reach)
    }

    /// Where each character walking the meadow is right now, matching the world's drawing.
    func walkersInMeadow(at t: Double = Date().timeIntervalSinceReferenceDate) -> [(person: Person, spot: Spot)] {
        peopleInMeadow()
            .filter { PersonArt.walking(for: $0.id, facing: .front) != nil }
            .enumerated()
            .map { index, person in
                let ownsFavorite = bunnies.contains { person.favoriteBreeds.contains($0.breedID) }
                let route = WorldLayout.strollRoute(lane: index, visitsBunnies: ownsFavorite)
                let step = WorldLayout.routeStep(route, at: t + Double(index) * 7.3, aspect: worldAspect, speed: 0.045)
                return (person: person, spot: step.spot)
            }
    }

    /// What the action button would do: people first, then doors, then things, and among
    /// those, what you're facing before what's merely nearby.
    func deckTarget() -> DeckTarget? {
        guard !isSleeping else { return nil }
        if town != nil { return townTarget() }
        if isAtHome { return homeTarget() }
        let spot = farmerSpot
        let faced = facedPoint(from: spot)
        let aspect = deckAspect

        func pick<T>(_ items: [(T, DeckRect)]) -> T? {
            if let hit = items.first(where: { $0.1.contains(faced.x, faced.y) }) { return hit.0 }
            let near = items.map { ($0.0, $0.1.distance(spot.x, spot.y, aspect: aspect)) }
                .filter { $0.1 <= Self.nearReach }
                .min { $0.1 < $1.1 }
            return near?.0
        }
        func reaches(_ zone: DeckRect) -> Bool {
            zone.contains(faced.x, faced.y) || zone.distance(spot.x, spot.y, aspect: aspect) <= Self.nearReach
        }

        // People: a little box around where they're standing.
        let people = walkersInMeadow().map { walker in
            (walker, DeckRect(minX: walker.spot.x - 0.03, minY: walker.spot.y - 0.08, maxX: walker.spot.x + 0.03, maxY: walker.spot.y + 0.02))
        }
        if let walker = pick(people) {
            return DeckTarget(kind: .person(walker.person.id), verb: canTalk(to: walker.person.id) ? "Talk to \(walker.person.name)" : "Visit \(walker.person.name)",
                              icon: .emoji("💬"), spot: walker.spot, secondary: "Gift")
        }
        if let bunnySpot = moonBunnyFarmSpot {
            let zone = DeckRect(minX: bunnySpot.x - 0.07, minY: bunnySpot.y - 0.07, maxX: bunnySpot.x + 0.07, maxY: bunnySpot.y + 0.04)
            if reaches(zone) {
                return DeckTarget(kind: .moonBunny, verb: "A white bunny…", icon: .emoji("🐰"), spot: bunnySpot)
            }
        }
        if reaches(Self.cottageDoorZone) {
            return DeckTarget(kind: .cottageDoor, verb: "Enter", icon: .emoji("🚪"), spot: Spot(x: 0.497, y: 0.27))
        }
        if reaches(Self.farmToTownZone) {
            return DeckTarget(kind: .goToTown, verb: "Go to the Village", icon: .emoji("🏘️"), spot: Spot(x: 0.5, y: 0.93))
        }
        if reaches(Self.farmPondZone) {
            return DeckTarget(kind: .goToPond, verb: "Go to the Pond", icon: .emoji("🎣"), spot: Spot(x: 0.30, y: 0.06))
        }
        if reaches(Self.lureBasketZone) {
            let arrived = lureSlots.contains(where: \.hasArrived)
            return DeckTarget(kind: .lureBasket, verb: arrived ? "Greet Visitor" : "Set Lure",
                              icon: arrived ? .asset("icon-bunnies") : .asset("icon-pantry"), spot: WorldLayout.lureBasket)
        }
        let plotZones = plots.indices.map { index in (index, plotRect(index)) }
        if let index = pick(plotZones) {
            return plotTarget(index)
        }
        return nil
    }

    /// In reach: faced, or right next to your feet.
    private func reaches(_ zone: DeckRect, from spot: Spot, facing faced: Spot) -> Bool {
        zone.contains(faced.x, faced.y) || zone.distance(spot.x, spot.y, aspect: deckAspect) <= Self.nearReach
    }

    /// The faced one of these, or else the nearest in reach.
    private func closest<T>(_ items: [(T, DeckRect)], from spot: Spot, facing faced: Spot) -> T? {
        if let hit = items.first(where: { $0.1.contains(faced.x, faced.y) }) { return hit.0 }
        var best: (item: T, distance: Double)?
        for item in items {
            let distance = item.1.distance(spot.x, spot.y, aspect: deckAspect)
            if distance <= Self.nearReach, best == nil || distance < best!.distance {
                best = (item.0, distance)
            }
        }
        return best?.item
    }

    /// In the village: people, then doors and the path home, then the market stalls.
    /// In a house: whoever lives there, then the way out, then things to look at.
    private func townTarget() -> DeckTarget? {
        guard let town else { return nil }
        let spot = townSpot
        let faced = facedPoint(from: spot)
        switch town {
        case .hub:
            let people = townWalkers.map { walker in
                (walker, DeckRect(minX: walker.step.spot.x - 0.03, minY: walker.step.spot.y - 0.09,
                                  maxX: walker.step.spot.x + 0.03, maxY: walker.step.spot.y + 0.02))
            }
            if let walker = closest(people, from: spot, facing: faced) {
                return personTarget(walker.person, at: walker.step.spot)
            }
            let doors = TownLayout.houses.map { ($0, $0.doorZone) }
            if let house = closest(doors, from: spot, facing: faced) {
                if house.id == "shop" {
                    return DeckTarget(kind: .enterHouse("shop"), verb: "Enter", icon: .emoji("🚪"), spot: house.doorstep)
                }
                if house.ownerID != nil {
                    return DeckTarget(kind: .enterHouse(house.id), verb: "Enter", icon: .emoji("🚪"), spot: house.doorstep)
                }
                return DeckTarget(kind: .look("The Village Library is closed today. A note on the door says “Back after the harvest festival! — the librarian”."),
                                  verb: "Look at the Library", icon: .emoji("📚"), spot: house.doorstep)
            }
            if reaches(TownLayout.farmExit, from: spot, facing: faced) {
                return DeckTarget(kind: .goToFarm, verb: "Back to the Farm", icon: .emoji("🌾"), spot: Spot(x: 0.57, y: 0.97))
            }
            // Every market stall sells seeds (Shop) and buys your crops (Sell, on the blue button).
            if let stall = closest(TownLayout.stalls.map { ($0, $0) }, from: spot, facing: faced) {
                return DeckTarget(kind: .stall, verb: "Shop", icon: .asset("icon-seed-packet"),
                                  spot: Spot(x: stall.center.x, y: stall.maxY), secondary: "Sell")
            }
            return nil
        case .pond:
            if let bunnySpot = moonBunnyPondSpot {
                let zone = DeckRect(minX: bunnySpot.x - 0.08, minY: bunnySpot.y - 0.08, maxX: bunnySpot.x + 0.08, maxY: bunnySpot.y + 0.05)
                if PondLayout.dockZone.contains(spot.x, spot.y) || reaches(zone, from: spot, facing: faced) {
                    return DeckTarget(kind: .moonBunny, verb: revealReady || finaleReady ? "The white bunny is waiting…" : "A white bunny…",
                                      icon: .emoji("🐰"), spot: bunnySpot)
                }
            }
            if capsuleAvailable, reaches(PondLayout.capsuleZone, from: spot, facing: faced) {
                return DeckTarget(kind: .digCapsule, verb: "Something glints in the shore stones…", icon: .emoji("✨"), spot: PondLayout.capsuleZone.center)
            }
            if PondLayout.dockZone.contains(spot.x, spot.y) {
                return DeckTarget(kind: .fish, verb: "Fish", icon: .emoji("🎣"), spot: PondLayout.dockSpot)
            }
            if reaches(PondLayout.exitZone, from: spot, facing: faced) {
                return DeckTarget(kind: .leavePond, verb: "Back to the Farm", icon: .emoji("🌾"), spot: Spot(x: 0.5, y: 0.97))
            }
            return nil
        case .house(let id):
            guard let room = TownLayout.interiors[id] else { return nil }
            if id == "shop", reaches(ShopLayout.counterZone, from: spot, facing: faced) {
                return DeckTarget(kind: .shopCounter, verb: "Shop Counter", icon: .asset("icon-shop"), spot: ShopLayout.counterZone.center)
            }
            if let resident = houseResident {
                let box = DeckRect(minX: room.resident.x - 0.06, minY: room.resident.y - 0.16, maxX: room.resident.x + 0.06, maxY: room.resident.y + 0.03)
                if reaches(box, from: spot, facing: faced) {
                    return personTarget(resident, at: room.resident)
                }
            }
            if reaches(room.exit, from: spot, facing: faced) {
                return DeckTarget(kind: .leaveHouse, verb: "Exit", icon: .emoji("🚪"), spot: room.exit.center)
            }
            if let thing = closest(room.things.map { ($0, $0.zone) }, from: spot, facing: faced) {
                return DeckTarget(kind: .look(thing.text), verb: "Look at \(thing.name)", icon: .emoji("👀"), spot: thing.zone.center)
            }
            return nil
        }
    }

    private func personTarget(_ person: Person, at spot: Spot) -> DeckTarget {
        DeckTarget(kind: .person(person.id), verb: canTalk(to: person.id) ? "Talk to \(person.name)" : "Visit \(person.name)",
                   icon: .emoji("💬"), spot: spot, secondary: "Gift")
    }

    private func plotRect(_ index: Int) -> DeckRect {
        let center = WorldLayout.plot(index)
        if index < WorldLayout.beds.count {
            let size = WorldLayout.bedSize
            return DeckRect(minX: center.x - size.width / 2, minY: center.y - size.height / 2,
                            maxX: center.x + size.width / 2, maxY: center.y + size.height / 2)
        }
        let field = WorldLayout.field
        let w = (field.maxX - field.minX) / 8, h = (field.maxY - field.minY) / 4
        return DeckRect(minX: center.x - w, minY: center.y - h, maxX: center.x + w, maxY: center.y + h)
    }

    /// The plot's action for what's in your hands.
    private func plotTarget(_ index: Int) -> DeckTarget {
        let plot = plots[index]
        let spot = WorldLayout.plot(index)
        switch quickSlot {
        case .harvest:
            return DeckTarget(kind: .plot(index), verb: readyPlotCount > 0 ? "Harvest & Replant All" : "Nothing Ready",
                              icon: .asset("icon-carrot"), canAct: readyPlotCount > 0, spot: spot)
        case .water:
            let growing = plots.contains { $0.cropID != nil && !$0.isReady }
            return DeckTarget(kind: .plot(index), verb: "Water All · \(Self.growAllGemCost)💎", icon: .asset("icon-watering-can"),
                              canAct: growing && gems >= Self.growAllGemCost, spot: spot)
        case .seeds, .spareSeed, .item:
            if plot.isReady, let id = plot.cropID {
                return DeckTarget(kind: .plot(index), verb: "Harvest \(Crop.find(id)?.name ?? "Crop")", icon: .item(id), spot: spot)
            }
            if let id = plot.cropID {
                let left = secondsLeft(on: plot).map { " · \($0.countdown)" } ?? ""
                return DeckTarget(kind: .plot(index), verb: "\(Crop.find(id)?.name ?? "Crop") Growing\(left)", icon: .item(id),
                                  canAct: false, spot: spot)
            }
            let crop = Crop.find(selectedSeed)
            let affordable = crop.map { coins >= $0.seedCost && isUnlocked($0) } ?? false
            return DeckTarget(kind: .plot(index), verb: "Plant \(crop?.name ?? "Seeds")", icon: .asset("icon-seed-packet"),
                              canAct: affordable, spot: spot)
        }
    }

    private func homeTarget() -> DeckTarget? {
        guard !isSitting else {
            return DeckTarget(kind: .chair, verb: "Stand Up", icon: .emoji("🪑"), spot: Spot(x: 0.79, y: 0.6))
        }
        let spot = homeSpot
        let faced = facedPoint(from: spot)
        let aspect = deckAspect
        let things: [(DeckTarget.Kind, DeckRect)] = [
            (.homeDoor, Self.homeDoorZone),
            (.bed, Self.homeBed),
            (.chair, DeckRect(minX: 0.73, minY: 0.48, maxX: 0.86, maxY: 0.62)),
            (.chest, Self.homeChest),
            (.petBed, Self.homePetBed),
        ]
        var found: (kind: DeckTarget.Kind, zone: DeckRect)?
        if let hit = things.first(where: { $0.1.contains(faced.x, faced.y) }) {
            found = (hit.0, hit.1)
        } else {
            var best = Self.nearReach
            for thing in things {
                let distance = thing.1.distance(spot.x, spot.y, aspect: aspect)
                if distance <= best {
                    best = distance
                    found = (thing.0, thing.1)
                }
            }
        }
        guard let kind = found?.kind, let zone = found?.zone else { return nil }
        switch kind {
        case .homeDoor:
            return DeckTarget(kind: kind, verb: "Go Outside", icon: .emoji("🚪"), spot: Spot(x: 0.5, y: 0.94))
        case .bed:
            return DeckTarget(kind: kind, verb: "Sleep", icon: .asset("moon-coin"), spot: zone.center)
        case .chair:
            return DeckTarget(kind: kind, verb: "Sit", icon: .emoji("🪑"), spot: Spot(x: 0.79, y: 0.6))
        case .chest:
            return DeckTarget(kind: kind, verb: "Open Storage", icon: .emoji("📦"), spot: zone.center)
        case .petBed:
            let bunny = bunnies.first(where: \.isFavorite) ?? bunnies.first
            return DeckTarget(kind: kind, verb: bunny.map { "Pick Up \($0.name)" } ?? "Empty Pet Bed", icon: .asset("icon-bunnies"),
                              canAct: bunny != nil, spot: zone.center)
        default:
            return nil
        }
    }

    /// The big pink button.
    func deckAction() {
        if fishing != nil { fishingTap(); return }
        if shopCounterOpen { return }
        if tourBlocksAction() { return }
        guard let target = deckTarget(), target.canAct else { return }
        deckDirection = .zero
        switch target.kind {
        case .person(let id):
            openProfile(id)
            if canTalk(to: id) {
                profileTalk = talk(to: id)
                profileAnswer = nil
            }
        case .cottageDoor:
            enterHome()
        case .lureBasket:
            if let index = lureSlots.firstIndex(where: \.hasArrived) {
                _ = greetVisitor(inSlot: index)
            } else {
                panelTabID = PanelTab.lures.rawValue
            }
        case .plot(let index):
            switch quickSlot {
            case .harvest: harvestAndReplantAll()
            case .water: growAllWithGems()
            case .seeds, .spareSeed, .item: tapPlot(index)
            }
        case .bed:
            restForTheNight()
        case .chair:
            toggleSitting()
        case .chest:
            panelTabID = "storage"
        case .petBed:
            if let bunny = bunnies.first(where: \.isFavorite) ?? bunnies.first {
                showToast("💕 You scoop up \(bunny.name) for a cuddle. They wiggle their nose at you.")
                feedbackCount += 1
            }
        case .homeDoor:
            leaveHome()
        case .goToTown:
            goToTown()
        case .goToFarm:
            goToFarm()
        case .goToPond:
            goToPond()
        case .leavePond:
            goToFarmFromPond()
        case .fish:
            beginFishing()
        case .moonBunny:
            interactMoonBunny()
        case .digCapsule:
            digCapsule()
        case .enterHouse(let id):
            enterHouse(id)
        case .shopCounter:
            shopCounterOpen = true
            shopMode = .options
        case .leaveHouse:
            leaveHouse()
        case .shop:
            panelTabID = PanelTab.shop.rawValue
        case .stall:
            panelTabID = "seeds"
        case .look(let text):
            showToast(text)
            feedbackCount += 1
        }
    }

    /// The blue button: Back from a panel, Gift to the person you're facing, Sell at the shop
    /// and the market stalls, or out the door at home.
    var deckSecondary: String? {
        if panelTabID != PanelTab.farm.rawValue { return "Back" }
        if let secondary = deckTarget()?.secondary { return secondary }
        return isAtHome && !isSleeping ? "Exit" : nil
    }

    func deckSecondaryAction() {
        if panelTabID != PanelTab.farm.rawValue {
            panelTabID = PanelTab.farm.rawValue
            return
        }
        switch deckTarget()?.kind {
        case .person(let id)?:
            profileOpensGifts = true
            openProfile(id)
            return
        case .shop?, .stall?:
            panelTabID = PanelTab.pantry.rawValue
            return
        default:
            break
        }
        if isAtHome { leaveHome() }
    }

    /// Picks a quick inventory slot. Tapping the seeds slot again opens every seed.
    func selectQuickSlot(_ slot: QuickSlot) {
        switch slot {
        case .spareSeed(let id):
            pickSeed(id)
        case .seeds where quickSlot == .seeds:
            panelTabID = "seeds"
        case .item(let id):
            quickSlot = slot
            if let crop = Crop.find(id), isUnlocked(crop) { selectedSeed = id }
        default:
            quickSlot = slot
        }
        feedbackCount += 1
    }

    /// Everything you're carrying, as (item, count) stacks in the order the pantry lists them.
    var carriedStacks: [(id: String, count: Int)] {
        ItemInfo.allIDs.compactMap { id in
            let count = count(of: id)
            return count > 0 ? (id: id, count: count) : nil
        }
    }

    /// Puts a seed in your hands.
    func pickSeed(_ id: String) {
        selectedSeed = id
        recentSeeds.removeAll { $0 == id }
        recentSeeds.insert(id, at: 0)
        quickSlot = .seeds
    }

    /// The two spare seed slots: seeds picked lately, then your newest unlocked ones.
    var spareSeeds: [String] {
        let unlocked = Crop.all.filter { isUnlocked($0) }.sorted { $0.unlockLevel > $1.unlockLevel }.map(\.id)
        var picks: [String] = []
        for id in recentSeeds + unlocked where id != selectedSeed && !picks.contains(id) && unlocked.contains(id) {
            picks.append(id)
        }
        return Array(picks.prefix(2))
    }
}

// MARK: - The deck

/// The bottom half: the tab bar across the top, then what the action button will do, then
/// the D-pad, the quick inventory and the action buttons. A tab (or the lure basket, the
/// seed bag or the storage chest) opens its panel in place of the controls, and Back closes it.
struct ControlDeck: View {
    let meadow: Meadow

    private static let tabs: [PanelTab] = [.pantry, .bunnies, .friends, .journal, .shop]

    private var openPanel: String? {
        meadow.panelTabID == PanelTab.farm.rawValue ? nil : meadow.panelTabID
    }

    /// Sizes for one deck, worked out together so nothing overlaps: the tab bar on top, the
    /// control row along the bottom, and the main grid in the open middle. The main grid's
    /// squares and the quick bar's squares are the same size.
    private struct Layout {
        let tabHeight: CGFloat
        let controlsHeight: CGFloat
        let pad: CGFloat
        let action: CGFloat
        let secondary: CGFloat
        let slot: CGFloat
        let gap: CGFloat
        let spacing: CGFloat

        static let frame: CGFloat = 8

        init(_ size: CGSize) {
            spacing = max(size.height * 0.025, 6)
            gap = 6
            tabHeight = min(max(size.height * 0.12, 36), 56)
            pad = min(max(size.height * 0.26, 70), size.width * 0.24, 170)
            action = min(max(pad * 0.62, 44), size.width * 0.15)
            secondary = action * 0.5
            let caption: CGFloat = 16
            // The quick bar fits between the D-pad and the buttons, with room to spare.
            let rightColumnWidth = max(action * 1.5, secondary + action * 0.55)
            let barRoom = size.width - pad - rightColumnWidth - 2 * 16 - 4
            let fromWidth = (barRoom - 4 * gap - 2 * Self.frame) / 5
            let rightColumn = action + secondary + caption + 4
            let controls = max(pad, rightColumn)
            // The main grid gets the middle, with clear space above and below.
            let middle = size.height - tabHeight - controls - 4 * spacing
            let fromHeight = (middle - 2 * gap - 2 * 10) / 3
            slot = max(min(fromWidth, fromHeight, controls - 2 * Self.frame, 76), 24)
            controlsHeight = max(controls, slot + 2 * Self.frame)
        }
    }

    /// The Tour's banner: the current step's hint, or the wrong-tap nudge, with a
    /// way out — Skip while touring, a dismiss for the send-off line.
    private var tourBanner: some View {
        HStack(spacing: 8) {
            Text(meadow.tourToast ?? meadow.tourStep.hint)
                .font(.caption.bold())
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
            if meadow.tourStep.isActive {
                Button("Skip tour") { meadow.tourSkip() }
                    .font(.caption2.bold())
                    .buttonStyle(SquishButtonStyle())
                    .opacity(0.75)
            } else {
                Button("✕") { meadow.tourToast = nil }
                    .font(.caption.bold())
                    .buttonStyle(SquishButtonStyle())
                    .accessibilityLabel("Dismiss")
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .pixelPanel(Palette.lilacCard, edge: Palette.lilacEdge, cornerRadius: 12)
    }

    var body: some View {
        GeometryReader { geo in
            let layout = Layout(geo.size)
            VStack(spacing: layout.spacing) {
                if meadow.tourStep.isActive || meadow.tourToast != nil {
                    tourBanner
                }
                tabBar(height: layout.tabHeight, width: geo.size.width)
                // The middle shows your carried inventory, or the open tab's panel (or the lure
                // basket, seed bag or storage chest) in its place.
                ZStack {
                    if let panel = openPanel {
                        VStack(spacing: 6) {
                            panelHeader(panel)
                            panelView(panel)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                        .padding(10)
                        .background(Palette.cream.opacity(0.55), in: .rect(cornerRadius: 20))
                        .transition(.panelSlide)
                    } else {
                        mainGrid(layout)
                            .transition(.opacity)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                // The controls stay along the bottom, usable whether or not a panel is open.
                controls(layout)
                    .frame(height: layout.controlsHeight)
            }
            .animation(.easeOut(duration: 0.25), value: meadow.panelTabID)
        }
        .foregroundStyle(Palette.ink)
        .fontDesign(.rounded)
        .disabled(meadow.isSleeping)
        .opacity(meadow.isSleeping ? 0.5 : 1)
        .onChange(of: meadow.quickSlot) { _, slot in
            if slot == .water { meadow.tourNoteWaterCan() }
        }
        .onChange(of: meadow.plots) { _, plots in
            if meadow.tourStep == .plant, plots.contains(where: { $0.cropID != nil }) {
                meadow.tourAdvance()
            }
        }
        .onChange(of: meadow.dayNumber) { _, _ in meadow.checkAmbientMoments() }
        .onChange(of: meadow.presentedScene?.id) { _, _ in meadow.presentPendingFragment() }
        .onChange(of: meadow.timeOfDay) { _, _ in meadow.checkAmbientMoments() }
        .onAppear { meadow.checkAmbientMoments() }
        .background {
            // Walking: one step per screen frame while the D-pad is held, by the time that
            // actually passed, so she moves at a constant pace.
            TimelineView(.animation(paused: !meadow.isDeckMoving)) { timeline in
                Color.clear
                    .onChange(of: timeline.date) { previous, now in
                        meadow.deckStep(dt: now.timeIntervalSince(previous))
                    }
            }
        }
        .onDisappear { meadow.deckDirection = .zero }
    }

    /// Your carried inventory: 5 squares across and 3 down, filled from the first square.
    /// More than 15 stacks scroll inside the grid.
    private func mainGrid(_ layout: Layout) -> some View {
        let stacks = meadow.carriedStacks
        let rows = max(3, (stacks.count + 4) / 5)
        let side = layout.slot
        let height = 3 * side + 2 * layout.gap
        return ScrollView(.vertical) {
            VStack(spacing: layout.gap) {
                ForEach(0..<rows, id: \.self) { row in
                    HStack(spacing: layout.gap) {
                        ForEach(0..<5, id: \.self) { column in
                            let index = row * 5 + column
                            InventorySlotView(meadow: meadow, stack: index < stacks.count ? stacks[index] : nil, size: side)
                        }
                    }
                }
            }
        }
        .scrollDisabled(stacks.count <= 15)
        .scrollIndicators(.hidden)
        .frame(width: 5 * side + 4 * layout.gap, height: height)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// A panel's own header row: its name, and Close.
    private func panelHeader(_ id: String) -> some View {
        HStack {
            Text(panelTitle(id)).font(.headline)
            Spacer()
            Button {
                meadow.panelTabID = PanelTab.farm.rawValue
            } label: {
                Label("Close", systemImage: "xmark")
                    .font(.caption.bold())
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .pixelPanel(Palette.periwinkle, edge: Palette.periwinkleEdge, cornerRadius: 10)
            }
            .buttonStyle(SquishButtonStyle())
        }
    }

    private func panelTitle(_ id: String) -> String {
        switch id {
        case "seeds": return "🌱 Seed bag"
        case "storage": return "📦 Storage chest"
        default:
            guard let tab = PanelTab(rawValue: id) else { return "" }
            return tab == .lures ? "🧺 Lure basket" : tab.title
        }
    }

    // MARK: Tabs

    private func tabBar(height: CGFloat, width: CGFloat) -> some View {
        HStack(spacing: max(width * 0.012, 4)) {
            ForEach(Self.tabs) { tab in
                let isOpen = meadow.panelTabID == tab.rawValue
                Button {
                    if !meadow.tourTapTab(tab, isOpen: isOpen) {
                        meadow.panelTabID = isOpen ? PanelTab.farm.rawValue : tab.rawValue
                    }
                } label: {
                    HStack(spacing: 4) {
                        if let icon = UIImage(named: "icon-\(tab.rawValue)") ?? tab.icon {
                            Image(uiImage: icon)
                                .resizable()
                                .interpolation(.none)
                                .scaledToFit()
                                .frame(height: height * 0.55)
                        } else {
                            Text(tab.emoji)
                        }
                        Text(tab.title)
                            .font(.system(size: max(height * 0.3, 11), weight: .bold, design: .rounded))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    .padding(.horizontal, 8)
                    .frame(maxWidth: .infinity)
                    .frame(height: height)
                    .pixelPanel(isOpen ? Palette.pinkCard : pillColors(tab).fill,
                                edge: isOpen ? Palette.rose : pillColors(tab).edge, cornerRadius: height / 2)
                    .offset(y: isOpen ? -2 : 0)
                    .overlay(alignment: .topTrailing) {
                        if hasBadge(tab) {
                            Circle().fill(Palette.rose).frame(width: 10, height: 10).padding(4)
                        }
                    }
                    .overlay {
                        if meadow.tourStep.targetTab == tab {
                            TourRing(cornerRadius: height / 2)
                        }
                    }
                }
                .buttonStyle(SquishButtonStyle())
                .accessibilityAddTraits(isOpen ? .isSelected : [])
            }
        }
    }

    /// Pink, lilac and blue pills, like the mockup.
    private func pillColors(_ tab: PanelTab) -> (fill: Color, edge: Color) {
        switch tab {
        case .pantry: return (Palette.pinkCard, Palette.pinkEdge)
        case .friends, .shop: return (Palette.periwinkle, Palette.periwinkleEdge)
        default: return (Palette.lilacCard, Palette.lilacEdge)
        }
    }

    private func hasBadge(_ tab: PanelTab) -> Bool {
        switch tab {
        case .pantry: return Recipe.all.contains(where: meadow.canCraft)
        case .bunnies: return !meadow.claimableMilestones.isEmpty
        case .friends: return Person.all.contains { !meadow.unseenEvents(for: $0.id).isEmpty || meadow.canTalk(to: $0.id) }
        case .journal: return meadow.pendingRewardCount > 0 || meadow.availableQuests.contains(where: meadow.canComplete)
        default: return false
        }
    }

    @ViewBuilder
    private func panelView(_ id: String) -> some View {
        switch id {
        case "seeds": FarmTab(meadow: meadow)
        case "storage": HomePanel(meadow: meadow)
        default:
            switch PanelTab(rawValue: id) ?? .farm {
            case .pantry: PantryTab(meadow: meadow)
            case .lures: LureTab(meadow: meadow)
            case .bunnies: CollectionTab(meadow: meadow)
            case .friends: FriendsTab(meadow: meadow)
            case .journal: JournalTab(meadow: meadow)
            case .shop: ShopTab(meadow: meadow)
            case .farm: EmptyView()
            }
        }
    }

    // MARK: Controls

    private func controls(_ layout: Layout) -> some View {
        HStack(alignment: .bottom, spacing: 0) {
            DeckPad(meadow: meadow, size: layout.pad)
                .overlay {
                    if meadow.tourStep == .move { TourRing(cornerRadius: 20) }
                }
            Spacer(minLength: 16)
            quickBar(layout)
                .padding(.bottom, max((layout.pad - layout.slot - 2 * Layout.frame) / 2, 0))
            Spacer(minLength: 16)
            // The smaller blue button above, then what the big button will do, right over it.
            VStack(alignment: .trailing, spacing: 2) {
                secondaryButton(size: layout.secondary)
                    .padding(.trailing, layout.action * 0.55)
                actionCaption(width: layout.action * 1.5)
                actionButton(size: layout.action)
                    .overlay {
                        if meadow.tourStep == .plant { TourRing(cornerRadius: layout.action * 0.3) }
                    }
            }
        }
    }

    /// The action button's label, just above it: Shop, Enter, Talk to June…
    private func actionCaption(width: CGFloat) -> some View {
        let target = meadow.deckTarget()
        return coinText(target?.verb ?? " ")
            .font(.caption.bold())
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(width: width, alignment: .trailing)
            .opacity(target?.canAct ?? false ? 1 : 0.6)
            .accessibilityHidden(true)
    }

    /// The quick inventory: five squares the same size as the main grid's, inside their own
    /// pink pixel frame.
    private func quickBar(_ layout: Layout) -> some View {
        let spares = meadow.spareSeeds
        var slots: [QuickSlot?] = [QuickSlot.harvest, QuickSlot.seeds, QuickSlot.water]
        for index in 0..<2 {
            slots.append(index < spares.count ? QuickSlot.spareSeed(spares[index]) : nil)
        }

        return HStack(spacing: layout.gap) {
            ForEach(Array(slots.enumerated()), id: \.offset) { _, item in
                QuickSlotView(meadow: meadow, slot: item, size: layout.slot)
            }
        }
        .padding(Layout.frame)
        .background(Palette.pinkCard, in: .rect(cornerRadius: 4))
        .overlay {
            Rectangle().strokeBorder(Palette.ink, lineWidth: 3)
            Rectangle().inset(by: 3).strokeBorder(Palette.rose, lineWidth: 3)
        }
        .overlay {
            // Little pixel studs on the corners, like the mockup's frame.
            GeometryReader { frame in
                ForEach(0..<4, id: \.self) { corner in
                    Rectangle()
                        .fill(Palette.pinkCard)
                        .overlay(Rectangle().strokeBorder(Palette.ink, lineWidth: 2))
                        .frame(width: 11, height: 11)
                        .position(x: corner % 2 == 0 ? 0 : frame.size.width, y: corner < 2 ? 0 : frame.size.height)
                }
            }
        }
    }

    private func actionButton(size: CGFloat) -> some View {
        let target = meadow.deckTarget()
        let enabled = target?.canAct ?? false
        return Button {
            // While the welcome card is up, the action button is its "okay".
            if meadow.showsWelcome { meadow.dismissWelcome() } else { meadow.deckAction() }
        } label: {
            ZStack {
                DeckArt(name: "icon-action-button", fallback: Palette.rose)
                Group {
                    if let target {
                        DeckIconView(icon: target.icon, size: size * 0.46)
                    } else {
                        DeckArt(name: "moon-coin", fallback: Palette.lavender)
                            .frame(width: size * 0.52, height: size * 0.52)
                    }
                }
                .offset(y: size * 0.02)
            }
            .frame(width: size, height: size)
            .saturation(enabled ? 1 : 0.35)
            .opacity(enabled ? 1 : 0.7)
        }
        .buttonStyle(SquishButtonStyle())
        .disabled(!enabled)
        .accessibilityLabel(target?.verb ?? "Nothing in reach")
    }

    private func secondaryButton(size: CGFloat) -> some View {
        let label = meadow.deckSecondary
        return Button {
            meadow.deckSecondaryAction()
        } label: {
            ZStack {
                DeckArt(name: "icon-secondary-button", fallback: Palette.sky)
                Text(label ?? "")
                    .font(.system(size: size * 0.24, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: Palette.ink.opacity(0.7), radius: 0, x: 1, y: 1)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(size * 0.12)
            }
            .frame(width: size, height: size)
            .opacity(label == nil ? 0.55 : 1)
        }
        .buttonStyle(SquishButtonStyle())
        .disabled(label == nil)
        .accessibilityLabel(label ?? "Nothing to go back to")
    }
}

/// One square of the main inventory grid: an item and how many you carry, or empty. Tapping
/// it puts that item in your hands (the same selection as the quick bar).
private struct InventorySlotView: View {
    let meadow: Meadow
    let stack: (id: String, count: Int)?
    let size: CGFloat

    var body: some View {
        let isSelected = stack.map { meadow.quickSlot == .item($0.id) } ?? false
        Button {
            if let stack { meadow.selectQuickSlot(.item(stack.id)) }
        } label: {
            ZStack(alignment: .bottomTrailing) {
                RoundedRectangle(cornerRadius: size * 0.2)
                    .fill(Palette.lilacCard.opacity(0.55))
                    .overlay(RoundedRectangle(cornerRadius: size * 0.2).inset(by: 3).strokeBorder(.white.opacity(0.7), lineWidth: 1.5))
                    .overlay(RoundedRectangle(cornerRadius: size * 0.2).strokeBorder(Palette.lilacEdge, lineWidth: 3))
                if let stack {
                    ItemIcon(itemID: stack.id, size: size * 0.58)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    Text("\(stack.count)")
                        .font(.system(size: max(size * 0.18, 9), weight: .heavy, design: .rounded))
                        .monospacedDigit()
                        .padding(.horizontal, 3)
                        .background(Palette.cream.opacity(0.9), in: .capsule)
                        .padding(size * 0.07)
                }
            }
            .frame(width: size, height: size)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: size * 0.2)
                        .strokeBorder(Palette.rose, lineWidth: 3)
                        .padding(-2)
                }
            }
        }
        .buttonStyle(SquishButtonStyle())
        .disabled(stack == nil)
        .accessibilityLabel(stack.map { "\(ItemInfo.name($0.id)), \($0.count)" } ?? "Empty slot")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// The D-pad: hold anywhere on it to walk that way, eight ways; let go to stop.
private struct DeckPad: View {
    let meadow: Meadow
    let size: CGFloat
    @State private var pressed = false

    var body: some View {
        DeckArt(name: "icon-dpad", fallback: Palette.lilac)
            .frame(width: size, height: size)
            .scaleEffect(pressed ? 0.97 : 1)
            .contentShape(.rect)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        pressed = true
                        meadow.holdDirection(direction(at: value.location))
                    }
                    .onEnded { _ in
                        pressed = false
                        meadow.holdDirection(.zero)
                    }
            )
            .accessibilityElement()
            .accessibilityLabel("D-pad")
            .accessibilityHint("Hold a direction to walk")
    }

    /// The nearest of eight directions from the middle, or none in the very middle.
    private func direction(at point: CGPoint) -> DeckVector {
        let dx = point.x - size / 2, dy = point.y - size / 2
        guard (dx * dx + dy * dy).squareRoot() > size * 0.1 else { return .zero }
        let eighth = (atan2(dy, dx) / (.pi / 4)).rounded()
        let angle = eighth * .pi / 4
        let x = cos(angle), y = sin(angle)
        return DeckVector(x: abs(x) < 0.01 ? 0 : (x > 0 ? 1 : -1), y: abs(y) < 0.01 ? 0 : (y > 0 ? 1 : -1))
    }
}

/// One quick inventory slot, in its dashed frame. The one in hand is outlined in pink.
private struct QuickSlotView: View {
    let meadow: Meadow
    let slot: QuickSlot?
    let size: CGFloat

    var body: some View {
        let isSelected = slot.map { $0 == meadow.quickSlot } ?? false
        Button {
            if let slot { meadow.selectQuickSlot(slot) }
        } label: {
            ZStack {
                DeckArt(name: "icon-slot-empty", fallback: Palette.lilacCard)
                content
            }
            .frame(width: size, height: size)
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: size * 0.2)
                        .strokeBorder(Palette.rose, lineWidth: 3)
                        .padding(-2)
                }
            }
            .scaleEffect(isSelected ? 1.06 : 1)
        }
        .buttonStyle(SquishButtonStyle())
        .disabled(slot == nil)
        .overlay {
            if slot == .water && meadow.tourStep == .water {
                TourRing(cornerRadius: 12)
            }
        }
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    @ViewBuilder
    private var content: some View {
        switch slot {
        case .harvest?:
            DeckArt(name: "icon-carrot", fallback: .clear).padding(size * 0.18)
                .overlay(alignment: .bottomTrailing) { badge(meadow.readyPlotCount > 0 ? "\(meadow.readyPlotCount)" : nil) }
        case .seeds?:
            DeckArt(name: "icon-seed-packet", fallback: .clear).padding(size * 0.16)
                .overlay(alignment: .bottomTrailing) { ItemIcon(itemID: meadow.selectedSeed, size: size * 0.36).padding(size * 0.06) }
        case .water?:
            DeckArt(name: "icon-watering-can", fallback: .clear).padding(size * 0.14)
                .overlay(alignment: .bottomTrailing) { badge("\(Meadow.growAllGemCost)💎") }
        case .spareSeed(let id)?, .item(let id)?:
            ItemIcon(itemID: id, size: size * 0.55)
        case nil:
            EmptyView()
        }
    }

    private func badge(_ text: String?) -> some View {
        Group {
            if let text {
                coinText(text)
                    .font(.system(size: max(size * 0.17, 9), weight: .heavy, design: .rounded))
                    .padding(.horizontal, 3)
                    .background(Palette.cream.opacity(0.9), in: .capsule)
                    .padding(size * 0.06)
            }
        }
    }

    private var label: String {
        switch slot {
        case .harvest?: return "Harvest and replant everything ready"
        case .seeds?: return "\(Crop.find(meadow.selectedSeed)?.name ?? "Seed") seeds. Tap again to pick another seed"
        case .water?: return "Watering can: grow everything for \(Meadow.growAllGemCost) gems"
        case .spareSeed(let id)?: return "\(Crop.find(id)?.name ?? "Seed") seeds"
        case .item(let id)?: return ItemInfo.name(id)
        case nil: return "Empty slot"
        }
    }
}

/// One of the drawn deck pictures, kept crisp; a plain shape stands in if it's missing.
private struct DeckArt: View {
    let name: String
    let fallback: Color

    var body: some View {
        if let image = UIImage(named: name) {
            Image(uiImage: image)
                .resizable()
                .interpolation(.none)
                .scaledToFit()
        } else {
            Circle().fill(fallback)
        }
    }
}

/// The current action's picture, drawn on the action button.
private struct DeckIconView: View {
    let icon: DeckTarget.Icon
    let size: CGFloat

    var body: some View {
        switch icon {
        case .asset(let name):
            DeckArt(name: name, fallback: .clear).frame(width: size, height: size)
        case .item(let id):
            ItemIcon(itemID: id, size: size)
        case .emoji(let emoji):
            Text(emoji).font(.system(size: size * 0.8))
        }
    }
}

/// A soft pulsing ring on whatever the action button would work, while you're walking.
struct DeckTargetMarker: View {
    let target: DeckTarget
    let unit: CGFloat
    let t: Double

    var body: some View {
        let pulse = (1 + sin(t * 4)) / 2
        Ellipse()
            .strokeBorder(target.canAct ? Palette.rose : Palette.lilacEdge,
                          style: StrokeStyle(lineWidth: 2.5, dash: [5, 3]))
            .frame(width: unit * (0.1 + 0.01 * pulse), height: unit * (0.05 + 0.005 * pulse))
            .opacity(0.65 + 0.35 * pulse)
            .allowsHitTesting(false)
    }
}

// MARK: - Collision overlay (hidden debug view)

/// Draws every blocked zone of a scene as translucent red, labeled, with the walkable area's
/// edge dashed and your farmer's foot box in yellow. Turned on by tapping the version in
/// Settings five times, for lining the zones up with the artwork.
struct CollisionOverlay: View {
    let scene: SceneCollision
    /// Where the scene's picture is drawn on screen.
    let rect: CGRect
    let feet: Spot

    private func point(_ spot: Spot) -> CGPoint {
        CGPoint(x: rect.minX + spot.x * rect.width, y: rect.minY + spot.y * rect.height)
    }

    private func outline(_ points: [Spot]) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: point(first))
            for spot in points.dropFirst() { path.addLine(to: point(spot)) }
            path.closeSubpath()
        }
    }

    private func corners(_ box: DeckRect) -> [Spot] {
        [Spot(x: box.minX, y: box.minY), Spot(x: box.maxX, y: box.minY), Spot(x: box.maxX, y: box.maxY), Spot(x: box.minX, y: box.maxY)]
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(Array(scene.blocks.enumerated()), id: \.offset) { _, zone in
                outline(zone.points).fill(Color.red.opacity(0.28))
                outline(zone.points).stroke(Color.red, lineWidth: 1)
            }
            outline(corners(scene.bounds)).stroke(Color.yellow, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            outline(corners(scene.footBox(at: feet))).fill(Color.yellow.opacity(0.8))
            ForEach(Array(scene.blocks.enumerated()), id: \.offset) { _, zone in
                Text(zone.label)
                    .font(.system(size: 7, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 2)
                    .background(Color.red.opacity(0.75))
                    .fixedSize()
                    .position(point(zone.bounds.center))
            }
            Text("Collision: \(scene.name) · \(scene.blocks.count) zones")
                .font(.system(size: 9, weight: .heavy))
                .padding(4)
                .background(Color.yellow.opacity(0.85), in: .rect(cornerRadius: 4))
                .foregroundStyle(.black)
                .position(x: rect.minX + 90, y: max(rect.minY, 0) + 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}
