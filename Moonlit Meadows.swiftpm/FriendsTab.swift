import SwiftUI

/// Everyone you can befriend: the five main characters, then the villagers.
struct FriendsTab: View {
    let meadow: Meadow

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(Person.main) { person in
                    row(person)
                }
                SectionTitle(text: "Villagers")
                    .padding(.top, 6)
                ForEach(Person.villagers) { person in
                    row(person)
                }
            }
        }
        .scrollIndicators(.hidden)
    }

    private func row(_ person: Person) -> some View {
        Button {
            meadow.openProfile(person.id)
        } label: {
            FriendRow(meadow: meadow, person: person)
        }
        .buttonStyle(SquishButtonStyle())
    }
}

private struct FriendRow: View {
    let meadow: Meadow
    let person: Person

    var body: some View {
        let state = meadow.relationship(person.id)
        let newChapters = meadow.unseenEvents(for: person.id).count
        CozyCard {
            HStack(spacing: 10) {
                PersonPortrait(look: person.look(onDay: meadow.today), artID: person.id, size: 56, isBlushing: state.path == .romance)
                    .frame(width: 56, height: 60)
                    .background(Palette.blush, in: .rect(cornerRadius: 16))
                VStack(alignment: .leading, spacing: 3) {
                    HStack(spacing: 6) {
                        Text(person.name).font(.headline)
                        Text(person.pronouns).font(.caption2).opacity(0.6)
                        if state.path == .romance { Text("💕") }
                        if state.path == .friendship { Text("🤝") }
                    }
                    Text("\(meadow.stageTitle(of: person.id)) · \(meadow.whereaboutsText(of: person))")
                        .font(.caption)
                        .opacity(0.75)
                        .lineLimit(1)
                    ProgressView(value: meadow.stageProgress(of: person.id))
                        .tint(Palette.rose)
                }
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 4) {
                    if newChapters > 0 { CozyTag(text: "💌 New chapter", color: Palette.petal) }
                    if meadow.canTalk(to: person.id) { CozyTag(text: "💬 Say hi", color: Palette.mint) }
                }
            }
        }
        .foregroundStyle(Palette.cocoa)
    }
}

// MARK: - Profile (top screen)

/// Top screen while a profile is open: the character's big portrait, your relationship,
/// what they just said, and everything about them.
struct PersonProfileScene: View {
    let meadow: Meadow
    let person: Person

    var body: some View {
        let state = meadow.relationship(person.id)
        let look = person.look(onDay: meadow.today)

        if let talk = meadow.profileTalk {
            // Chatting: their chat scene, with what they said.
            ChatScene(meadow: meadow, speaker: .person(person), name: person.name, text: chatText(talk),
                      voiceHint: meadow.relationship(person.id).path == .romance ? "ROMANCE" : "BESTIE")
        } else {
            profile(state: state, look: look)
        }
    }

    private func chatText(_ talk: TalkResult) -> String {
        if let answer = meadow.profileAnswer { return answer }
        if let question = talk.question { return "\(talk.line)\n\n\(question.prompt)" }
        return talk.line
    }

