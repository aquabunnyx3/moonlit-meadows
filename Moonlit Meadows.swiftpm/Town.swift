import SwiftUI
import UIKit

// MARK: - The village: places

/// Where you are off the farm: walking around the village (`city-hub-map`), or inside
/// someone's house (`interior-<id>-v2`). `nil` on `Meadow.town` means the farm.
enum TownPlace: Equatable {
    case hub
    case house(String)
}

/// Where someone is right now, from their schedule.
enum Whereabouts: Equatable {
    /// Visiting your farm (they stroll the meadow there).
    case farm
    /// Inside their own house in the village.
    case home
    /// Out in the village, at their favorite spot.
    case town
    /// Somewhere off the map (the creek, the clock tower…). They're still in the Friends tab.
    case errand
}

/// A house on the village map.
struct TownHouse {
    /// The person who lives there, or `library` for the village library.
    let id: String
    let name: String
    /// Where you stand to go in, and where you come back out.
    let doorstep: Spot

    var ownerID: String? { Person.find(id) == nil ? nil : id }

    /// The area in front of the door the action button reaches.
    var doorZone: DeckRect {
        DeckRect(minX: doorstep.x - 0.035, minY: doorstep.y - 0.07, maxX: doorstep.x + 0.035, maxY: doorstep.y + 0.01)
    }
}

/// One thing in a room you can look at.
struct RoomThing {
    let name: String
    let zone: DeckRect
    let text: String
}

/// A house's room: where you can walk, what's in the way, and what you can look at, all
/// as fractions of its picture (each is laid out differently on purpose).
struct TownInterior {
    let bounds: DeckRect
    let blocks: [DeckRect]
    /// Where you appear when you come in.
    let entrance: Spot
    /// Walk into this to go back outside.
    let exit: DeckRect
    /// Where the person who lives there stands when they're home.
    let resident: Spot
    let things: [RoomThing]
}

enum TownLayout {
    // MARK: Village map (`city-hub-map`, 2096 × 1184)

    static let hubBounds = DeckRect(minX: 0.03, minY: 0.02, maxX: 0.97, maxY: 0.975)
    /// Where you arrive from the farm, at the bottom path.
    static let arrival = Spot(x: 0.57, y: 0.94)
    /// Walk into this (the path off the bottom of the map) to go back to the farm.
    static let farmExit = DeckRect(minX: 0.535, minY: 0.955, maxX: 0.61, maxY: 1.0)
    /// The two lanes between the houses and the plaza, and the side lanes joining them,
    /// which villagers follow when they walk around.
    static let topLane = 0.265
    static let bottomLane = 0.735
    static let leftLane = 0.215
    static let rightLane = 0.86

    static let houses: [TownHouse] = [
        TownHouse(id: "wes", name: "Wes's Cottage", doorstep: Spot(x: 0.125, y: 0.245)),
        TownHouse(id: "june", name: "June's Glasshouse", doorstep: Spot(x: 0.432, y: 0.215)),
        TownHouse(id: "roz", name: "the Sweet Burrow", doorstep: Spot(x: 0.665, y: 0.245)),
        TownHouse(id: "theo", name: "Theo's Observatory", doorstep: Spot(x: 0.89, y: 0.245)),
        TownHouse(id: "library", name: "the Village Library", doorstep: Spot(x: 0.10, y: 0.6)),
        TownHouse(id: "kai", name: "Kai's Woodshop", doorstep: Spot(x: 0.925, y: 0.63)),
        TownHouse(id: "bree", name: "Bree's Bramble Cottage", doorstep: Spot(x: 0.095, y: 0.95)),
        TownHouse(id: "vi", name: "Vi's Flower Cottage", doorstep: Spot(x: 0.265, y: 0.96)),
        TownHouse(id: "silas", name: "Silas's Apiary Cottage", doorstep: Spot(x: 0.44, y: 0.955)),
        TownHouse(id: "rowan", name: "Rowan's Forge", doorstep: Spot(x: 0.69, y: 0.95)),
        TownHouse(id: "sol", name: "Sol's Patchwork Atelier", doorstep: Spot(x: 0.915, y: 0.95)),
    ]
    static let shopDoorstep = Spot(x: 0.74, y: 0.645)
    static var shopZone: DeckRect {
        DeckRect(minX: shopDoorstep.x - 0.04, minY: shopDoorstep.y - 0.07, maxX: shopDoorstep.x + 0.04, maxY: shopDoorstep.y + 0.01)
    }

    /// The four market stalls: each sells seeds and buys your crops.
    static let stalls = [DeckRect(minX: 0.31, minY: 0.31, maxX: 0.40, maxY: 0.47), DeckRect(minX: 0.505, minY: 0.31, maxX: 0.60, maxY: 0.47),
                         DeckRect(minX: 0.31, minY: 0.50, maxX: 0.40, maxY: 0.66), DeckRect(minX: 0.505, minY: 0.50, maxX: 0.60, maxY: 0.66)]

