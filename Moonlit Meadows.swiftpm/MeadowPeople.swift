import Foundation

/// A short scene with a character: a gift reaction, an activity, or a date.
struct Moment: Identifiable {
    let id = UUID()
    let personID: String
    let title: String
    let text: String
    /// A date scene video to play with it.
    var video: String? = nil
}

/// Something to show full-screen: a story chapter, a moment, or the collection finale.
enum ScenePresentation: Identifiable {
    case story(StoryEvent)
    case moment(Moment)
    case completion

    var id: String {
        switch self {
        case .story(let event): return event.id
        case .moment(let moment): return moment.id.uuidString
        case .completion: return "completion"
        }
    }
}

enum GiftResult: Equatable {
    case given(GiftRecord.Reaction, points: Int)
    case alreadyGiftedToday
    case notAvailable
}

/// Someone's hearts went up or down, for the on-screen pop.
struct HeartChange: Identifiable, Equatable {
    let id = UUID()
    let personID: String
    let amount: Int
}

/// How someone feels about you right now. Strained and Distant sit below Friend on the meter:
/// at Distant they talk like strangers and pause activities and requests, but nothing is lost.
enum Warmth: Equatable {
    case warm, strained, distant

    var title: String {
        switch self {
        case .warm: return ""
        case .strained: return "Strained"
        case .distant: return "Distant"
        }
    }
}

struct TalkResult {
    let line: String
    let points: Int
    let question: Question?
}

extension Meadow {
    // MARK: Points and stages

    func relationship(_ personID: String) -> RelationshipState {
        relationships[personID] ?? RelationshipState()
    }

    /// The stage reached. Before the crossroads chapter, it stays at Close Friend.
    func stage(of personID: String) -> RelationshipStage {
        let state = relationship(personID)
        var stage = RelationshipStage.allCases.last { state.points >= $0.threshold } ?? .stranger
        if state.path == .undecided && stage > .closeFriend {
            stage = .closeFriend
        }
        if let person = Person.find(personID), stage > person.maxStage {
            stage = person.maxStage
        }
        return stage
    }

    func stageTitle(of personID: String) -> String {
        stage(of: personID).title(path: relationship(personID).path)
    }

    /// Progress within the current stage, for the relationship meter.
    func stageProgress(of personID: String) -> Double {
        let state = relationship(personID)
        let current = stage(of: personID)
        if let person = Person.find(personID), current >= person.maxStage { return 1 }
        guard let next = RelationshipStage(rawValue: current.rawValue + 1) else { return 1 }
        let span = Double(next.threshold - current.threshold)
        return min(max(Double(state.points - current.threshold) / span, 0), 1)
    }

    /// Whether the next stage is waiting on the crossroads chapter.
    func isAwaitingCrossroads(_ personID: String) -> Bool {
        let state = relationship(personID)
        guard Person.find(personID)?.isVillager != true else { return false }
        return state.path == .undecided && state.points >= RelationshipStage.romanticInterest.threshold
    }

    var bestStage: Int {
        Person.all.map { stage(of: $0.id).rawValue }.max() ?? 1
    }

    func addPoints(_ amount: Int, to personID: String) {
        guard amount > 0, let person = Person.find(personID) else { return }
        // Theo, before the Reveal: guilt slows his friendship gains to 60% (story bible §5).
        let gained = personID == "theo" && !revealDone ? max(1, Int((Double(amount) * 0.6).rounded())) : amount
        let before = stage(of: personID)
        var state = relationship(personID)
        // Villagers top out at Close Friend, so their meter fills there and stops.
        let cap = person.isVillager ? RelationshipStage.romanticInterest.threshold : RelationshipStage.committed.maxPoints
        // Sibling rule (Michelle, 2026-10-30): while one Okafor-Bell sibling
        // is being romanced, the other stalls below the crossroads — you
        // can't quietly romance them both.
        var effectiveCap = cap
        if personID == "imani" || personID == "silas" {
            let siblingID = personID == "imani" ? "silas" : "imani"
            if relationship(siblingID).path == .romance, stage(of: siblingID) >= .romanticInterest {
                effectiveCap = min(effectiveCap, RelationshipStage.romanticInterest.threshold - 1)
            }
        }
        state.points = min(state.points + gained, effectiveCap)
        relationships[personID] = state
        let after = stage(of: personID)
        if after > before {
            revealFavorites(for: personID)
            let title = after.title(path: state.path)
            spawn(.heart, "💗 \(person.name): \(title)!", at: Spot(x: 0.5, y: 0.45))
            showToast("You and \(person.name) are now \(title). A new chapter may be waiting 💌")
        }
        if personID == "theo" { storyNoteTheoStage() }
    }