    private func profile(state: RelationshipState, look: PersonLook) -> some View {
        ZStack {
            DialogBackdrop(isRomantic: state.path == .romance)
            GeometryReader { proxy in
                HStack(alignment: .bottom, spacing: 12) {
                    if let art = PersonArt.image(for: person.id) {
                        Image(uiImage: art)
                            .resizable()
                            .scaledToFit()
                            .frame(height: proxy.size.height * 0.95)
                            .frame(maxWidth: proxy.size.width * 0.3)
                            .accessibilityHidden(true)
                    }
                    // Everything up here fits without scrolling; the long reads live in the
                    // About tab on the bottom screen.
                    VStack(spacing: 8) {
                        card {
                            Text(person.personality)
                                .font(.callout)
                                .lineLimit(3)
                                .minimumScaleFactor(0.8)
                            HStack(spacing: 4) {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundStyle(Palette.rose)
                                Text("Now: \(meadow.whereaboutsText(of: person))")
                            }
                            .font(.caption.bold())
                            .opacity(0.8)
                        }
                        favorites
                    }
                    .padding(.vertical, 10)
                    .frame(maxHeight: .infinity, alignment: .top)
                }
                .padding(.horizontal, 14)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .foregroundStyle(Palette.ink)
        .fontDesign(.rounded)
    }

    private func card<Content: View>(_ fill: Color = Palette.cream.opacity(0.94), edge: Color = Palette.lilacEdge,
                                     @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) { content() }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pixelPanel(fill, edge: edge, cornerRadius: 16)
    }

    private var favorites: some View {
        let revealed = meadow.revealedFavorites(of: person.id)
        let lovesRevealed = meadow.stage(of: person.id) >= .friend

        return card {
            SectionTitle(text: "Favorites")
            HStack(spacing: 10) {
                ForEach(person.favoriteBreeds, id: \.self) { id in
                    if let breed = Breed.find(id) {
                        let isRevealed = revealed.contains(id)
                        VStack(spacing: 2) {
                            BreedBunnyView(breed: breed, size: 40, isSilhouette: !isRevealed || !meadow.isDiscovered(breed))
                                .frame(height: 44)
                            Text(isRevealed ? breed.name : "???").font(.caption2.bold())
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            HStack(spacing: 4) {
                Text("Loves:").font(.caption.bold())
                if lovesRevealed {
                    ForEach(person.lovedGifts, id: \.self) { ItemIcon(itemID: $0, size: 18) }
                } else {
                    Text("Become Friends to find out").font(.caption).opacity(0.6)
                }
            }
        }
    }
}

// MARK: - Profile info (bottom screen)

/// The bottom screen while a profile is open shows ONLY their info card —
/// name, role, stage and hearts. No buttons: chatting, gifts and everything
/// else happen out in the world (Michelle's Friends = info-only rule).
struct PersonInfoCard: View {
    let meadow: Meadow
    let person: Person

    var body: some View {
        let state = meadow.relationship(person.id)
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(person.fullName).font(.title3.bold())
                if state.path == .romance {
                    Image(systemName: "heart.fill").foregroundStyle(Palette.rose)
                }
                if state.path == .friendship {
                    Image(systemName: "person.2.fill").foregroundStyle(Palette.periwinkle)
                }
                Spacer()
                if person.isVillager { CozyTag(text: "Villager", color: Palette.periwinkle) }
            }
            Text("\(person.gender) · \(person.pronouns) · \(person.role)").font(.caption).opacity(0.8)
            HStack {
                Text(meadow.stageTitle(of: person.id)).font(.subheadline.bold())
                Spacer()
                Text("Stage \(meadow.stage(of: person.id).rawValue)/\(person.maxStage.rawValue)").font(.caption).opacity(0.7)
            }
            ProgressView(value: meadow.stageProgress(of: person.id)).tint(Palette.rose)
            WarmthHearts(meadow: meadow, personID: person.id)
            if meadow.isAwaitingCrossroads(person.id) {
                HStack(spacing: 4) {
                    Image(systemName: "envelope.fill").foregroundStyle(Palette.rose)
                    Text("Your relationship is at a crossroads. Read their next chapter to choose your path.")
                }
                .font(.caption)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .pixelPanel(Palette.lilacCard, edge: Palette.lilacEdge, cornerRadius: 16)
        .foregroundStyle(Palette.ink)
        .fontDesign(.rounded)
    }
}

// MARK: - Profile actions (retired from the profile; kept for reference)

/// Bottom screen while a profile is open: every button, sorted into tappable sections,
/// like the farm deck.
struct PersonActionsPanel: View {
    let meadow: Meadow
    let person: Person
    @State private var section = ProfileSection.gifts
    @State private var giftKind = GiftKind.items
    @State private var confirming: BunnyInstance?

    enum ProfileSection: String, CaseIterable, Identifiable {
        case gifts, together, story, requests, about

        var id: String { rawValue }

        var title: String {
            switch self {
            case .gifts: return "Gifts"
            case .together: return "Together"
            case .story: return "Story"
            case .requests: return "Requests"
            case .about: return "About"
            }
        }

        var emoji: String {
            switch self {
            case .gifts: return "🎁"
            case .together: return "🌼"
            case .story: return "💌"
            case .requests: return "📜"
            case .about: return "📖"
            }
        }
    }

    enum GiftKind: String, CaseIterable {
        case items = "Items"
        case bunnies = "Bunnies"
    }

    var body: some View {
        VStack(spacing: 10) {
            ScrollView(.horizontal) {
                HStack(spacing: 6) {
                    Button {
                        meadow.closeProfile()
                    } label: {
                        VStack(spacing: 2) {
                            Text("◂").font(.title3.bold())
                            Text("Friends").font(.caption.bold())
                        }
                        .frame(width: 66, height: 54)
                        .pixelPanel(Palette.periwinkle, edge: Palette.periwinkleEdge, cornerRadius: 14)
                    }
                    .buttonStyle(SquishButtonStyle())
                    .accessibilityLabel("Back to Friends")

                    ForEach(ProfileSection.allCases) { item in
                        Button {
                            withAnimation(.snappy) { section = item }
                        } label: {
                            VStack(spacing: 2) {
                                Text(item.emoji).font(.title3)
                                Text(item.title).font(.caption.bold())
                            }
                            .frame(width: 72, height: 54)
                            .pixelPanel(section == item ? Palette.pinkCard : Palette.lilacCard,
                                        edge: section == item ? Palette.rose : Palette.lilacEdge, cornerRadius: 14)
                            .overlay(alignment: .topTrailing) {
                                if hasBadge(item) {
                                    Circle().fill(Palette.rose).frame(width: 10, height: 10).padding(5)
                                }
                            }
                        }
                        .buttonStyle(SquishButtonStyle())
                        .accessibilityAddTraits(section == item ? .isSelected : [])
                    }
                }
                .padding(4)
            }
            .scrollIndicators(.hidden)

            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    switch section {
                    case .gifts: gifts
                    case .together: together
                    case .story: story
                    case .requests: requests
                    case .about:
                        about(look: person.look(onDay: meadow.today))
                        memories(state: meadow.relationship(person.id))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }
            .scrollIndicators(.hidden)
        }
        .foregroundStyle(Palette.ink)
        .fontDesign(.rounded)
        .onChange(of: section) { _, newSection in
            if newSection == .requests {
                meadow.moment("firstRequest", "📜 Requests are little jobs from villagers — bring what they ask for and you'll grow closer.")
            }
        }
        .onAppear {
            // Opened with the deck's Gift button: start on the gifts.
            if meadow.profileOpensGifts {
                section = .gifts
                meadow.profileOpensGifts = false
            }
        }
        .confirmationDialog(
            "Give \(confirming?.name ?? "this bunny") to \(person.name)?",
            isPresented: Binding(get: { confirming != nil }, set: { if !$0 { confirming = nil } }),
            titleVisibility: .visible
        ) {
            Button("Give 🎁") {
                if let bunny = confirming {
                    meadow.giveBunny(bunny.id, to: person.id)
                }
                confirming = nil
            }
            Button("Keep them", role: .cancel) {
                confirming = nil
            }
        } message: {
            Text("They'll live with \(person.name) from now on. This can't be undone.")
        }
    }

    private func hasBadge(_ item: ProfileSection) -> Bool {
        switch item {
        case .story: return !meadow.unseenEvents(for: person.id).isEmpty
        case .requests: return meadow.availableQuests.contains { $0.personID == person.id && meadow.canComplete($0) }
        default: return false
        }
    }

    /// A big pixel-bordered button, like the farm's Harvest & Grow buttons.
    private func bigButton(_ label: String, isEnabled: Bool = true, pink: Bool = true, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.subheadline.bold())
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .padding(.horizontal, 8)
                .pixelPanel(pink ? Palette.pinkCard : Palette.periwinkle, edge: pink ? Palette.pinkEdge : Palette.periwinkleEdge,
                            cornerRadius: 16)
        }
        .buttonStyle(SquishButtonStyle())
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }

    // MARK: Gifts

    @ViewBuilder
    private var gifts: some View {
        HStack(spacing: 8) {
            ForEach(GiftKind.allCases, id: \.self) { kind in
                Button {
                    withAnimation(.snappy) { giftKind = kind }
                } label: {
                    Text(kind == .items ? "🎁 Items" : "🐰 Bunnies")
                        .font(.caption.bold())
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .pixelPanel(giftKind == kind ? Palette.pinkCard : Palette.periwinkle,
                                    edge: giftKind == kind ? Palette.rose : Palette.periwinkleEdge, cornerRadius: 12)
                }
                .buttonStyle(SquishButtonStyle())
            }
        }
        switch giftKind {
        case .items: itemGifts
        case .bunnies: bunnyGifts
        }
    }

    @ViewBuilder
    private var itemGifts: some View {
        let items = ItemInfo.allIDs.filter { meadow.count(of: $0) > 0 }
        let lovesRevealed = meadow.stage(of: person.id) >= .friend
        let canGive = meadow.canGiveItem(to: person.id)
        Text(canGive ? "Tap an item to give it. One item gift a day." : "You've given \(person.name) an item today ✓")
            .font(.caption).opacity(0.7)
        if items.isEmpty {
            Text("Your basket is empty — harvest something first. 🥕").font(.callout)
        }
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 8)], spacing: 8) {
            ForEach(items, id: \.self) { id in
                let loved = lovesRevealed && meadow.reaction(to: id, from: person) == .loved
                Button {
                    meadow.giveItem(id, to: person.id)
                } label: {
                    VStack(spacing: 2) {
                        ItemIcon(itemID: id, size: 28)
                        Text(ItemInfo.name(id)).font(.caption2.bold()).lineLimit(1)
                        Text("×\(meadow.count(of: id))").font(.caption2).opacity(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 78)
                    .pixelPanel(loved ? Palette.pinkCard : Palette.periwinkle, edge: loved ? Palette.pinkEdge : Palette.periwinkleEdge,
                                cornerRadius: 14)
                    .overlay(alignment: .topTrailing) {
                        if loved { Text("💖").font(.caption2).padding(4) }
                    }
                }
                .buttonStyle(SquishButtonStyle())
                .disabled(!canGive)
                .opacity(canGive ? 1 : 0.5)
            }
        }
    }

    @ViewBuilder
    private var bunnyGifts: some View {
        let revealed = meadow.revealedFavorites(of: person.id)
        let canGive = meadow.canGiveBunny(to: person.id)
        Text(canGive ? "A bunny moves in with \(person.name) and leaves your habitat. Your collection book keeps the breed."
                     : "You've given \(person.name) a bunny today ✓")
            .font(.caption).opacity(0.7)
        if meadow.bunnies.isEmpty {
            Text("You don't have any bunnies to give yet.").font(.callout)
        }
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 86), spacing: 8)], spacing: 8) {
            ForEach(meadow.bunnies) { bunny in
                if let breed = Breed.find(bunny.breedID) {
                    let favorite = revealed.contains(breed.id)
                    Button {
                        confirming = bunny
                    } label: {
                        VStack(spacing: 2) {
                            BreedBunnyView(breed: breed, size: 38).frame(height: 40)
                            Text(bunny.name).font(.caption2.bold()).lineLimit(1)
                            Text(breed.name).font(.caption2).opacity(0.7).lineLimit(1)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 86)
                        .pixelPanel(favorite ? Palette.pinkCard : Palette.lilacCard, edge: favorite ? Palette.pinkEdge : Palette.lilacEdge,
                                    cornerRadius: 14)
                        .overlay(alignment: .topTrailing) {
                            if favorite { Text("💖").font(.caption2).padding(4) }
                        }
                    }
                    .buttonStyle(SquishButtonStyle())
                    .disabled(!canGive)
                    .opacity(canGive ? 1 : 0.5)
                }
            }
        }
    }

    // MARK: Together

    @ViewBuilder
    private var together: some View {
        let dating = meadow.isDating(person.id)
        Text(dating ? "💕 Go on a date" : "🌼 Spend time together").font(.subheadline.bold())
        if meadow.stage(of: person.id) < .friend {
            Text("Become Friends to spend time together.").font(.caption).opacity(0.7)
        } else {
            let canDo = meadow.canDoActivity(with: person.id)
            ForEach(Array(person.activities.enumerated()), id: \.offset) { index, activity in
                bigButton("\(activity.emoji) \(activity.name)", isEnabled: canDo, pink: dating) {
                    meadow.doActivity(index, with: person.id)
                }
            }
            if !canDo {
                Text("You've spent time together today. See you tomorrow! 💕").font(.caption).opacity(0.7)
            }
        }
    }

    // MARK: Story

    @ViewBuilder
    private var story: some View {
        let unseen = meadow.unseenEvents(for: person.id)
        let seen = meadow.seenEvents(for: person.id)
        let state = meadow.relationship(person.id)
        if unseen.isEmpty {
            Text("No new chapters yet. Grow closer to unlock the next one. 🌱").font(.caption).opacity(0.7)
        }
        ForEach(unseen) { event in
            bigButton("💌 Read: \(event.title)") {
                meadow.play(event)
            }
        }
        if meadow.canChangePath(for: person.id) {
            bigButton(state.path == .romance ? "🤝 Just be friends" : "💕 Confess your feelings", pink: state.path != .romance) {
                meadow.setPath(state.path == .romance ? .friendship : .romance, for: person.id)
            }
        }
        if !seen.isEmpty {
            Text("Replay a chapter").font(.caption.bold()).padding(.top, 4)
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 140), spacing: 8)], spacing: 8) {
                ForEach(seen) { event in
                    bigButton(event.title, pink: false) {
                        meadow.play(event)
                    }
                }
            }
        }
    }

    private func about(look: PersonLook) -> some View {
        aboutCard {
            SectionTitle(text: "About \(person.name)")
            Text(person.personality).font(.callout)
            Text(person.backstory).font(.callout).opacity(0.85)
            Text("Loves: \(person.interests)").font(.caption).opacity(0.8)
            if !look.styleNote.isEmpty {
                Text("Today's look: \(look.styleNote)").font(.caption).opacity(0.8)
            }
            Text("Daily schedule").font(.subheadline.bold()).padding(.top, 4)
            ForEach(person.schedule, id: \.time) { slot in
                HStack {
                    Text("\(slot.time.emoji) \(slot.time.name)").font(.caption.bold()).frame(width: 90, alignment: .leading)
                    Text("\(slot.emoji) \(slot.place)").font(.caption)
                    switch meadow.whereabouts(of: person.id, at: slot.time) {
                    case .farm: CozyTag(text: "On your farm")
                    case .town: CozyTag(text: "In the village")
                    case .home: CozyTag(text: "At home")
                    case .errand: EmptyView()
                    }
                }
            }
        }
    }

    private func memories(state: RelationshipState) -> some View {
        aboutCard(Palette.pinkCard.opacity(0.9), edge: Palette.pinkEdge) {
            SectionTitle(text: "Memories")
            if state.memories.isEmpty {
                Text("Your story with \(person.name) is just beginning. 🌱").font(.caption)
            }
            ForEach(Array(state.memories.reversed().prefix(12).enumerated()), id: \.offset) { _, memory in
                HStack(alignment: .top) {
                    Text("•")
                    Text(memory.text).font(.caption)
                    Spacer()
                    Text(memory.date.formatted(date: .abbreviated, time: .omitted)).font(.caption2).opacity(0.6)
                }
            }
            let bunnyGifts = meadow.gifts.filter { $0.personID == person.id && $0.bunnyID != nil }
            if !bunnyGifts.isEmpty {
                Text("Bunnies living with \(person.name): \(bunnyGifts.compactMap(\.bunnyName).joined(separator: ", "))")
                    .font(.caption.bold())
                    .padding(.top, 4)
            }
        }
    }

    private func aboutCard<Content: View>(_ fill: Color = Palette.cream.opacity(0.9), edge: Color = Palette.lilacEdge,
                                          @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 6) { content() }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .pixelPanel(fill, edge: edge, cornerRadius: 14)
    }

    // MARK: Requests

    @ViewBuilder
    private var requests: some View {
        let quests = meadow.availableQuests.filter { $0.personID == person.id }
        if quests.isEmpty {
            Text("\(person.name) doesn't need anything right now.").font(.caption).opacity(0.7)
        }
        ForEach(quests) { quest in
            QuestRow(meadow: meadow, quest: quest)
                .padding(10)
                .pixelPanel(Palette.cream.opacity(0.9), edge: Palette.lilacEdge, cornerRadius: 14)
        }
    }
}