    /// Buildings, trees, fences and stalls (by your feet).
    static let hubBlocks: [DeckRect] = [
        // Houses along the top, the greenhouse gardens, and the big trees.
        DeckRect(minX: 0.07, minY: 0, maxX: 0.19, maxY: 0.215),
        DeckRect(minX: 0.19, minY: 0, maxX: 0.30, maxY: 0.17),
        DeckRect(minX: 0.36, minY: 0, maxX: 0.535, maxY: 0.185),
        DeckRect(minX: 0.33, minY: 0.09, maxX: 0.41, maxY: 0.265),
        DeckRect(minX: 0.455, minY: 0.13, maxX: 0.535, maxY: 0.265),
        DeckRect(minX: 0.60, minY: 0, maxX: 0.73, maxY: 0.215),
        DeckRect(minX: 0.76, minY: 0, maxX: 0.83, maxY: 0.13),
        DeckRect(minX: 0.84, minY: 0, maxX: 0.95, maxY: 0.215),
        DeckRect(minX: 0.91, minY: 0.2, maxX: 1, maxY: 0.33),
        // Houses down the sides and along the bottom.
        DeckRect(minX: 0.03, minY: 0.34, maxX: 0.17, maxY: 0.575),
        DeckRect(minX: 0.875, minY: 0.35, maxX: 1, maxY: 0.575),
        DeckRect(minX: 0.875, minY: 0.585, maxX: 0.905, maxY: 0.635),
        DeckRect(minX: 0.95, minY: 0.55, maxX: 1, maxY: 0.66),
        DeckRect(minX: 0.03, minY: 0.68, maxX: 0.16, maxY: 0.925),
        DeckRect(minX: 0.18, minY: 0.7, maxX: 0.34, maxY: 0.935),
        DeckRect(minX: 0.38, minY: 0.71, maxX: 0.53, maxY: 0.93),
        DeckRect(minX: 0.6, minY: 0.71, maxX: 0.78, maxY: 0.925),
        DeckRect(minX: 0.79, minY: 0.82, maxX: 0.84, maxY: 0.97),
        DeckRect(minX: 0.84, minY: 0.7, maxX: 0.97, maxY: 0.925),
        // The plaza fence (with its gaps for the paths), the shop, the basket and the stalls.
        DeckRect(minX: 0.245, minY: 0.28, maxX: 0.4, maxY: 0.305),
        DeckRect(minX: 0.455, minY: 0.28, maxX: 0.645, maxY: 0.305),
        DeckRect(minX: 0.7, minY: 0.28, maxX: 0.855, maxY: 0.305),
        DeckRect(minX: 0.265, minY: 0.69, maxX: 0.43, maxY: 0.715),
        DeckRect(minX: 0.47, minY: 0.69, maxX: 0.855, maxY: 0.715),
        DeckRect(minX: 0.245, minY: 0.28, maxX: 0.26, maxY: 0.45),
        DeckRect(minX: 0.245, minY: 0.55, maxX: 0.26, maxY: 0.715),
        DeckRect(minX: 0.84, minY: 0.28, maxX: 0.855, maxY: 0.45),
        DeckRect(minX: 0.84, minY: 0.55, maxX: 0.855, maxY: 0.715),
        DeckRect(minX: 0.67, minY: 0.33, maxX: 0.81, maxY: 0.62),
        DeckRect(minX: 0.415, minY: 0.45, maxX: 0.49, maxY: 0.54),
    ] + stalls.map { DeckRect(minX: $0.minX, minY: $0.minY, maxX: $0.maxX, maxY: $0.maxY - 0.03) }

    /// Each villager's favorite spot in the village (by their feet).
    static let townSpots: [String: Spot] = [
        "june": Spot(x: 0.44, y: 0.275),
        "roz": Spot(x: 0.555, y: 0.49),
        "theo": Spot(x: 0.62, y: 0.5),
        "kai": Spot(x: 0.865, y: 0.5),
        "sol": Spot(x: 0.45, y: 0.6),
        "rowan": Spot(x: 0.57, y: 0.745),
        "silas": Spot(x: 0.355, y: 0.48),
        "bree": Spot(x: 0.17, y: 0.955),
        "vi": Spot(x: 0.355, y: 0.68),
    ]

    /// The morning / midday / evening schedule in the village: when each villager is at their
    /// spot in the hub, and when they're briefly away. The rest of the time they're home,
    /// except while their schedule has them visiting your farm (that's unchanged).
    static let townTimes: [String: Set<TimeOfDay>] = [
        "june": [.dusk],
        "roz": [.dawn],
        "theo": [.day],
        "kai": [.day],
        "sol": [.dawn],
        "rowan": [.day],
        "silas": [.dawn],
        "bree": [.dawn],
        "vi": [.day],
    ]
    static let errands: [String: Set<TimeOfDay>] = [
        "wes": [.day],
        "bree": [.dusk],
        "vi": [.dawn],
    ]

    static func house(_ id: String) -> TownHouse? {
        houses.first { $0.id == id }
    }

    // MARK: Rooms (`interior-<id>-v2`, 2096 × 1184)

