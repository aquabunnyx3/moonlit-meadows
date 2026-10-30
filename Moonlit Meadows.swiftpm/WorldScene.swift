import SwiftUI
import UIKit

/// Background artwork from `Assets.xcassets`. Without it, a drawn scene is used.
enum WorldArt {
    /// The top-down pixel-art meadow.
    static let meadow = UIImage(named: "world-meadow")
    /// Watercolor paper for the control deck.
    static let panel = UIImage(named: "panel-paper")
}

/// Maps world coordinates (unit coordinates of the meadow artwork) into the view.
///
/// - Wider screens: the art fills the width, cropping a little of the trees at the top and
///   bottom. On very wide screens, the art stops growing and ground color fills the sides.
/// - Narrower screens: the whole art is shown at the bottom, with ground color above.
struct WorldMap {
    /// The artwork's width / height.
    static let aspect: CGFloat = 2096.0 / 1184.0
    /// The most of the art's height we're willing to crop on wide screens.
    private static let maxCrop: CGFloat = 0.22
    /// The part of the art kept in the middle of the screen when cropping.
    private static let focusY: CGFloat = 0.48

    let rect: CGRect

    /// A picture placed exactly where it's drawn (like a room shown whole).
    init(rect: CGRect) {
        self.rect = rect
    }

    init(size: CGSize) {
        let aspect = Self.aspect
        let width = size.width, height = max(size.height, 1)
        if width / height >= aspect {
            var artHeight = width / aspect
            var artWidth = width
            if height / artHeight < 1 - Self.maxCrop {
                artHeight = height / (1 - Self.maxCrop)
                artWidth = artHeight * aspect
            }
            let y = min(max(height / 2 - Self.focusY * artHeight, height - artHeight), 0)
            rect = CGRect(x: (width - artWidth) / 2, y: y, width: artWidth, height: artHeight)
        } else {
            let artHeight = width / aspect
            rect = CGRect(x: 0, y: height - artHeight, width: width, height: artHeight)
        }
    }

    /// Size unit: the artwork's height.
    var unit: CGFloat { rect.height }

    /// Width over height of the art on screen, so walking speed is the same in every direction.
    var aspect: Double { Double(rect.width / max(rect.height, 1)) }

    func point(_ x: Double, _ y: Double) -> CGPoint {
        CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
    }

    func point(_ spot: Spot) -> CGPoint {
        point(spot.x, spot.y)
    }
}

/// The top screen: Moonlit Meadows itself. It shows progress rather than taking input:
/// crops grow in the beds, visitors walk up to the lure garden, your bunnies play in the
/// meadow, characters stroll by on their schedules, and decor appears as you earn it.
struct WorldScene: View {
    let meadow: Meadow
    @AppStorage("debugCollision") private var showsCollision = false

    var body: some View {
        // While the farmer creator is open, the top screen previews your farmer.
        if meadow.showsFarmerCreator {
            FarmerPreviewScene(meadow: meadow)
                .clipped()
        } else if let person = meadow.focusedPersonID.flatMap(Person.find) {
            // A character's profile: their portrait and story up top, buttons on the deck below.
            PersonProfileScene(meadow: meadow, person: person)
                .clipped()
        } else if let town = meadow.town {
            TownScene(meadow: meadow, place: town)
        } else if meadow.isAtHome {
            HomeScene(meadow: meadow)
                .clipped()
        } else {
            world
        }
    }

