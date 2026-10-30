import Foundation

// MARK: - Relationship stages

enum RelationshipPath: String, Codable {
    /// Before the crossroads chapter at Close Friend.
    case undecided
    case friendship
    case romance
}

enum RelationshipStage: Int, CaseIterable, Comparable {
    case stranger = 1
    case acquaintance
    case friend
    case closeFriend
    case romanticInterest
    case dating
    case committed

    static func < (lhs: RelationshipStage, rhs: RelationshipStage) -> Bool { lhs.rawValue < rhs.rawValue }

    /// Relationship points needed to reach each stage.
    var threshold: Int {
        switch self {
        case .stranger: return 0
        case .acquaintance: return 30
        case .friend: return 100
        case .closeFriend: return 220
        case .romanticInterest: return 380
        case .dating: return 580
        case .committed: return 820
        }
    }

    /// Stages 5–7 have friendship names for players who choose to stay friends.
    func title(path: RelationshipPath) -> String {
        switch self {
        case .stranger: return "Stranger"
        case .acquaintance: return "Acquaintance"
        case .friend: return "Friend"
        case .closeFriend: return "Close Friend"
        case .romanticInterest: return path == .friendship ? "Best Friend" : "Romantic Interest"
        case .dating: return path == .friendship ? "Kindred Spirit" : "Dating"
        case .committed: return path == .friendship ? "Lifelong Friend" : "Committed"
        }
    }

    var maxPoints: Int { RelationshipStage.committed.threshold + 200 }
}

// MARK: - Looks

/// A drawn character design. `PersonPortrait` turns this into a picture.
struct PersonLook {
    enum Hair {
        case long, bob, short, curlyPuffs, messy, wavy, ponytail
    }

    enum Accessory {
        case none, flowerClip, headband, glasses, beanie, bow, cap, starEarring, strawberryClip, blueberryClip, beret
    }

    let skin: RGB
    let hair: RGB
    let hairStyle: Hair
    let eyes: RGB
    let outfit: RGB
    let outfitAccent: RGB
    var accessory: Accessory = .none
    var accessoryColor = RGB(0xFFFFFF)
    /// A short note for the profile, like "Sage cardigan and a daisy clip".
    var styleNote = ""
}

// MARK: - Supporting types

struct ItemCount {
    let itemID: String
    let count: Int
}

struct ScheduleSlot {
    let time: TimeOfDay
    let place: String
    let emoji: String
    /// Whether they're out and about in the meadow (visible in the world) at this time.
    let inMeadow: Bool
}

struct SharedActivity {
    let name: String
    let emoji: String
    let friendLine: String
    let dateLine: String
}

struct Answer {
    let text: String
    let response: String
    let points: Int
    /// A deliberately rude answer: shown with a thorny broken heart, and it costs a heart.
    var isRude = false
}

struct Question {
    let id: String
    let prompt: String
    let answers: [Answer]
}

/// A delivery request from a character, or a seasonal festival request.
struct Quest: Identifiable {
    let id: String
    let personID: String?
    var season: Season?
    let title: String
    let description: String
    let requiredStage: RelationshipStage
    let items: [ItemCount]
    let points: Int
    let rewards: [Reward]
}

struct DailyLines {
    /// Stranger and Acquaintance.
    let early: [String]
    /// Friend and Close Friend.
    let friend: [String]
    /// Stages 5–7 on the romance path.
    let romance: [String]
    /// Stages 5–7 on the friendship path.
    let bestie: [String]
}

// MARK: - People

/// A character you can befriend: one of the seven main characters (who can also be romanced) or a villager.
struct Person: Identifiable {
    let id: String
    let name: String
    let fullName: String
    let pronouns: String
    let gender: String
    let role: String
    let personality: String
    let backstory: String
    let interests: String
    /// Usually one look. Add more to rotate outfits by day (Sol loves changing styles); illustrated
    /// artwork, when present, is used instead.
    let looks: [PersonLook]
    let favoriteBreeds: [String]
    let lovedGifts: [String]
    let likedGifts: [String]
    let dislikedGifts: [String]
    let schedule: [ScheduleSlot]
    let activities: [SharedActivity]
    let lines: DailyLines
    let questions: [Question]
    let quests: [Quest]
    /// `{bunny}` is replaced by the bunny's name and `{breed}` by the breed.
    let favoriteBunnyReaction: String
    let bunnyReaction: String
    let showFavoriteReaction: String
    let lovedGiftReaction: String
    let likedGiftReaction: String
    let neutralGiftReaction: String
    let dislikedGiftReaction: String
    /// Villagers can be befriended up to Close Friend (three chapters) but aren't romance options.
    var isVillager = false

    /// The highest stage you can reach with them.
    var maxStage: RelationshipStage { isVillager ? .closeFriend : .committed }

    func look(onDay day: Int) -> PersonLook {
        looks[((day % looks.count) + looks.count) % looks.count]
    }

    func slot(at time: TimeOfDay) -> ScheduleSlot {
        schedule.first { $0.time == time } ?? schedule[0]
    }

    static func find(_ id: String) -> Person? {
        all.first { $0.id == id }
    }

    /// The seven romanceable main characters.
    static let main: [Person] = [june, roz, theo, kai, sol, rowan, silas]
    static let all: [Person] = main + villagers
}

// MARK: - June