    // Each room on its own, so the compiler checks them one at a time.
    static let juneRoom = TownInterior(
        bounds: DeckRect(minX: 0.1, minY: 0.5, maxX: 0.72, maxY: 0.94),
        blocks: [DeckRect(minX: 0.08, minY: 0.38, maxX: 0.24, maxY: 0.85), DeckRect(minX: 0.49, minY: 0.42, maxX: 0.7, maxY: 0.68),
                 DeckRect(minX: 0.33, minY: 0.77, maxX: 0.56, maxY: 0.95)],
        entrance: Spot(x: 0.64, y: 0.78), exit: DeckRect(minX: 0.7, minY: 0.6, maxX: 0.8, maxY: 0.94),
        resident: Spot(x: 0.4, y: 0.62),
        things: [
            RoomThing(name: "June's bed", zone: DeckRect(minX: 0.08, minY: 0.38, maxX: 0.24, maxY: 0.85),
                      text: "A flowery quilt, perfectly tucked. A pressed clover is tucked under the pillow."),
            RoomThing(name: "Seedling rack", zone: DeckRect(minX: 0.49, minY: 0.42, maxX: 0.7, maxY: 0.68),
                      text: "Rows of seedlings, each with a tiny handwritten label. One just says “hopeful”."),
            RoomThing(name: "Worktable", zone: DeckRect(minX: 0.33, minY: 0.77, maxX: 0.56, maxY: 0.95),
                      text: "A mortar and pestle, a jar of dried petals, and a fresh bundle of rosemary. It smells like tea."),
        ])
    static let rozRoom = TownInterior(
        bounds: DeckRect(minX: 0.1, minY: 0.58, maxX: 0.95, maxY: 0.94),
        blocks: [DeckRect(minX: 0.0, minY: 0.3, maxX: 0.09, maxY: 1), DeckRect(minX: 0.53, minY: 0.5, maxX: 0.7, maxY: 0.65),
                 DeckRect(minX: 0.56, minY: 0.66, maxX: 0.67, maxY: 0.74), DeckRect(minX: 0.71, minY: 0.45, maxX: 0.81, maxY: 0.62),
                 DeckRect(minX: 0.82, minY: 0.4, maxX: 0.97, maxY: 0.95), DeckRect(minX: 0.49, minY: 0.56, maxX: 0.515, maxY: 0.62)],
        entrance: Spot(x: 0.3, y: 0.88), exit: DeckRect(minX: 0.2, minY: 0.94, maxX: 0.45, maxY: 1),
        resident: Spot(x: 0.32, y: 0.64),
        things: [
            RoomThing(name: "Brick oven", zone: DeckRect(minX: 0.08, minY: 0.27, maxX: 0.21, maxY: 0.59),
                      text: "The oven's still warm. Something with cinnamon was in here not long ago."),
            RoomThing(name: "Baking counter", zone: DeckRect(minX: 0.21, minY: 0.3, maxX: 0.48, maxY: 0.59),
                      text: "A strawberry cake under a glass dome, and flour on absolutely everything."),
            RoomThing(name: "Roz's bed", zone: DeckRect(minX: 0.82, minY: 0.4, maxX: 0.97, maxY: 0.95),
                      text: "A pink canopy bed with a little flour on the pillow. Of course."),
            RoomThing(name: "Bookshelf", zone: DeckRect(minX: 0.71, minY: 0.45, maxX: 0.81, maxY: 0.62),
                      text: "Cookbooks, mostly. One is just called “Pies I Will Make Someday”."),
        ])
    static let theoRoom = TownInterior(
        bounds: DeckRect(minX: 0.1, minY: 0.6, maxX: 0.9, maxY: 0.95),
        blocks: [DeckRect(minX: 0.28, minY: 0, maxX: 0.72, maxY: 0.68), DeckRect(minX: 0.1, minY: 0.58, maxX: 0.27, maxY: 0.88),
                 DeckRect(minX: 0.06, minY: 0.84, maxX: 0.43, maxY: 1), DeckRect(minX: 0.77, minY: 0.27, maxX: 0.89, maxY: 0.82),
                 DeckRect(minX: 0.77, minY: 0.8, maxX: 0.89, maxY: 0.96), DeckRect(minX: 0.3, minY: 0.72, maxX: 0.41, maxY: 0.86)],
        entrance: Spot(x: 0.58, y: 0.9), exit: DeckRect(minX: 0.48, minY: 0.95, maxX: 0.72, maxY: 1),
        resident: Spot(x: 0.5, y: 0.76),
        things: [
            RoomThing(name: "Telescope", zone: DeckRect(minX: 0.42, minY: 0.5, maxX: 0.58, maxY: 0.69),
                      text: "Pointed at the moon. A sticky note on it says “do NOT touch the focus, Theo, it's perfect”."),
            RoomThing(name: "Theo's bed", zone: DeckRect(minX: 0.1, minY: 0.58, maxX: 0.27, maxY: 0.88),
                      text: "A constellation quilt. It doesn't look slept in very often."),
            RoomThing(name: "Star charts", zone: DeckRect(minX: 0.06, minY: 0.84, maxX: 0.43, maxY: 1),
                      text: "Maps of the sky, covered in notes. One star is circled and labeled “for later”."),
            RoomThing(name: "Bookshelf", zone: DeckRect(minX: 0.77, minY: 0.27, maxX: 0.89, maxY: 0.82),
                      text: "Astronomy books, jars of something glittery, and a tiny spare telescope."),
        ])
    static let kaiRoom = TownInterior(
        bounds: DeckRect(minX: 0.17, minY: 0.47, maxX: 0.93, maxY: 0.94),
        blocks: [DeckRect(minX: 0.07, minY: 0.36, maxX: 0.33, maxY: 0.68), DeckRect(minX: 0, minY: 0.62, maxX: 0.17, maxY: 1),
                 DeckRect(minX: 0.33, minY: 0.6, maxX: 0.39, maxY: 0.68), DeckRect(minX: 0.7, minY: 0.44, maxX: 0.91, maxY: 0.68),
                 DeckRect(minX: 0.87, minY: 0.62, maxX: 0.96, maxY: 0.86)],
        entrance: Spot(x: 0.5, y: 0.88), exit: DeckRect(minX: 0.4, minY: 0.94, maxX: 0.6, maxY: 1),
        resident: Spot(x: 0.44, y: 0.62),
        things: [
            RoomThing(name: "Workbench", zone: DeckRect(minX: 0.07, minY: 0.36, maxX: 0.33, maxY: 0.68),
                      text: "A half-built bunny hutch, a hammer and a saw, and sawdust everywhere. It smells like pine."),
            RoomThing(name: "Kai's bed", zone: DeckRect(minX: 0.7, minY: 0.44, maxX: 0.91, maxY: 0.68),
                      text: "Neatly made, with a woven teal blanket. Three carved wooden bunnies keep watch from the shelf."),
            RoomThing(name: "Wood stove", zone: DeckRect(minX: 0.87, minY: 0.62, maxX: 0.96, maxY: 0.86),
                      text: "A little stove with a kettle on top, ticking as it warms."),
        ])
    static let solRoom = TownInterior(
        bounds: DeckRect(minX: 0.13, minY: 0.6, maxX: 0.95, maxY: 0.95),
        blocks: [DeckRect(minX: 0.03, minY: 0.52, maxX: 0.12, maxY: 0.95), DeckRect(minX: 0.1, minY: 0.4, maxX: 0.24, maxY: 0.85),
                 DeckRect(minX: 0.24, minY: 0.38, maxX: 0.55, maxY: 0.6), DeckRect(minX: 0.7, minY: 0.5, maxX: 0.98, maxY: 0.88)],
        entrance: Spot(x: 0.5, y: 0.9), exit: DeckRect(minX: 0.35, minY: 0.95, maxX: 0.65, maxY: 1),
        resident: Spot(x: 0.62, y: 0.64),
        things: [
            RoomThing(name: "Sewing machine", zone: DeckRect(minX: 0.1, minY: 0.4, maxX: 0.24, maxY: 0.85),
                      text: "Bolts of pastel fabric and a pincushion bristling with pins. A sleeve is halfway done."),
            RoomThing(name: "Sol's bed", zone: DeckRect(minX: 0.24, minY: 0.38, maxX: 0.55, maxY: 0.6),
                      text: "A patchwork quilt. Every square is a different fabric, and every one has a story."),
            RoomThing(name: "Music corner", zone: DeckRect(minX: 0.7, minY: 0.5, maxX: 0.98, maxY: 0.88),
                      text: "A guitar, a music stand, cushions in a circle, and a tambourine waiting for a friend."),
        ])
    static let wesRoom = TownInterior(
        bounds: DeckRect(minX: 0.14, minY: 0.45, maxX: 0.88, maxY: 0.94),
        blocks: [DeckRect(minX: 0.08, minY: 0.43, maxX: 0.15, maxY: 0.92), DeckRect(minX: 0.2, minY: 0.42, maxX: 0.35, maxY: 0.7),
                 DeckRect(minX: 0.43, minY: 0.38, maxX: 0.57, maxY: 0.62), DeckRect(minX: 0.73, minY: 0.35, maxX: 0.87, maxY: 0.65),
                 DeckRect(minX: 0.7, minY: 0.65, maxX: 0.9, maxY: 0.95)],
        entrance: Spot(x: 0.5, y: 0.88), exit: DeckRect(minX: 0.3, minY: 0.94, maxX: 0.65, maxY: 1),
        resident: Spot(x: 0.38, y: 0.76),
        things: [
            RoomThing(name: "Seed jars", zone: DeckRect(minX: 0.08, minY: 0.43, maxX: 0.15, maxY: 0.92),
                      text: "Jars of seeds, every one labeled in careful old handwriting with the year it was saved."),
            RoomThing(name: "Rocking chair", zone: DeckRect(minX: 0.2, minY: 0.42, maxX: 0.35, maxY: 0.7),
                      text: "Wes's rocking chair, with a lavender blanket folded over the back."),
            RoomThing(name: "Wood stove", zone: DeckRect(minX: 0.43, minY: 0.38, maxX: 0.57, maxY: 0.62),
                      text: "A crackling fire. There's always a log or two stacked underneath."),
            RoomThing(name: "Wes's bed", zone: DeckRect(minX: 0.73, minY: 0.35, maxX: 0.87, maxY: 0.65),
                      text: "A plain wooden bed with a thick cream quilt. Very tidy."),
            RoomThing(name: "Tea table", zone: DeckRect(minX: 0.7, minY: 0.65, maxX: 0.9, maxY: 0.95),
                      text: "A blue teapot and two cups. He always sets out a second one, just in case."),
        ])
    static let breeRoom = TownInterior(
        bounds: DeckRect(minX: 0.35, minY: 0.5, maxX: 0.95, maxY: 0.95),
        blocks: [DeckRect(minX: 0.03, minY: 0.4, maxX: 0.35, maxY: 0.95), DeckRect(minX: 0.53, minY: 0.4, maxX: 0.65, maxY: 0.67),
                 DeckRect(minX: 0.72, minY: 0.4, maxX: 0.92, maxY: 0.68), DeckRect(minX: 0.78, minY: 0.62, maxX: 1, maxY: 1)],
        entrance: Spot(x: 0.5, y: 0.88), exit: DeckRect(minX: 0.42, minY: 0.94, maxX: 0.62, maxY: 1),
        resident: Spot(x: 0.68, y: 0.76),
        things: [
            RoomThing(name: "Bree's bed", zone: DeckRect(minX: 0.03, minY: 0.4, maxX: 0.35, maxY: 0.95),
                      text: "A blueberry quilt on a white iron bed, surrounded by potted blueberry bushes."),
            RoomThing(name: "Berry crates", zone: DeckRect(minX: 0.72, minY: 0.4, maxX: 0.92, maxY: 0.68),
                      text: "Crates of blueberries and a little scale. A notebook tracks every pound picked this year."),
            RoomThing(name: "Wicker chair", zone: DeckRect(minX: 0.53, minY: 0.4, maxX: 0.65, maxY: 0.67),
                      text: "A sunny wicker chair with a blue cushion, right by the window."),
        ])
    static let viRoom = TownInterior(
        bounds: DeckRect(minX: 0.27, minY: 0.42, maxX: 0.72, maxY: 0.95),
        blocks: [DeckRect(minX: 0.06, minY: 0.42, maxX: 0.27, maxY: 0.7), DeckRect(minX: 0.06, minY: 0.68, maxX: 0.43, maxY: 1),
                 DeckRect(minX: 0.63, minY: 0.27, maxX: 0.93, maxY: 0.58), DeckRect(minX: 0.72, minY: 0.5, maxX: 0.95, maxY: 1)],
        entrance: Spot(x: 0.51, y: 0.58), exit: DeckRect(minX: 0.43, minY: 0.64, maxX: 0.59, maxY: 1),
        resident: Spot(x: 0.42, y: 0.5),
        things: [
            RoomThing(name: "Vi's bed", zone: DeckRect(minX: 0.63, minY: 0.27, maxX: 0.93, maxY: 0.58),
                      text: "A rose-print quilt, with dried flowers hanging over the headboard."),
            RoomThing(name: "Arranging table", zone: DeckRect(minX: 0.06, minY: 0.42, maxX: 0.27, maxY: 0.7),
                      text: "Ribbons, scissors, and a bouquet half-wrapped in brown paper. There's a poem tucked inside."),
            RoomThing(name: "Flower buckets", zone: DeckRect(minX: 0.72, minY: 0.5, maxX: 0.95, maxY: 1),
                      text: "Tulips, daisies, hyacinths and roses. The whole room smells like spring."),
            RoomThing(name: "Vanity", zone: DeckRect(minX: 0.1, minY: 0.2, maxX: 0.25, maxY: 0.45),
                      text: "A round mirror framed in roses, and a hairbrush with a flower stuck in it."),
        ])
    static let rowanRoom = TownInterior(
        bounds: DeckRect(minX: 0.1, minY: 0.58, maxX: 0.92, maxY: 0.94),
        blocks: [DeckRect(minX: 0.1, minY: 0, maxX: 0.27, maxY: 0.57), DeckRect(minX: 0.29, minY: 0.38, maxX: 0.36, maxY: 0.6),
                 DeckRect(minX: 0.38, minY: 0.38, maxX: 0.46, maxY: 0.59), DeckRect(minX: 0.57, minY: 0.35, maxX: 0.87, maxY: 0.58),
                 DeckRect(minX: 0.66, minY: 0.57, maxX: 0.84, maxY: 0.86), DeckRect(minX: 0.83, minY: 0.55, maxX: 0.92, maxY: 0.95)],
        entrance: Spot(x: 0.45, y: 0.88), exit: DeckRect(minX: 0.35, minY: 0.94, maxX: 0.6, maxY: 1),
        resident: Spot(x: 0.42, y: 0.68),
        things: [
            RoomThing(name: "Forge", zone: DeckRect(minX: 0.1, minY: 0, maxX: 0.27, maxY: 0.6),
                      text: "The forge glows orange. Even from here, it's toasty."),
            RoomThing(name: "Anvil", zone: DeckRect(minX: 0.29, minY: 0.38, maxX: 0.46, maxY: 0.62),
                      text: "An anvil and a water barrel. A half-finished star charm is cooling on the edge."),
            RoomThing(name: "Rowan's bed", zone: DeckRect(minX: 0.66, minY: 0.57, maxX: 0.84, maxY: 0.86),
                      text: "A plaid blanket, folded with military neatness. Star lights hang over the wall."),
            RoomThing(name: "Table", zone: DeckRect(minX: 0.57, minY: 0.35, maxX: 0.87, maxY: 0.6),
                      text: "A bowl of stew and a mug. One bench, but a second one pulled up, just in case."),
        ])
    static let silasRoom = TownInterior(
        bounds: DeckRect(minX: 0.05, minY: 0.6, maxX: 0.95, maxY: 0.95),
        blocks: [DeckRect(minX: 0.03, minY: 0.4, maxX: 0.22, maxY: 0.7), DeckRect(minX: 0.23, minY: 0, maxX: 0.52, maxY: 0.58),
                 DeckRect(minX: 0.3, minY: 0.48, maxX: 0.44, maxY: 0.7), DeckRect(minX: 0.5, minY: 0, maxX: 0.61, maxY: 0.85),
                 DeckRect(minX: 0.71, minY: 0.38, maxX: 0.84, maxY: 0.66), DeckRect(minX: 0.84, minY: 0.4, maxX: 1, maxY: 1),
                 DeckRect(minX: 0.61, minY: 0.38, maxX: 0.7, maxY: 0.52)],
        entrance: Spot(x: 0.3, y: 0.88), exit: DeckRect(minX: 0.2, minY: 0.94, maxX: 0.45, maxY: 1),
        resident: Spot(x: 0.47, y: 0.76),
        things: [
            RoomThing(name: "Honey shelves", zone: DeckRect(minX: 0.23, minY: 0.3, maxX: 0.5, maxY: 0.6),
                      text: "Jar after jar of golden honey, glowing in the light. Each lid is labeled with a flower."),
            RoomThing(name: "Honey pot", zone: DeckRect(minX: 0.3, minY: 0.48, maxX: 0.44, maxY: 0.72),
                      text: "A pot of honey with the dipper still in it, and two cups. Chamomile, by the smell."),
            RoomThing(name: "Beehives", zone: DeckRect(minX: 0.71, minY: 0.38, maxX: 0.84, maxY: 0.68),
                      text: "Two white hives, humming softly. A bee lands on your sleeve, looks at you, and leaves."),
            RoomThing(name: "Silas's bed", zone: DeckRect(minX: 0.03, minY: 0.4, maxX: 0.22, maxY: 0.72),
                      text: "A honeycomb quilt in sunny yellow. Very on brand."),
        ])

