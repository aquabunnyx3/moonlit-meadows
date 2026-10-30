import Foundation

// MARK: - The Moon Bunny story (added by Merlin, 2026-10-30)
//
// The hidden heart of Moonlit Meadows (story bible: moon-bunny-story-bible.md).
// One childhood summer, a storm at the pond, a friend who never forgot and a
// farmer who couldn't remember. The white bunny is Mochi's spirit; she came
// back because the farmer did. Theo's slow, guarded track lives in
// MeadowPeople (60% gains, flat gifts, storm silence — all until the Reveal);
// this file holds the arc itself: sightings, memory fragments, the time
// capsule, the Reveal at the pond, and the full-moon goodbye.

extension Meadow {
    // MARK: Beats and gates

    /// The Reveal can happen: the capsule is open and Theo's friendship has
    /// reached the crossroads threshold — everything is waiting on the truth.
    var revealReady: Bool {
        capsuleOpened && !revealDone
            && relationship("theo").points >= RelationshipStage.romanticInterest.threshold
    }

    /// The finale can happen: the truth is out, and tonight is a full moon.
    var finaleReady: Bool { revealDone && !finaleDone && isFullMoonNight }

    /// The capsule can be dug up once two memory fragments have surfaced.
    var capsuleAvailable: Bool { memoryFragments >= 2 && !capsuleOpened }

    // MARK: Memory fragments

    /// Fragments surface as Theo's stage rises: Acquaintance, Friend, Close
    /// Friend. Queued here (addPoints calls this); presented when the screen
    /// is free, so a fragment never talks over another scene.
    func storyNoteTheoStage() {
        let stage = stage(of: "theo")
        let earned = stage >= .closeFriend ? 3 : stage >= .friend ? 2 : stage >= .acquaintance ? 1 : 0
        if memoryFragments < earned, pendingFragment == nil {
            pendingFragment = memoryFragments + 1
        }
    }

    func presentPendingFragment() {
        guard let number = pendingFragment, presentedScene == nil, !isSleeping, !isAtMainMenu else { return }
        pendingFragment = nil
        memoryFragments = max(memoryFragments, number)
        presentedScene = .story(Self.fragmentEvent(number))
        save()
    }

    // MARK: The Moon Bunny's appearances

    enum MoonBunnyPlace: Equatable {
        case farmGate, farmTree, pondShore, pondDock
    }

    /// Where the white bunny is tonight, if anywhere: clear nights only
    /// (sunny after dark), pond-weighted on a rotation — except on Reveal and
    /// finale nights, when she waits at the dock and does not leave.
    var moonBunnyPlace: MoonBunnyPlace? {
        guard !finaleDone, timeOfDay == .night, weather == .sunny, moonBunnyGoneNight != dayNumber else { return nil }
        if revealReady || finaleReady { return .pondDock }
        switch dayNumber % 4 {
        case 0, 2: return .pondShore
        case 1: return .farmGate
        default: return .farmTree
        }
    }

    var moonBunnyPondSpot: Spot? {
        switch moonBunnyPlace {
        case .pondShore: return Spot(x: 0.615, y: 0.815)
        case .pondDock: return Spot(x: 0.50, y: 0.70)
        default: return nil
        }
    }

    var moonBunnyFarmSpot: Spot? {
        switch moonBunnyPlace {
        case .farmGate: return Spot(x: 0.50, y: 0.90)
        case .farmTree: return Spot(x: 0.895, y: 0.26)
        default: return nil
        }
    }

    /// Theo waits at the pond on the nights the bunny waits at the dock.
    var storyTheoAtPond: Bool { moonBunnyPlace == .pondDock }

    /// Meeting the white bunny: a plain sighting (with its kid treasures), the
    /// Reveal, or the goodbye — whichever tonight is for.
    func interactMoonBunny() {
        let beat = finaleReady ? 2 : revealReady ? 1 : 0
        moonBunnyGoneNight = dayNumber
        moonBunnySightings += 1
        metMoonBunny = true
        switch beat {
        case 2:
            finaleDone = true
            keepsakes.remove("capsulePhoto")
            keepsakes.insert("capsulePhotoClear")
            keepsakes.insert("mochiCharmHalf")
            presentedScene = .story(Self.finaleEvent)
        case 1:
            revealDone = true
            presentedScene = .story(Self.revealEvent)
        default:
            switch moonBunnySightings {
            case 1:
                keepsakes.insert("kidRibbon")
                showToast("🐰 It didn't run. When it hopped away, something small was left in the grass: a faded ribbon.")
                moment("firstMoonBunny", "🌙 A bunny that only comes out under the moon… Your collection book has a new page: ???.")
            case 2:
                keepsakes.insert("smoothStone")
                showToast("🐰 It watched you a long time. Left behind: a smooth stone, warm as if from someone's pocket.")
            case 3:
                keepsakes.insert("pressedFlower")
                showToast("🐰 Left behind: a pressed moonflower, still glowing faintly at the edges.")
            default:
                showToast("🐰 The white bunny watched you a while, then hopped off into the moonlight.")
            }
        }
        feedbackCount += 1
        save()
    }