private let june = Person(
    id: "june",
    name: "June",
    fullName: "Juniper Ashwell",
    pronouns: "she/her",
    gender: "Woman",
    role: "Herbalist at the Glasshouse",
    personality: "Gentle, shy, and quietly funny. Speaks in plant facts when she's nervous, which is often.",
    backstory: "June was a pharmacist in the city until she burned out. When her grandmother left her the old glasshouse at the edge of the meadow, she moved in with three suitcases and a very determined fern. She's learning that people, like plants, need sunlight and patience.",
    interests: "Pressing flowers, herbal tea blends, rainy-day reading",
    looks: [
        PersonLook(skin: RGB(0xFBE3D6), hair: RGB(0xCDBDEE), hairStyle: .long, eyes: RGB(0x7B5FB8),
                   outfit: RGB(0xCBBDF0), outfitAccent: RGB(0xFFF4E4), accessory: .beret, accessoryColor: RGB(0xC9B8EE),
                   styleNote: "A periwinkle capelet over a long blue dress, a pink ribbon bow, a leather satchel, and one long golden braid"),
    ],
    favoriteBreeds: ["lavenderBunny", "willowBunny", "eucalyptusBunny"],
    lovedGifts: ["tea", "herbalPosy", "lavender"],
    likedGifts: ["chamomile", "mint", "chamomileTea", "rose"],
    dislikedGifts: ["hazelnut", "sweetPotato"],
    schedule: [
        ScheduleSlot(time: .dawn, place: "The Glasshouse", emoji: "🌿", inMeadow: false),
        ScheduleSlot(time: .day, place: "Meadow herb garden", emoji: "🌼", inMeadow: true),
        ScheduleSlot(time: .dusk, place: "Village library", emoji: "📚", inMeadow: false),
        ScheduleSlot(time: .night, place: "Reading at home", emoji: "🕯️", inMeadow: false),
    ],
    activities: [
        SharedActivity(name: "Herb walk", emoji: "🌿",
                       friendLine: "June points out every herb on the path. “That one's lemon balm. It's good for… um, calm. Ironically I'm not.”",
                       dateLine: "June hooks her pinky around yours halfway through the herb walk and doesn't let go."),
        SharedActivity(name: "Press flowers", emoji: "🌸",
                       friendLine: "You press violets between pages of an old encyclopedia. June labels each one in tiny handwriting.",
                       dateLine: "June presses a clover you found together. “So we remember today,” she says, cheeks pink."),
        SharedActivity(name: "Tea tasting", emoji: "🍵",
                       friendLine: "You taste five blends. June takes notes like it's a science experiment. It is, she insists.",
                       dateLine: "June names a new blend after you. It's sweet with a little bit of spice. “Like you,” she whispers."),
    ],
    lines: DailyLines(
        early: [
            "Oh! Hello. Sorry, I was talking to the basil. It's a good listener.",
            "Did you know chamomile grows better when it's walked on? Not that I'm… recommending walking on things.",
            "The bunnies keep nibbling my mint. I can't even be mad. Look at their faces.",
        ],
        friend: [
            "I saved you a cutting from Grandma's rosemary. It's… it's kind of a big deal. To me.",
            "I've been sleeping better since I moved here. I think the meadow is good medicine.",
            "You're easy to talk to. I don't say that to many people. Or plants.",
        ],
        romance: [
            "I wrote your name on a seed packet so I'd remember to plant something for you. Then I planted all of them.",
            "Every time you visit, the greenhouse feels warmer. That's not a plant fact. That's just true.",
            "Stay for tea? You don't have to. I'd like it, though. A lot.",
        ],
        bestie: [
            "My best friend and my best fern. I'm so lucky.",
            "Let's start a rainy-day book club. Members: you, me, and a Lavender bunny.",
            "I told Grandma's photo all about you. She'd have adored you.",
        ]
    ),
    questions: [
        Question(id: "june-q1", prompt: "“If you were a plant, which one would you be?”", answers: [
            Answer(text: "A sunflower, always facing the light.", response: "“That's lovely. Sunflowers follow the sun… I think I'd follow you around too. As a friend! Mostly.”", points: 15),
            Answer(text: "A cactus. Prickly, but low-maintenance.", response: "“Ha! Cacti bloom the brightest flowers, you know. I'll wait.”", points: 10),
            Answer(text: "Whatever grows fastest.", response: "“Clover, then. Humble and lucky.”", points: 5),
            Answer(text: "Something that isn't so jumpy.", response: "June's smile slips. “Oh. Right. Sorry.” She goes back to her ferns.", points: 0, isRude: true),
        ]),
        Question(id: "june-q2", prompt: "“Do you ever feel like you're not where you're supposed to be?”", answers: [
            Answer(text: "Sometimes. But here feels right.", response: "“Me too. Here feels right. Especially lately.”", points: 15),
            Answer(text: "Everyone's figuring it out as they go.", response: "“That's… really comforting, actually. Thank you.”", points: 10),
            Answer(text: "Not really, no.", response: "“I envy that. Maybe you can teach me.”", points: 5),
            Answer(text: "Maybe you just don't fit anywhere.", response: "June goes very quiet. “…Maybe.” She doesn't look at you for the rest of the day.", points: 0, isRude: true),
        ]),
    ],
    quests: [
        Quest(id: "june-1", personID: "june", title: "Seeds of Trust",
              description: "June wants fresh clover to start a new herb bed.", requiredStage: .acquaintance,
              items: [ItemCount(itemID: "clover", count: 6)], points: 30, rewards: [.coins(60)]),
        Quest(id: "june-2", personID: "june", title: "A Calming Brew",
              description: "June's had a long week. A pot of chamomile tea would help.", requiredStage: .friend,
              items: [ItemCount(itemID: "chamomileTea", count: 1)], points: 40, rewards: [.gems(2), .hint("lavenderBunny")]),
        Quest(id: "june-3", personID: "june", title: "The Moss Mystery",
              description: "Strange glowing moss appeared by the glasshouse. June thinks a rare bunny might be nesting nearby.",
              requiredStage: .closeFriend,
              items: [ItemCount(itemID: "lettuce", count: 5), ItemCount(itemID: "lavender", count: 2)], points: 50,
              rewards: [.gems(3), .hint("eucalyptusBunny")]),
    ],
    favoriteBunnyReaction: "June gasps and cradles {bunny} the {breed}. “Oh, oh, oh. Hello, sweetheart.” She tucks a sprig of lavender behind its ear and her eyes go shiny. “I'll take such good care of them. Thank you. Truly.”",
    bunnyReaction: "June holds {bunny} carefully. “Hello, little one. Welcome to the glasshouse.”",
    showFavoriteReaction: "June's hand flies to her mouth. “Is that a {breed}? They're my favorite. Don't tell the other bunnies.”",
    lovedGiftReaction: "“You remembered!” June hugs it to her chest. “This is perfect.”",
    likedGiftReaction: "“Oh, how thoughtful. Thank you.”",
    neutralGiftReaction: "“Thank you! I'll find a use for it.”",
    dislikedGiftReaction: "“Oh! That's… very kind. I'm sure someone will love it.”"
)

// MARK: - Roz