    static let interiors: [String: TownInterior] = [
        "june": juneRoom,
        "roz": rozRoom,
        "theo": theoRoom,
        "kai": kaiRoom,
        "sol": solRoom,
        "wes": wesRoom,
        "bree": breeRoom,
        "vi": viRoom,
        "rowan": rowanRoom,
        "silas": silasRoom,
    ]
}

// MARK: - The village: going places and who's where

extension Meadow {
    static let farmToTownZone = DeckRect(minX: 0.44, minY: 0.875, maxX: 0.56, maxY: 0.96)
    /// Where you come back onto the farm from the village.
    static let farmFromTown = Spot(x: 0.5, y: 0.9)
    /// How long a villager takes to walk across the village when their plans change, in game hours.
    static let townWalkHours = 0.5

    func goToTown() {
        closeProfile()
        town = .hub
        townSpot = TownLayout.arrival
        heldHome = []
        faceUp()
    }

    func goToFarm() {
        town = nil
        heldHome = []
        isDeckDriving = true
        farmerSpot = Self.farmFromTown
        faceUp()
    }

    /// Goes inside. If they're home, they stay home until you leave.
    func enterHouse(_ id: String) {
        guard let room = TownLayout.interiors[id] else { return }
        heldHome = whereabouts(of: id) == .home && hubWalker(id) == nil ? [id] : []
        town = .house(id)
        townSpot = room.entrance
        faceUp()
    }