    private var world: some View {
        // Everything in the meadow holds still while paused or on the start screen.
        TimelineView(.animation(minimumInterval: 1 / 24, paused: meadow.isPaused || meadow.isAtMainMenu)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            let mood = SkyMood(hour: Int(meadow.clockHour))
            let weather = meadow.weather

            GeometryReader { proxy in
                let size = proxy.size
                let map = WorldMap(size: size)

                ZStack(alignment: .topLeading) {
                    if let art = WorldArt.meadow {
                        Palette.ground
                        Image(uiImage: art)
                            .resizable()
                            .interpolation(.none)
                            .frame(width: map.rect.width, height: map.rect.height)
                            .position(x: map.rect.midX, y: map.rect.midY)
                    } else {
                        SkyView(mood: mood, weather: weather, t: t)
                        HillsView()
                        DrawnScenery(map: map, t: t, isNight: mood.isNight)
                    }

                    CropsOverlay(plots: meadow.plots, map: map, t: t)

                    ForEach(Decor.all.filter { meadow.decor.contains($0.id) }) { item in
                        DecorSprite(item: item, unit: map.unit, t: t, isNight: mood.isNight)
                            .position(map.point(item.spot))
                    }

                    HabitatBunnies(meadow: meadow, map: map, t: t)

                    LureGarden(meadow: meadow, map: map, t: t)

                    // The path to the village, at the bottom of the farm.
                    Text("🏘️ Village")
                        .font(.system(size: max(map.unit * 0.022, 9), weight: .bold, design: .rounded))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Palette.cream.opacity(0.9), in: .capsule)
                        .position(map.point(0.5, 0.955))
                        .allowsHitTesting(false)

                    // What the deck's action button would work on, once you're walking.
                    if let target = meadow.deckTarget() {
                        DeckTargetMarker(target: target, unit: map.unit, t: t)
                            .position(map.point(target.spot))
                    }

                    // The meadow gets a soft moonlit tint after dark, and a warm one at dawn and dusk.
                    timeTint(mood: mood, date: timeline.date)
                        .allowsHitTesting(false)

                    // Only characters with walking sprites stroll the meadow.
                    ForEach(Array(meadow.peopleInMeadow()
                        .filter { PersonArt.walking(for: $0.id, facing: .front) != nil }
                        .enumerated()), id: \.element.id) { index, person in
                        WalkingPerson(meadow: meadow, person: person, index: index, map: map, t: t)
                    }

                    // Your farmer walks their loop once you've made them in the farmer creator.
                    if let artID = meadow.farmerArtID(), PersonArt.walking(for: artID, facing: .front) != nil {
                        FarmerWalker(meadow: meadow, artID: artID, map: map, t: t)
                    }

                    WeatherOverlay(weather: weather, t: t)

                    if showsCollision {
                        CollisionOverlay(scene: Meadow.farmCollision, rect: map.rect, feet: meadow.farmerSpot)
                    }

                    WorldHUD(meadow: meadow, weather: weather, isNight: mood.isNight, date: timeline.date)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        .padding(10)

                    ForEach(meadow.bits) { bit in
                        BitView(bit: bit)
                            .position(map.point(bit.spot))
                    }
                }
                .onAppear { meadow.worldAspect = map.aspect }
                .onChange(of: map.aspect) { _, aspect in meadow.worldAspect = aspect }
            }
        }
        .clipped()
    }

    @ViewBuilder
    private func timeTint(mood: SkyMood, date: Date) -> some View {
        switch meadow.timeOfDay {
        case .night: Palette.night.opacity(0.3)
        case .dawn: Palette.peach.opacity(0.12)
        case .dusk: Palette.rose.opacity(0.12)
        case .day: Color.clear
        }
    }
}

// MARK: - Drawn fallback

/// The meadow drawn with shapes, laid out to match the artwork, for when the artwork is missing.
private struct DrawnScenery: View {
    let map: WorldMap
    let t: Double
    let isNight: Bool