    // MARK: Hearts (warmth)

    static let startingWarmth = 0
    static let maxWarmth = 10

    func warmth(of personID: String) -> Int {
        relationship(personID).warmth ?? Self.startingWarmth
    }

    func warmthLevel(of personID: String) -> Warmth {
        switch warmth(of: personID) {
        case ...(-4): return .distant
        case -3...(-2): return .strained
        default: return .warm
        }
    }

    func isDistant(_ personID: String) -> Bool { warmthLevel(of: personID) == .distant }

    /// Moves their hearts up or down, with the heart pop.
    func changeWarmth(_ amount: Int, for personID: String) {
        guard amount != 0, let person = Person.find(personID) else { return }
        var state = relationship(personID)
        let before = state.warmth ?? Self.startingWarmth
        let after = min(max(before + amount, -6), Self.maxWarmth)
        guard after != before else { return }
        state.warmth = after
        relationships[personID] = state
        heartChange = HeartChange(personID: personID, amount: after - before)
        if amount < 0 {
            spawn(.crack, "💔 \(after - before)", at: Spot(x: 0.5, y: 0.5))
            let level = warmthLevel(of: personID)
            if level != .warm { showToast("\(person.name) feels \(level.title.lowercased()). An apology or a gift they like will help.") }
        } else {
            spawn(.heart, "❤️ +\(after - before)", at: Spot(x: 0.5, y: 0.5))
        }
    }

    func canApologize(to personID: String) -> Bool {
        warmth(of: personID) < Self.maxWarmth && relationship(personID).lastApologyDay != today
    }

    /// Once a day at their home: say sorry for a heart back.
    func apologize(to personID: String) {
        guard canApologize(to: personID) else { return }
        var state = relationship(personID)
        state.lastApologyDay = today
        relationships[personID] = state
        changeWarmth(1, for: personID)
        feedbackCount += 1
        save()
    }

    // MARK: Favorite breeds

    /// Favorite breeds are revealed one at a time as you get closer (or by showing them one).
    func revealedFavorites(of personID: String) -> [String] {
        guard let person = Person.find(personID) else { return [] }
        let state = relationship(personID)
        let byStage: Int
        switch stage(of: personID) {
        case .stranger: byStage = 0
        case .acquaintance: byStage = 1
        case .friend: byStage = 2
        default: byStage = 3
        }
        return person.favoriteBreeds.enumerated()
            .filter { $0.offset < byStage || state.revealedFavorites.contains($0.element) }
            .map(\.element)
    }

    private func revealFavorites(for personID: String) {
        var state = relationship(personID)
        for id in revealedFavorites(of: personID) where !state.revealedFavorites.contains(id) {
            state.revealedFavorites.append(id)
        }
        relationships[personID] = state
    }

    private func revealFavorite(_ breedID: String, for personID: String) {
        var state = relationship(personID)
        if !state.revealedFavorites.contains(breedID) {
            state.revealedFavorites.append(breedID)
        }
        relationships[personID] = state
    }

    func remember(_ text: String, with personID: String) {
        var state = relationship(personID)
        state.memories.append(Memory(text: text, date: now))
        relationships[personID] = state
    }

    // MARK: Talking

    func canTalk(to personID: String) -> Bool {
        // Theo won't talk on stormy days before the Reveal (story bible §5).
        if personID == "theo", !revealDone, weather == .rainy { return false }
        return relationship(personID).lastTalkDay != today
    }