    func leaveHouse() {
        guard case .house(let id) = town else { return }
        heldHome = []
        town = .hub
        townSpot = TownLayout.house(id)?.doorstep ?? TownLayout.arrival
        farmerFacing = .front
        deckFacing = DeckVector(x: 0, y: 1)
        deckDirection = .zero
    }

    private func faceUp() {
        panelTabID = PanelTab.farm.rawValue
        farmerFacing = .back
        deckFacing = DeckVector(x: 0, y: -1)
        deckDirection = .zero
        feedbackCount += 1
    }

    /// Where someone is at a time of day: on your farm when their schedule says so, otherwise
    /// at their spot in the village, out on an errand, or at home.
    func whereabouts(of personID: String, at time: TimeOfDay? = nil) -> Whereabouts {
        let time = time ?? timeOfDay
        guard let person = Person.find(personID) else { return .home }
        if person.slot(at: time).inMeadow { return .farm }
        if TownLayout.townTimes[personID]?.contains(time) ?? false { return .town }
        if TownLayout.errands[personID]?.contains(time) ?? false { return .errand }
        return .home
    }

    /// For the Friends tab: where they are, in plain words, like "Roz is at home".
    func whereaboutsText(of person: Person) -> String {
        let slot = person.slot(at: timeOfDay)
        if let step = hubWalker(person.id), step.isWalking {
            return "🚶 \(person.name) is walking through the hub"
        }
        switch whereabouts(of: person.id) {
        case .farm: return "🌾 \(person.name) is on your farm · \(slot.place)"
        case .town: return "🏘️ \(person.name) is in the hub · \(slot.place)"
        case .errand: return "🧭 \(person.name) is away for a bit · \(slot.place)"
        case .home: return "🏠 \(person.name) is at home"
        }
    }

