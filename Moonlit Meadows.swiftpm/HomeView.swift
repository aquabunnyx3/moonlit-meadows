import SwiftUI
import UIKit

// MARK: - House (top screen)

/// Inside your cottage. The window shows day or night, and at bedtime the room goes dark
/// and fades into morning.
struct HomeScene: View {
    let meadow: Meadow
    @AppStorage("debugCollision") private var collisionOn = false
    @AppStorage("developerMode") private var developerMode = false
    private var showsCollision: Bool { developerMode && collisionOn }
    /// The sleeping bedroom (blanket breathing, Z's floating) is showing.
    @State private var showsSleepArt = false
    @State private var wantsToWake = false
    /// The bedtime scene playing over the room (Merlin, 2026-10-29), and whether it has ended.
    @State private var bedtimeVideo: String?
    @State private var bedtimeEnded = false

    /// Spots in the room art (`home-day` / `home-night`, 2096 × 1184), as fractions.
    private enum Spot {
        static let floor = CGPoint(x: 0.5, y: 0.78)
        static let chair = CGPoint(x: 0.79, y: 0.6)
        static let bed = CGPoint(x: 0.23, y: 0.47)
        static let petBed = CGPoint(x: 0.16, y: 0.84)
    }

    var body: some View {
        let night = meadow.isSleeping || meadow.clockHour >= 20

        GeometryReader { geo in
            let art = fit(geo.size)
            ZStack(alignment: .topLeading) {
                Color(red: 0.07, green: 0.07, blue: 0.2)
                room(night: false).opacity(night ? 0 : 1)
                room(night: true).opacity(night ? 1 : 0)

                if showsSleepArt {
                    SleepingRoom(art: art, isPaused: meadow.isPaused)
                        .transition(.opacity)
                }

                // Your farmer's goodnight scene plays first, over the room (Merlin, 2026-10-29).
                if meadow.isSleeping, let bedtimeVideo, !bedtimeEnded {
                    BedtimeSceneView(meadow: meadow, video: bedtimeVideo) { bedtimeEnded = true }
                        .transition(.opacity)
                }

                // A bunny napping in the pet bed.
                if !meadow.isSleeping, let bunny = meadow.bunnies.first(where: \.isFavorite) ?? meadow.bunnies.first,
                   let breed = Breed.find(bunny.breedID) {
                    TimelineView(.animation(minimumInterval: 1 / 12, paused: meadow.isPaused)) { timeline in
                        BreedBunnyView(breed: breed, size: art.height * 0.12,
                                       time: night ? nil : timeline.date.timeIntervalSinceReferenceDate)
                    }
                    .position(point(Spot.petBed, art))
                }

                if meadow.isSleeping {
                    EmptyView()
                } else if let artID = meadow.farmerArtID() {
                    // Your farmer stands where the D-pad walked them, or sits at the desk.
                    let spot = meadow.isSitting ? Spot.chair : CGPoint(x: meadow.homeSpot.x, y: meadow.homeSpot.y)
                    TimelineView(.animation(minimumInterval: 1 / 12, paused: meadow.isPaused)) { timeline in
                        PersonFigure(look: .farmer(wearing: Outfit.find(meadow.equippedOutfit) ?? Outfit.all[0]),
                                     artID: artID, size: art.height * (meadow.isSitting ? 0.28 : 0.36),
                                     time: meadow.isDeckMoving ? meadow.walkCycleTime : timeline.date.timeIntervalSinceReferenceDate,
                                     facing: meadow.isSitting ? .back : meadow.farmerFacing,
                                     isWalking: !meadow.isSitting && meadow.isDeckMoving)
                    }
                    .position(point(CGPoint(x: spot.x, y: spot.y - (meadow.isSitting ? 0.14 : 0.18)), art))
                    .animation(.easeInOut(duration: 0.5), value: meadow.isSitting)
                }

                // What the action button would work on.
                if !meadow.isSleeping, !meadow.isSitting, let target = meadow.deckTarget() {
                    TimelineView(.animation(minimumInterval: 1 / 12, paused: meadow.isPaused)) { timeline in
                        DeckTargetMarker(target: target, unit: art.height, t: timeline.date.timeIntervalSinceReferenceDate)
                    }
                    .position(point(CGPoint(x: target.spot.x, y: target.spot.y), art))
                }

                if showsCollision {
                    CollisionOverlay(scene: Meadow.homeCollision, rect: art, feet: meadow.homeSpot)
                }

                HStack(spacing: 6) {
                    Text(meadow.isSleeping ? "🌙 Sleeping…" : "🏠 Home · Day \(meadow.dayCount) · \(meadow.clockText)")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .pixelPanel(Palette.lilacCard, edge: Palette.lilacEdge, cornerRadius: 12)
                }
                .foregroundStyle(Palette.ink)
                .padding(10)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .animation(.easeInOut(duration: 2.5), value: night)
        }
        .contentShape(.rect)
        .onTapGesture {
            // Tap the room to wake up early.
            if meadow.isSleeping { wantsToWake = true }
        }
        .task(id: meadow.isSleeping) {
            // Sleep: your goodnight scene first if it's in the app, then the blanket (breathing,
            // Z's floating), back to the quiet night room, then morning. Without a scene video,
            // sleep is exactly as it was before (Merlin, 2026-10-29).
            guard meadow.isSleeping else { return }
            wantsToWake = false
            bedtimeVideo = BedtimeScene.videoName(for: meadow)
            bedtimeEnded = bedtimeVideo == nil
            if bedtimeVideo != nil {
                var waited = 0.0
                while !bedtimeEnded && !wantsToWake && !Task.isCancelled && waited < 15 {
                    try? await Task.sleep(for: .milliseconds(250))
                    if !meadow.isPaused { waited += 0.25 }
                }
                withAnimation(.easeInOut(duration: 1)) { bedtimeEnded = true }
            }
            if !wantsToWake {
                withAnimation(.easeInOut(duration: 1)) { showsSleepArt = true }
                var slept = 0.0
                // A short drift under the blanket after the scene; the full wait without one.
                let target = bedtimeVideo == nil ? 8.0 : 3.0
                while slept < target && !wantsToWake && !Task.isCancelled {
                    try? await Task.sleep(for: .milliseconds(250))
                    if !meadow.isPaused { slept += 0.25 }
                }
            }
            withAnimation(.easeInOut(duration: 1)) { showsSleepArt = false }
            try? await Task.sleep(for: .seconds(1.3))
            withAnimation(.easeInOut(duration: 2.5)) { meadow.wakeUp() }
        }
    }

    private func room(night: Bool) -> some View {
        GeometryReader { geo in
            if let image = UIImage(named: night ? "home-night" : "home-day") {
                let art = fit(geo.size)
                Image(uiImage: image)
                    .resizable()
                    .interpolation(.none)
                    .frame(width: art.width, height: art.height)
                    .position(x: art.midX, y: art.midY)
            }
        }
    }

    /// Fills the width and crops the top and bottom a little on wide screens; never stretches.
    private func fit(_ size: CGSize) -> CGRect {
        let aspect: CGFloat = 2096 / 1184
        var width = size.width, height = width / aspect
        if height < size.height { height = size.height; width = height * aspect }
        return CGRect(x: (size.width - width) / 2, y: (size.height - height) / 2, width: width, height: height)
    }

    private func point(_ spot: CGPoint, _ art: CGRect) -> CGPoint {
        CGPoint(x: art.minX + spot.x * art.width, y: art.minY + spot.y * art.height)
    }
}

// MARK: - Sleeping

/// The night bedroom with you asleep: the blanket rises and falls, and Z's drift up from
/// the pillow one at a time. Nothing else moves.
private struct SleepingRoom: View {
    let art: CGRect
    let isPaused: Bool

