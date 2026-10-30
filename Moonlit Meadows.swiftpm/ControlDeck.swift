import SwiftUI

// MARK: - Control deck, slice 1 (Merlin, 2026-10-29, while Claude was out of tokens)

/// The first slice of the Stardew-style control deck from the Duo design: a D-pad that
/// drives your farmer around the meadow (replacing their stroll loop while it's on), a
/// context chip naming what the big button would do, and an adaptive action button that
/// works the nearest plot — Plant with the seed picked below, or Harvest when it's ready,
/// exactly like tapping that plot in the list. Everything else about farming is unchanged:
/// the tab bar, the plot grid and the seed picker all still work as they did.
///
/// Slice 2 (Claude): the full deck chrome from the mockup — quick inventory slots, the
/// deck across every tab, and contextual actions for people, doors and the lure basket.
extension Meadow {
    /// Standing still or walking, for the farmer's walk cycle while driving.
    var isDeckMoving: Bool { deckDirection.x != 0 || deckDirection.y != 0 }

    /// Switch between watching your farmer stroll and driving them yourself.
    func toggleDeckDriving() {
        isDeckDriving.toggle()
        deckDirection = (0, 0)
        if isDeckDriving, farmerSpot == nil {
            farmerSpot = Spot(x: 0.5, y: 0.58)
        }
        feedbackCount += 1
    }

    /// One small step of D-pad movement. Called on a timer by the deck while driving.
    func deckStep(dt: Double) {
        guard isDeckDriving, !isPaused, !isAtMainMenu, let spot = farmerSpot else { return }
        let d = deckDirection
        guard d.x != 0 || d.y != 0 else { return }
        let speed = 0.14
        let x = min(max(spot.x + d.x * speed * dt / max(worldAspect, 0.5), 0.05), 0.95)
        let y = min(max(spot.y + d.y * speed * dt, 0.30), 0.93)
        farmerSpot = Spot(x: x, y: y)
        if abs(d.x) > abs(d.y) {
            farmerFacing = d.x >= 0 ? .right : .left
        } else {
            farmerFacing = d.y < 0 ? .back : .front
        }
    }

    /// The plot in reach of your farmer and what the action button would do there.
    func deckTarget() -> (index: Int, verb: String, canAct: Bool)? {
        guard isDeckDriving, let spot = farmerSpot else { return nil }
        var best: (index: Int, distance: Double)?
        for index in plots.indices {
            let p = plotSpot(index)
            let dx = (p.x - spot.x) * worldAspect
            let dy = p.y - spot.y
            let distance = (dx * dx + dy * dy).squareRoot()
            if distance < 0.24, best == nil || distance < best!.distance {
                best = (index, distance)
            }
        }
        guard let target = best else { return nil }
        let plot = plots[target.index]
        if plot.isReady { return (target.index, "Harvest", true) }
        if plot.cropID == nil {
            return (target.index, "Plant \(Crop.find(selectedSeed)?.name ?? "seeds")", true)
        }
        return (target.index, "Growing", false)
    }

    /// The adaptive action button: works the plot in reach, like tapping it in the list.
    func deckAction() {
        guard let target = deckTarget(), target.canAct else { return }
        tapPlot(target.index)
    }
}