    /// Today's line for the stage and path you're on.
    func dailyLine(for person: Person) -> String {
        // Theo and storms: closed off before the Reveal; some of his warmest
        // lines after it (story bible §5).
        if person.id == "theo", weather == .rainy {
            let lines = revealDone
                ? ["Rain on the observatory roof. It used to mean that night. Now it just means tea — if you're staying.",
                   "Storm's coming in. I'll walk you home after. Old habit. A good one, though."]
                : ["…Not today.",
                   "Stay off the dock when it storms. …Just do it."]
            return lines[((today % lines.count) + lines.count) % lines.count]
        }
        let state = relationship(person.id)
        let lines: [String]
        // Distant: they talk to you like a stranger again, until things are mended.
        if isDistant(person.id) {
            return person.lines.early[((today % person.lines.early.count) + person.lines.early.count) % person.lines.early.count]
        }
        switch stage(of: person.id) {
        case .stranger, .acquaintance: lines = person.lines.early
        case .friend, .closeFriend: lines = person.lines.friend
        default: lines = state.path == .romance ? person.lines.romance : person.lines.bestie
        }
        return lines[((today % lines.count) + lines.count) % lines.count]
    }

    /// Chat once a day for a little friendship. Every other day they may ask you a question.
    @discardableResult
    func talk(to personID: String) -> TalkResult? {
        guard let person = Person.find(personID) else { return nil }
        let line = dailyLine(for: person)
        guard canTalk(to: personID) else {
            return TalkResult(line: line, points: 0, question: nil)
        }
        var state = relationship(personID)
        state.lastTalkDay = today
        relationships[personID] = state
        addPoints(10, to: personID)
        feedbackCount += 1

        // "Something Fishy": Imani's first real conversation sets the quest;
        // bringing her a pond fish completes it. All fish quests are hers
        // (Michelle, 2026-10-30) — they used to be Theo's.
        let earnedPoints = personID == "theo" && !revealDone ? 6 : 10
        if personID == "imani" {
            if fishyPending, let fishID = carriedStacks.first(where: { $0.id.hasPrefix("fish-") })?.id {
                removeItems(fishID, 1)
                fishyPending = false
                fishyDone = true
                addPoints(10, to: personID)
                save()
                moment("somethingFishy", "🎣 Something Fishy — complete! Imani weighed the fish, nodded once, and wrote your name in the pond ledger.")
                return TalkResult(line: "…Clean catch. Quick, too. The pond approves of you. So do I — and I don't say that about visitors.", points: earnedPoints, question: nil)
            }
            if !fishyPending && !fishyDone {
                fishyPending = true
                save()
                moment("somethingFishy", "🎣 New quest — Something Fishy: catch any fish at the Pond and bring it to Imani.")
                return TalkResult(line: line + "\n\n…One thing, since you'll be back — and you will be back. Bring me the first fish you catch here. A keeper likes to know who's fishing her water.", points: earnedPoints, question: nil)
            }
        }

        // Sibling drama (Michelle, 2026-10-30): romancing one Okafor-Bell
        // sibling makes talking to the other one pointed, some days.
        if today % 2 == 0, stage(of: personID) >= .friend {
            if personID == "imani", relationship("silas").path == .romance, stage(of: "silas") >= .romanticInterest {
                return TalkResult(line: "…You've got honey on your sleeve. HIS honey. …Forget it. It's not my business who you fall for. Even when it is my brother. Especially then.", points: earnedPoints, question: nil)
            }
            if personID == "silas", relationship("imani").path == .romance, stage(of: "imani") >= .romanticInterest {
                return TalkResult(line: "One of my bees came home smelling of pond water, love. …Imani's a better catch than anything in that pond. Mind you treat her right. And don't tell her I said 'better catch.' She'd frame it.", points: earnedPoints, question: nil)
            }
        }

        // Village tension (Michelle, 2026-10-30): exes and grudges. Get
        // close to someone a villager has history with, and on some days
        // they say the quiet part out loud. Lines only — no points move,
        // nobody is ever blocked. (Bible §11.)
        if today % 2 == 0, stage(of: personID) >= .friend {
            // Kai & Sol are exes — a year together, ended "amicably".
            if personID == "kai", relationship("sol").path == .romance, stage(of: "sol") >= .romanticInterest {
                return TalkResult(line: "So… you and Sol. Official, huh? …I'm happy for you. I am. I built the stage they play on, did you know that? Every nail. If the atelier roof ever leaks I'll fix it — just don't tell them I said that.", points: earnedPoints, question: nil)
            }
            if personID == "kai", stage(of: "sol") >= .closeFriend {
                return TalkResult(line: "You've been spending a lot of time at Sol's place lately. …Cool. That's cool. They make good tea. If they hum while they work, it means things are going well. Whatever 'things' are. Not my business.", points: earnedPoints, question: nil)
            }
            if personID == "sol", relationship("kai").path == .romance, stage(of: "kai") >= .romanticInterest {
                return TalkResult(line: "Kai waved at me today. A year together, and I get a WAVE — like I'm the postman. …Sorry. That one isn't yours to carry. He hums off-key when he's happy, you know. I keep hearing it when he's near you.", points: earnedPoints, question: nil)
            }
            if personID == "sol", stage(of: "kai") >= .closeFriend {
                return TalkResult(line: "You and Kai have been collaborating a lot. He laughs around you — the real one, not the market-day one. I used to— …never mind. Play something for me instead? Something that isn't a love song.", points: earnedPoints, question: nil)
            }
            // Roz & Rowan are exes — one summer, "ancient history". It isn't.
            if personID == "roz", relationship("rowan").path == .romance, stage(of: "rowan") >= .romanticInterest {
                return TalkResult(line: "You smell like forge smoke. …He's a good man, Rowan. Stubborn as a cold oven. He keeps every note anyone's ever written him, you know — if he ever shows you mine from when I was seventeen, I was DRAMATIC and it doesn't count.", points: earnedPoints, question: nil)
            }
            if personID == "roz", stage(of: "rowan") >= .closeFriend {
                return TalkResult(line: "Rowan asked about you today. ROWAN. Asked. Out loud, in words. …Don't give me that look. It's ancient history. Practically archaeology. Pass the flour.", points: earnedPoints, question: nil)
            }
            if personID == "rowan", relationship("roz").path == .romance, stage(of: "roz") >= .romanticInterest {
                return TalkResult(line: "Roz is good for you. She laughs enough for two people. …She got me to dance once, at the midsummer fair. Whole village saw. She wrote me a note after. I keep it in the box. Don't make it a thing.", points: earnedPoints, question: nil)
            }
            if personID == "rowan", stage(of: "roz") >= .closeFriend {
                return TalkResult(line: "You were at the bakery a long while today. She gives you the good loaf. …She gives most people the good loaf. Most.", points: earnedPoints, question: nil)
            }
            // Theo & Kai just can't stand each other.
            if personID == "theo", relationship("kai").path == .romance, stage(of: "kai") >= .romanticInterest {
                return TalkResult(line: "So it's him. Then don't expect a blessing from me. I hate Kai Nakamura-Hale — his noise, his grin, his need to be adored by every room he walks into. Keep him away from my observatory, and don't ask me to smile about it.", points: earnedPoints, question: nil)
            }
            if personID == "theo", stage(of: "kai") >= .closeFriend {
                return TalkResult(line: "Don't dress it up — I hate Kai. The grin, the racket, the way he turns every room into an audience. If I could go the rest of my life without hearing that laugh again, I'd call it mercy.", points: earnedPoints, question: nil)
            }
            if personID == "kai", relationship("theo").path == .romance, stage(of: "theo") >= .romanticInterest {
                return TalkResult(line: "Wait. You and THEO? Huh. Didn't have that on my chart. Does he smile? Like, with his whole face? …Good for him. Seriously. Don't tell him I said that — he'll get strange about it.", points: earnedPoints, question: nil)
            }
            if personID == "kai", stage(of: "theo") >= .closeFriend {
                return TalkResult(line: "You hang out with Theo a lot, huh? No judgment — somebody has to check he's alive. Guy talks to the moon more than to people. He's not bad. He's just… Theo-shaped.", points: earnedPoints, question: nil)
            }
        }

        let unanswered = person.questions.filter { relationship(personID).choices[$0.id] == nil }
        // The pacing ladder (story bible §5): strangers get small talk only —
        // personal questions start at Acquaintance. Questions used to also
        // wait for an even-numbered day, which made them so rare that chats
        // seemed to never offer options at all (Michelle, 2026-10-30) — and
        // with no questions there were no rude answers, no strained warmth,
        // and the Apologize button never appeared either. The once-each
        // questions and the once-a-day first talk are pacing enough.
        let question = stage(of: personID) >= .acquaintance ? unanswered.first : nil
        moment("firstChat", "💬 That's chatting! The Friends tab keeps track of everyone's hearts and favorites.")
        return TalkResult(line: line, points: earnedPoints, question: question)
    }

