import SwiftUI

/// Shows story scenes and toasts from whatever layer is on top.
///
/// SwiftUI can only present from the topmost view, so this is attached both to the root view
/// and to sheets that can trigger scenes (a profile, the gift pickers). Only the topmost one
/// actually presents.
struct ScenePresenter: ViewModifier {
    let meadow: Meadow

    func body(content: Content) -> some View {
        content
            .fullScreenCover(item: Binding(get: { meadow.presentedScene }, set: { meadow.presentedScene = $0 })) { scene in
                StorySceneView(meadow: meadow, scene: scene) {
                    meadow.presentedScene = nil
                }
            }
            .overlay(alignment: .top) {
                if let toast = meadow.toast {
                    coinText(toast)
                        .font(.callout.weight(.semibold))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Palette.cream, in: .rect(cornerRadius: 18))
                        .shadow(color: Palette.rose.opacity(0.3), radius: 10, y: 4)
                        .padding(.horizontal, 24)
                        .padding(.top, 8)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .onTapGesture { meadow.toast = nil }
                }
            }
            .animation(.snappy, value: meadow.toast)
            .task(id: meadow.toast) {
                guard let shown = meadow.toast else { return }
                try? await Task.sleep(for: .seconds(4))
                if meadow.toast == shown {
                    meadow.toast = nil
                }
            }
    }
}

extension View {
    func presentsScenes(_ meadow: Meadow) -> some View {
        modifier(ScenePresenter(meadow: meadow))
    }
}

// MARK: - Bedtime

extension View {
    /// When the day's time runs out, your farmer says goodnight over everything else.
    func bedtime(_ meadow: Meadow) -> some View {
        overlay {
            if meadow.isBedtime && !meadow.isSleeping {
                BedtimeView(meadow: meadow)
                    .ignoresSafeArea()
            }
        }
        .animation(.easeInOut(duration: 0.6), value: meadow.isBedtime && !meadow.isSleeping)
    }
}

// MARK: - Farmer creator

/// Top screen while the farmer creator is open: your farmer's big portrait and a little
/// walking sprite that turns around, over the blurred meadow.
struct FarmerPreviewScene: View {
    let meadow: Meadow