private let roz = Person(
    id: "roz",
    name: "Roz",
    fullName: "Rosalind Okafor",
    pronouns: "she/her",
    gender: "Woman",
    role: "Baker at the Sweet Burrow",
    personality: "Bubbly, loud-laughing, and fiercely competitive about pie. Gives everyone nicknames within a minute of meeting them.",
    backstory: "The eldest of six siblings, Roz has fed a crowd since she could reach the stove. She trained at a fancy pastry school in the city, then walked out a month before graduating to open a bakery where nothing has to be perfect — just warm. She's still learning that it's okay to rest.",
    interests: "Baking contests, market days, loud music in the kitchen",
    looks: [
        PersonLook(skin: RGB(0xFBE1D2), hair: RGB(0xB08A63), hairStyle: .bob, eyes: RGB(0xA8682A),
                   outfit: RGB(0xEFE2CC), outfitAccent: RGB(0xD9C6A8), accessory: .strawberryClip, accessoryColor: RGB(0xE5584F),
                   styleNote: "Cream overalls with a strawberry pin, a rolled-sleeve linen shirt, a brown belt, a messy bun, and lace-up boots"),
    ],
    favoriteBreeds: ["strawberryBunny", "honeybunBunny", "sugarplumBunny"],
    lovedGifts: ["jam", "sunriseShortcake", "cherrySundae"],
    likedGifts: ["strawberry", "carrotCake", "peach", "pie"],
    dislikedGifts: ["mint", "lettuce"],
    schedule: [
        ScheduleSlot(time: .dawn, place: "Sweet Burrow Bakery", emoji: "🥐", inMeadow: false),
        ScheduleSlot(time: .day, place: "Meadow market stall", emoji: "🧺", inMeadow: true),
        ScheduleSlot(time: .dusk, place: "Meadow picnic blanket", emoji: "🍓", inMeadow: true),
        ScheduleSlot(time: .night, place: "Sweet Burrow, prepping dough", emoji: "🌙", inMeadow: false),
    ],
    activities: [
        SharedActivity(name: "Bake-off", emoji: "🧁",
                       friendLine: "Roz challenges you to a cupcake bake-off. She wins. She also eats your cupcake and declares it the real winner.",
                       dateLine: "Flour everywhere. Roz wipes a smudge off your nose and leaves her hand on your cheek a second too long."),
        SharedActivity(name: "Market stroll", emoji: "🧺",
                       friendLine: "Roz haggles for peaches like it's a sport. You leave with three crates and a new nickname: “Sweet Pea.”",
                       dateLine: "Roz buys you a flower crown at the market and insists you wear it all day. You do."),
        SharedActivity(name: "Picnic", emoji: "🍓",
                       friendLine: "Roz packs enough food for twelve. You eat until you can't move. Perfect afternoon.",
                       dateLine: "Lying on the picnic blanket, Roz laces her fingers with yours. “Is this okay?” It's more than okay."),
    ],
    lines: DailyLines(
        early: [
            "Hey, new neighbor! Want a scone? That wasn't a question. Here's a scone.",
            "Don't touch the sourdough starter. Her name is Beyoncé and she bites.",
            "Six siblings and I still have the loudest laugh. It's a gift.",
        ],
        friend: [
            "Sweet Pea! You're just in time to taste-test. Be honest. Actually, be nice.",
            "Sometimes I sit in the bakery after closing and just… breathe. Is that weird?",
            "You know what? You're officially family. Sorry, no take-backs.",
        ],
        romance: [
            "I saved the last strawberry tart for you. I've never saved anything for anyone. Draw your own conclusions.",
            "You make me want to slow down. Nobody's ever made me want to slow down.",
            "Come by after closing? I'll make you something that's not on the menu.",
        ],
        bestie: [
            "Bestie! I made you a cake shaped like your face. It's horrifying. You'll love it.",
            "If I ever open a second bakery, you're my business partner. Non-negotiable.",
            "My siblings keep asking about you. They think you're cooler than me. Rude. Accurate.",
        ]
    ),
    questions: [
        Question(id: "roz-q1", prompt: "“Settle a debate: cake or pie?”", answers: [
            Answer(text: "Pie. Obviously.", response: "“YES. Finally, someone with taste!”", points: 15),
            Answer(text: "Cake, for birthdays.", response: "“Okay, okay. Respectable. Wrong, but respectable.”", points: 10),
            Answer(text: "I don't really like sweets.", response: "“…I'm going to pretend I didn't hear that.”", points: 5),
            Answer(text: "Neither. Your baking's too sweet.", response: "Roz's spatula freezes mid-air. “Huh. Okay.” For once, she has nothing to say.", points: 0, isRude: true),
        ]),
        Question(id: "roz-q2", prompt: "“Do you ever take a day off? Like, really off?”", answers: [
            Answer(text: "We should take one together.", response: "“A day off… with you? I could be talked into that.”", points: 15),
            Answer(text: "Rest is important, Roz.", response: "“Ugh, you sound like my mom. She's right too.”", points: 10),
            Answer(text: "Never. Grind forever!", response: "“Ha! A kindred spirit. Though… maybe neither of us should.”", points: 5),
            Answer(text: "You'd be less exhausting if you did.", response: "Roz laughs, but it comes out thin. “Noted.”", points: 0, isRude: true),
        ]),
    ],
    quests: [
        Quest(id: "roz-1", personID: "roz", title: "Berry Rush",
              description: "Roz is short on strawberries for the morning tarts!", requiredStage: .acquaintance,
              items: [ItemCount(itemID: "strawberry", count: 6)], points: 30, rewards: [.coins(80)]),
        Quest(id: "roz-2", personID: "roz", title: "Taste Tester",
              description: "Roz wants to compare her carrot cake recipe with yours.", requiredStage: .friend,
              items: [ItemCount(itemID: "carrotCake", count: 2)], points: 40, rewards: [.gems(2), .hint("peachBunny")]),
        Quest(id: "roz-3", personID: "roz", title: "The Grand Bake-Off",
              description: "Roz is entering the village bake-off and needs a jar of jam and a pie for inspiration. She swears a pink-and-lilac bunny tried to steal her sugarcane…",
              requiredStage: .closeFriend,
              items: [ItemCount(itemID: "jam", count: 1), ItemCount(itemID: "pie", count: 1)], points: 50,
              rewards: [.gems(3), .hint("sugarplumBunny")]),
    ],
    favoriteBunnyReaction: "Roz shrieks so loudly the birds take off. “A {breed}?! For ME?” She scoops up {bunny} and spins in a circle. “You're my new sous-chef. Your first job is being adorable. You're already great at it.”",
    bunnyReaction: "Roz boops {bunny} on the nose. “Welcome to the bakery, little bun. No paws in the dough!”",
    showFavoriteReaction: "“STOP. A {breed}? That's my favorite in the whole world. Can I hold it? I'm holding it.”",
    lovedGiftReaction: "“Are you kidding me? This is my favorite! C'mere, I'm hugging you.”",
    likedGiftReaction: "“Ooh, nice! This'll go in something delicious.”",
    neutralGiftReaction: "“Aw, thanks, Sweet Pea!”",
    dislikedGiftReaction: "“Ha, you know I hate this! …Still, it's the thought that counts.”"
)

// MARK: - Theo