    /// Every answer is kind; some just land a little better. Each question is answered once.
    @discardableResult
    func answer(_ questionID: String, option: Int, for personID: String) -> Answer? {
        guard let person = Person.find(personID),
              let question = person.questions.first(where: { $0.id == questionID }),
              question.answers.indices.contains(option),
              relationship(personID).choices[questionID] == nil else { return nil }
        var state = relationship(personID)
        state.choices[questionID] = option
        relationships[personID] = state
        let answer = question.answers[option]
        addPoints(answer.points, to: personID)
        // The kindest answer warms them; a rude one costs a heart.
        if answer.isRude {
            changeWarmth(-1, for: personID)
        } else if answer.points >= (question.answers.filter { !$0.isRude }.map(\.points).max() ?? 0) {
            changeWarmth(1, for: personID)
        }
        save()
        return answer
    }

    // MARK: Item gifts

    func reaction(to itemID: String, from person: Person) -> GiftRecord.Reaction {
        // Theo, before the Reveal: every gift lands flat — except bunny- and
        // moon-things, which crack him from day one (story bible §3/§5).
        if person.id == "theo", !revealDone {
            return itemID.contains("moon") || itemID.contains("bunny") ? .loved : .neutral
        }
        if person.lovedGifts.contains(itemID) { return .loved }
        if person.likedGifts.contains(itemID) { return .liked }
        if person.dislikedGifts.contains(itemID) { return .disliked }
        return .neutral
    }