    var body: some View {
        let unit = map.unit
        let rect = map.rect
        ZStack(alignment: .topLeading) {
            BlossomTree(height: unit * 0.4, t: t, phase: 1)
                .position(map.point(0.07, 0.3))
            BlossomTree(height: unit * 0.45, t: t, phase: 2)
                .position(map.point(0.9, 0.3))
            Cottage(width: unit * 0.28, isNight: isNight)
                .position(map.point(0.497, 0.17))

            ForEach(Array(WorldLayout.beds.enumerated()), id: \.offset) { _, bed in
                RoundedRectangle(cornerRadius: unit * 0.015)
                    .fill(Palette.darkSoil)
                    .frame(width: rect.width * WorldLayout.bedSize.width, height: unit * WorldLayout.bedSize.height)
                    .position(map.point(bed))
            }
            let field = WorldLayout.field
            RoundedRectangle(cornerRadius: unit * 0.02)
                .fill(Palette.darkSoil)
                .overlay(RoundedRectangle(cornerRadius: unit * 0.02).strokeBorder(Palette.bark.opacity(0.7), lineWidth: 2))
                .frame(width: rect.width * (field.maxX - field.minX), height: unit * (field.maxY - field.minY))
                .position(map.point((field.minX + field.maxX) / 2, (field.minY + field.maxY) / 2))
            let garden = WorldLayout.lureGarden
            Ellipse()
                .fill(Palette.mint)
                .overlay(Ellipse().strokeBorder(Palette.bark.opacity(0.7), style: StrokeStyle(lineWidth: 3, dash: [6, 4])))
                .frame(width: rect.width * (garden.maxX - garden.minX), height: unit * (garden.maxY - garden.minY))
                .position(map.point((garden.minX + garden.maxX) / 2, (garden.minY + garden.maxY) / 2))
            Text("🧺")
                .font(.system(size: unit * 0.06))
                .position(map.point(WorldLayout.lureBasket))
        }
    }
}

// MARK: - Crops

/// Crops growing in the beds and the big field. Sprouts sway; ready crops bounce.
private struct CropsOverlay: View {
    let plots: [Plot]
    let map: WorldMap
    let t: Double

    var body: some View {
        let unit = map.unit
        ZStack(alignment: .topLeading) {
            ForEach(Array(plots.enumerated()), id: \.offset) { index, plot in
                if let id = plot.cropID {
                    let phase = Double(index)
                    Group {
                        if plot.isReady {
                            ItemIcon(itemID: id, size: unit * 0.065)
                                .offset(y: -abs(sin(t * 3 + phase)) * unit * 0.008)
                        } else {
                            Text(plot.progress < 0.5 ? "🌱" : "🌿")
                                .font(.system(size: unit * (0.03 + 0.03 * plot.progress)))
                                .rotationEffect(.degrees(sin(t * 1.4 + phase) * 5), anchor: .bottom)
                        }
                    }
                    .position(map.point(WorldLayout.plot(index)))
                }
                // Pops the crop's icon in the bed when it's harvested.
                Color.clear
                    .frame(width: 1, height: 1)
                    .harvestPop(isReady: plot.isReady, cropID: plot.cropID, size: unit * 0.07)
                    .position(map.point(WorldLayout.plot(index)))
            }
        }
    }
}

// MARK: - Lure garden

/// Lure items sit by the basket. Visitors appear as silhouettes while approaching and stay
/// a mystery until you greet them.
private struct LureGarden: View {
    let meadow: Meadow
    let map: WorldMap
    let t: Double