private let theo = Person(
    id: "theo",
    name: "Theo",
    fullName: "Theodore Marchetti",
    pronouns: "he/him",
    gender: "Man",
    role: "Keeper of the hilltop observatory",
    personality: "Dry-humored, precise, and introverted. Pretends not to be sentimental, then names constellations after people he likes.",
    backstory: "Theo's grandfather — Nonno — built the little observatory on the hill and taught Theo every star by name. When Nonno passed, Theo left his university job to keep the telescope running. Some nights he talks to the sky like Nonno is still listening.",
    interests: "Stargazing, fixing old instruments, very strong cocoa",
    looks: [
        PersonLook(skin: RGB(0xF2CBAE), hair: RGB(0x8A5E3B), hairStyle: .messy, eyes: RGB(0x9A5B22),
                   outfit: RGB(0x7E8F55), outfitAccent: RGB(0x8C6A4E), accessory: .beret, accessoryColor: RGB(0x6F8150),
                   styleNote: "A hooded midnight cloak lined in violet, a crescent-moon brooch, black gloves, and tall riding boots"),
    ],
    favoriteBreeds: ["midnightBunny", "cometBunny", "galaxyBunny"],
    lovedGifts: ["stargazerCocoa", "starJam", "muffin"],
    likedGifts: ["blueberry", "moonflower", "hazelnutBread", "chamomileTea", "hazelnut"],
    dislikedGifts: ["lettuce", "salad"],
    schedule: [
        ScheduleSlot(time: .dawn, place: "Asleep (finally)", emoji: "😴", inMeadow: false),
        ScheduleSlot(time: .day, place: "Clock tower workshop", emoji: "🔧", inMeadow: false),
        ScheduleSlot(time: .dusk, place: "Meadow hill", emoji: "🌄", inMeadow: true),
        ScheduleSlot(time: .night, place: "Stargazing in the meadow", emoji: "🔭", inMeadow: true),
    ],
    activities: [
        SharedActivity(name: "Stargazing", emoji: "🔭",
                       friendLine: "Theo shows you Cassiopeia. “Vain queen. Nonno's favorite. He said she reminded him of Nonna.”",
                       dateLine: "Theo adjusts the telescope for you, then forgets to step back. Neither of you mentions it."),
        SharedActivity(name: "Comet watch", emoji: "☄️",
                       friendLine: "No comet tonight. Theo says that's statistically likely. You both stay out anyway.",
                       dateLine: "A shooting star crosses the sky. Theo doesn't look at it. He's looking at you."),
        SharedActivity(name: "Fix the telescope", emoji: "🔧",
                       friendLine: "You hand Theo tiny screwdrivers for an hour. He says you're the best assistant he's ever had. You're the only one.",
                       dateLine: "Theo teaches you to calibrate the lens, his hands over yours. “Steady,” he says. His voice isn't."),
    ],
    lines: DailyLines(
        early: [
            "Hm. Hello. If you're here for the observatory tour, it's closed. There is no tour. I'm the tour.",
            "The moon's in a waxing gibbous. You didn't ask. I'm telling you anyway.",
            "I don't do mornings. Or crowds. Or… this is going well, isn't it.",
        ],
        friend: [
            "Nonno would have liked you. He liked people who ask good questions.",
            "I made extra cocoa. By accident. Twice. You should probably have one.",
            "You know Vega? Brightest star in Lyra. I've been thinking of calling it your star. Kidding. Mostly.",
        ],
        romance: [
            "I mapped every star in the sky and still didn't find anything as bright as you. …That was terrible. I'm keeping it.",
            "Stay a little longer. The good stars come out after midnight.",
            "Nonno used to say the sky is too big to look at alone. I finally understand what he meant.",
        ],
        bestie: [
            "You're my favorite person to be quiet with. That's the highest honor I give.",
            "I named an asteroid after you in my notebook. It's very small and very loyal.",
            "Come to the observatory anytime. The spare key is under the moon-shaped rock. For you.",
        ]
    ),
    questions: [
        Question(id: "theo-q1", prompt: "“Do you believe the stars mean anything? Or are they just… very far away fire?”", answers: [
            Answer(text: "They're stories we tell each other.", response: "“…Nonno said exactly that. Huh.”", points: 15),
            Answer(text: "Far away fire. But beautiful fire.", response: "“Practical and romantic. A rare combination.”", points: 10),
            Answer(text: "I've never thought about it.", response: "“Then I'll have to show you. Tonight. If you're free.”", points: 5),
            Answer(text: "Just fire. Stargazing is a waste of time.", response: "Theo closes his notebook. “I see.” He turns back to the telescope without another word.", points: 0, isRude: true),
        ]),
        Question(id: "theo-q2", prompt: "“What's something you miss?”", answers: [
            Answer(text: "Someone I lost. Like you miss Nonno.", response: "Theo is quiet a long time. “Then you understand. Thank you for telling me.”", points: 15),
            Answer(text: "Being a kid and not worrying.", response: "“Ah. The golden age of no taxes.”", points: 10),
            Answer(text: "Nothing. I live in the present.", response: "“Teach me that trick sometime.”", points: 5),
            Answer(text: "Nothing. Missing things is pointless.", response: "Theo's jaw tightens. “Right. Never mind.”", points: 0, isRude: true),
        ]),
    ],
    quests: [
        Quest(id: "theo-1", personID: "theo", title: "Night Lights",
              description: "Theo is out of chamomile for his late-night tea.", requiredStage: .acquaintance,
              items: [ItemCount(itemID: "chamomile", count: 4)], points: 30, rewards: [.coins(70)]),
        Quest(id: "theo-2", personID: "theo", title: "Warm Hands",
              description: "The observatory gets cold at night. Theo would love some chamomile tea for the long watch.",
              requiredStage: .friend,
              items: [ItemCount(itemID: "chamomileTea", count: 2)], points: 40, rewards: [.gems(2), .hint("midnightBunny")]),
        Quest(id: "theo-3", personID: "theo", title: "Nonno's Star Map",
              description: "Theo found a note in Nonno's star map: “Galaxy bunnies come for moonflowers on clear, starry nights.” Bring lavender and strawberries for the long night watch, and he'll share the rest of the note.",
              requiredStage: .closeFriend,
              items: [ItemCount(itemID: "lavender", count: 2), ItemCount(itemID: "strawberry", count: 4)], points: 50,
              rewards: [.gems(3), .hint("galaxyBunny")]),
    ],
    favoriteBunnyReaction: "Theo goes very still. “A {breed}.” He kneels and {bunny} hops right into his hands. “Nonno used to say these were stars that fell asleep in the meadow.” He clears his throat. “I'm fine. There's something in my eye. Thank you.”",
    bunnyReaction: "Theo holds {bunny} like a delicate instrument. “Hello. I'll show you the moon later.”",
    showFavoriteReaction: "Theo pulls his hood forward, trying not to grin. “That's a {breed}. Do you know how rare… Can I just look at them for a minute?”",
    lovedGiftReaction: "“This is… exactly right. You pay attention. I like that.”",
    likedGiftReaction: "“Oh. That's thoughtful. Thank you.”",
    neutralGiftReaction: "“Thanks. I'll find somewhere to put it.”",
    dislikedGiftReaction: "“Ah. Leafy. …Thank you anyway.”"
)

// MARK: - Kai