    /// Where the blanket layer (`home-sleep-blanket`) sits in the room art, as fractions.
    private static let blanket = CGRect(x: 0.1551, y: 0.2914, width: 0.1813, height: 0.2914)
    private static let pillow = CGPoint(x: 0.14, y: 0.35)
    private static let breathPeriod = 2.6
    private static let zPeriod = 3.0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20, paused: isPaused)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            // 0 → 1 → 0, easing in and out.
            let breath = (1 - cos(t * 2 * .pi / Self.breathPeriod)) / 2
            let frame = CGRect(x: art.minX + Self.blanket.minX * art.width, y: art.minY + Self.blanket.minY * art.height,
                               width: Self.blanket.width * art.width, height: Self.blanket.height * art.height)

            ZStack(alignment: .topLeading) {
                if let room = UIImage(named: "home-sleep") {
                    Image(uiImage: room)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: art.width, height: art.height)
                        .offset(x: art.minX, y: art.minY)
                }
                if let blanket = UIImage(named: "home-sleep-blanket") {
                    // Rises about 2.5 points at the top of each breath.
                    Image(uiImage: blanket)
                        .resizable()
                        .interpolation(.none)
                        .frame(width: frame.width, height: frame.height)
                        .scaleEffect(x: 1 + breath * 0.004, y: 1 + breath * 2.5 / max(frame.height, 1), anchor: .bottom)
                        .offset(x: frame.minX, y: frame.minY)
                }
                ForEach(0..<3, id: \.self) { index in
                    let cycle = ((t / Self.zPeriod) + Double(index) / 3).truncatingRemainder(dividingBy: 1)
                    Text("Z")
                        .font(.system(size: art.height * (0.035 + 0.02 * cycle), weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.lavender)
                        .shadow(color: Palette.night, radius: 0, x: 1, y: 1)
                        .opacity(cycle < 0.15 ? cycle / 0.15 : 1 - (cycle - 0.15) / 0.85)
                        .position(x: art.minX + (Self.pillow.x + 0.03 * cycle + 0.008 * sin(cycle * 6)) * art.width,
                                  y: art.minY + (Self.pillow.y - 0.16 * cycle) * art.height)
                }
            }
        }
        .allowsHitTesting(false)
        .accessibilityLabel("You're asleep. Tap to wake up.")
    }
}