    func canGiveItem(to personID: String) -> Bool {
        relationship(personID).lastGiftDay != today
    }

    /// One item gift per person per day. Liked and loved gifts warm them; a disliked one costs a heart.
    @discardableResult
    func giveItem(_ itemID: String, to personID: String) -> GiftResult {
        guard let person = Person.find(personID), ItemInfo.exists(itemID), count(of: itemID) > 0 else { return .notAvailable }
        guard canGiveItem(to: personID) else { return .alreadyGiftedToday }
        removeItems(itemID, 1)
        moment("firstGift", "🎁 Gift given! Everyone has favorites — the Friends tab shows what each person loves.")

        let mood = reaction(to: itemID, from: person)
        let points: Int
        let message: String
        switch mood {
        case .loved, .favorite:
            points = 40
            message = person.lovedGiftReaction
        case .liked:
            points = 20
            message = person.likedGiftReaction
        case .neutral:
            points = 8
            message = person.neutralGiftReaction
        case .disliked:
            points = 0
            message = person.dislikedGiftReaction
        }
        var state = relationship(personID)
        state.lastGiftDay = today
        relationships[personID] = state
        gifts.append(GiftRecord(id: UUID(), personID: personID, itemID: itemID, bunnyID: nil, breedID: nil,
                                bunnyName: nil, reaction: mood, date: now))
        addPoints(points, to: personID)
        if mood == .loved {
            remember("Gave \(person.name) \(ItemInfo.emoji(itemID)) \(ItemInfo.name(itemID)) — a favorite!", with: personID)
        }
        showToast("\(person.name): \(message)")
        voiceCue = VoiceCue(owner: personID, text: message)
        if points > 0 { spawn(.heart, mood == .loved ? "💖 +\(points)" : "💗 +\(points)", at: Spot(x: 0.5, y: 0.55)) }
        switch mood {
        case .loved, .favorite: changeWarmth(2, for: personID)
        case .liked: changeWarmth(1, for: personID)
        case .disliked: changeWarmth(-1, for: personID)
        case .neutral: break
        }
        feedbackCount += 1
        save()
        return .given(mood, points: points)
    }

