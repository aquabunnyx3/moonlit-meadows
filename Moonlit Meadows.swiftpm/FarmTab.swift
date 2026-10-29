import SwiftUI

/// Pick a seed, tap empty plots to plant, tap ready plots to harvest.
struct FarmTab: View {
    @Bindable var meadow: Meadow

    var body: some View {
        VStack(spacing: 10) {
            seedPicker

            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 76), spacing: 10)], spacing: 10) {
                    ForEach(meadow.plots.indices, id: \.self) { index in
                        PlotCell(
                            plot: meadow.plots[index],
                            secondsLeft: meadow.secondsLeft(on: meadow.plots[index]),
                            selectedSeedID: meadow.selectedSeed
                        ) {
                            meadow.tapPlot(index)
                        }
                    }
                    if let cost = meadow.nextPlotCost {
                        Button {
                            meadow.buyPlot()
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: "plus")
                                    .font(.title3.bold())
                                coinText("🪙 \(cost.cozy)")
                                    .font(.caption.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .foregroundStyle(Palette.ink)
                            .frame(height: 86)
                            .background(Palette.lilacCard.opacity(0.8), in: .rect(cornerRadius: 14))
                            .overlay {
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Palette.lilacEdge, style: StrokeStyle(lineWidth: 2.5, dash: [6, 4]))
                            }
                        }
                        .buttonStyle(SquishButtonStyle())
                        .disabled(meadow.coins < cost)
                        .opacity(meadow.coins < cost ? 0.5 : 1)
                        .accessibilityLabel("Buy a new plot for \(cost) coins")
                    }
                }
            }
            .scrollIndicators(.hidden)

            HStack(spacing: 8) {
                Button {
                    withAnimation(.easeInOut(duration: 0.4)) { meadow.enterHome() }
                } label: {
                    Text("🏠 Home")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .foregroundStyle(Palette.ink)
                        .pixelPanel(Palette.lilacCard, edge: Palette.lilacEdge, cornerRadius: 16)
                }
                .buttonStyle(SquishButtonStyle())
                .accessibilityLabel("Go inside your cottage")

                Button {
                    meadow.harvestAndReplantAll()
                } label: {
                    Label("Harvest all", systemImage: "basket.fill")
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .foregroundStyle(Palette.ink)
                        .pixelPanel(Palette.pinkCard, edge: Palette.pinkEdge, cornerRadius: 16)
                }
                .buttonStyle(SquishButtonStyle())

                Button {
                    meadow.growAllWithGems()
                } label: {
                    Text("✨ Grow all · \(Meadow.growAllGemCost)💎")
                        .font(.subheadline.bold())
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .foregroundStyle(Palette.ink)
                        .pixelPanel(Palette.periwinkle, edge: Palette.periwinkleEdge, cornerRadius: 16)
                }
                .buttonStyle(SquishButtonStyle())
                .disabled(meadow.gems < Meadow.growAllGemCost)
            }
        }
    }

    private var seedPicker: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(Crop.all) { crop in
                    let isUnlocked = meadow.isUnlocked(crop)
                    let isSelected = meadow.selectedSeed == crop.id
                    Button {
                        meadow.selectedSeed = crop.id
                    } label: {
                        HStack(spacing: 4) {
                            if isUnlocked {
                                ItemIcon(itemID: crop.id, size: 20)
                            } else {
                                Text("🔒")
                            }
                            VStack(alignment: .leading, spacing: 0) {
                                Text(crop.name)
                                    .font(.caption.bold())
                                coinText(isUnlocked
                                     ? "🪙 \(crop.seedCost) · \(crop.growSeconds.countdown) · 🐰×\(lureUses(crop))"
                                     : "Unlocks at Lv \(crop.unlockLevel)")
                                    .font(.caption2)
                                    .opacity(0.75)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .foregroundStyle(Palette.ink)
                        .pixelPanel(isSelected ? Palette.pinkCard : Palette.periwinkle,
                                    edge: isSelected ? Palette.rose : Palette.periwinkleEdge, cornerRadius: 14)
                    }
                    .buttonStyle(SquishButtonStyle())
                    .disabled(!isUnlocked)
                    .opacity(isUnlocked ? 1 : 0.55)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    /// How many breeds use this crop in their lure, so players see why each crop matters.
    private func lureUses(_ crop: Crop) -> Int {
        Breed.all.filter { $0.lure.contains(crop.id) }.count
    }
}

private struct PlotCell: View {
    let plot: Plot
    let secondsLeft: TimeInterval?
    let selectedSeedID: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                // Periwinkle pixel tiles like the mockup; a planted plot shows soil inside.
                RoundedRectangle(cornerRadius: 14)
                    .fill(Palette.periwinkle)
                    .overlay(RoundedRectangle(cornerRadius: 14).inset(by: 3).strokeBorder(.white.opacity(0.55), lineWidth: 1.5))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(Palette.periwinkleEdge, lineWidth: 2.5))
                if plot.cropID != nil {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Palette.darkSoil)
                        .padding(7)
                }

                if let id = plot.cropID {
                    if plot.isReady {
                        VStack(spacing: 0) {
                            ItemIcon(itemID: id, size: 34)
                            Text("Harvest!")
                                .font(.caption2.bold())
                                .foregroundStyle(.white)
                        }
                    } else {
                        VStack(spacing: 2) {
                            Text(plot.progress < 0.5 ? "🌱" : "🌿")
                                .font(.system(size: 26))
                            ProgressView(value: plot.progress)
                                .tint(Palette.mint)
                                .frame(width: 46)
                            if let secondsLeft {
                                Text(secondsLeft.countdown)
                                    .font(.caption2.bold())
                                    .monospacedDigit()
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                } else {
                    VStack(spacing: 2) {
                        ItemIcon(itemID: selectedSeedID, size: 24)
                            .opacity(0.6)
                        Text("Plant")
                            .font(.caption.bold())
                            .foregroundStyle(.white)
                            .shadow(color: Palette.periwinkleEdge, radius: 0, x: 1, y: 1)
                    }
                }
            }
            .frame(height: 86)
            .overlay {
                if plot.isReady {
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Palette.butter, lineWidth: 3)
                }
            }
        }
        .harvestPop(isReady: plot.isReady, cropID: plot.cropID, size: 34)
        .buttonStyle(SquishButtonStyle())
    }
}