// MARK: - Storage chest (bottom screen)

/// The storage chest at home, opened from the chest with the deck's action button: tap
/// something in the chest to take it out, or in your backpack to put it away.
struct HomePanel: View {
    let meadow: Meadow

    var body: some View {
        backpackArea
            .foregroundStyle(Palette.ink)
            .fontDesign(.rounded)
    }

    private var backpackArea: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text("📦 Storage chest · tap to take out").font(.caption.bold())
                grid(items: ItemInfo.allIDs.filter { meadow.count(inStorage: $0) > 0 },
                     count: meadow.count(inStorage:), minimumSlots: 10) { meadow.takeFromStorage($0) }
                Text("🎒 Backpack · tap to put away").font(.caption.bold()).padding(.top, 4)
                grid(items: backpack, count: meadow.count(of:), minimumSlots: 10) { meadow.putInStorage($0) }
            }
            .padding(.bottom, 60)
        }
        .scrollIndicators(.hidden)
    }

    private var backpack: [String] {
        ItemInfo.allIDs.filter { meadow.count(of: $0) > 0 }
    }

    private func grid(items: [String], count: @escaping (String) -> Int, minimumSlots: Int,
                      tap: @escaping (String) -> Void) -> some View {
        let slots = max(minimumSlots, (items.count + 4) / 5 * 5)
        return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 5), spacing: 8) {
            ForEach(0..<slots, id: \.self) { index in
                let id = index < items.count ? items[index] : nil
                Button {
                    if let id { tap(id) }
                } label: {
                    ZStack(alignment: .bottomTrailing) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Palette.cream.opacity(0.75))
                            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Palette.ink.opacity(0.75), lineWidth: 2))
                        if let id {
                            ItemIcon(itemID: id, size: 30)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            Text("\(count(id))")
                                .font(.caption2.bold())
                                .monospacedDigit()
                                .contentTransition(.numericText())
                                .popOnIncrease(count(id), scale: 1.25)
                                .padding(.horizontal, 4)
                                .padding(4)
                        }
                    }
                    .aspectRatio(1, contentMode: .fit)
                }
                .buttonStyle(SquishButtonStyle())
                .disabled(id == nil || meadow.isSleeping)
                .accessibilityLabel(id.map { "\(ItemInfo.name($0)), \(count($0))" } ?? "Empty slot")
            }
        }
    }
}