// MARK: - Quest row (shared with the Journal)

struct QuestRow: View {
    let meadow: Meadow
    let quest: Quest

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(quest.title).font(.subheadline.bold())
                Spacer()
                PriceButton(label: "Deliver", isEnabled: meadow.canComplete(quest)) {
                    meadow.completeQuest(quest.id)
                }
            }
            Text(quest.description).font(.caption).opacity(0.8)
            HStack(spacing: 6) {
                ForEach(quest.items, id: \.itemID) { item in
                    let have = meadow.count(of: item.itemID)
                    HStack(spacing: 2) {
                        ItemIcon(itemID: item.itemID, size: 14)
                        Text("\(min(have, item.count))/\(item.count)")
                    }
                    .font(.caption.bold())
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(have >= item.count ? Palette.mint : Palette.blush, in: .capsule)
                }
            }
            RewardList(rewards: quest.rewards)
            if quest.points > 0 {
                Text("💗 +\(quest.points) relationship").font(.caption2).opacity(0.7)
            }
        }
    }
}

/// A rude answer, picked on purpose: a thorny broken heart and a red border, apart from the kind ones.
private struct RudeAnswerButton: View {
    let text: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text("🥀💔").font(.subheadline)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Rude").font(.caption2.bold()).foregroundStyle(Color(red: 0.75, green: 0.15, blue: 0.2))
                    Text(text).font(.subheadline.bold()).multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Text("−1 ❤️").font(.caption.bold()).foregroundStyle(Color(red: 0.75, green: 0.15, blue: 0.2))
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .pixelPanel(Color(red: 0.98, green: 0.88, blue: 0.88), edge: Color(red: 0.75, green: 0.25, blue: 0.3), cornerRadius: 16)
        }
        .buttonStyle(SquishButtonStyle())
        .padding(.top, 6)
        .accessibilityLabel("Rude answer: \(text). Costs a heart.")
    }
}