    var body: some View {
        let look = meadow.farmerDraft
        let id = FarmerRenderer.artID(for: look)

        ZStack {
            DialogBackdrop(isRomantic: false)
            GeometryReader { proxy in
                HStack(alignment: .bottom, spacing: 12) {
                    if let art = PersonArt.image(for: id) {
                        Image(uiImage: art)
                            .resizable()
                            .scaledToFit()
                            .frame(height: proxy.size.height * 0.92)
                            .accessibilityLabel("Your farmer")
                    }
                    VStack(spacing: 10) {
                        Text(meadow.farmerGender == nil ? "Create your farmer" : "Change your look")
                            .font(.title3.bold())
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .pixelPanel(Palette.lilacCard, edge: Palette.lilacEdge, cornerRadius: 14)
                        Text(summary(look))
                            .font(.caption.bold())
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .pixelPanel(Palette.pinkCard, edge: Palette.pinkEdge, cornerRadius: 12)
                        Spacer(minLength: 0)
                        TimelineView(.periodic(from: .now, by: 0.9)) { timeline in
                            let turns: [PersonArt.Facing] = [.front, .right, .back, .left]
                            let facing = turns[Int(timeline.date.timeIntervalSinceReferenceDate / 0.9) % turns.count]
                            PersonFigure(look: .farmer(wearing: Outfit.find(look.outfit) ?? Outfit.all[0]),
                                         artID: id, size: proxy.size.height * 0.45, facing: facing)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .foregroundStyle(Palette.ink)
        .fontDesign(.rounded)
    }

    private func summary(_ look: FarmerLook) -> String {
        let hair = FarmerLook.hair(look.hairColor)?.name ?? ""
        let eyes = FarmerLook.eyes(look.eyeColor)?.name ?? ""
        let style = look.gender.hairStyles[safe: look.hairStyle] ?? ""
        return "\(style) · \(hair) hair · \(eyes) eyes"
    }
}

/// Bottom screen while the farmer creator is open: tap a category, then tap a choice,
/// just like picking seeds on the farm.
struct FarmerOptionsPanel: View {
    let meadow: Meadow
    @State private var section = CreatorSection.body

    enum CreatorSection: String, CaseIterable, Identifiable {
        case body, skin, hairStyle, hairColor, eyes, outfit

        var id: String { rawValue }

        var title: String {
            switch self {
            case .body: return "Body"
            case .skin: return "Skin"
            case .hairStyle: return "Hair"
            case .hairColor: return "Color"
            case .eyes: return "Eyes"
            case .outfit: return "Outfit"
            }
        }

        /// Pixel icon from the Farmer Creator Tabs sheet.
        var iconName: String {
            switch self {
            case .hairStyle: return "creator-hair"
            case .hairColor: return "creator-color"
            default: return "creator-\(rawValue)"
            }
        }

        var emoji: String {
            switch self {
            case .body: return "🧑‍🌾"
            case .skin: return "🤎"
            case .hairStyle: return "💇"
            case .hairColor: return "🎨"
            case .eyes: return "👀"
            case .outfit: return "👕"
            }
        }
    }

    var body: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    ForEach(CreatorSection.allCases) { item in
                        Button {
                            withAnimation(.snappy) { section = item }
                        } label: {
                            VStack(spacing: 2) {
                                ArtIcon(name: item.iconName, emoji: item.emoji, size: 26)
                                Text(item.title).font(.caption.bold())
                            }
                            .frame(width: 66, height: 54)
                            .pixelPanel(section == item ? Palette.pinkCard : Palette.lilacCard,
                                        edge: section == item ? Palette.rose : Palette.lilacEdge, cornerRadius: 14)
                        }
                        .buttonStyle(SquishButtonStyle())
                        .accessibilityAddTraits(section == item ? .isSelected : [])
                    }
                }
                .padding(4)
            }
            .scrollIndicators(.hidden)

            ScrollView {
                options
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)

            HStack(spacing: 8) {
                if meadow.farmerGender != nil {
                    Button {
                        meadow.isCustomizingFarmer = false
                    } label: {
                        Text("Cancel")
                            .font(.subheadline.bold())
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .pixelPanel(Palette.periwinkle, edge: Palette.periwinkleEdge, cornerRadius: 16)
                    }
                    .buttonStyle(SquishButtonStyle())
                }
                Button {
                    meadow.setFarmer(meadow.farmerDraft)
                } label: {
                    Text(meadow.farmerGender == nil ? "🌱 Start farming" : "💕 Save look")
                        .font(.subheadline.bold())
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .pixelPanel(Palette.pinkCard, edge: Palette.pinkEdge, cornerRadius: 16)
                }
                .buttonStyle(SquishButtonStyle())
            }
        }
        .foregroundStyle(Palette.ink)
        .fontDesign(.rounded)
    }

    @ViewBuilder
    private var options: some View {
        let draft = meadow.farmerDraft
        switch section {
        case .body:
            HStack(spacing: 12) {
                ForEach(FarmerGender.allCases) { gender in
                    faceTile(draft.with { $0.gender = gender; $0 = $0.validated() }, title: gender.title,
                             isSelected: draft.gender == gender) {
                        update { $0.gender = gender; $0 = $0.validated() }
                    }
                }
            }
        case .skin:
            swatchRow(FarmerGender.skinTones.map { tone in
                SwatchItem(id: "\(tone)", name: FarmerLook.skinSwatches[tone]?.name ?? "", color: FarmerLook.skinSwatches[tone]?.rgb ?? RGB(0x6B4430))
            }, selected: "\(draft.skinTone)") { id in
                update { $0.skinTone = Int(id) ?? 3 }
            }
        case .hairStyle:
            HStack(spacing: 12) {
                ForEach(Array(draft.gender.hairStyles.enumerated()), id: \.offset) { index, name in
                    faceTile(draft.with { $0.hairStyle = index; $0 = $0.validated() }, title: name,
                             isSelected: draft.hairStyle == index) {
                        update { $0.hairStyle = index; $0 = $0.validated() }
                    }
                }
            }
        case .hairColor:
            VStack(spacing: 10) {
                if draft.gender.hairStyles[safe: draft.hairStyle] == "Bald" {
                    Text("Bald looks have no hair to color. Your pick is kept if you change styles.")
                        .font(.caption2).multilineTextAlignment(.center).opacity(0.75)
                }
                Text("Natural").font(.caption.bold())
                swatchRow(FarmerLook.hairColors.filter { !$0.isFantasy }.map { SwatchItem($0, fallback: RGB(0x1E1A1C)) },
                          selected: draft.hairColor) { id in update { $0.hairColor = id } }
                Text("Fantasy").font(.caption.bold())
                swatchRow(FarmerLook.hairColors.filter(\.isFantasy).map { SwatchItem($0, fallback: RGB(0x1E1A1C)) },
                          selected: draft.hairColor) { id in update { $0.hairColor = id } }
            }
        case .eyes:
            swatchRow(FarmerLook.eyeColors.map { SwatchItem($0, fallback: RGB(0x6B4430)) },
                      selected: draft.eyeColor) { id in update { $0.eyeColor = id } }
        case .outfit:
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 150), spacing: 8)], spacing: 8) {
                ForEach(Outfit.all.filter { meadow.outfits.contains($0.id) && $0.fits(draft.gender) }) { outfit in
                    let drawn = draft.canWear(outfit)
                    Button {
                        update { $0.outfit = outfit.id }
                    } label: {
                        HStack(spacing: 8) {
                            Text(outfit.emoji).font(.title3)
                            VStack(alignment: .leading, spacing: 3) {
                                Text(outfit.name).font(.caption.bold()).lineLimit(1)
                                if !drawn {
                                    Text("Not drawn for this hair yet").font(.caption2).lineLimit(1)
                                }
                                HStack(spacing: 3) {
                                    ForEach(Array(outfitDots(outfit).enumerated()), id: \.offset) { _, color in
                                        Circle().fill(Color(color)).frame(width: 10, height: 10)
                                            .overlay(Circle().strokeBorder(Palette.ink.opacity(0.25), lineWidth: 1))
                                    }
                                }
                            }
                            Spacer(minLength: 0)
                        }
                        .padding(10)
                        .pixelPanel(draft.outfit == outfit.id ? Palette.pinkCard : Palette.periwinkle,
                                    edge: draft.outfit == outfit.id ? Palette.rose : Palette.periwinkleEdge, cornerRadius: 14)
                    }
                    .buttonStyle(SquishButtonStyle())
                    .disabled(!drawn)
                    .opacity(drawn ? 1 : 0.5)
                    .accessibilityAddTraits(draft.outfit == outfit.id ? .isSelected : [])
                }
            }
            Text("More outfits unlock through stories and achievements.")
                .font(.caption2)
                .opacity(0.7)
                .padding(.top, 4)
        }
    }

    private func update(_ change: (inout FarmerLook) -> Void) {
        withAnimation(.snappy) { change(&meadow.farmerDraft) }
    }

    private func faceTile(_ look: FarmerLook, title: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if let face = FarmerRenderer.image(.face, look: look) {
                    Image(uiImage: face)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 68, height: 68)
                        .background(Palette.lilacCard)
                        .clipShape(.circle)
                }
                Text(title).font(.caption.bold())
            }
            .padding(10)
            .frame(width: 112)
            .pixelPanel(isSelected ? Palette.pinkCard : Palette.lilacCard,
                        edge: isSelected ? Palette.rose : Palette.lilacEdge, cornerRadius: 16)
        }
        .buttonStyle(SquishButtonStyle())
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private struct SwatchItem: Identifiable {
        let id: String
        let name: String
        let color: RGB

        init(id: String, name: String, color: RGB) {
            self.id = id
            self.name = name
            self.color = color
        }

        /// `fallback` is shown for "keep the art's color" choices.
        init(_ swatch: LookSwatch, fallback: RGB) {
            self.init(id: swatch.id, name: swatch.name, color: swatch.rgb ?? fallback)
        }
    }

    private func swatchRow(_ items: [SwatchItem], selected: String,
                           pick: @escaping (String) -> Void) -> some View {
        HStack(spacing: 10) {
            ForEach(items) { item in
                Button {
                    pick(item.id)
                } label: {
                    VStack(spacing: 3) {
                        Circle()
                            .fill(Color(item.color))
                            .frame(width: 40, height: 40)
                            .overlay(Circle().strokeBorder(.white, lineWidth: 3))
                            .overlay(Circle().strokeBorder(selected == item.id ? Palette.rose : .clear, lineWidth: 3).padding(-4))
                        Text(item.name).font(.caption2.bold()).lineLimit(1)
                    }
                    .frame(width: 58)
                }
                .buttonStyle(SquishButtonStyle())
                .accessibilityLabel(item.name)
                .accessibilityAddTraits(selected == item.id ? .isSelected : [])
            }
        }
    }

    /// Swatches for an outfit's jacket, top, and pants.
    private func outfitDots(_ outfit: Outfit) -> [RGB] {
        guard outfit.cut == .jacket else { return [outfit.main, outfit.accent] }
        return [outfit.colors.jacket ?? RGB(0x2E2A2C), outfit.colors.top ?? RGB(0xFFFFFF), outfit.colors.pants ?? RGB(0x3E5F9C)]
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