    // MARK: The time capsule

    func digCapsule() {
        guard capsuleAvailable else { return }
        capsuleOpened = true
        keepsakes.insert("theoCharmHalf")
        keepsakes.insert("capsulePhoto")
        showToast("📦 Under the shore stones: a buried time capsule. Kid drawings, a blurred photo… and half of a carved wooden moon. Theo would know about this. Theo would know everything about this.")
        feedbackCount += 1
        save()
    }

    // MARK: The scenes (ad-hoc events, played through the story scene player;
    // their beats are applied by the triggers above, not by completeEvent)

    private static func fragmentEvent(_ number: Int) -> StoryEvent {
        let bodies: [[StoryLine]] = [
            [StoryLine(speaker: .narrator, text: "A memory, uninvited: two kids laughing under a tree too big for them. Small hands hold a white bunny up to the moon, like an offering."),
             StoryLine(speaker: .narrator, text: "Then it's gone. But your hands are shaking a little, and you don't know why.")],
            [StoryLine(speaker: .narrator, text: "A memory: initials carved into bark at kid-height, the cuts still pale. T — and below it, the start of another letter you can't quite read."),
             StoryLine(speaker: .narrator, text: "You know that tree. You've walked past it a hundred times this year.")],
            [StoryLine(speaker: .narrator, text: "A memory: rain on black water. A dock, slick as glass. A boy shouting your name — and underneath the fear, a certainty: he will catch you. He always catches you."),
             StoryLine(speaker: .narrator, text: "The rest won't come. Not yet. But it is closer than it was.")],
        ]
        return StoryEvent(id: "moonbunny-fragment-\(number)", personID: "theo", title: "A Memory Surfaces",
                          stage: .stranger, path: .any,
                          lines: bodies[min(max(number - 1, 0), bodies.count - 1)], rewards: [])
    }

    private static var revealEvent: StoryEvent {
        StoryEvent(id: "moonbunny-reveal", personID: "theo", title: "The Night at the Pond",
                   stage: .stranger, path: .any, lines: [
                    StoryLine(speaker: .narrator, text: "The white bunny is waiting at the end of the dock. It does not run. Theo stands at the shore like he has been standing there for fifteen years."),
                    StoryLine(speaker: .narrator, text: "Rain on black water. A dock, slick as glass. Two kids chasing a moon-white bunny, laughing —"),
                    StoryLine(speaker: .narrator, text: "— then slipping. Falling. The cold closing over your head. And through it all, a boy shouting your name — and his hand. His hand, pulling you out."),
                    StoryLine(speaker: .person, text: "It was my fault. It was always my fault. I said, 'just a little further.' I have said it in my sleep for fifteen years."),
                    StoryLine(speaker: .you, text: "Theo. It wasn't your fault. And I didn't choose to forget you — I never chose that. The summer was taken. It wasn't given away."),
                    StoryLine(speaker: .person, text: "You… remember. After all this time — you remember."),
                    StoryLine(speaker: .narrator, text: "The bunny binkies once, softly, and settles between you like a secret finally told. The pond is very quiet. So is he. But it is a different quiet now."),
                   ], rewards: [])
    }

    private static var finaleEvent: StoryEvent {
        StoryEvent(id: "moonbunny-finale", personID: "theo", title: "The Full-Moon Goodbye",
                   stage: .stranger, path: .any, lines: [
                    StoryLine(speaker: .narrator, text: "Full moon. The pond is a mirror, and she is waiting at the dock — brighter tonight, almost made of moonlight itself."),
                    StoryLine(speaker: .narrator, text: "Theo is here too. For a while, nobody says anything. Some goodbyes don't need help."),
                    StoryLine(speaker: .narrator, text: "Then she binkies — high and joyful and impossible — straight up into the moonlight, and is gone."),
                    StoryLine(speaker: .person, text: "She waited, you know. Every clear night. Bunnies are patient about the people they love."),
                    StoryLine(speaker: .narrator, text: "On the dock, where she landed: a small carved wooden half-moon. Your half — lost the night of the storm, and kept safe all these years by a bunny. The pair is whole again."),
                   ], rewards: [])
    }
}