/// Ten hearts for how they feel about you right now, with Strained / Distant when they're low.
/// A lost heart cracks with a red −1.
struct WarmthHearts: View {
    let meadow: Meadow
    let personID: String
    @State private var crack: HeartChange?
    @State private var shown = false

    var body: some View {
        let hearts = meadow.warmth(of: personID)
        let level = meadow.warmthLevel(of: personID)
        HStack(spacing: 2) {
            ForEach(0..<Meadow.maxWarmth, id: \.self) { index in
                Image(systemName: index < hearts ? "heart.fill" : "heart")
                    .font(.system(size: 11))
                    .foregroundStyle(index < hearts ? Palette.rose : Color.gray.opacity(0.45))
            }
            if level != .warm {
                Text(level.title)
                    .font(.caption2.bold())
                    .padding(.horizontal, 6).padding(.vertical, 1)
                    .background(level == .distant ? Color(red: 0.85, green: 0.3, blue: 0.35).opacity(0.25) : Palette.butter, in: .capsule)
            }
            Spacer(minLength: 0)
        }
        .overlay(alignment: .trailing) {
            if let crack, crack.personID == personID {
                HeartPop(amount: crack.amount, shown: shown)
            }
        }
        .onChange(of: meadow.heartChange) { _, change in
            guard let change, change.personID == personID else { return }
            crack = change
            shown = false
            withAnimation(.easeOut(duration: 1.2)) { shown = true }
            Task {
                try? await Task.sleep(for: .seconds(1.3))
                if crack == change { crack = nil }
            }
        }
        .accessibilityLabel("\(hearts) of \(Meadow.maxWarmth) hearts\(level == .warm ? "" : ", \(level.title)")")
    }
}