    var body: some View {
        let unit = map.unit
        let basket = WorldLayout.lureBasket
        let bunnySize = unit * 0.065

        ZStack(alignment: .topLeading) {
            ForEach(Array(meadow.lureSlots.enumerated()), id: \.offset) { index, slot in
                // The first basket is in the artwork; extra baskets sit beside it.
                let offset = index == 0 ? 0.0 : (index == 1 ? -0.045 : 0.045)
                let spot = Spot(x: basket.x + offset, y: basket.y + (index == 0 ? 0 : 0.03))
                if index > 0 || WorldArt.meadow == nil {
                    Text("🧺")
                        .font(.system(size: unit * 0.04))
                        .position(map.point(spot))
                }
                HStack(spacing: 0) {
                    ForEach(slot.items, id: \.self) { item in
                        ItemIcon(itemID: item, size: unit * 0.022)
                    }
                }
                .position(map.point(spot.x, spot.y - 0.035))

                if let id = slot.visitorBreedID, let breed = Breed.find(id), slot.progress >= 0.5 {
                    let approach = min((slot.progress - 0.5) * 2, 1)
                    let bx = spot.x - 0.035 - 0.1 * (1 - approach)
                    VStack(spacing: 2) {
                        Text(slot.hasArrived ? "❗️" : "❓")
                            .font(.system(size: bunnySize * 0.3))
                            .offset(y: slot.hasArrived ? -abs(sin(t * 4)) * 6 : 0)
                        BreedBunnyView(breed: breed, size: bunnySize, time: slot.hasArrived ? t : nil,
                                       phase: Double(index), isSilhouette: !slot.hasArrived || !meadow.isDiscovered(breed))
                            .offset(y: slot.hasArrived ? 0 : -abs(sin(t * 5)) * 5)
                    }
                    .position(map.point(bx, spot.y - 0.02))
                }
            }
        }
    }
}

// MARK: - Habitat

/// Your bunnies playing in the meadow, each doing its breed's idle behavior.
private struct HabitatBunnies: View {
    let meadow: Meadow
    let map: WorldMap
    let t: Double

    var body: some View {
        let area = WorldLayout.habitat
        let shown = Array(meadow.bunnies.sorted { $0.isFavorite && !$1.isFavorite }.prefix(8))
        let accessory = meadow.equippedAccessory.flatMap { BunnyAccessory.find($0)?.emoji }
        let bunnySize = map.unit * 0.06

        ZStack(alignment: .topLeading) {
            ForEach(Array(shown.enumerated()), id: \.element.id) { index, bunny in
                if let breed = Breed.find(bunny.breedID) {
                    let phase = Double(index) * 1.3
                    let column = Double(index % 4)
                    let row = Double(index / 4)
                    let wander = sin(t * 0.25 + phase) * 0.015
                    // Hopping while wandering (up eases out, down eases in); a slow bob while resting.
                    let isMoving = abs(cos(t * 0.25 + phase)) > 0.35
                    let hopPhase = ((t + phase) / 0.5).truncatingRemainder(dividingBy: 1)
                    let hop = isMoving ? sin(hopPhase * .pi) * bunnySize * 0.14 : 0
                    let bob = isMoving ? 0 : (1 - cos((t + phase) * 2 * .pi / 3.2)) / 2 * PersonFigure.bobHeight
                    BreedBunnyView(breed: breed, size: bunnySize, time: t, phase: phase, accessory: accessory)
                        .offset(y: -hop - bob)
                        .position(map.point(area.minX + (area.maxX - area.minX) * (0.12 + 0.25 * column) + wander,
                                            area.minY + (area.maxY - area.minY) * (0.3 + 0.5 * row)))
                }
            }
        }
    }
}

// MARK: - People

/// A character strolling across the meadow. If you own one of their favorite breeds,
/// they wander over to coo at it.
private struct WalkingPerson: View {
    let meadow: Meadow
    let person: Person
    let index: Int
    let map: WorldMap
    let t: Double