private let kai = Person(
    id: "kai",
    name: "Kai",
    fullName: "Kai Nakamura-Hale",
    pronouns: "he/him",
    gender: "Man",
    role: "Carpenter and bunny-hutch builder",
    personality: "Sunny, sporty, and a little clumsy. Tells the worst puns with total confidence and shows up before you can ask for help.",
    backstory: "Kai grew up moving between foster homes and never had a room that stayed his. He learned carpentry from a neighbor who let him help fix fences, and now he builds homes for everyone in the meadow — including the bunnies. He's never built anything for himself.",
    interests: "Woodworking, sunrise jogs, campfire cooking (badly)",
    looks: [
        PersonLook(skin: RGB(0xFBE3D6), hair: RGB(0xAFC9AE), hairStyle: .messy, eyes: RGB(0x4F86C6),
                   outfit: RGB(0xA9C7A5), outfitAccent: RGB(0xEEF3E6), accessory: .blueberryClip, accessoryColor: RGB(0x5B6FB8),
                   styleNote: "A teal bomber jacket with a cream collar, a linen shirt, teal cargo pants, and laced brown boots"),
    ],
    favoriteBreeds: ["mapleBunny", "cocoaBunny", "willowbarkBunny"],
    lovedGifts: ["campfireStew", "hazelnutBread", "pie"],
    likedGifts: ["carrot", "sweetPotato", "pumpkin", "carrotCake", "blueberry"],
    dislikedGifts: ["rose", "roseMacaron"],
    schedule: [
        ScheduleSlot(time: .dawn, place: "Jogging through the meadow", emoji: "🏃", inMeadow: true),
        ScheduleSlot(time: .day, place: "Woodshop", emoji: "🪚", inMeadow: false),
        ScheduleSlot(time: .dusk, place: "Fixing fences in the meadow", emoji: "🔨", inMeadow: true),
        ScheduleSlot(time: .night, place: "Campfire at home", emoji: "🔥", inMeadow: false),
    ],
    activities: [
        SharedActivity(name: "Build a birdhouse", emoji: "🔨",
                       friendLine: "Kai hits his thumb twice. The birdhouse is crooked. He declares it “rustic.” You agree.",
                       dateLine: "Kai carves your initials and his into the birdhouse roof. “So the birds know who built it.”"),
        SharedActivity(name: "Morning jog", emoji: "🏃",
                       friendLine: "Kai jogs backwards so he can talk to you. He trips over a bunny. Both are fine.",
                       dateLine: "You race to the hill. Kai lets you win, then pretends he didn't. You both collapse laughing in the grass."),
        SharedActivity(name: "Campfire", emoji: "🔥",
                       friendLine: "Kai burns the marshmallows on purpose. “It's called caramelizing.” It's called burning, Kai.",
                       dateLine: "Kai wraps his flannel around your shoulders by the fire. “You looked cold.” You weren't. You keep it anyway."),
    ],
    lines: DailyLines(
        early: [
            "Hey! Need a hand? I've got two. Well — one and a half, I hit my thumb this morning.",
            "Why did the bunny join the band? It had a lot of hop-tential. …I'll see myself out.",
            "I'm building a hutch for the meadow bunnies. Wanna help? You can hold the nails!",
        ],
        friend: [
            "You're always so busy helping everyone. Who helps you? …I volunteer.",
            "I never stayed anywhere long enough to have a best friend. I think I might have one now.",
            "Made you a little shelf. It's only a tiny bit wonky. Like me.",
        ],
        romance: [
            "I've built a hundred homes in this meadow. You're the first person who's ever felt like one.",
            "I'm usually good with my hands. Around you, I drop everything. Literally. Ask my hammer.",
            "Wanna watch the sunrise tomorrow? I'll bring cocoa. And I'll try not to fall off the hill.",
        ],
        bestie: [
            "Partner! Ready for our next project? I'm thinking… a treehouse. For bunnies. Two stories.",
            "You're the family I picked. That's a big deal for a guy like me.",
            "I carved you a little bunny figure. It looks like a potato. It's a bunny. It's from the heart.",
        ]
    ),
    questions: [
        Question(id: "kai-q1", prompt: "“What makes a place feel like home to you?”", answers: [
            Answer(text: "The people in it.", response: "Kai's smile wobbles a bit. “Yeah. Yeah, me too.”", points: 15),
            Answer(text: "A comfy bed and good snacks.", response: "“Ha! Simple. Solid. I respect that.”", points: 10),
            Answer(text: "I don't need a home.", response: "“I used to say that too. I'm not sure I meant it.”", points: 5),
            Answer(text: "Somewhere you're not, honestly.", response: "Kai's grin falters. “Ha. Good one.” He finds a reason to leave early.", points: 0, isRude: true),
        ]),
        Question(id: "kai-q2", prompt: "“Be honest — are my puns funny?”", answers: [
            Answer(text: "They're terrible. I love them.", response: "“That's the nicest thing anyone's ever said to me.”", points: 15),
            Answer(text: "Some of them!", response: "“I'll take some!”", points: 10),
            Answer(text: "Please stop.", response: "“Never. But I respect the honesty.”", points: 5),
            Answer(text: "No. They're painful. Please stop talking.", response: "Kai blinks. “Oh. Sure. Sorry.” He's quiet the rest of the visit.", points: 0, isRude: true),
        ]),
    ],
    quests: [
        Quest(id: "kai-1", personID: "kai", title: "Lumber Lunch",
              description: "Kai forgot his lunch again. Carrots will do!", requiredStage: .acquaintance,
              items: [ItemCount(itemID: "carrot", count: 8)], points: 30, rewards: [.coins(60)]),
        Quest(id: "kai-2", personID: "kai", title: "Hutch Warming",
              description: "Kai finished a new bunny hutch and wants to throw a little party with salad and sweet peas. He swears a chocolate-brown lop was napping in the wheat nearby.",
              requiredStage: .friend,
              items: [ItemCount(itemID: "salad", count: 1), ItemCount(itemID: "peas", count: 4)], points: 40,
              rewards: [.gems(2), .hint("cocoaBunny")]),
        Quest(id: "kai-3", personID: "kai", title: "Barn Raising",
              description: "Kai is building a barn for the bunnies. While measuring, he spotted a bark-brown bunny gnawing willow twigs into tiny sculptures…",
              requiredStage: .closeFriend,
              items: [ItemCount(itemID: "pumpkin", count: 3), ItemCount(itemID: "sweetPotato", count: 2)], points: 50,
              rewards: [.gems(3), .hint("willowbarkBunny")]),
    ],
    favoriteBunnyReaction: "Kai's jaw drops. “No way. A {breed}?” {bunny} climbs straight up his overalls and sits on his shoulder. Kai laughs so hard he has to sit down. “That's it. I'm building you the fanciest hutch in the meadow. Two floors. A balcony. Thank you, seriously.”",
    bunnyReaction: "Kai gives {bunny} a gentle scritch. “Welcome to the crew, buddy. Hard hats optional.”",
    showFavoriteReaction: "“Whoa, whoa! A {breed}? Those are my favorite! Look at its little face!”",
    lovedGiftReaction: "“Are you serious? This is my all-time favorite! You're the best!”",
    likedGiftReaction: "“Sweet, thanks! This'll fuel me through the whole afternoon.”",
    neutralGiftReaction: "“Oh, cool! Thanks!”",
    dislikedGiftReaction: "“Ha, flowers make me sneeze. But that's really nice of you!”"
)

// MARK: - Sol