/// The deck strip at the top of the Farm tab: D-pad on the left, context in the middle,
/// the big adaptive button on the right.
struct ControlDeckStrip: View {
    @Bindable var meadow: Meadow

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            pad
            middle
            Spacer(minLength: 0)
            buttons
        }
        .padding(10)
        .pixelPanel(Palette.cream.opacity(0.65), edge: Palette.lilacEdge, cornerRadius: 18)
        .task(id: meadow.isDeckDriving) {
            // The driving loop: small even steps while Drive mode is on.
            guard meadow.isDeckDriving else { return }
            while !Task.isCancelled {
                meadow.deckStep(dt: 0.05)
                try? await Task.sleep(for: .milliseconds(50))
            }
        }
    }

    // MARK: D-pad

    private var pad: some View {
        Grid(horizontalSpacing: 4, verticalSpacing: 4) {
            GridRow {
                Color.clear.frame(width: 40, height: 40)
                padButton("chevron.up", "Walk up", (0, -1))
                Color.clear.frame(width: 40, height: 40)
            }
            GridRow {
                padButton("chevron.left", "Walk left", (-1, 0))
                Circle()
                    .fill(Palette.lilacEdge)
                    .frame(width: 12, height: 12)
                    .frame(width: 40, height: 40)
                padButton("chevron.right", "Walk right", (1, 0))
            }
            GridRow {
                Color.clear.frame(width: 40, height: 40)
                padButton("chevron.down", "Walk down", (0, 1))
                Color.clear.frame(width: 40, height: 40)
            }
        }
        .opacity(meadow.isDeckDriving ? 1 : 0.45)
    }

    private func padButton(_ symbol: String, _ label: String, _ direction: (x: Double, y: Double)) -> some View {
        let held = meadow.deckDirection.x == direction.x && meadow.deckDirection.y == direction.y
            && (direction.x != 0 || direction.y != 0)
        return Image(systemName: symbol)
            .font(.system(size: 17, weight: .bold))
            .foregroundStyle(Palette.ink)
            .frame(width: 40, height: 40)
            .pixelPanel(held ? Palette.pinkCard : Palette.lilacCard,
                        edge: held ? Palette.rose : Palette.lilacEdge, cornerRadius: 12)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if meadow.isDeckDriving { meadow.deckDirection = direction }
                    }
                    .onEnded { _ in
                        if meadow.deckDirection.x == direction.x && meadow.deckDirection.y == direction.y {
                            meadow.deckDirection = (0, 0)
                        }
                    }
            )
            .accessibilityLabel(label)
            .accessibilityAddTraits(.isButton)
    }

    // MARK: Context

    private var middle: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(chipText)
                .font(.caption.bold())
                .foregroundStyle(Palette.ink)
                .lineLimit(2)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .pixelPanel(Palette.lilacCard, edge: Palette.lilacEdge, cornerRadius: 12)
            if meadow.isDeckDriving {
                HStack(spacing: 4) {
                    ItemIcon(itemID: meadow.selectedSeed, size: 18)
                    Text("Seed: \(Crop.find(meadow.selectedSeed)?.name ?? "—")")
                        .font(.caption2.bold())
                        .foregroundStyle(Palette.ink)
                }
                .opacity(0.85)
            }
        }
    }

    private var chipText: String {
        guard meadow.isDeckDriving else { return "Your farmer is strolling 🌙" }
        if let target = meadow.deckTarget() {
            return "Plot \(target.index + 1) · \(target.verb)"
        }
        return meadow.isDeckMoving ? "Walking…" : "Nothing in reach 🌙"
    }

    // MARK: Buttons

    private var buttons: some View {
        VStack(spacing: 8) {
            if meadow.isDeckDriving {
                let target = meadow.deckTarget()
                Button {
                    meadow.deckAction()
                } label: {
                    Text(target?.verb ?? "···")
                        .font(.subheadline.bold())
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: 104, height: 46)
                        .foregroundStyle(.white)
                        .pixelPanel(Palette.rose, edge: Palette.pinkEdge, cornerRadius: 16)
                }
                .buttonStyle(SquishButtonStyle())
                .disabled(!(target?.canAct ?? false))
                .opacity(target?.canAct ?? false ? 1 : 0.55)
                .accessibilityLabel(target.map { "\($0.verb) plot \($0.index + 1)" } ?? "Nothing in reach")

                Button {
                    meadow.toggleDeckDriving()
                } label: {
                    Text("Stroll")
                        .font(.caption.bold())
                        .frame(width: 104, height: 30)
                        .foregroundStyle(Palette.ink)
                        .pixelPanel(Palette.periwinkle, edge: Palette.periwinkleEdge, cornerRadius: 12)
                }
                .buttonStyle(SquishButtonStyle())
                .accessibilityLabel("Stop driving and let your farmer stroll")
            } else {
                Button {
                    meadow.toggleDeckDriving()
                } label: {
                    Text("🕹️ Drive")
                        .font(.subheadline.bold())
                        .frame(width: 104, height: 46)
                        .foregroundStyle(.white)
                        .pixelPanel(Palette.rose, edge: Palette.pinkEdge, cornerRadius: 16)
                }
                .buttonStyle(SquishButtonStyle())
                .accessibilityLabel("Drive your farmer with the D-pad")
            }
        }
    }
}
