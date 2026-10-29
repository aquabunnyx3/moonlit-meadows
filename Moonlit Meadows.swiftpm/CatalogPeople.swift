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

/// A character you can befriend: one of the five main characters (who can also be romanced) or a villager.
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

    /// The five romanceable main characters.
    static let main: [Person] = [june, roz, theo, kai, sol]
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
        ]),
        Question(id: "june-q2", prompt: "“Do you ever feel like you're not where you're supposed to be?”", answers: [
            Answer(text: "Sometimes. But here feels right.", response: "“Me too. Here feels right. Especially lately.”", points: 15),
            Answer(text: "Everyone's figuring it out as they go.", response: "“That's… really comforting, actually. Thank you.”", points: 10),
            Answer(text: "Not really, no.", response: "“I envy that. Maybe you can teach me.”", points: 5),
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
        ]),
        Question(id: "roz-q2", prompt: "“Do you ever take a day off? Like, really off?”", answers: [
            Answer(text: "We should take one together.", response: "“A day off… with you? I could be talked into that.”", points: 15),
            Answer(text: "Rest is important, Roz.", response: "“Ugh, you sound like my mom. She's right too.”", points: 10),
            Answer(text: "Never. Grind forever!", response: "“Ha! A kindred spirit. Though… maybe neither of us should.”", points: 5),
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
        ]),
        Question(id: "theo-q2", prompt: "“What's something you miss?”", answers: [
            Answer(text: "Someone I lost. Like you miss Nonno.", response: "Theo is quiet a long time. “Then you understand. Thank you for telling me.”", points: 15),
            Answer(text: "Being a kid and not worrying.", response: "“Ah. The golden age of no taxes.”", points: 10),
            Answer(text: "Nothing. I live in the present.", response: "“Teach me that trick sometime.”", points: 5),
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
        ]),
        Question(id: "kai-q2", prompt: "“Be honest — are my puns funny?”", answers: [
            Answer(text: "They're terrible. I love them.", response: "“That's the nicest thing anyone's ever said to me.”", points: 15),
            Answer(text: "Some of them!", response: "“I'll take some!”", points: 10),
            Answer(text: "Please stop.", response: "“Never. But I respect the honesty.”", points: 5),
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
        ]),
        Question(id: "sol-q2", prompt: "“What do you think makes someone stay somewhere?”", answers: [
            Answer(text: "Finding people who make them feel seen.", response: "Sol's voice goes soft. “Yeah. That's exactly it.”", points: 15),
            Answer(text: "A place that feels like it fits.", response: "“Like a good jacket. I like that.”", points: 10),
            Answer(text: "Running out of gas money.", response: "“Ha! That's how I got here, honestly.”", points: 5),
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