private let sol = Person(
    id: "sol",
    name: "Sol",
    fullName: "Sol Rivera",
    pronouns: "they/them",
    gender: "Gender-fluid",
    role: "Musician and tailor at the Patchwork Atelier",
    personality: "Playful, theatrical, and deeply caring. Hums constantly, collects fabric scraps and stray stories, and remembers everyone's birthday.",
    backstory: "Sol toured for years as a traveling folk musician, never staying anywhere longer than a season. They stopped in the meadow to mend a guitar strap, fell in love with the light, and opened a tiny tailoring shop. Sol is gender-fluid, and their style shifts with how they feel each day — ruffles and ribbons one morning, suspenders and a cap the next. They're writing a song about the meadow and are afraid to finish it, because finishing means staying.",
    interests: "Songwriting, sewing outfits from scraps, lantern-lit dancing",
    looks: [
        PersonLook(skin: RGB(0xFBE1D6), hair: RGB(0xE48FA8), hairStyle: .wavy, eyes: RGB(0xB5566E),
                   outfit: RGB(0xF4C3CF), outfitAccent: RGB(0xEFD9DC), accessory: .beanie, accessoryColor: RGB(0xF2B3C3),
                   styleNote: "A rose cardigan over a lacy blossom dress, pearl earrings, bow shoes, and a cloud of pink curls"),
    ],
    favoriteBreeds: ["cherryBlossomBunny", "pixelBunny", "auroraBunny"],
    lovedGifts: ["melodyMacarons", "roseMacaron", "cherry"],
    likedGifts: ["peachIce", "starberry", "strawberry", "cherrySundae"],
    dislikedGifts: ["peas", "clover"],
    schedule: [
        ScheduleSlot(time: .dawn, place: "Patchwork Atelier", emoji: "🧵", inMeadow: false),
        ScheduleSlot(time: .day, place: "Busking in the meadow", emoji: "🎸", inMeadow: true),
        ScheduleSlot(time: .dusk, place: "The bandstand", emoji: "🎶", inMeadow: true),
        ScheduleSlot(time: .night, place: "Sewing by lamplight", emoji: "🪡", inMeadow: false),
    ],
    activities: [
        SharedActivity(name: "Duet", emoji: "🎶",
                       friendLine: "Sol hands you a tambourine. You are terrible. Sol says you have “raw, untamed rhythm.” You both cry laughing.",
                       dateLine: "Sol sings the chorus of their meadow song and changes one word in it — to your name."),
        SharedActivity(name: "Sewing lesson", emoji: "🧵",
                       friendLine: "Sol teaches you a blanket stitch. You sew your sleeve to the pillow. Sol frames it.",
                       dateLine: "Sol stitches a tiny heart into the hem of your sleeve. “A secret,” they say. “Just between us.”"),
        SharedActivity(name: "Lantern dance", emoji: "🏮",
                       friendLine: "Sol teaches you a folk dance from a town they once toured. You step on their toes twelve times. They count out loud.",
                       dateLine: "Under the lanterns, Sol pulls you close for a slow dance. Neither of you hears the music anymore."),
    ],
    lines: DailyLines(
        early: [
            "Well, hello, new face! Want to hear a song? It's about a goose. It's mostly honking.",
            "I'm feeling very ruffles-and-ribbons today. Tomorrow? Who knows. That's the fun part.",
            "I've played in forty-two towns. None of them had bunnies this cute. Don't tell the other towns.",
        ],
        friend: [
            "I wrote a verse about you. Don't worry, it rhymes with “wonderful,” not “onion.”",
            "I used to leave every place before it could leave me. I haven't packed my bags in months. Weird, huh?",
            "Got a new jacket in the window. It'd look amazing on you. I may have made it for you.",
        ],
        romance: [
            "Every song I write lately is secretly about you. The secret is out. Oops.",
            "I'm not scared of staying anymore. Not with you here.",
            "Come to the bandstand tonight? I saved you the best seat. It's right next to me.",
        ],
        bestie: [
            "My favorite person! Want to make matching outfits? Say yes. You're saying yes.",
            "You're the chorus of my meadow song. Every verse comes back to you.",
            "I've never had a best friend who stayed. You stayed. I'm going to cry, give me a second.",
        ]
    ),
    questions: [
        Question(id: "sol-q1", prompt: "“If your life had a theme song, what would it sound like?”", answers: [
            Answer(text: "Something you'd write.", response: "Sol grins and grabs their notebook. “Challenge accepted.”", points: 15),
            Answer(text: "A cozy acoustic ballad.", response: "“Mm, I can hear it. Lots of warm strings.”", points: 10),
            Answer(text: "Elevator music.", response: "“Ha! Underrated genre. Very soothing.”", points: 5),
            Answer(text: "Something quieter than you.", response: "Sol's hands go still on the strings. “…Wow. Okay.”", points: 0, isRude: true),
        ]),
        Question(id: "sol-q2", prompt: "“What do you think makes someone stay somewhere?”", answers: [
            Answer(text: "Finding people who make them feel seen.", response: "Sol's voice goes soft. “Yeah. That's exactly it.”", points: 15),
            Answer(text: "A place that feels like it fits.", response: "“Like a good jacket. I like that.”", points: 10),
            Answer(text: "Running out of gas money.", response: "“Ha! That's how I got here, honestly.”", points: 5),
            Answer(text: "Nothing. People always leave.", response: "Sol looks away. “That's a sad way to see it.” The song they were humming stops.", points: 0, isRude: true),
        ]),
    ],
    quests: [
        Quest(id: "sol-1", personID: "sol", title: "Busking Snacks",
              description: "Sol plays better with strawberries. That's a scientific fact, they say.", requiredStage: .acquaintance,
              items: [ItemCount(itemID: "strawberry", count: 4)], points: 30, rewards: [.coins(70)]),
        Quest(id: "sol-2", personID: "sol", title: "Thread & Blossom",
              description: "Sol is dyeing fabric with flowers and needs chamomile and clover.", requiredStage: .friend,
              items: [ItemCount(itemID: "chamomile", count: 4), ItemCount(itemID: "clover", count: 4)], points: 40,
              rewards: [.gems(2), .hint("cherryBlossomBunny")]),
        Quest(id: "sol-3", personID: "sol", title: "Encore",
              description: "Sol is finishing their meadow song. They swear a bunny with shimmering wings and a halo of northern lights danced past at night, nibbling a rainbow-colored berry…",
              requiredStage: .closeFriend,
              items: [ItemCount(itemID: "jam", count: 1), ItemCount(itemID: "chamomileTea", count: 1)], points: 50,
              rewards: [.gems(3), .hint("auroraBunny")]),
    ],
    favoriteBunnyReaction: "Sol drops their guitar pick. “Is that a {breed}?” They kneel and {bunny} bumps their nose against Sol's hand. Sol starts humming, and the bunny sways along. “Oh, we're going to be in a band. Thank you. I'm writing you a song about this. Two songs.”",
    bunnyReaction: "Sol tips their hat to {bunny}. “Welcome to the Atelier, little star. I'll make you a scarf.”",
    showFavoriteReaction: "Sol gasps dramatically. “A {breed}! My heart! It's doing a drumroll!”",
    lovedGiftReaction: "“You know me so well! This is going in a song.”",
    likedGiftReaction: "“Ooh, lovely! Thank you, friend.”",
    neutralGiftReaction: "“Aw, thank you! Every gift's a little melody.”",
    dislikedGiftReaction: "“Ha, not quite my rhythm — but I love that you thought of me.”"
)

// MARK: - Rowan