    // MARK: Bunny gifts

    func canGiveBunny(to personID: String) -> Bool {
        relationship(personID).lastBunnyGiftDay != today
    }

    func isFavorite(_ breedID: String, of personID: String) -> Bool {
        Person.find(personID)?.favoriteBreeds.contains(breedID) ?? false
    }

    /// Gives one of your bunnies to a character. The bunny leaves your habitat (it lives with
    /// them now), but its breed stays discovered in your collection book. Each bunny can only
    /// be given once, and each person accepts one bunny a day.
    @discardableResult
    func giveBunny(_ bunnyID: UUID, to personID: String) -> GiftResult {
        guard let person = Person.find(personID),
              let index = bunnies.firstIndex(where: { $0.id == bunnyID }),
              let breed = Breed.find(bunnies[index].breedID) else { return .notAvailable }
        guard canGiveBunny(to: personID) else { return .alreadyGiftedToday }

        let bunny = bunnies.remove(at: index)
        moment("firstGift", "🎁 Gift given! Everyone has favorites — the Friends tab shows what each person loves.")
        let isFavoriteBreed = person.favoriteBreeds.contains(breed.id)
        let reaction: GiftRecord.Reaction = isFavoriteBreed ? .favorite : (breed.rarity >= .rare ? .loved : .liked)
        let points = isFavoriteBreed ? 80 : (breed.rarity >= .rare ? 35 : 20)

        var state = relationship(personID)
        state.lastBunnyGiftDay = today
        relationships[personID] = state
        gifts.append(GiftRecord(id: UUID(), personID: personID, itemID: nil, bunnyID: bunny.id, breedID: breed.id,
                                bunnyName: bunny.name, reaction: reaction, date: now))
        addPoints(points, to: personID)

        let template = isFavoriteBreed ? person.favoriteBunnyReaction : person.bunnyReaction
        let text = template
            .replacingOccurrences(of: "{bunny}", with: bunny.name)
            .replacingOccurrences(of: "{breed}", with: breed.name)
        if isFavoriteBreed {
            favoriteBunnyGifts += 1
            revealFavorite(breed.id, for: personID)
            remember("You gave \(person.name) \(bunny.name), a \(breed.name) — one of their favorites. 💖", with: personID)
            presentedScene = .moment(Moment(personID: personID, title: "A Special Gift", text: text))
        } else {
            remember("You gave \(person.name) \(bunny.name) the \(breed.name).", with: personID)
            showToast("\(bunny.name) now lives with \(person.name). \(text)")
            voiceCue = VoiceCue(owner: personID, text: template)
        }
        spawn(.heart, isFavoriteBreed ? "💖 +\(points)" : "💗 +\(points)", at: Spot(x: 0.5, y: 0.55))
        feedbackCount += 1
        save()
        return .given(reaction, points: points)
    }

    // MARK: Showing breeds

    func canShow(_ breedID: String, to personID: String) -> Bool {
        discovered[breedID] != nil && !relationship(personID).shownBreeds.contains(breedID)
    }

