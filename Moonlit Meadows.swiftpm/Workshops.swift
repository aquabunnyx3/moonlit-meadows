import SwiftUI

// MARK: - The Workshops (added by Merlin, 2026-10-30, while Claude is out)

/// The Workshops: another explorable area off the village's east lane, where the
/// characters keep their other places — June's glasshouse and herb beds, Rowan's
/// forge workshop, and Silas's apiary with its honey stand. Collision is derived
/// from `workshops-map`: the buildings, beds, hives and the well are solid (the
/// forge yard's fence too, with its gap left open at the bottom), trees block
/// only at their trunks, and the roads and flower meadow are walkable. The road
/// in from the village leaves by the west edge.
enum WorkshopsLayout {
    /// Where you arrive from the village, on the west road.
    static let arrival = Spot(x: 0.06, y: 0.515)
    /// The west road strip: walking left off it returns to the village.
    static let exitZone = DeckRect(minX: 0.0, minY: 0.47, maxX: 0.045, maxY: 0.56)

    /// Where each character stands at work, by their feet.
    static let spots: [String: Spot] = [
        "june": Spot(x: 0.272, y: 0.475),
        "rowan": Spot(x: 0.66, y: 0.255),
        "silas": Spot(x: 0.665, y: 0.80),
    ]

    /// Things to look at, in the rooms' style.
    static let things: [RoomThing] = [
        RoomThing(name: "The Glasshouse", zone: DeckRect(minX: 0.125, minY: 0.055, maxX: 0.415, maxY: 0.295),
                  text: "June's glasshouse. Inside, rows of seedlings lean toward the light, each with a tiny handwritten label."),
        RoomThing(name: "Herb beds", zone: DeckRect(minX: 0.125, minY: 0.31, maxX: 0.415, maxY: 0.44),
                  text: "Raised beds of rosemary, mint and chamomile, weeded to within an inch of their lives."),
        RoomThing(name: "The forge", zone: DeckRect(minX: 0.715, minY: 0.01, maxX: 0.89, maxY: 0.30),
                  text: "Rowan's forge, breathing heat. A horseshoe and three star charms are cooling by the door."),
        RoomThing(name: "Anvil and workbench", zone: DeckRect(minX: 0.59, minY: 0.15, maxX: 0.71, maxY: 0.42),
                  text: "An anvil on a stump, a bench of hammers and tongs, and barrels of water for the quench."),
        RoomThing(name: "Beehives", zone: DeckRect(minX: 0.672, minY: 0.59, maxX: 0.872, maxY: 0.74),
                  text: "Two rows of white hives, all humming at slightly different pitches. Silas says that's how you know they're happy."),
        RoomThing(name: "Honey stand", zone: DeckRect(minX: 0.687, minY: 0.76, maxX: 0.843, maxY: 0.91),
                  text: "Shelves of golden jars, each labeled with the flower it came from. One just says “the good stuff”."),
        RoomThing(name: "Sunflowers", zone: DeckRect(minX: 0.572, minY: 0.57, maxX: 0.663, maxY: 0.76),
                  text: "Sunflowers taller than you, turning their faces to follow the sun — and the bees commute below."),
        RoomThing(name: "The well", zone: DeckRect(minX: 0.46, minY: 0.45, maxX: 0.55, maxY: 0.56),
                  text: "A stone well at the crossroads. The bucket's rope is worn smooth by workshop hands."),
        RoomThing(name: "Flower bed", zone: DeckRect(minX: 0.09, minY: 0.83, maxX: 0.445, maxY: 0.91),
                  text: "A long bed of pink and lavender blooms. Vi plants these; the whole village argues about whose are best."),
    ]