private let rowan = Person(
    id: "rowan",
    name: "Rowan",
    fullName: "Rowan Calloway",
    pronouns: "he/him",
    gender: "Man",
    role: "Blacksmith at the stone forge",
    personality: "Quiet, steady, and dependable. Says little and means all of it, with a dry, gentle humor. Shows he cares by making and mending things instead of talking.",
    backstory: "Rowan grew up in his mother's forge in a mountain town, mending plows for people who couldn't always pay. When she passed, he loaded her anvil onto a cart and walked until he found somewhere quiet enough to think. Six years later he's still in the meadow, and he still keeps every thank-you note anyone has ever left on his doorstep, in a tin under the bed where no one will find it.",
    interests: "Forging, mending, stargazing from the warm forge roof, walks before dawn",
    looks: [
        PersonLook(skin: RGB(0xF3D2BF), hair: RGB(0xC1502E), hairStyle: .ponytail, eyes: RGB(0x5E9E4B),
                   outfit: RGB(0x6B4A33), outfitAccent: RGB(0xEFE6D6),
                   styleNote: "A cream linen shirt, a brown leather apron, a hammer at his belt, and a short copper ponytail"),
    ],
    favoriteBreeds: ["emberBunny", "cometBunny", "stormBunny"],
    lovedGifts: ["emberBake", "campfireStew", "moonMochi"],
    likedGifts: ["pumpkin", "sweetPotato", "corn", "turnip", "hazelnutBread", "pie", "muffin"],
    dislikedGifts: ["roseMacaron", "wisteria", "lilac"],
    schedule: [
        ScheduleSlot(time: .dawn, place: "Walking the meadow path before work", emoji: "🌄", inMeadow: true),
        ScheduleSlot(time: .day, place: "The stone forge", emoji: "⚒️", inMeadow: false),
        ScheduleSlot(time: .dusk, place: "Delivering mended tools around the meadow", emoji: "🧰", inMeadow: true),
        ScheduleSlot(time: .night, place: "Forge cottage, banking the fire", emoji: "🔥", inMeadow: false),
    ],
    activities: [
        SharedActivity(name: "Forge a Star Charm", emoji: "⭐️",
                       friendLine: "Rowan lets you work the bellows. Your star comes out lopsided. He hangs it over the forge door anyway. “It stays.”",
                       dateLine: "Rowan guides your hands on the hammer, his arms around yours. The star you make together is perfect. He keeps the one you botched, too."),
        SharedActivity(name: "Mend something together", emoji: "🔧",
                       friendLine: "You bring him a broken watering can. He fixes it in silence, then shows you how. Twice. He doesn't mind the second time.",
                       dateLine: "Rowan mends your watering can and engraves a tiny bunny on the handle. He pretends not to notice you noticing."),
        SharedActivity(name: "Stargazing on the forge roof", emoji: "🌙",
                       friendLine: "You climb onto the warm forge roof. Rowan names three constellations and says nothing else for an hour. It's the nicest hour of your week.",
                       dateLine: "On the warm roof, Rowan's hand finds yours in the dark. “Warmest spot in the meadow,” he says. He doesn't mean the roof."),
    ],
    lines: DailyLines(
        early: [
            "Mind the sparks. Everything I make, I make to last.",
            "Bring me what's broken. I'll see what I can do.",
            "Morning. Hm. Good day for it.",
        ],
        friend: [
            "Fixed your gate latch. It was squeaking. You don't have to say anything.",
            "Most people talk to fill the quiet. You don't. I like that.",
            "Made you a trowel. Balanced it for your hand. Took a few tries.",
        ],
        romance: [
            "I've made a thousand things to last. Never wanted anything to last this much.",
            "I'm not good with words. So I made you this instead. …It's a little iron heart. It won't break.",
            "Stay by the forge a while? It's warm. And you're here. That's two good things.",
        ],
        bestie: [
            "You and me, we're built the same. Sturdy. Not flashy. Good to lean on.",
            "I keep a tin of thank-you notes. Yours are on top.",
            "Need anything mended? Even if it's just a bad day. I'm good at those too.",
        ]
    ),
    questions: [
        Question(id: "rowan-q1", prompt: "“What's something you'd want to last forever?”", answers: [
            Answer(text: "This meadow, just like it is.", response: "Rowan nods slowly. “Then we'll look after it. Both of us.”", points: 15),
            Answer(text: "A really good pair of boots.", response: "A short laugh, surprised out of him. “Practical. I can make those.”", points: 10),
            Answer(text: "Nothing lasts forever.", response: "“No. But some things last long enough.”", points: 5),
            Answer(text: "Nothing you make, that's for sure.", response: "Rowan sets down his hammer. He says nothing at all, which is worse.", points: 0, isRude: true),
        ]),
        Question(id: "rowan-q2", prompt: "“Do you talk to the things you fix? …Never mind.”", answers: [
            Answer(text: "Always. They listen better.", response: "Rowan goes a little pink. “…They do, don't they.”", points: 15),
            Answer(text: "Only when they won't work.", response: "“Fair.”", points: 10),
            Answer(text: "That's a little odd.", response: "“Hm. Probably.”", points: 5),
            Answer(text: "That's weird. Don't be weird.", response: "Rowan's ears go red. “Forget I asked.” He turns back to the forge.", points: 0, isRude: true),
        ]),
    ],
    quests: [
        Quest(id: "rowan-1", personID: "rowan", title: "Fuel for the Forge",
              description: "Rowan has been at the anvil since dawn and forgot to eat. Sweet potatoes, please.", requiredStage: .acquaintance,
              items: [ItemCount(itemID: "sweetPotato", count: 6)], points: 30, rewards: [.coins(60)]),
        Quest(id: "rowan-2", personID: "rowan", title: "Bellows Weather",
              description: "A storm is rolling in and Rowan wants a hearty pot going before it hits. He says a rain-grey bunny was watching him from the hedge.",
              requiredStage: .friend,
              items: [ItemCount(itemID: "pumpkin", count: 2), ItemCount(itemID: "wheat", count: 6)], points: 40,
              rewards: [.gems(2), .hint("stormBunny")]),
        Quest(id: "rowan-3", personID: "rowan", title: "Embers at Dusk",
              description: "Rowan is forging new hinges for the whole meadow. He swears a bunny with glowing ember-red ears sat by the coals all night…",
              requiredStage: .closeFriend,
              items: [ItemCount(itemID: "turnip", count: 4), ItemCount(itemID: "hazelnutBread", count: 1)], points: 50,
              rewards: [.gems(3), .hint("emberBunny")]),
    ],
    favoriteBunnyReaction: "Rowan sets down his hammer. “A {breed}.” He kneels, very slowly, and {bunny} hops into his apron pocket like it's always lived there. He's quiet for a long moment. “…I'll make you a little bed by the forge. Warm. Safe. Thank you.”",
    bunnyReaction: "Rowan gives {bunny} a careful scratch with one big finger. “Welcome. Stay clear of the anvil.”",
    showFavoriteReaction: "Rowan stops mid-swing. “Is that a {breed}?” A rare, full smile. “Those are my favorite.”",
    lovedGiftReaction: "“…This is exactly what I needed. How did you know?”",
    likedGiftReaction: "“Good. Thank you. That'll keep me going.”",
    neutralGiftReaction: "“Hm. Thanks.”",
    dislikedGiftReaction: "“Pretty. Too delicate for a forge, though. I'd only break it. Still, thank you for thinking of me.”"
)

// MARK: - Silas