/// A heart that cracks in two (lost) or swells (gained), with the number rising off it.
struct HeartPop: View {
    let amount: Int
    let shown: Bool

    var body: some View {
        let lost = amount < 0
        ZStack {
            if lost {
                HStack(spacing: shown ? 6 : 0) {
                    Text("❤️").mask(Rectangle().offset(x: -6)).rotationEffect(.degrees(shown ? -18 : 0))
                    Text("❤️").mask(Rectangle().offset(x: 6)).rotationEffect(.degrees(shown ? 18 : 0))
                }
                .font(.system(size: 22))
                .overlay { Text("💔").font(.system(size: 22)).opacity(shown ? 0 : 1) }
            } else {
                Text("💖").font(.system(size: 22)).scaleEffect(shown ? 1.3 : 0.8)
            }
            Text(lost ? "\(amount)" : "+\(amount)")
                .font(.headline.weight(.heavy))
                .foregroundStyle(lost ? Color(red: 0.85, green: 0.15, blue: 0.2) : Palette.rose)
                .shadow(color: .white, radius: 0, x: 1, y: 1)
                .offset(x: 22, y: shown ? -22 : 0)
        }
        .opacity(shown ? 0 : 1)
        .animation(.easeOut(duration: 1.2), value: shown)
        .allowsHitTesting(false)
    }
}