    /// Show each discovered breed to each person once. Showing a favorite reveals it.
    @discardableResult
    func showBreed(_ breedID: String, to personID: String) -> Int {
        guard let person = Person.find(personID), let breed = Breed.find(breedID), canShow(breedID, to: personID) else { return 0 }
        var state = relationship(personID)
        state.shownBreeds.append(breedID)
        relationships[personID] = state
        let isFavoriteBreed = person.favoriteBreeds.contains(breedID)
        let points = isFavoriteBreed ? 15 : 5
        addPoints(points, to: personID)
        if isFavoriteBreed {
            revealFavorite(breedID, for: personID)
            showToast(person.showFavoriteReaction.replacingOccurrences(of: "{breed}", with: breed.name))
            voiceCue = VoiceCue(owner: person.id, text: person.showFavoriteReaction)
        } else {
            showToast("\(person.name) smiles at the \(breed.name). “So cute!”")
        }
        feedbackCount += 1
        return points
    }

    // MARK: Activities and dates

    func isDating(_ personID: String) -> Bool {
        relationship(personID).path == .romance && stage(of: personID) >= .dating
    }

    func canDoActivity(with personID: String) -> Bool {
        stage(of: personID) >= .friend && relationship(personID).lastActivityDay != today && !isDistant(personID)
    }

    /// Spend time together once a day, from Friend onward. When dating, activities become dates.
    @discardableResult
    func doActivity(_ index: Int, with personID: String) -> Moment? {
        guard let person = Person.find(personID), person.activities.indices.contains(index),
              canDoActivity(with: personID) else { return nil }
        let activity = person.activities[index]
        let dating = isDating(personID)
        var state = relationship(personID)
        state.lastActivityDay = today
        let firstDate = dating && !state.hasHadFirstDate
        if dating { state.hasHadFirstDate = true }
        relationships[personID] = state
        addPoints(dating ? 35 : 25, to: personID)
        if firstDate {
            remember("Your first date with \(person.name): \(activity.emoji) \(activity.name).", with: personID)
        }
        var moment = Moment(
            personID: personID,
            title: dating ? "Date: \(activity.emoji) \(activity.name)" : "\(activity.emoji) \(activity.name)",
            text: dating ? activity.dateLine : activity.friendLine
        )
        if dating, let scene = activity.dateScene {
            moment.video = scene
            dateScenesSeen.insert(scene)
        }
        presentedScene = .moment(moment)
        feedbackCount += 1
        save()
        return moment
    }

    // MARK: Date scenes

    /// The date scenes you've seen, to watch again from the Journal.
    var unlockedDateScenes: [(person: Person, activity: SharedActivity)] {
        Person.all.flatMap { person in
            person.activities.compactMap { activity in
                activity.dateScene.flatMap { dateScenesSeen.contains($0) ? (person, activity) : nil }
            }
        }
    }

    func replayDateScene(_ scene: String) {
        guard let (person, activity) = unlockedDateScenes.first(where: { $0.activity.dateScene == scene }) else { return }
        presentedScene = .moment(Moment(personID: person.id, title: "Date: \(activity.emoji) \(activity.name)",
                                        text: activity.dateLine, video: scene))
    }

    // MARK: Story chapters

    func isUnlocked(_ event: StoryEvent) -> Bool {
        let state = relationship(event.personID)
        guard stage(of: event.personID) >= event.stage else { return false }
        // Theo's crossroads chapter stays hidden until the Reveal (story bible
        // §4): his path can't be chosen — either way — until the truth is out.
        if event.personID == "theo", event.isCrossroads, !revealDone { return false }
        switch event.path {
        case .any: return true
        case .romance: return state.path == .romance
        case .friendship: return state.path == .friendship
        }
    }

    func unseenEvents(for personID: String) -> [StoryEvent] {
        let seen = Set(relationship(personID).seenEvents)
        return StoryEvent.events(for: personID).filter { !seen.contains($0.id) && isUnlocked($0) }
    }

    func seenEvents(for personID: String) -> [StoryEvent] {
        let seen = Set(relationship(personID).seenEvents)
        return StoryEvent.events(for: personID).filter { seen.contains($0.id) }
    }

    func play(_ event: StoryEvent) {
        presentedScene = .story(event)
    }