    /// Someone out walking in the village right now: at their favorite spot, or on their
    /// way between places for a little while after their plans change. `nil` when they're
    /// not in the village (or are inside, or you're visiting them at home).
    func hubWalker(_ personID: String) -> RouteStep? {
        guard !heldHome.contains(personID), let house = TownLayout.house(personID) else { return nil }
        let hour = clockHour
        let current = whereabouts(of: personID, at: TimeOfDay.at(hour: Int(hour)))
        func point(_ place: Whereabouts) -> Spot? {
            switch place {
            case .home: return house.doorstep
            case .town: return TownLayout.townSpots[personID]
            case .farm, .errand: return Spot(x: (TownLayout.farmExit.minX + TownLayout.farmExit.maxX) / 2, y: 0.97)
            }
        }
        // The first half hour after their plans change, they walk from the old place to the new.
        let start = Self.slotStart(for: hour)
        let walked = hour - max(start, Self.dayStartHour)
        if walked < Self.townWalkHours {
            let previous = whereabouts(of: personID, at: TimeOfDay.at(hour: (Int(start) + 23) % 24))
            if previous != current, previous == .home || previous == .town || current == .home || current == .town,
               let from = point(previous), let to = point(current) {
                return Self.walk(from: from, to: to, progress: walked / Self.townWalkHours)
            }
        }
        if current == .town, let spot = point(.town) {
            return RouteStep(spot: spot, dx: 0, dy: 1, isWalking: false)
        }
        return nil
    }