    var body: some View {
        let offset = Double(index) * 7.3
        let ownsFavorite = meadow.bunnies.contains { person.favoriteBreeds.contains($0.breedID) }
        let route = WorldLayout.strollRoute(lane: index, visitsBunnies: ownsFavorite)
        let step = WorldLayout.routeStep(route, at: t + offset, aspect: map.aspect, speed: 0.045)
        let atBunnies = ownsFavorite && step.stop == 2
        let size = map.unit * 0.13
        let facing = WalkFacing.facing(for: step, id: person.id)
        let bubble: String? = atBunnies ? "🐰💕" : (step.stop != nil && sin(t * 0.3 + offset) > 0.2 ? person.slot(at: meadow.timeOfDay).emoji : nil)

        VStack(spacing: 2) {
            if let bubble {
                Text(bubble)
                    .font(.system(size: max(size * 0.14, 10)))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Palette.cream, in: .capsule)
                    .transition(.scale.combined(with: .opacity))
            }
            PersonFigure(look: person.look(onDay: meadow.today), artID: person.id, size: size, time: t + offset,
                         facing: facing, isWalking: step.isWalking)
            Text(person.name)
                .font(.system(size: max(size * 0.09, 9), weight: .bold, design: .rounded))
                .padding(.horizontal, 5)
                .background(Palette.cream.opacity(0.85), in: .capsule)
        }
        .position(map.point(step.spot.x, step.spot.y - 0.09))
        .accessibilityLabel("\(person.name) is in the meadow")
    }
}

/// Which sprite to show for a moment on a route.
enum WalkFacing {
    static func facing(for step: RouteStep, id: String) -> PersonArt.Facing {
        // Stopping shows the front sprite, or for someone without one, the step of their own walk
        // where their feet are together, still facing the way they were going.
        if !step.isWalking {
            return PersonArt.hasFrontSprite(id) ? .front : (step.dx >= 0 ? .right : .left)
        }
        let side: PersonArt.Facing = step.dx >= 0 ? .right : .left
        if abs(step.dx) > abs(step.dy) {
            return side
        }
        // Up or down the screen: a walk filmed for that direction if there is one, otherwise
        // the side walk (real steps beat a single picture sliding along).
        let vertical: PersonArt.Facing = step.dy < 0 ? .back : .front
        if PersonArt.hasWalkCycle(for: id, facing: vertical) || !PersonArt.hasWalkCycle(for: id, facing: side) {
            return vertical
        }
        return side
    }
}

/// Your farmer, standing where you last walked her. She never moves on her own.
private struct FarmerWalker: View {
    let meadow: Meadow
    let artID: String
    let map: WorldMap
    let t: Double

    var body: some View {
        let size = map.unit * 0.13
        let spot = meadow.farmerSpot
        PersonFigure(look: .farmer(wearing: Outfit.find(meadow.equippedOutfit) ?? Outfit.all[0]),
                     artID: artID, size: size, time: meadow.isDeckMoving ? meadow.walkCycleTime : t,
                     facing: meadow.farmerFacing, isWalking: meadow.isDeckMoving)
            .position(map.point(spot.x, spot.y - 0.065))
            .allowsHitTesting(false)
            .accessibilityLabel("Your farmer")
    }
}

// MARK: - Decor

private struct DecorSprite: View {
    let item: Decor
    let unit: CGFloat
    let t: Double
    let isNight: Bool

    var body: some View {
        let floats = ["balloon", "butterflies", "constellationLights"].contains(item.id)
        let bob = floats ? sin(t * 1.2 + item.spot.x * 10) * unit * 0.015 : 0

        Group {
            // The big detailed art when there is some, otherwise the icon.
            if let art = UIImage(named: "decor-\(item.id)") ?? UIImage(named: "decor-icon-\(item.id)") {
                Image(uiImage: art)
                    .resizable()
                    .interpolation(.none)
                    .scaledToFit()
                    .frame(width: unit * item.scale * 1.5, height: unit * item.scale * 1.5)
            } else {
                Text(item.emoji)
                    .font(.system(size: unit * item.scale))
            }
        }
            .offset(y: bob)
            .background {
                if (item.id == "lantern" || item.id == "starLanterns") && isNight {
                    Circle()
                        .fill(Palette.butter.opacity(0.45))
                        .frame(width: unit * 0.16, height: unit * 0.16)
                        .blur(radius: 12)
                }
            }
            .opacity(item.id == "rainbow" ? 0.85 : 1)
    }
}

// MARK: - HUD

