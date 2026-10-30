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
    /// The shore stones east of the dock, where something was buried long ago.
    static let capsuleZone = DeckRect(minX: 0.58, minY: 0.79, maxX: 0.68, maxY: 0.88)
    /// Imani's cabin at the pond's south-east corner (moved there 2026-10-30,
    /// clear of the fishing water; its door faces west, onto the shore path).
    static let cabinZone = DeckRect(minX: 0.70, minY: 0.63, maxX: 0.90, maxY: 0.88)
    /// The cabin's doorstep: stand here and the action button offers a visit.
    static let cabinDoorZone = DeckRect(minX: 0.665, minY: 0.74, maxX: 0.745, maxY: 0.88)
    static let cabinDoorSpot = Spot(x: 0.71, y: 0.81)
    /// Where Imani stands: the south-east shore by her cabin, off the dock.
    static let imaniSpot = Spot(x: 0.665, y: 0.775)

    static let collision = SceneCollision(
        name: "The Pond",
        bounds: DeckRect(minX: 0.03, minY: 0.26, maxX: 0.97, maxY: 0.985),
        blocks: [
            // The water is one closed shape now (no gaps to wade through),
            // wrapped around the dock, which juts in from the south shore.
            BlockZone(label: "pond: water (west)", rect: DeckRect(minX: 0.265, minY: 0.42, maxX: 0.44, maxY: 0.775)),
            BlockZone(label: "pond: water (north)", rect: DeckRect(minX: 0.44, minY: 0.405, maxX: 0.795, maxY: 0.65)),
            BlockZone(label: "pond: water (east)", rect: DeckRect(minX: 0.565, minY: 0.65, maxX: 0.795, maxY: 0.79)),
            BlockZone(label: "pond: Imani's cabin", rect: DeckRect(minX: 0.745, minY: 0.655, maxX: 0.90, maxY: 0.88)),
            // The willow on the west shore: trunk and the ground its fronds guard.
            BlockZone(label: "pond: willow", rect: DeckRect(minX: 0.21, minY: 0.44, maxX: 0.30, maxY: 0.66)),
            // Tree trunks.
            BlockZone(label: "pond: pine trunk (west)", rect: DeckRect(minX: 0.15, minY: 0.58, maxX: 0.19, maxY: 0.73)),
            BlockZone(label: "pond: round tree trunk (northwest)", rect: DeckRect(minX: 0.355, minY: 0.29, maxX: 0.39, maxY: 0.37)),
            BlockZone(label: "pond: round tree trunk (north)", rect: DeckRect(minX: 0.475, minY: 0.28, maxX: 0.51, maxY: 0.36)),
            BlockZone(label: "pond: round tree trunk (northeast)", rect: DeckRect(minX: 0.645, minY: 0.27, maxX: 0.68, maxY: 0.35)),
            BlockZone(label: "pond: round tree trunk (east)", rect: DeckRect(minX: 0.865, minY: 0.52, maxX: 0.915, maxY: 0.66)),
            BlockZone(label: "pond: pine trunk (southeast)", rect: DeckRect(minX: 0.94, minY: 0.86, maxX: 0.99, maxY: 0.99)),
            // The big fern clumps on the south and east shores.
            BlockZone(label: "pond: fern (dock west)", rect: DeckRect(minX: 0.345, minY: 0.765, maxX: 0.45, maxY: 0.865)),
            BlockZone(label: "pond: fern (southwest)", rect: DeckRect(minX: 0.13, minY: 0.845, maxX: 0.26, maxY: 0.97)),
        ],
        figure: 0.13, reach: 0.07)
}