    static let collision = SceneCollision(
        name: "The Workshops",
        bounds: DeckRect(minX: 0.02, minY: 0.03, maxX: 0.98, maxY: 0.97),
        blocks: [
            BlockZone(label: "workshops: glasshouse", rect: DeckRect(minX: 0.125, minY: 0.055, maxX: 0.415, maxY: 0.295)),
            BlockZone(label: "workshops: herb beds (west)", rect: DeckRect(minX: 0.125, minY: 0.31, maxX: 0.26, maxY: 0.44)),
            BlockZone(label: "workshops: herb beds (east)", rect: DeckRect(minX: 0.285, minY: 0.31, maxX: 0.415, maxY: 0.44)),
            BlockZone(label: "workshops: well", rect: DeckRect(minX: 0.46, minY: 0.45, maxX: 0.55, maxY: 0.56)),
            BlockZone(label: "workshops: forge building", rect: DeckRect(minX: 0.715, minY: 0.01, maxX: 0.89, maxY: 0.30)),
            BlockZone(label: "workshops: forge fence (west)", rect: DeckRect(minX: 0.572, minY: 0.125, maxX: 0.585, maxY: 0.45)),
            BlockZone(label: "workshops: forge fence (top)", rect: DeckRect(minX: 0.575, minY: 0.12, maxX: 0.72, maxY: 0.135)),
            BlockZone(label: "workshops: forge fence (bottom west)", rect: DeckRect(minX: 0.575, minY: 0.435, maxX: 0.715, maxY: 0.455)),
            BlockZone(label: "workshops: forge fence (bottom east)", rect: DeckRect(minX: 0.795, minY: 0.435, maxX: 0.905, maxY: 0.455)),
            BlockZone(label: "workshops: forge fence (east)", rect: DeckRect(minX: 0.895, minY: 0.125, maxX: 0.908, maxY: 0.45)),
            BlockZone(label: "workshops: anvil stump", rect: DeckRect(minX: 0.593, minY: 0.15, maxX: 0.637, maxY: 0.23)),
            BlockZone(label: "workshops: barrels by the forge", rect: DeckRect(minX: 0.645, minY: 0.155, maxX: 0.712, maxY: 0.225)),
            BlockZone(label: "workshops: workbench", rect: DeckRect(minX: 0.617, minY: 0.27, maxX: 0.697, maxY: 0.35)),
            BlockZone(label: "workshops: quench barrel", rect: DeckRect(minX: 0.592, minY: 0.34, maxX: 0.633, maxY: 0.415)),
            BlockZone(label: "workshops: coal pile (west)", rect: DeckRect(minX: 0.712, minY: 0.33, maxX: 0.778, maxY: 0.41)),
            BlockZone(label: "workshops: coal pile (east)", rect: DeckRect(minX: 0.803, minY: 0.325, maxX: 0.888, maxY: 0.415)),
            BlockZone(label: "workshops: sunflowers", rect: DeckRect(minX: 0.572, minY: 0.57, maxX: 0.663, maxY: 0.76)),
            BlockZone(label: "workshops: beehives", rect: DeckRect(minX: 0.672, minY: 0.59, maxX: 0.872, maxY: 0.74)),
            BlockZone(label: "workshops: honey shelf", rect: DeckRect(minX: 0.687, minY: 0.77, maxX: 0.762, maxY: 0.91)),
            BlockZone(label: "workshops: honey stand", rect: DeckRect(minX: 0.763, minY: 0.76, maxX: 0.843, maxY: 0.91)),
            BlockZone(label: "workshops: flower bed", rect: DeckRect(minX: 0.09, minY: 0.83, maxX: 0.445, maxY: 0.91)),
            BlockZone(label: "workshops: pink tree trunk (west)", rect: DeckRect(minX: 0.048, minY: 0.385, maxX: 0.068, maxY: 0.425)),
            BlockZone(label: "workshops: pine trunk (east, upper)", rect: DeckRect(minX: 0.948, minY: 0.265, maxX: 0.968, maxY: 0.30)),
            BlockZone(label: "workshops: pine trunk (east, middle)", rect: DeckRect(minX: 0.948, minY: 0.425, maxX: 0.968, maxY: 0.46)),
            BlockZone(label: "workshops: pink tree trunk (southeast)", rect: DeckRect(minX: 0.918, minY: 0.775, maxX: 0.938, maxY: 0.815)),
            BlockZone(label: "workshops: pine trunk (southwest)", rect: DeckRect(minX: 0.028, minY: 0.755, maxX: 0.048, maxY: 0.795)),
        ],
        figure: 0.12, reach: 0.06)
}