private let silas = Person(
    id: "silas",
    name: "Silas",
    fullName: "Silas Okafor-Bell",
    pronouns: "he/him",
    gender: "Man",
    role: "Beekeeper at the apiary cottage",
    personality: "Warm, gentle, and unhurried. A patient listener who talks in little bee and weather sayings, never raises his voice, and is the one everyone visits when the day has been too much.",
    backstory: "Silas inherited the apiary from his grandfather, along with forty hives, a straw hat, and the habit of telling the bees everything. He came here after years of working too hard in the city and promised himself he'd never rush anything again. Now he tends the hives, plants sunflowers for his bees, and keeps a kettle on for anyone who needs to sit a while.",
    interests: "Beekeeping, wildflowers, honey tasting, reading the weather",
    looks: [
        PersonLook(skin: RGB(0x5A3A28), hair: RGB(0x1C1614), hairStyle: .short, eyes: RGB(0xA8702F),
                   outfit: RGB(0xE8B64C), outfitAccent: RGB(0xF2E7CF),
                   styleNote: "A cream shirt, a honey-yellow vest with honeycomb trim, a golden honey-dipper pendant, and short black locs, with a few friendly bees nearby"),
    ],
    favoriteBreeds: ["honeybunBunny", "daffodilBunny", "goldenBunny"],
    lovedGifts: ["honeyCake", "honey", "chamomileTea"],
    likedGifts: ["sunflower", "lavender", "daffodil", "clover", "melon", "blueberry", "carrot"],
    dislikedGifts: ["campfireStew", "chili", "nightshade"],
    schedule: [
        ScheduleSlot(time: .dawn, place: "Apiary cottage, checking the hives", emoji: "🐝", inMeadow: false),
        ScheduleSlot(time: .day, place: "Gathering wildflowers in the meadow", emoji: "🌼", inMeadow: true),
        ScheduleSlot(time: .dusk, place: "Walking the meadow with his bees", emoji: "🌅", inMeadow: true),
        ScheduleSlot(time: .night, place: "Apiary cottage, kettle on", emoji: "🫖", inMeadow: false),
    ],
    activities: [
        SharedActivity(name: "Honey Tasting", emoji: "🍯",
                       friendLine: "Silas sets out six little jars. Clover, lavender, sunflower… He tells you a story about each one. You like the sunflower best. So does he.",
                       dateLine: "Silas feeds you a spoonful from the last jar. “Moonflower honey. I only ever made one batch.” He saved it for you."),
        SharedActivity(name: "Tend the hives", emoji: "🐝",
                       friendLine: "You help Silas check the hives in borrowed gloves. A bee lands on your nose. “She likes you,” he says. “Good sign.”",
                       dateLine: "Silas tells the bees your name. “You have to tell them the important things,” he says, very seriously. Then he kisses your hand."),
        SharedActivity(name: "Sunflower walk", emoji: "🌻",
                       friendLine: "You walk the sunflower rows at Silas's pace, which is slow. You notice twelve things you've never seen before.",
                       dateLine: "Silas tucks a sunflower behind your ear. “There. Now the bees will follow you too.” He walks very close the whole way home."),
    ],
    lines: DailyLines(
        early: [
            "The bees are calm tonight. They only hum like that when they are happy.",
            "Long day? Sit a minute. The kettle's always on.",
            "Smells like rain by evening. The bees are coming home early.",
        ],
        friend: [
            "You've been carrying a lot lately. You can set some of it down here.",
            "I told the bees about you. They approve. They're very picky.",
            "Saved you a jar of the good honey. Don't tell the others.",
        ],
        romance: [
            "My grandfather said you know it's love when the bees settle around someone. They settle around you.",
            "Everything slows down when you're here. In the best way. Like honey.",
            "Stay for supper? I'll make the honey cake. You can watch me pretend I'm not nervous.",
        ],
        bestie: [
            "Some people are like sunshine after rain. You're one of them.",
            "When your day is too much, you know where I am. Always.",
            "The bees know your footsteps now. That makes you family, in bee terms.",
        ]
    ),
    questions: [
        Question(id: "silas-q1", prompt: "“What helps you most after a hard day?”", answers: [
            Answer(text: "A friend who just listens.", response: "Silas smiles, slow and warm. “Then I'll keep listening.”", points: 15),
            Answer(text: "A hot drink and a blanket.", response: "“Ah. A person of good sense.”", points: 10),
            Answer(text: "I just keep working.", response: "“Hm. Even bees rest in winter, you know.”", points: 5),
            Answer(text: "Not you lecturing me about it.", response: "Silas nods slowly. “All right.” Even the bees go quiet.", points: 0, isRude: true),
        ]),
        Question(id: "silas-q2", prompt: "“If you were a flower, which would you be?”", answers: [
            Answer(text: "Lavender. Calm, and a little wild.", response: "“The bees' favorite,” Silas says, pleased. “Good choice.”", points: 15),
            Answer(text: "A dandelion. I grow anywhere.", response: "“Ha. Tough and cheerful. I can see it.”", points: 10),
            Answer(text: "I'd rather be a bee.", response: "Silas laughs. “Busy, buzzy, and a little bit stingy? Sure.”", points: 5),
            Answer(text: "Who cares? Flowers are boring.", response: "Silas's smile fades. “The bees would disagree. So do I.”", points: 0, isRude: true),
        ]),
    ],
    quests: [
        Quest(id: "silas-1", personID: "silas", title: "Flowers for the Hives",
              description: "Silas's bees need more blooms near the apiary. Sunflowers, please.", requiredStage: .acquaintance,
              items: [ItemCount(itemID: "sunflower", count: 5)], points: 30, rewards: [.coins(60)]),
        Quest(id: "silas-2", personID: "silas", title: "A Sweet Exchange",
              description: "Silas wants clover to plant for next season's honey. He mentions a sunny yellow bunny napping by the daffodils.",
              requiredStage: .friend,
              items: [ItemCount(itemID: "clover", count: 6), ItemCount(itemID: "daffodil", count: 3)], points: 40,
              rewards: [.gems(2), .hint("daffodilBunny")]),
        Quest(id: "silas-3", personID: "silas", title: "Golden Hour",
              description: "Silas is setting a honey harvest feast. While laying the table, he saw a bunny that shimmered like gold in the evening light…",
              requiredStage: .closeFriend,
              items: [ItemCount(itemID: "lavender", count: 4), ItemCount(itemID: "chamomileTea", count: 1)], points: 50,
              rewards: [.gems(3), .hint("goldenBunny")]),
    ],
    favoriteBunnyReaction: "Silas's whole face softens. “Oh, a {breed}.” {bunny} curls up in his hands while two bees circle overhead, perfectly calm. “Look at that. They've already decided you're family. Thank you, truly. I'll keep them safe and sweet.”",
    bunnyReaction: "Silas strokes {bunny} gently. “Welcome to the apiary. The bees won't mind you.”",
    showFavoriteReaction: "Silas lets out a slow, delighted breath. “A {breed}. My favorite. Isn't that a gift.”",
    lovedGiftReaction: "“Oh, you remembered. This is just the sweetest thing.”",
    likedGiftReaction: "“How lovely. Thank you. The bees will be jealous.”",
    neutralGiftReaction: "“That's kind of you. Thank you.”",
    dislikedGiftReaction: "“Ah, that's a bit too smoky for me. The bees don't care for it either. But I appreciate the thought, really.”"
)
