import SwiftUI

/// The seed bag, opened by tapping the seeds slot of the quick inventory when it's already in
/// hand: every crop, with its price, growing time and how many bunny lures use it. Pick one
/// to plant it with the action button. (Planting and harvesting happen out in the world now,
/// with the D-pad and the action button.)
struct FarmTab: View {
    @Bindable var meadow: Meadow

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("🌱 Seeds · pick one to plant").font(.subheadline.bold())
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 170), spacing: 8)], spacing: 8) {
                    ForEach(Crop.all) { crop in
                        seedButton(crop)
                    }
                }
                .padding(.bottom, 60)
            }
            .scrollIndicators(.hidden)
        }
    }

    private func seedButton(_ crop: Crop) -> some View {
        let isUnlocked = meadow.isUnlocked(crop)
        let isSelected = meadow.selectedSeed == crop.id
        let packets = meadow.count(of: ShopLayout.seedPacketID(crop.id))
        return Button {
            meadow.pickSeed(crop.id)
            meadow.panelTabID = PanelTab.farm.rawValue
        } label: {
            HStack(spacing: 6) {
                if isUnlocked {
                    ItemIcon(itemID: crop.id, size: 26)
                } else {
                    Text("🔒")
                }
                VStack(alignment: .leading, spacing: 0) {
                    Text(crop.name)
                        .font(.caption.bold())
                    coinText(isUnlocked
                         ? "\(packets > 0 ? "🎒 ×\(packets) · " : "")🪙 \(crop.seedCost) · \(crop.growSeconds.countdown) · 🐰×\(lureUses(crop))"
                         : "Unlocks at Lv \(crop.unlockLevel)")
                        .font(.caption2)
                        .opacity(0.75)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .foregroundStyle(Palette.ink)
            .pixelPanel(isSelected ? Palette.pinkCard : Palette.periwinkle,
                        edge: isSelected ? Palette.rose : Palette.periwinkleEdge, cornerRadius: 14)
        }
        .buttonStyle(SquishButtonStyle())
        .disabled(!isUnlocked)
        .opacity(isUnlocked ? 1 : 0.55)
    }

    /// How many breeds use this crop in their lure, so players see why each crop matters.
    private func lureUses(_ crop: Crop) -> Int {
        Breed.all.filter { $0.lure.contains(crop.id) }.count
    }
}