private struct WorldHUD: View {
    let meadow: Meadow
    let weather: Weather
    let isNight: Bool
    let date: Date

    var body: some View {
        // Full bar when there's room; on narrow screens the title is dropped so nothing wraps.
        ViewThatFits(in: .horizontal) {
            bar(showsTitle: true)
            bar(showsTitle: false)
        }
        .foregroundStyle(Palette.ink)
    }

    private func bar(showsTitle: Bool) -> some View {
        HStack(alignment: .top, spacing: 6) {
            HStack(spacing: 6) {
                Text("🐰").font(.system(size: 20))
                VStack(alignment: .leading, spacing: 2) {
                    if showsTitle {
                        Text("Moonlit Meadows")
                            .font(.caption.bold())
                    }
                    Text("Lv. \(meadow.level) · 🐰 \(meadow.discoveredCount)/50")
                        .font(.caption2.bold())
                    ProgressView(value: Double(meadow.xp), total: Double(meadow.xpToNextLevel))
                        .tint(Palette.rose)
                        .frame(width: 80)
                }
            }
            .lineLimit(1)
            .fixedSize()
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .pixelPanel(Palette.lilacCard, edge: Palette.lilacEdge)

            Spacer(minLength: 4)

            HStack(alignment: .top, spacing: 6) {
                PauseButton(meadow: meadow)
                pill(value: meadow.coins.cozy) {
                    Text("☽").font(.system(size: 14, weight: .bold))
                }
                .popOnIncrease(meadow.coins)
                pill(value: meadow.gems.cozy) {
                    Text("💎").font(.system(size: 12))
                }
                .popOnIncrease(meadow.gems)
                HStack(spacing: 6) {
                    Text(Season.at(date).emoji).font(.system(size: 20))
                    VStack(alignment: .leading, spacing: 1) {
                        Text("\(isNight && weather == .sunny ? "🌙" : weather.emoji) \(isNight && weather == .sunny ? "Clear night" : weather.name)")
                            .font(.caption.bold())
                        Text("\(meadow.isFestivalDay ? "🎉 " : "")Day \(meadow.dayCount) · \(meadow.clockText)")
                            .font(.caption2.bold())
                        // How much of the day is left before bedtime.
                        ProgressView(value: meadow.dayElapsed, total: Meadow.dayLength)
                            .tint(meadow.clockHour >= 22 ? Palette.night : Palette.rose)
                            .frame(width: 90)
                    }
                }
                .lineLimit(1)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .pixelPanel(Palette.pinkCard, edge: Palette.pinkEdge)
            }
            .fixedSize()
        }
    }

    /// A small periwinkle counter that matches the weather card's text size.
    private func pill<Icon: View>(value: String, @ViewBuilder icon: () -> Icon) -> some View {
        HStack(spacing: 4) {
            icon()
            Text(value)
                .font(.caption.bold())
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .lineLimit(1)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .pixelPanel(Palette.periwinkle, edge: Palette.periwinkleEdge, cornerRadius: 14)
    }
}

// MARK: - Floating bits

private struct BitView: View {
    let bit: FloatingBit
    @State private var isDone = false

    var body: some View {
        coinText(bit.text)
            .font(.headline.bold())
            .foregroundStyle(bit.kind == .crack ? Color(red: 0.85, green: 0.18, blue: 0.22) : bit.kind == .heart ? Palette.rose : Palette.cocoa)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Palette.cream.opacity(0.92), in: .capsule)
            .scaleEffect(isDone && bit.kind != .text ? 1.25 : 1)
            .offset(y: isDone ? -60 : 0)
            .opacity(isDone ? 0 : 1)
            .allowsHitTesting(false)
            .onAppear {
                withAnimation(.easeOut(duration: 1.6)) {
                    isDone = true
                }
            }
    }
}

#Preview {
    WorldScene(meadow: Meadow(store: MemoryStore()))
        .frame(height: 420)
}