    /// The hour the current part of the day began.
    private static func slotStart(for hour: Double) -> Double {
        switch Int(hour) {
        case 5..<8: return 5
        case 8..<17: return 8
        case 17..<20: return 17
        default: return hour >= 20 ? 20 : -4
        }
    }

    /// A walk along the village lanes: out to the nearest lane, along it (and across by a side
    /// lane if the two ends are on different lanes), then in to where they're going.
    private static func walk(from a: Spot, to b: Spot, progress: Double) -> RouteStep {
        let laneA = a.y < 0.5 ? TownLayout.topLane : TownLayout.bottomLane
        let laneB = b.y < 0.5 ? TownLayout.topLane : TownLayout.bottomLane
        var points = [a, Spot(x: a.x, y: laneA)]
        if laneA != laneB {
            let side = (a.x + b.x) / 2 < 0.5 ? TownLayout.leftLane : TownLayout.rightLane
            points += [Spot(x: side, y: laneA), Spot(x: side, y: laneB)]
        }
        points += [Spot(x: b.x, y: laneB), b]
        let aspect = 2096.0 / 1184.0
        let legs = zip(points, points.dropFirst()).map { leg in
            (from: leg.0, to: leg.1, length: hypot((leg.1.x - leg.0.x) * aspect, leg.1.y - leg.0.y))
        }
        let total = legs.reduce(0) { $0 + $1.length }
        var left = min(max(progress, 0), 1) * total
        for leg in legs {
            if left <= leg.length, leg.length > 0 {
                let f = left / leg.length
                return RouteStep(spot: Spot(x: leg.from.x + (leg.to.x - leg.from.x) * f, y: leg.from.y + (leg.to.y - leg.from.y) * f),
                                 dx: (leg.to.x - leg.from.x) * aspect, dy: leg.to.y - leg.from.y, isWalking: true,
                                 distance: progress * total)
            }
            left -= leg.length
        }
        return RouteStep(spot: b, dx: 0, dy: 1, isWalking: false)
    }

    /// Everyone out in the village right now.
    var townWalkers: [(person: Person, step: RouteStep)] {
        Person.all.compactMap { person in hubWalker(person.id).map { (person: person, step: $0) } }
    }

    /// Who's home in the house you're visiting.
    var houseResident: Person? {
        guard case .house(let id) = town, heldHome.contains(id) else { return nil }
        return Person.find(id)
    }
}

// MARK: - The village (top screen)

/// The village map and the house rooms. They're kept as plain data in the assets (like the
/// videos and voices), not as image sets, so building the app doesn't have to process 11 more
/// big pictures; each is decoded the first time it's shown.
enum TownArt {
    private static var cache: [String: UIImage] = [:]

