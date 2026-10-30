import SwiftUI

/// Lays out the village and the control deck.
///
/// Swift Playgrounds doesn't include the iPhone Duo fold APIs yet, so instead of detecting
/// the fold, there's a **Laptop mode** switch. It splits the screen in half, right where the
/// iPhone Duo folds: village on top, control deck below. Without it, the game picks a
/// side-by-side layout on wide screens (like an iPad in landscape) and a stacked one otherwise.
struct ContentView: View {
    @State private var meadow = Meadow()
    @AppStorage("laptopMode") private var isLaptopMode = false
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GeometryReader { proxy in
            let size = proxy.size

            Group {
                if isLaptopMode {
                    laptopLayout(size: size)
                } else if size.width > size.height * 1.2 {
                    sideBySideLayout(size: size)
                } else {
                    stackedLayout(size: size)
                }
            }
            .animation(.smooth, value: isLaptopMode)
        }
        .background(Palette.blush)
        .foregroundStyle(Palette.cocoa)
        .fontDesign(.rounded)
        .preferredColorScheme(.light)
        .task {
            while !Task.isCancelled {
                meadow.tick()
                try? await Task.sleep(for: .milliseconds(100))
            }
        }
        .onChange(of: scenePhase, initial: true) { _, phase in
            switch phase {
            case .active: meadow.welcomeBack()
            case .background: meadow.save()
            default: break
            }
        }
        .overlay {
            if let visit = meadow.pendingVisit {
                DiscoveryOverlay(outcome: visit) {
                    withAnimation { meadow.pendingVisit = nil }
                }
                .transition(.opacity)
            }
        }
        .sheet(item: $meadow.awayReport) { report in
            WelcomeBackView(report: report) {
                meadow.awayReport = nil
            }
            .presentationDetents([.medium])
        }
        .presentsScenes(meadow)
        .bedtime(meadow)
        .gameMenus(meadow)
        .backgroundMusic(meadow)
        .buttonStyle(TapSoundButtonStyle())
    }

    // MARK: Layouts

    /// Village on the top half, control deck on the bottom half, with a gap at the fold.
    private func laptopLayout(size: CGSize) -> some View {
        let foldGap: CGFloat = 40
        let half = max((size.height - foldGap) / 2, 0)

        return VStack(spacing: 0) {
            world
                .padding([.horizontal, .top], 12)
                .padding(.bottom, 8)
                .frame(height: half)

            Color.clear
                .frame(height: foldGap)

            ControlPanel(meadow: meadow)
                .padding([.horizontal, .bottom], 12)
                .padding(.top, 8)
                .frame(height: half)
        }
        .transition(.blurReplace)
    }

    private func sideBySideLayout(size: CGSize) -> some View {
        HStack(spacing: 12) {
            world
                .frame(width: size.width * 0.55)
            ControlPanel(meadow: meadow)
        }
        .padding(12)
        .transition(.blurReplace)
    }

    private func stackedLayout(size: CGSize) -> some View {
        VStack(spacing: 12) {
            world
                .frame(height: size.height * 0.42)
            ControlPanel(meadow: meadow)
        }
        .padding(12)
        .transition(.blurReplace)
    }

    private var world: some View {
        WorldScene(meadow: meadow)
            .clipShape(.rect(cornerRadius: 28))
            .overlay(alignment: .bottomTrailing) {
                Button {
                    isLaptopMode.toggle()
                } label: {
                    Label(isLaptopMode ? "Normal" : "Laptop mode", systemImage: isLaptopMode ? "iphone" : "laptopcomputer")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Palette.cream.opacity(0.92), in: .capsule)
                }
                .buttonStyle(SquishButtonStyle())
                .padding(10)
            }
    }
}

#Preview {
    ContentView()
}
