import SwiftUI

// MARK: - The Pond (added by Merlin, 2026-10-30)

/// The forest pond: a third explorable area, reached by the footpath from the
/// farm's north edge. Collision is derived from `pond-scene.png`: the water is
/// blocked except the dock, which juts into it from the south shore; trees and
/// the big ferns block at their bases; the dirt path along the bottom is the
/// way in and out. The dock is where fishing happens (§4 of the design).
enum PondLayout {
    /// Where you arrive from the farm path.
    static let arrival = Spot(x: 0.5, y: 0.92)
    /// The bottom path strip: walking down off it returns to the farm.
    static let exitZone = DeckRect(minX: 0.40, minY: 0.94, maxX: 0.60, maxY: 1.0)
    /// The wooden dock: stand here and the action button offers Fish.
    static let dockZone = DeckRect(minX: 0.435, minY: 0.65, maxX: 0.57, maxY: 0.85)
    /// Mid-dock, where the Fish target marker sits.
    static let dockSpot = Spot(x: 0.5, y: 0.72)

    static let collision = SceneCollision(
        name: "The Pond",
        bounds: DeckRect(minX: 0.05, minY: 0.30, maxX: 0.95, maxY: 0.97),
        blocks: [
            // The water, shaped around the dock (west / east / north of it).
            BlockZone(label: "pond: water (west)", rect: DeckRect(minX: 0.27, minY: 0.42, maxX: 0.44, maxY: 0.79)),
            BlockZone(label: "pond: water (east)", rect: DeckRect(minX: 0.565, minY: 0.42, maxX: 0.79, maxY: 0.79)),
            BlockZone(label: "pond: water (north of the dock)", rect: DeckRect(minX: 0.44, minY: 0.40, maxX: 0.565, maxY: 0.66)),
            BlockZone(label: "pond: water (north lobe)", rect: DeckRect(minX: 0.60, minY: 0.385, maxX: 0.72, maxY: 0.44)),
            // The willow on the west shore: trunk and the ground its fronds guard.
            BlockZone(label: "pond: willow", rect: DeckRect(minX: 0.225, minY: 0.50, maxX: 0.29, maxY: 0.66)),
            // Tree trunks.
            BlockZone(label: "pond: pine trunk (west)", rect: DeckRect(minX: 0.15, minY: 0.58, maxX: 0.19, maxY: 0.73)),
            BlockZone(label: "pond: round tree trunk (northwest)", rect: DeckRect(minX: 0.355, minY: 0.29, maxX: 0.39, maxY: 0.37)),
            BlockZone(label: "pond: round tree trunk (north)", rect: DeckRect(minX: 0.475, minY: 0.28, maxX: 0.51, maxY: 0.36)),
            BlockZone(label: "pond: round tree trunk (northeast)", rect: DeckRect(minX: 0.645, minY: 0.27, maxX: 0.68, maxY: 0.35)),
            BlockZone(label: "pond: round tree trunk (east)", rect: DeckRect(minX: 0.865, minY: 0.52, maxX: 0.915, maxY: 0.66)),
            BlockZone(label: "pond: pine trunk (southeast)", rect: DeckRect(minX: 0.94, minY: 0.86, maxX: 0.99, maxY: 0.99)),
            // The big fern clumps on the south and east shores.
            BlockZone(label: "pond: fern (dock west)", rect: DeckRect(minX: 0.345, minY: 0.765, maxX: 0.45, maxY: 0.865)),
            BlockZone(label: "pond: fern (east shore)", rect: DeckRect(minX: 0.78, minY: 0.62, maxX: 0.87, maxY: 0.735)),
            BlockZone(label: "pond: fern (southeast)", rect: DeckRect(minX: 0.735, minY: 0.735, maxX: 0.855, maxY: 0.815)),
            BlockZone(label: "pond: fern (southwest)", rect: DeckRect(minX: 0.13, minY: 0.845, maxX: 0.26, maxY: 0.97)),
        ],
        figure: 0.13, reach: 0.07)
}