    static func image(_ name: String) -> UIImage? {
        if let image = cache[name] { return image }
        guard let data = NSDataAsset(name: name)?.data, let image = UIImage(data: data) else {
            artLog.notice("Missing village art \(name, privacy: .public)")
            return nil
        }
        cache[name] = image
        return image
    }
}

/// The village map or a house's room, with the people there and your farmer, who you
/// walk with the D-pad just like on the farm.
struct TownScene: View {
    let meadow: Meadow
    let place: TownPlace

    private var art: String {
        switch place {
        case .hub: return "city-hub-map"
        case .house(let id): return "interior-\(id)-v2"
        }
    }

    /// The farmer's (and everyone's) height, in art heights: smaller out in the village.
    private var figureScale: CGFloat { place == .hub ? 0.12 : 0.34 }

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 24, paused: meadow.isPaused || meadow.isAtMainMenu)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            GeometryReader { proxy in
                let map = place == .hub ? WorldMap(size: proxy.size) : Self.room(in: proxy.size)
                let size = map.unit * figureScale

                ZStack(alignment: .topLeading) {
                    if place == .hub { Palette.ground } else { Color(red: 0.07, green: 0.07, blue: 0.2) }
                    if let image = TownArt.image(art) {
                        Image(uiImage: image)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: map.rect.width, height: map.rect.height)
                            .position(x: map.rect.midX, y: map.rect.midY)
                    }

                    if let target = meadow.deckTarget() {
                        DeckTargetMarker(target: target, unit: map.unit * (place == .hub ? 1 : 2.2), t: t)
                            .position(map.point(target.spot))
                    }

                    // Everyone here, drawn back to front so nearer people overlap farther ones.
                    ForEach(figures(t: t), id: \.id) { figure in
                        figureView(figure, size: size, t: t)
                            .position(map.point(figure.spot.x, figure.spot.y - Double(figureScale) / 2))
                    }

                    label
                        .padding(10)
                }
            }
        }
        .clipped()
    }

    /// A room is shown whole, as big as fits, like your own house: never cropped or stretched.
    private static func room(in size: CGSize) -> WorldMap {
        let aspect: CGFloat = 2096 / 1184
        let width = min(size.width, size.height * aspect)
        let height = width / aspect
        return WorldMap(rect: CGRect(x: (size.width - width) / 2, y: (size.height - height) / 2, width: width, height: height))
    }

    private struct Figure {
        let id: String
        let person: Person?
        let spot: Spot
        let facing: PersonArt.Facing
        let isWalking: Bool
    }

    private func figures(t: Double) -> [Figure] {
        var list: [Figure] = []
        switch place {
        case .hub:
            for walker in meadow.townWalkers {
                list.append(Figure(id: walker.person.id, person: walker.person, spot: walker.step.spot,
                                   facing: WalkFacing.facing(for: walker.step, id: walker.person.id), isWalking: walker.step.isWalking))
            }
        case .house:
            if let resident = meadow.houseResident, let room = TownLayout.interiors[resident.id] {
                list.append(Figure(id: resident.id, person: resident, spot: room.resident, facing: .front, isWalking: false))
            }
        }
        list.append(Figure(id: "farmer", person: nil, spot: meadow.townSpot, facing: meadow.farmerFacing, isWalking: meadow.isDeckMoving))
        return list.sorted { $0.spot.y < $1.spot.y }
    }

    @ViewBuilder
    private func figureView(_ figure: Figure, size: CGFloat, t: Double) -> some View {
        if let person = figure.person {
            VStack(spacing: 2) {
                PersonFigure(look: person.look(onDay: meadow.today), artID: person.id, size: size, time: t,
                             facing: figure.facing, isWalking: figure.isWalking)
                Text(person.name)
                    .font(.system(size: max(size * 0.09, 9), weight: .bold, design: .rounded))
                    .padding(.horizontal, 5)
                    .background(Palette.cream.opacity(0.85), in: .capsule)
            }
            .offset(y: size * 0.06)
            .accessibilityLabel("\(person.name) is here")
        } else if let artID = meadow.farmerArtID() {
            PersonFigure(look: .farmer(wearing: Outfit.find(meadow.equippedOutfit) ?? Outfit.all[0]),
                         artID: artID, size: size, time: t, facing: figure.facing, isWalking: figure.isWalking)
                .allowsHitTesting(false)
                .accessibilityLabel("Your farmer")
        }
    }

    private var label: some View {
        let name: String = {
            switch place {
            case .hub: return "🏘️ Moonlit Village"
            case .house(let id): return "🏡 \(TownLayout.house(id)?.name.capitalizedFirst ?? "A house")"
            }
        }()
        return HStack(spacing: 6) {
            Text("\(name) · Day \(meadow.dayCount) · \(meadow.clockText)")
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .pixelPanel(Palette.lilacCard, edge: Palette.lilacEdge, cornerRadius: 12)
            PauseButton(meadow: meadow)
        }
        .foregroundStyle(Palette.ink)
    }
}

extension String {
    /// "the Sweet Burrow" → "The Sweet Burrow".
    var capitalizedFirst: String { String(prefix(1)).uppercased() + String(dropFirst()) }
}
