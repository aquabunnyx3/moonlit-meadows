import SwiftUI

/// Shown when you come back: how long you were gone, what the helper bunnies harvested,
/// and whether any lure visitors are waiting.
struct WelcomeBackView: View {
    let report: AwayReport
    let dismiss: () -> Void

    var body: some View {
        let harvested = ItemInfo.allIDs.compactMap { id in
            report.harvested[id].map { (id: id, count: $0) }
        }

        VStack(spacing: 14) {
            HStack(spacing: -8) {
                if let clover = Breed.find("cloverBunny") { BreedBunnyView(breed: clover, size: 70) }
                if let snowflake = Breed.find("snowflakeBunny") { BreedBunnyView(breed: snowflake, size: 60) }
            }
            Text("Welcome back to Moonlit Meadows!")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("You were away for \(report.duration.countdown).")
                .opacity(0.8)

            if harvested.isEmpty {
                Text(report.readyPlots > 0
                     ? "Your crops grew while you were gone. \(report.readyPlots) plots are ready to harvest! 🌱"
                     : "Your crops kept growing while you were gone 🌱")
                    .multilineTextAlignment(.center)
            } else {
                Text("Your helper bunnies harvested:")
                HStack(spacing: 8) {
                    ForEach(harvested, id: \.id) { item in
                        HStack(spacing: 2) {
                            ItemIcon(itemID: item.id, size: 18)
                            Text("×\(item.count)")
                        }
                        .font(.headline)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Palette.cream, in: .capsule)
                    }
                }
            }
            if report.visitorsArrived > 0 {
                Text("🐾 \(report.visitorsArrived) bunny visitor\(report.visitorsArrived == 1 ? " is" : "s are") waiting at your lures!")
                    .font(.subheadline.bold())
            }

            Button(action: dismiss) {
                Text("Yay! 💕")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 40)
                    .padding(.vertical, 14)
                    .background(Palette.rose, in: .capsule)
            }
            .buttonStyle(SquishButtonStyle())
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Palette.blush)
        .foregroundStyle(Palette.cocoa)
        .fontDesign(.rounded)
    }
}