    /// Finishes a chapter once: applies the choice, rewards, and memory.
    @discardableResult
    func completeEvent(_ eventID: String, choice: Int?) -> Bool {
        guard let event = StoryEvent.find(eventID), isUnlocked(event),
              !relationship(event.personID).seenEvents.contains(eventID) else { return false }
        var state = relationship(event.personID)
        state.seenEvents.append(eventID)
        var points = 0
        if let choice, let options = event.choice?.options, options.indices.contains(choice) {
            state.choices[eventID] = choice
            points = options[choice].points
            if let path = options[choice].setsPath {
                state.path = path
            }
        }
        state.memories.append(Memory(text: "Chapter: \(event.title)", date: now))
        relationships[event.personID] = state
        addPoints(points, to: event.personID)
        for reward in event.rewards {
            grant(reward)
        }
        feedbackCount += 1
        save()
        return true
    }

    func isStorylineComplete(_ personID: String) -> Bool {
        let seen = Set(relationship(personID).seenEvents)
        return StoryEvent.events(for: personID).contains { $0.isFinale && seen.contains($0.id) }
    }

    var storylinesCompleted: Int {
        Person.all.filter { isStorylineComplete($0.id) }.count
    }

    /// After the crossroads, you can always change your mind.
    func canChangePath(for personID: String) -> Bool {
        let seen = Set(relationship(personID).seenEvents)
        return StoryEvent.events(for: personID).contains { $0.isCrossroads && seen.contains($0.id) }
    }

    func setPath(_ path: RelationshipPath, for personID: String) {
        guard path != .undecided, canChangePath(for: personID) else { return }
        var state = relationship(personID)
        state.path = path
        relationships[personID] = state
        feedbackCount += 1
        save()
    }

    // MARK: Quests

    var availableQuests: [Quest] {
        var quests = Quest.starter.filter {
            !completedQuests.contains($0.id)
                && ($0.prerequisite.map { completedQuests.contains($0) } ?? true)
        }
        quests += Person.all.flatMap(\.quests).filter {
            !completedQuests.contains($0.id) && stage(of: $0.personID ?? "") >= $0.requiredStage
                && !isDistant($0.personID ?? "")
        }
        let festival = Festival.current(at: now)
        if !festivalCycles.contains(Season.cycleID(now)) {
            quests.append(festival.quest)
        }
        return quests
    }

    /// How many of a crop you've harvested, ever (Settle In counts carrots).
    func harvestCount(of id: String) -> Int { harvestCounts[id] ?? 0 }

    func canComplete(_ quest: Quest) -> Bool {
        if let goal = quest.harvestGoal {
            return harvestCount(of: goal.itemID) >= goal.count
        }
        if quest.lureGoal { return hasLuredBunny }
        return quest.items.allSatisfy { count(of: $0.itemID) >= $0.count }
    }

    @discardableResult
    func completeQuest(_ questID: String) -> Bool {
        guard let quest = availableQuests.first(where: { $0.id == questID }), canComplete(quest) else { return false }
        for item in quest.items {
            removeItems(item.itemID, item.count)
        }
        if quest.season != nil {
            festivalCycles.insert(Season.cycleID(now))
        } else {
            completedQuests.insert(quest.id)
        }
        if let personID = quest.personID {
            addPoints(quest.points, to: personID)
            remember("Quest complete: \(quest.title).", with: personID)
        }
        for reward in quest.rewards {
            grant(reward)
        }
        spawn(.sparkle, "📜 \(quest.title)!", at: Spot(x: 0.5, y: 0.5))
        if quest.season != nil {
            moment("firstFestival", "🎪 That's a festival request done! Every season has one — and they always come back around.")
        }
        feedbackCount += 1
        save()
        return true
    }

    // MARK: Who's around

    func peopleInMeadow() -> [Person] {
        // Michelle's farm rule: no villagers on the farm screen, ever — only the
        // farmer. Kept as an empty list so the farm scene's stroller layer renders
        // nothing; characters live in the hub, their homes and their themed areas.
        []
    }
}
