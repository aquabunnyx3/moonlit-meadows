import Foundation

struct StoryLine {
    enum Speaker {
        case narrator
        case person
        case you
    }

    let speaker: Speaker
    let text: String
}

struct StoryOption {
    let text: String
    let response: String
    let points: Int
    var setsPath: RelationshipPath?
}

struct StoryChoice {
    let prompt: String
    let options: [StoryOption]
}

/// A heart event: a short scene that unlocks at a relationship stage.
///
/// Chapters 1–3 are shared. Chapter 3 is the crossroads, where you choose romance or friendship.
/// Each path then has its own chapters, ending in a finale with a keepsake.
struct StoryEvent: Identifiable {
    enum PathRequirement {
        case any
        case romance
        case friendship
    }

    let id: String
    let personID: String
    let title: String
    let stage: RelationshipStage
    let path: PathRequirement
    let lines: [StoryLine]
    var choice: StoryChoice?
    let rewards: [Reward]
    var isCrossroads = false
    var isFinale = false

    static func find(_ id: String) -> StoryEvent? {
        all.first { $0.id == id }
    }

    static func events(for personID: String) -> [StoryEvent] {
        all.filter { $0.personID == personID }
    }

    static let all: [StoryEvent] = juneEvents + rozEvents + theoEvents + kaiEvents + solEvents + rowanEvents + silasEvents + imaniEvents + villagerEvents
}

private func n(_ text: String) -> StoryLine { StoryLine(speaker: .narrator, text: text) }
private func p(_ text: String) -> StoryLine { StoryLine(speaker: .person, text: text) }
private func y(_ text: String) -> StoryLine { StoryLine(speaker: .you, text: text) }

private func crossroads(_ personID: String, confess: String, friends: String, romanceReply: String, friendReply: String) -> StoryChoice {
    StoryChoice(prompt: "How do you feel?", options: [
        StoryOption(text: confess, response: romanceReply, points: 15, setsPath: .romance),
        StoryOption(text: friends, response: friendReply, points: 15, setsPath: .friendship),
    ])
}

// MARK: - June

private let juneEvents: [StoryEvent] = [
    StoryEvent(id: "june-1", personID: "june", title: "The Glasshouse", stage: .acquaintance, path: .any, lines: [
        n("You find June on her knees in the glasshouse, whispering to a wilted fern."),
        p("Oh! I— this is Gerald. He's having a hard week."),
        p("My grandmother kept this place alive for forty years. I'm trying not to be the one who loses it."),
        p("Here — this is her herbal posy recipe. She gave it to everyone she liked. I think… I'm supposed to give it to you."),
    ], choice: StoryChoice(prompt: "What do you say about Gerald?", options: [
        StoryOption(text: "“Gerald's lucky to have you.”", response: "June laughs, surprised. “I'll tell him you said so.”", points: 10),
        StoryOption(text: "“Want help repotting him?”", response: "“You'd do that? …Yes. Thank you.”", points: 10),
    ]), rewards: [.recipe("herbalPosy")]),
    StoryEvent(id: "june-2", personID: "june", title: "Rainy Day Reading", stage: .friend, path: .any, lines: [
        n("A storm rolls over the meadow. June waves you into the glasshouse, where rain drums on the glass."),
        p("I used to hate storms in the city. Here they sound like applause."),
        n("She reads you a passage from her grandmother's garden journal. Her voice gets steadier with every page."),
        p("I made you something. For your farm. So you have a little piece of the glasshouse."),
    ], choice: StoryChoice(prompt: "June looks nervous about the gift.", options: [
        StoryOption(text: "“It's perfect. I'll put it somewhere sunny.”", response: "June beams. “It likes morning light. Like me.”", points: 10),
        StoryOption(text: "“Will you show me how to care for it?”", response: "“Every week, if you want.” She sounds like she really hopes you do.", points: 10),
    ]), rewards: [.decor("herbPlanter"), .hint("fernBunny")]),
    StoryEvent(id: "june-3", personID: "june", title: "Lantern Moths", stage: .closeFriend, path: .any, lines: [
        n("At dusk, June takes you to the edge of the meadow, where soft moths glow over the lavender."),
        p("Grandma called them lantern moths. She said they only come out for people who are paying attention."),
        p("I've been paying attention to… a lot of things lately. Mostly you."),
        p("I don't know what this is. I just know I'm happier when you're around. I knitted you a cardigan, by the way. It's very green."),
    ], choice: crossroads("june",
        confess: "“I feel it too, June. More than friends.”",
        friends: "“You're one of my dearest friends. I treasure that.”",
        romanceReply: "June's breath catches. Then she laughs, bright and teary. “Okay. Okay! The moths were right.”",
        friendReply: "June smiles, warm and relieved. “Me too. You're my best person. That's a whole kind of love.”"),
    rewards: [.outfit("gardenerCardigan")], isCrossroads: true),
    StoryEvent(id: "june-r4", personID: "june", title: "Pressed Between Pages", stage: .romanticInterest, path: .romance, lines: [
        n("June hands you a book. Between the pages, a pressed clover from your first herb walk."),
        p("I keep everything from our days together. Is that silly?"),
        y("It's the opposite of silly."),
        p("Here — a sprig of lavender for your favorite bunny. So they smell like the glasshouse."),
    ], choice: StoryChoice(prompt: "June is blushing furiously.", options: [
        StoryOption(text: "Tuck a flower behind her ear.", response: "June goes completely still. Then she leans into your hand.", points: 15),
        StoryOption(text: "“Can I keep the clover?”", response: "“It was always yours,” she says softly.", points: 10),
    ]), rewards: [.accessory("lavenderSprig")]),
    StoryEvent(id: "june-r5", personID: "june", title: "A Date in Bloom", stage: .dating, path: .romance, lines: [
        n("June has decorated the glasshouse with fairy lights and a little table for two."),
        p("I made dinner. Everything's from the garden. Including the dessert. Don't ask how."),
        n("Halfway through, a Lavender bunny wanders in and falls asleep on June's foot. She doesn't dare move."),
        p("This is the best night I've had in years. Maybe ever."),
    ], choice: StoryChoice(prompt: "The candles flicker.", options: [
        StoryOption(text: "Hold her hand across the table.", response: "June laces her fingers through yours like she's been waiting all night.", points: 15),
        StoryOption(text: "“Let's do this every week.”", response: "“Every week,” she promises. “Rain or shine.”", points: 10),
    ]), rewards: [.decor("pressedFlowerArch")]),
    StoryEvent(id: "june-r6", personID: "june", title: "Rooted", stage: .committed, path: .romance, lines: [
        n("June meets you under the oldest tree in the meadow, holding a letter sealed with lavender."),
        p("I wrote it down because I'm braver on paper. But I want to say it out loud, too."),
        p("I came here to hide. Then I met you, and I stopped hiding. I love you. I want to grow old in this meadow with you."),
        n("The lantern moths rise around you both, glowing like they've been waiting for this."),
    ], choice: StoryChoice(prompt: "June waits, holding her breath.", options: [
        StoryOption(text: "“I love you too. Let's grow together.”", response: "June throws her arms around you, laughing and crying at once.", points: 20),
        StoryOption(text: "Kiss her forehead and say yes.", response: "“Yes,” she echoes, like a promise. “Yes, yes.”", points: 20),
    ]), rewards: [.keepsake("flowerLetter"), .gems(10)], isFinale: true),
    StoryEvent(id: "june-f4", personID: "june", title: "Book Club of Two", stage: .romanticInterest, path: .friendship, lines: [
        n("June founds the Rainy Day Book Club. Members: you, her, and a sleeping Lavender bunny."),
        p("I've never had a best friend before. I looked up how to do it. The internet said snacks."),
        p("Also, I made this for your bunnies. A lavender sprig. Very calming. Very official club merch."),
    ], choice: StoryChoice(prompt: "June hands you a laminated membership card.", options: [
        StoryOption(text: "“I'll treasure it forever.”", response: "“It's laminated,” she says proudly. “It will last forever.”", points: 15),
        StoryOption(text: "“Can the bunnies vote?”", response: "“Only on snack choices.”", points: 10),
    ]), rewards: [.accessory("lavenderSprig")]),
    StoryEvent(id: "june-f6", personID: "june", title: "Grandmother's Garden", stage: .committed, path: .friendship, lines: [
        n("June takes you to a corner of the glasshouse you've never seen: her grandmother's private garden."),
        p("Nobody's been in here since she passed. I wanted the first person to be you."),
        p("She'd say you're the kind of friend you plant a tree for. So here — seeds from her garden. Wherever you go, you'll have a little of this place."),
    ], choice: StoryChoice(prompt: "June presses a tiny locket into your palm.", options: [
        StoryOption(text: "“I'm not going anywhere, June.”", response: "“I know,” she says, and for the first time she sounds certain.", points: 20),
        StoryOption(text: "Hug her tight.", response: "June hugs back hard, the way people do when they've missed hugs.", points: 20),
    ]), rewards: [.keepsake("seedLocket"), .gems(10)], isFinale: true),
]

// MARK: - Roz

private let rozEvents: [StoryEvent] = [
    StoryEvent(id: "roz-1", personID: "roz", title: "Sweet Pea", stage: .acquaintance, path: .any, lines: [
        n("Roz drags you into the Sweet Burrow before you can say hello."),
        p("You! Taste this. No, this one. No, BOTH."),
        p("Okay, you've got good instincts. Here — my sunrise shortcake. Family recipe. Don't tell my grandma I shared it."),
        p("From now on you're Sweet Pea. That's not up for discussion."),
    ], choice: StoryChoice(prompt: "Roz waits for your verdict, flour on her nose.", options: [
        StoryOption(text: "“Best thing I've ever eaten.”", response: "“I KNOW. But thank you for saying it.”", points: 10),
        StoryOption(text: "Point out the flour on her nose.", response: "Roz wipes it and leaves more. “It's a signature look.”", points: 10),
    ]), rewards: [.recipe("sunriseShortcake")]),
    StoryEvent(id: "roz-2", personID: "roz", title: "After Closing", stage: .friend, path: .any, lines: [
        n("You find Roz sitting on the bakery floor after closing, back against the oven."),
        p("Don't look at me like that. I'm fine. I'm just… tired. I'm always tired."),
        p("My whole life, someone needed feeding. I don't know how to stop."),
        n("You sit beside her. After a while, she rests her head on your shoulder."),
        p("Thanks. Here — take this cake stand. You'll put it out and think of me. It's a trap. A sweet one."),
    ], choice: StoryChoice(prompt: "What do you tell her?", options: [
        StoryOption(text: "“Let someone feed you for once.”", response: "Roz blinks hard. “…Okay. Maybe. Yeah.”", points: 10),
        StoryOption(text: "“Rest is part of the recipe.”", response: "“Ugh. That's good. I'm stealing that.”", points: 10),
    ]), rewards: [.decor("cakeStand"), .hint("butterscotchBunny")]),
    StoryEvent(id: "roz-3", personID: "roz", title: "The Midnight Cake", stage: .closeFriend, path: .any, lines: [
        n("Roz calls you at midnight. “Emergency. Bring an apron.” It is not an emergency. It's a cake."),
        p("I wanted to make something with you. Not for a customer. Just for us."),
        n("The cake is lopsided and perfect. Roz is quieter than usual. She keeps glancing at you."),
        p("Sweet Pea… I don't know how to say this without a pastry metaphor. You make everything warmer. I made you an apron, by the way. It matches mine."),
    ], choice: crossroads("roz",
        confess: "“Roz, I think I'm falling for you.”",
        friends: "“You're family to me, Roz. My favorite family.”",
        romanceReply: "Roz drops the spatula. Then she laughs — that huge, room-filling laugh. “Oh, thank goodness. Me too!”",
        friendReply: "Roz grins and pulls you into a crushing hug. “Family. Yeah. Best family.”"),
    rewards: [.outfit("bakerApron")], isCrossroads: true),
    StoryEvent(id: "roz-r4", personID: "roz", title: "Slow Morning", stage: .romanticInterest, path: .romance, lines: [
        n("For the first time in years, the Sweet Burrow opens late. Roz is sitting with you on the bench out front, drinking coffee."),
        p("My siblings think I've been replaced by a pod person. I took a MORNING OFF."),
        p("I made your bunnies little strawberry bows. Don't laugh. Okay, you can laugh."),
    ], choice: StoryChoice(prompt: "Roz leans against your shoulder.", options: [
        StoryOption(text: "“You look happy.”", response: "“I am. It's weird. I love it.”", points: 15),
        StoryOption(text: "“Let's do nothing more often.”", response: "“Doing nothing with you is my new favorite thing.”", points: 10),
    ]), rewards: [.accessory("strawberryBow")]),
    StoryEvent(id: "roz-r5", personID: "roz", title: "A Table for Two", stage: .dating, path: .romance, lines: [
        n("Roz closes the bakery early and sets one table with a candle and an absurd number of desserts."),
        p("I made a tasting menu. Twelve courses. All dessert. This is my love language, deal with it."),
        n("Course seven is a tiny cake shaped like two bunnies holding paws."),
        p("That one's just for decoration. It's us. Okay, it's a little bit us."),
    ], choice: StoryChoice(prompt: "Roz is looking at you instead of the cake.", options: [
        StoryOption(text: "Feed her a bite of course twelve.", response: "Roz laughs into the fork, then kisses your cheek, sticky with frosting.", points: 15),
        StoryOption(text: "“It's the best date I've ever had.”", response: "“Better than the cake?” “Better than the cake.” “Wow.”", points: 10),
    ]), rewards: [.decor("loveCake")]),
    StoryEvent(id: "roz-r6", personID: "roz", title: "Recipe for Forever", stage: .committed, path: .romance, lines: [
        n("Roz invites you to Sunday dinner with all six siblings. It is chaos. It is wonderful."),
        n("Afterwards, on the porch, she hands you a whisk bent into the shape of a heart."),
        p("I'm not good at slow things. But I want to do the slowest thing with you: everything. Forever. Bake with me forever?"),
    ], choice: StoryChoice(prompt: "Roz's hands are shaking just a little.", options: [
        StoryOption(text: "“Forever sounds perfect.”", response: "Roz whoops so loudly that all six siblings cheer from inside.", points: 20),
        StoryOption(text: "Kiss her instead of answering.", response: "“…Is that a yes?” You nod. “That's a YES!”", points: 20),
    ]), rewards: [.keepsake("heartWhisk"), .gems(10)], isFinale: true),
    StoryEvent(id: "roz-f4", personID: "roz", title: "Bakery Besties", stage: .romanticInterest, path: .friendship, lines: [
        n("Roz hangs a sign in the bakery: “EMPLOYEE OF THE MONTH: SWEET PEA.” You don't work there."),
        p("Honorary employee. Lifetime position. Benefits include unlimited scones."),
        p("Oh, and your bunnies get uniforms. Strawberry bows. They're mandatory."),
    ], choice: StoryChoice(prompt: "Roz salutes you.", options: [
        StoryOption(text: "Salute back.", response: "“Ha! Welcome to the team!”", points: 15),
        StoryOption(text: "“I demand a raise.”", response: "“Your raise is TWO scones.”", points: 10),
    ]), rewards: [.accessory("strawberryBow")]),
    StoryEvent(id: "roz-f6", personID: "roz", title: "Family Recipes", stage: .committed, path: .friendship, lines: [
        n("Roz invites you to Sunday dinner. All six siblings greet you by name. They've heard everything."),
        n("Afterwards, Roz hands you her family's recipe book. There's a new page at the back, in her handwriting: “Sweet Pea's Shortcake.”"),
        p("Family recipes are for family. You're in the book now. No take-backs."),
    ], choice: StoryChoice(prompt: "You look at your page.", options: [
        StoryOption(text: "“Thank you for choosing me, Roz.”", response: "“Pfft. You chose us first.” She hugs you hard.", points: 20),
        StoryOption(text: "“Next Sunday, I'm cooking.”", response: "Every sibling cheers. Roz pretends to faint.", points: 20),
    ]), rewards: [.keepsake("recipeBook"), .gems(10)], isFinale: true),
]

// MARK: - Theo

private let theoEvents: [StoryEvent] = [
    StoryEvent(id: "theo-1", personID: "theo", title: "The Observatory", stage: .acquaintance, path: .any, lines: [
        n("You climb the hill at dusk and find Theo fighting a very old telescope."),
        p("It's fine. It's fine. It does this. It's ninety years old and dramatic."),
        p("…You can come look, if you want. Saturn's up."),
        n("Through the lens, Saturn's rings are impossibly tiny and perfect. Theo watches you instead of the planet."),
        p("Here. My stargazer cocoa recipe. You'll need it if you keep coming up here. It's cold. I mean — if. If you keep coming."),
    ], choice: StoryChoice(prompt: "Theo is fidgeting with the lens cap.", options: [
        StoryOption(text: "“I'll keep coming.”", response: "Theo looks away fast. “Good. Fine. Good.”", points: 10),
        StoryOption(text: "“Saturn is beautiful.”", response: "“It is. Most people don't stop to look.”", points: 10),
    ]), rewards: [.recipe("stargazerCocoa")]),
    StoryEvent(id: "theo-2", personID: "theo", title: "Nonno's Chair", stage: .friend, path: .any, lines: [
        n("There are two chairs in the observatory. Theo always sits in the left one."),
        p("The right one was Nonno's. I haven't let anyone sit in it."),
        p("…You can. If you want. I think he'd want someone to."),
        n("You sit. The stars feel closer. Theo tells you about the night Nonno taught him Orion."),
        p("Here. A spare telescope for your farm. So you can look up even when I'm not around."),
    ], choice: StoryChoice(prompt: "Theo's voice wavers at the end.", options: [
        StoryOption(text: "“Tell me more about him.”", response: "Theo talks until the moon sets. He smiles more than you've ever seen.", points: 10),
        StoryOption(text: "Sit quietly with him.", response: "After a long time, Theo whispers, “Thank you. This helps.”", points: 10),
    ]), rewards: [.decor("telescope"), .hint("velvetBunny")]),
    StoryEvent(id: "theo-3", personID: "theo", title: "The Brightest Star", stage: .closeFriend, path: .any, lines: [
        n("A meteor shower. Theo spreads a blanket on the hill and you count shooting stars."),
        p("Fourteen. Fifteen. I'm keeping score. You're losing."),
        n("Then, quieter:"),
        p("I didn't think I'd ever want to share the sky with anyone again. And then you sat in Nonno's chair. Also, I knitted you a sweater. Badly. It has stars on it."),
    ], choice: crossroads("theo",
        confess: "“I'd share every sky with you, Theo.”",
        friends: "“You're my favorite stargazing partner. Always.”",
        romanceReply: "Theo laughs softly, disbelieving. “Statistically, this was unlikely. I'm very glad it happened.”",
        friendReply: "Theo nods, and his smile is real. “Always. That's a long time. I'm counting on it.”"),
    rewards: [.outfit("starrySweater")], isCrossroads: true),
    StoryEvent(id: "theo-r4", personID: "theo", title: "Constellation Lessons", stage: .romanticInterest, path: .romance, lines: [
        n("Theo is teaching you to find Lyra. His hand guides yours across the sky."),
        p("There. Vega. I told you I'd been thinking of calling it your star. I wasn't kidding."),
        p("I made your bunnies little star pins. So they match the sky."),
    ], choice: StoryChoice(prompt: "Theo hasn't let go of your hand.", options: [
        StoryOption(text: "Lace your fingers through his.", response: "Theo's breath fogs in the cold. “Okay,” he whispers. “Okay.”", points: 15),
        StoryOption(text: "“Which one is yours?”", response: "“I don't have one.” He pauses. “Maybe you can pick.”", points: 10),
    ]), rewards: [.accessory("starPin")]),
    StoryEvent(id: "theo-r5", personID: "theo", title: "Picnic on the Moon", stage: .dating, path: .romance, lines: [
        n("Theo has strung tiny lights in the shape of a bunny constellation across the observatory dome."),
        p("I may have spent three weeks on this. Don't tell anyone. I have a reputation."),
        p("It's called Lepus. The hare. Nonno said it's always running toward something it loves."),
    ], choice: StoryChoice(prompt: "The lights twinkle overhead.", options: [
        StoryOption(text: "Kiss him under Lepus.", response: "Theo's hood slips back. Neither of you notices.", points: 15),
        StoryOption(text: "“It's the most romantic thing anyone's done for me.”", response: "“Good,” he says, a little smug. “That was the goal.”", points: 10),
    ]), rewards: [.decor("constellationLights")]),
    StoryEvent(id: "theo-r6", personID: "theo", title: "A Star With Your Name", stage: .committed, path: .romance, lines: [
        n("Theo hands you a framed certificate. A star, officially named after you. Below his signature is a second one: “& Nonno.”"),
        p("He would've liked you so much. He'd have embarrassed me constantly."),
        p("I spent years looking up because I was afraid to look around. Now I look at you. I love you. Will you keep stargazing with me — for good?"),
    ], choice: StoryChoice(prompt: "The sky is perfectly clear tonight.", options: [
        StoryOption(text: "“For as long as there are stars.”", response: "“That's about five billion years,” he says, voice thick. “Deal.”", points: 20),
        StoryOption(text: "Pull him into a hug.", response: "Theo holds on like you're the only fixed point in the sky.", points: 20),
    ]), rewards: [.keepsake("namedStar"), .gems(10)], isFinale: true),
    StoryEvent(id: "theo-f4", personID: "theo", title: "Observatory Club", stage: .romanticInterest, path: .friendship, lines: [
        n("Theo has made two membership badges: “Observatory Club, Est. This Year.”"),
        p("Club rules: one, no talking during meteor showers. Two, cocoa is mandatory. Three, you're the vice president."),
        p("Your bunnies get star pins. They're junior members."),
    ], choice: StoryChoice(prompt: "Theo pins the badge on you very seriously.", options: [
        StoryOption(text: "“Who's president?”", response: "“Nonno. Honorary. Forever.” He smiles.", points: 15),
        StoryOption(text: "“I accept with honor.”", response: "Theo salutes. He is trying very hard not to grin.", points: 10),
    ]), rewards: [.accessory("starPin")]),
    StoryEvent(id: "theo-f6", personID: "theo", title: "Nonno's Chart", stage: .committed, path: .friendship, lines: [
        n("Theo unrolls an old, hand-inked star chart across the observatory desk."),
        p("Nonno made this. Every star he taught me is on it. I want you to have it."),
        p("You helped me look at the sky again without it hurting. That's… what a best friend does, I think. I didn't know until you."),
    ], choice: StoryChoice(prompt: "The chart is soft with age.", options: [
        StoryOption(text: "“Let's add new stars to it together.”", response: "Theo's eyes shine. “He'd love that. Yes.”", points: 20),
        StoryOption(text: "“I'll take care of it, Theo.”", response: "“I know. That's why it's yours.”", points: 20),
    ]), rewards: [.keepsake("starChart"), .gems(10)], isFinale: true),
]

// MARK: - Kai

private let kaiEvents: [StoryEvent] = [
    StoryEvent(id: "kai-1", personID: "kai", title: "Helping Hands", stage: .acquaintance, path: .any, lines: [
        n("Your fence has a broken post. Before you can grab a hammer, Kai is already there."),
        p("Saw it on my jog! Don't worry, I've got it. Ow. I've got it."),
        n("He fixes it in ten minutes, then stays for lunch. You make stew. He's amazed."),
        p("Okay, you have to teach me — wait, here, I'll teach YOU my campfire stew. Trade secrets!"),
    ], choice: StoryChoice(prompt: "Kai is shaking out his hammered thumb.", options: [
        StoryOption(text: "Bandage his thumb.", response: "Kai goes a little pink. “Ha. Thanks. Nobody usually notices.”", points: 10),
        StoryOption(text: "“You didn't have to help.”", response: "“I know! I wanted to. That's the best kind.”", points: 10),
    ]), rewards: [.recipe("campfireStew")]),
    StoryEvent(id: "kai-2", personID: "kai", title: "A Hutch for Everyone", stage: .friend, path: .any, lines: [
        n("Kai shows you his woodshop. Every shelf is full of tiny hutches, birdhouses, and benches — all for other people."),
        y("Have you built anything for yourself?"),
        p("Me? Nah. I never stayed anywhere long enough to need stuff."),
        n("He goes quiet, then shakes it off with a grin."),
        p("Anyway! This one's for your bunnies. Two floors. Look at the little door!"),
    ], choice: StoryChoice(prompt: "Kai is waiting for your reaction.", options: [
        StoryOption(text: "“You deserve a home too, Kai.”", response: "Kai's grin falters. Then, softly: “…Maybe I'm starting one.”", points: 10),
        StoryOption(text: "“It's the best hutch in the meadow.”", response: "“RIGHT? It has a balcony!”", points: 10),
    ]), rewards: [.decor("bunnyHutch"), .hint("hazelBunny")]),
    StoryEvent(id: "kai-3", personID: "kai", title: "Sunrise on the Hill", stage: .closeFriend, path: .any, lines: [
        n("Kai convinces you to climb the hill before dawn. He brings two thermoses and trips only once."),
        p("I've watched a hundred sunrises alone. Wanted to see one with someone who matters."),
        n("The sky goes pink, then gold."),
        p("You matter a lot. Like — a lot a lot. Also I got you overalls. They match mine. That's not weird, right?"),
    ], choice: crossroads("kai",
        confess: "“Kai, I think I'm in love with you.”",
        friends: "“You're my best friend, Kai. My family.”",
        romanceReply: "Kai drops his thermos. It rolls all the way down the hill. Neither of you chases it. “You— really? Me?”",
        friendReply: "Kai laughs and tackles you into a hug. “Family! I have FAMILY! Okay, I'm gonna cry a little.”"),
    rewards: [.outfit("carpenterOveralls")], isCrossroads: true),
    StoryEvent(id: "kai-r4", personID: "kai", title: "Measuring Twice", stage: .romanticInterest, path: .romance, lines: [
        n("Kai asks you to hold one end of a measuring tape. He keeps walking closer instead of measuring."),
        p("Sorry. You're distracting. In a good way. In the best way."),
        p("I made tiny hard hats for your bunnies. Safety first, cuteness second. Actually, cuteness first."),
    ], choice: StoryChoice(prompt: "Kai is standing very close now.", options: [
        StoryOption(text: "“Measure twice, kiss once?”", response: "Kai laughs so hard he has to sit on a sawhorse. Then he kisses you.", points: 15),
        StoryOption(text: "Straighten his blueberry clip.", response: "Kai goes completely red. “You can't just DO that.”", points: 10),
    ]), rewards: [.accessory("tinyHardHat")]),
    StoryEvent(id: "kai-r5", personID: "kai", title: "Porch Swing", stage: .dating, path: .romance, lines: [
        n("Kai leads you to your farm with his hands over your eyes. When he lets go, there's a porch swing — just big enough for two."),
        p("I carved bunnies on the arms. That one's yours. That one's mine. They're holding paws."),
        n("You swing together until the stars come out."),
    ], choice: StoryChoice(prompt: "Kai's arm is around your shoulders.", options: [
        StoryOption(text: "Rest your head on his chest.", response: "You can hear his heartbeat. It's going very fast.", points: 15),
        StoryOption(text: "“You built this for us?”", response: "“For us,” he says, like he's tasting a new word.", points: 10),
    ]), rewards: [.decor("porchSwing")]),
    StoryEvent(id: "kai-r6", personID: "kai", title: "The First Beam", stage: .committed, path: .romance, lines: [
        n("Kai shows you a clearing at the edge of the meadow. There's a single wooden beam set into the ground."),
        p("First thing I've ever built for me. Well — for us. If you want. A house. Our house."),
        n("He hands you a heart carved from the same wood."),
        p("I never had a home. I think it was because I was waiting for you. I love you. Will you build a life with me?"),
    ], choice: StoryChoice(prompt: "Kai's hands are shaking around the carved heart.", options: [
        StoryOption(text: "“Yes. Let's build it together.”", response: "Kai whoops, lifts you off the ground, and spins you until you're both dizzy.", points: 20),
        StoryOption(text: "Take his hands in yours.", response: "“Steady,” you say. Kai laughs, eyes wet. “Steady. Yeah. With you, always.”", points: 20),
    ]), rewards: [.keepsake("carvedHeart"), .gems(10)], isFinale: true),
    StoryEvent(id: "kai-f4", personID: "kai", title: "Partners", stage: .romanticInterest, path: .friendship, lines: [
        n("Kai paints a sign for the woodshop: “KAI & FRIEND, BUILDERS.” Then he crosses out FRIEND and writes BEST FRIEND."),
        p("Partners in crime! Well. Partners in carpentry. Less crime."),
        p("Your bunnies get hard hats. They're on the crew now."),
    ], choice: StoryChoice(prompt: "Kai offers a fist bump.", options: [
        StoryOption(text: "Fist bump.", response: "Kai makes an explosion sound. You both do.", points: 15),
        StoryOption(text: "“What's our first job?”", response: "“Treehouse. For bunnies. Two stories. Maybe three.”", points: 10),
    ]), rewards: [.accessory("tinyHardHat")]),
    StoryEvent(id: "kai-f6", personID: "kai", title: "Matching Tool Belts", stage: .committed, path: .friendship, lines: [
        n("Kai finishes his first house — for himself. He invites you to the housewarming. You're the only guest. You're the guest of honor."),
        p("I built a spare room. For you. For whenever. Because family has a room."),
        p("And these. Matching tool belts. Yours has a bunny patch. Partners forever."),
    ], choice: StoryChoice(prompt: "Kai looks at you, nervous and hopeful.", options: [
        StoryOption(text: "“I'm proud of you, Kai.”", response: "Kai has to look at the ceiling for a second. “Nobody's ever said that to me.”", points: 20),
        StoryOption(text: "Put on the tool belt.", response: "“LOOK AT US,” Kai yells. “Unstoppable!”", points: 20),
    ]), rewards: [.keepsake("toolBelt"), .gems(10)], isFinale: true),
]

// MARK: - Sol

private let solEvents: [StoryEvent] = [
    StoryEvent(id: "sol-1", personID: "sol", title: "Busking in the Meadow", stage: .acquaintance, path: .any, lines: [
        n("Sol is playing guitar in the middle of the meadow, surrounded by an audience of bunnies."),
        p("My biggest crowd yet! They're very polite. No heckling."),
        p("Sing the chorus with me? It's just “la la la.” You can't get it wrong."),
        n("You get it wrong. Sol plays louder to cover you, grinning."),
        p("Here — my melody macaron recipe. Bake them and hum while you do. That's the secret ingredient."),
    ], choice: StoryChoice(prompt: "Sol bows to the bunnies.", options: [
        StoryOption(text: "Applaud loudly.", response: "Sol takes three more bows. “Thank you, thank you, I'm here all week!”", points: 10),
        StoryOption(text: "“Play another one?”", response: "Sol's whole face lights up. “For you? I'll play ten.”", points: 10),
    ]), rewards: [.recipe("melodyMacarons")]),
    StoryEvent(id: "sol-2", personID: "sol", title: "The Atelier", stage: .friend, path: .any, lines: [
        n("Sol's shop is a rainbow of fabric scraps. Outfits hang everywhere — frilly, sharp, cozy, wild."),
        p("I dress how I feel. Some days I'm all ribbons, some days I'm all suspenders. Today I'm… somewhere fun in between."),
        p("People used to ask me to pick one. I don't have to. Neither does a song — it can change key and still be itself."),
        p("Oh! I made a little music box for your farm. It plays my meadow song. Well — the first half. I haven't finished it."),
    ], choice: StoryChoice(prompt: "Sol holds up two scarves, one in each hand.", options: [
        StoryOption(text: "“Why not wear both?”", response: "Sol gasps. “Genius. Visionary. Both it is.”", points: 10),
        StoryOption(text: "“Why haven't you finished the song?”", response: "Sol's smile flickers. “Finishing means staying. I'm… working on that.”", points: 10),
    ]), rewards: [.decor("musicBox"), .hint("daffodilBunny")]),
    StoryEvent(id: "sol-3", personID: "sol", title: "Unpacked", stage: .closeFriend, path: .any, lines: [
        n("Sol shows you a dusty suitcase in the back of the Atelier."),
        p("I used to keep this packed. Every town, every season. Ready to run."),
        n("They open it. It's empty."),
        p("I unpacked it last week. Because of the meadow. Because of… you, mostly. Also I made you a patchwork jacket. Every scrap is from a town I left. You're the town I stayed in."),
    ], choice: crossroads("sol",
        confess: "“Sol, I want you to stay — with me.”",
        friends: "“You're my dearest friend, Sol. Stay, and we'll be family.”",
        romanceReply: "Sol laughs, then cries, then laughs again. “Oh, I'm absolutely writing a song about this.”",
        friendReply: "Sol hugs you so tight you squeak. “Family. I've never had one that stayed. Now I do.”"),
    rewards: [.outfit("patchworkJacket")], isCrossroads: true),
    StoryEvent(id: "sol-r4", personID: "sol", title: "Second Verse", stage: .romanticInterest, path: .romance, lines: [
        n("Sol plays you the second verse of the meadow song. It's about two people sharing an umbrella in the rain."),
        p("That one's based on a true story. You were there. Remember? You held the umbrella so I'd stay dry and got soaked."),
        p("I sewed ribbon bows for your bunnies. They're very dashing now."),
    ], choice: StoryChoice(prompt: "Sol strums one last chord and waits.", options: [
        StoryOption(text: "“Play it again.”", response: "Sol plays it again. This time, they sing it looking right at you.", points: 15),
        StoryOption(text: "Sit closer to them.", response: "Sol leans into you mid-strum. The song gets a little softer.", points: 10),
    ]), rewards: [.accessory("ribbonBow")]),
    StoryEvent(id: "sol-r5", personID: "sol", title: "Lantern Dance", stage: .dating, path: .romance, lines: [
        n("Sol has turned the meadow bandstand into a dance floor, strung with lanterns and bunny bunting."),
        p("Private concert. Audience of one. Two, if you count the Cherry Blossom bunny. Three. There are many bunnies."),
        n("They teach you a slow dance. You step on their toes. They don't count this time."),
    ], choice: StoryChoice(prompt: "The lanterns sway above you.", options: [
        StoryOption(text: "Dip them dramatically.", response: "Sol shrieks with laughter. “Yes! Again!”", points: 15),
        StoryOption(text: "Kiss them as the song ends.", response: "The last note hangs in the air. Sol forgets to play the next one.", points: 15),
    ]), rewards: [.decor("duetBandstand")]),
    StoryEvent(id: "sol-r6", personID: "sol", title: "The Last Verse", stage: .committed, path: .romance, lines: [
        n("The whole meadow gathers at the bandstand. Sol is finally playing the finished song."),
        n("The last verse has your name in it."),
        p("I spent my whole life singing about places I was leaving. This is the first song about a place I'm staying. With the person I'm staying for."),
        p("I love you. Will you be my home?"),
    ], choice: StoryChoice(prompt: "Everyone is very quiet. Even the bunnies.", options: [
        StoryOption(text: "“Always. You're mine, too.”", response: "Sol drops the guitar (gently, it's vintage) and runs to you. The meadow cheers.", points: 20),
        StoryOption(text: "Climb onstage and hug them.", response: "Sol laughs into your shoulder. “Best encore ever.”", points: 20),
    ]), rewards: [.keepsake("songForYou"), .gems(10)], isFinale: true),
    StoryEvent(id: "sol-f4", personID: "sol", title: "Matching Outfits", stage: .romanticInterest, path: .friendship, lines: [
        n("Sol presents two matching outfits. They are extremely sparkly."),
        p("Best friends who dress together, stress together. That's the saying. I made up the saying."),
        p("Also, ribbon bows for the bunnies. They're in the band now."),
    ], choice: StoryChoice(prompt: "Sol is already wearing theirs.", options: [
        StoryOption(text: "Put yours on immediately.", response: "Sol screams with joy and takes forty photos.", points: 15),
        StoryOption(text: "“Can I add a cape?”", response: "“Can you— OF COURSE you can add a cape.”", points: 10),
    ]), rewards: [.accessory("ribbonBow")]),
    StoryEvent(id: "sol-f6", personID: "sol", title: "Chorus", stage: .committed, path: .friendship, lines: [
        n("Sol plays the finished meadow song for the whole village. The chorus is about a friend who made them stay."),
        n("Afterwards, they tie a bracelet around your wrist, woven from scraps of every outfit they've made you."),
        p("You're the chorus. Every verse of my life comes back to you now. Best friends. Forever. That's a rhyme, technically."),
    ], choice: StoryChoice(prompt: "Sol ties the bracelet carefully.", options: [
        StoryOption(text: "“Forever's a rhyme with forever.”", response: "“It counts!” Sol laughs, eyes shiny.", points: 20),
        StoryOption(text: "Make them one back.", response: "You fumble a messy knot. Sol wears it every single day.", points: 20),
    ]), rewards: [.keepsake("friendshipBracelet"), .gems(10)], isFinale: true),
]

// MARK: - Rowan

private let rowanEvents: [StoryEvent] = [
    StoryEvent(id: "rowan-1", personID: "rowan", title: "The Quiet Forge", stage: .acquaintance, path: .any, lines: [
        n("Your hoe snaps in half. A neighbor points you to the stone forge with the smoking chimney."),
        p("Hm. Bad steel. Not your fault."),
        n("Rowan fixes it while you wait. He doesn't make small talk. Somehow, it isn't awkward."),
        p("Here. Should outlast us both. And take this. A recipe. My mother's. Too hearty for one person."),
    ], choice: StoryChoice(prompt: "Rowan wipes his hands on his apron.", options: [
        StoryOption(text: "“Thank you. Really.”", response: "Rowan nods once. Later, you see him tuck your thank-you into his apron pocket like something precious.", points: 10),
        StoryOption(text: "“Can I watch you work sometime?”", response: "A pause. “…If you mind the sparks.”", points: 10),
    ]), rewards: [.recipe("emberBake")]),
    StoryEvent(id: "rowan-2", personID: "rowan", title: "The Tin of Notes", stage: .friend, path: .any, lines: [
        n("You drop by to return a borrowed trowel. Rowan isn't home, but his door is open, and a dented tin has tipped over by the bed."),
        n("It's full of notes. Thank-yous, hundreds of them. Some are years old. One is yours."),
        p("…Ah. You found that."),
        p("People say thank you and forget. I don't. Seemed wrong to throw them out."),
    ], choice: StoryChoice(prompt: "Rowan is very carefully not looking at you.", options: [
        StoryOption(text: "Help him gather them up.", response: "You work in silence. When you're done, he lets out a breath. “Thanks. That's going in the tin too.”", points: 10),
        StoryOption(text: "“That might be the sweetest thing I've ever seen.”", response: "Rowan turns the color of his hair. “Don't tell anyone.”", points: 10),
    ]), rewards: [.hint("cometBunny"), .coins(150)]),
    StoryEvent(id: "rowan-3", personID: "rowan", title: "Iron and Starlight", stage: .closeFriend, path: .any, lines: [
        n("Rowan asks you to meet him on the forge roof after dark. The stone is still warm from the fire."),
        p("Made something. Took me a month. Kept getting it wrong."),
        n("It's a little iron star, polished until it shines like the real ones overhead."),
        p("I'm no good at saying things. So. This is me saying it."),
    ], choice: crossroads("rowan",
        confess: "“Rowan, I think I'm falling for you.”",
        friends: "“You're my closest friend, Rowan. I mean that.”",
        romanceReply: "Rowan is quiet for so long you start to worry. Then he laughs, low and astonished. “Good. That's good. I was hoping.”",
        friendReply: "Rowan nods, and his shoulders ease. “Good. Then it'll last. The best things do.”"),
    rewards: [.gems(5)], isCrossroads: true),
    StoryEvent(id: "rowan-r4", personID: "rowan", title: "Two Hammers", stage: .romanticInterest, path: .romance, lines: [
        n("Rowan sets a second hammer beside his own at the anvil. It's smaller, balanced for your hand."),
        p("Made it for you. So you can work next to me. If you want."),
        p("…I want."),
    ], choice: StoryChoice(prompt: "Rowan is waiting, very still.", options: [
        StoryOption(text: "Pick up the hammer.", response: "You strike together. The ring of it fills the whole forge. Rowan grins like a boy.", points: 15),
        StoryOption(text: "Kiss his sooty cheek.", response: "Rowan drops his hammer. On his foot. He doesn't seem to mind at all.", points: 10),
    ]), rewards: [.gems(5)]),
    StoryEvent(id: "rowan-r5", personID: "rowan", title: "Forge a Star Charm", stage: .dating, path: .romance, lines: [
        n("Rowan teaches you to forge a star charm, his hands steady over yours."),
        p("Slow. Let the metal tell you when it's ready. …You're a natural."),
        n("You make two. He hangs one on your bag and one on his apron."),
    ], choice: StoryChoice(prompt: "Two little stars cool on the anvil.", options: [
        StoryOption(text: "“Now we match.”", response: "“We match,” he agrees, and he doesn't stop smiling for an hour.", points: 15),
        StoryOption(text: "Lean against his shoulder.", response: "Rowan's arm settles around you, warm as the forge. “Stay.”", points: 10),
    ]), rewards: [.coins(300)]),
    StoryEvent(id: "rowan-r6", personID: "rowan", title: "Made to Last", stage: .committed, path: .romance, lines: [
        n("Rowan brings you to the forge at dawn. The fire is already lit. On the anvil sits a small iron box."),
        p("I keep every thank-you anyone gives me. You've given me more than anyone. So I made you something to keep yours in."),
        n("Inside, on a scrap of velvet, is a star charm on a chain, and every note you ever left him."),
        p("Everything I make, I make to last. I want us to last. Will you stay with me? Always?"),
    ], choice: StoryChoice(prompt: "Rowan's hands are steady. His voice isn't.", options: [
        StoryOption(text: "“Always.”", response: "Rowan pulls you close and holds on like he's never letting go. He isn't.", points: 20),
        StoryOption(text: "Put the charm on.", response: "Rowan fastens it at your neck, gentle as anything. “There. Now it's finished.”", points: 20),
    ]), rewards: [.keepsake("starCharm"), .gems(10)], isFinale: true),
    StoryEvent(id: "rowan-f4", personID: "rowan", title: "Apprentice", stage: .romanticInterest, path: .friendship, lines: [
        n("Rowan paints a new sign over the forge door: CALLOWAY & FRIEND, SMITHS. He made the FRIEND part bigger."),
        p("Every forge needs two. One to hammer, and one to tell the first one to eat lunch."),
    ], choice: StoryChoice(prompt: "Rowan hands you an apron with your name stitched on it.", options: [
        StoryOption(text: "Put it on.", response: "“Suits you,” Rowan says. From him, that's a speech.", points: 15),
        StoryOption(text: "“So I'm the lunch one?”", response: "A rare laugh. “You're the important one.”", points: 10),
    ]), rewards: [.gems(5)]),
    StoryEvent(id: "rowan-f6", personID: "rowan", title: "The Mended Lantern", stage: .committed, path: .friendship, lines: [
        n("Rowan gives you his mother's old lantern, the one that hung in her forge for forty years. He's mended every seam."),
        p("She said a light should go to whoever keeps others warm. That's you."),
        p("Friends like you are rare. I'm keeping you."),
    ], choice: StoryChoice(prompt: "The lantern glows warm in your hands.", options: [
        StoryOption(text: "“I'll keep it lit.”", response: "Rowan nods, eyes bright. “I know you will.”", points: 20),
        StoryOption(text: "Hug him.", response: "Rowan stiffens for a second, then hugs back like he's been waiting years. Maybe he has.", points: 20),
    ]), rewards: [.keepsake("mendedLantern"), .gems(10)], isFinale: true),
]

// MARK: - Silas

private let silasEvents: [StoryEvent] = [
    StoryEvent(id: "silas-1", personID: "silas", title: "Telling the Bees", stage: .acquaintance, path: .any, lines: [
        n("You find a stranger sitting by your sunflowers, talking softly to a bee on his knuckle."),
        p("Oh, hello. Sorry. She wandered over from my hives. She wanted to see your flowers."),
        n("He introduces himself as Silas, the beekeeper, and leaves a jar of honey on your step."),
        p("There's a cake my grandfather used to make with that. I'll write it down for you."),
    ], choice: StoryChoice(prompt: "The bee hums on Silas's hand.", options: [
        StoryOption(text: "“She has good taste in flowers.”", response: "Silas laughs, warm and low. “She does. So do you.”", points: 10),
        StoryOption(text: "Offer him a seat.", response: "He takes it, and stays for an hour, and it feels like ten minutes.", points: 10),
    ]), rewards: [.recipe("honeyCake")]),
    StoryEvent(id: "silas-2", personID: "silas", title: "A Hard Day", stage: .friend, path: .any, lines: [
        n("It's been one of those days. Without quite meaning to, you end up at the apiary."),
        p("Ah. Come in. Kettle's on. You don't have to say anything."),
        n("He pours tea and lets you sit. Outside, the bees hum like a lullaby."),
        p("My grandfather said the bees know when someone's sad. Look. They've all come out to keep you company."),
    ], choice: StoryChoice(prompt: "Silas sets a slice of honey cake in front of you.", options: [
        StoryOption(text: "“How did you know I needed this?”", response: "“You walked in like a rain cloud,” he says gently. “Rainy days need cake.”", points: 10),
        StoryOption(text: "“Thank you, Silas.”", response: "He just smiles. “Anytime. I mean that. Anytime.”", points: 10),
    ]), rewards: [.hint("honeybunBunny"), .coins(150)]),
    StoryEvent(id: "silas-3", personID: "silas", title: "The Honey Moon", stage: .closeFriend, path: .any, lines: [
        n("Silas invites you to the harvest on the night of the full moon, when the hives are calm and the honey runs gold."),
        p("My grandfather called this the honey moon. He said it's the night you tell the bees what matters most."),
        n("He takes off his hat and turns to the hives."),
        p("I'm telling them about you. I hope that's all right."),
    ], choice: crossroads("silas",
        confess: "“Tell them I'm falling for you, Silas.”",
        friends: "“Tell them you've got a best friend for life.”",
        romanceReply: "Silas's breath catches. Then he smiles, slow as a sunrise. “Did you hear that?” he whispers to the hives. “They're humming.”",
        friendReply: "Silas laughs, soft and glad. “They heard. I think they've always known.”"),
    rewards: [.gems(5)], isCrossroads: true),
    StoryEvent(id: "silas-r4", personID: "silas", title: "Borrowed Veil", stage: .romanticInterest, path: .romance, lines: [
        n("Silas helps you into a beekeeper's veil, tying the strings with careful fingers."),
        p("There. Safe. …You look nice in a veil. That came out strange. I meant it."),
    ], choice: StoryChoice(prompt: "A bee lands on Silas's shoulder, perfectly calm.", options: [
        StoryOption(text: "Lift the veil and kiss him.", response: "The bees hum louder. Silas swears it's a coincidence. He's smiling too hard to be convincing.", points: 15),
        StoryOption(text: "“You look nice too.”", response: "Silas ducks his head, delighted. “I'll wear the hat more often, then.”", points: 10),
    ]), rewards: [.gems(5)]),
    StoryEvent(id: "silas-r5", personID: "silas", title: "Honey Tasting", stage: .dating, path: .romance, lines: [
        n("Silas sets out a row of tiny jars under the lanterns. Clover, lavender, sunflower, and one with no label."),
        p("This last one is moonflower. I only ever made one jar. I've been saving it for something special."),
        p("…For someone special."),
    ], choice: StoryChoice(prompt: "Silas holds out a little honey spoon.", options: [
        StoryOption(text: "Taste it.", response: "It tastes like summer evenings. Silas watches you like you're the sweet thing.", points: 15),
        StoryOption(text: "“Share it with me?”", response: "You share the spoon, laughing, and somehow end up sharing a kiss too.", points: 10),
    ]), rewards: [.coins(300)]),
    StoryEvent(id: "silas-r6", personID: "silas", title: "Forty Hives and One Home", stage: .committed, path: .romance, lines: [
        n("At dawn, Silas leads you to the apiary. Among the white hives stands a new one, painted with sunflowers and your name."),
        p("My grandfather said you build a hive for the people you plan to grow old beside."),
        n("He hands you his grandfather's golden honey dipper on a chain."),
        p("I'd like to grow old beside you. Slowly. Sweetly. Will you share a home with me, and forty hives?"),
    ], choice: StoryChoice(prompt: "Silas's eyes are bright with tears and morning sun.", options: [
        StoryOption(text: "“Yes. Every slow, sweet day.”", response: "Silas laughs through his tears and pulls you close. All forty hives hum at once.", points: 20),
        StoryOption(text: "Tell the bees yourself.", response: "You turn to the hives. “I'm staying,” you tell them. Silas has to sit down, overwhelmed with joy.", points: 20),
    ]), rewards: [.keepsake("honeyDipper"), .gems(10)], isFinale: true),
    StoryEvent(id: "silas-f4", personID: "silas", title: "Kettle Company", stage: .romanticInterest, path: .friendship, lines: [
        n("Silas hangs a second mug by the apiary door. It has a little bee painted on it, slightly crooked."),
        p("For you. So you never have to ask if the kettle's on. It always is."),
    ], choice: StoryChoice(prompt: "Silas pours your tea into the new mug.", options: [
        StoryOption(text: "“Best mug I own.”", response: "“It's the only mug you own here,” he says, delighted. “Best by default.”", points: 15),
        StoryOption(text: "Paint a bee on his mug too.", response: "Yours is worse. Silas declares it his favorite thing in the house.", points: 10),
    ]), rewards: [.gems(5)]),
    StoryEvent(id: "silas-f6", personID: "silas", title: "The Bees Remember", stage: .committed, path: .friendship, lines: [
        n("Silas gives you a little glass charm with a single honeybee wing inside, sealed in gold."),
        p("Bees remember the people who are kind to them. So do I. This is so you'll remember too."),
        p("Whatever happens, you'll always have a seat at my table and a spoon in my honey."),
    ], choice: StoryChoice(prompt: "The bees drift lazily around you both.", options: [
        StoryOption(text: "“I'll remember. Always.”", response: "Silas squeezes your hand. “I know. That's why I chose you.”", points: 20),
        StoryOption(text: "Hug him tight.", response: "Silas hugs like he does everything: slowly, warmly, and completely.", points: 20),
    ]), rewards: [.keepsake("beeCharm"), .gems(10)], isFinale: true),
]


// MARK: - Imani's chapters (added by Merlin, 2026-10-30)

private let imaniEvents: [StoryEvent] = [
    StoryEvent(id: "imani-1", personID: "imani", title: "The Pond Keeper", stage: .acquaintance, path: .any, lines: [
        n("At the pond, a woman in waders is standing very still in the shallows, notebook in hand, counting something only she can see."),
        p("Fourteen… fifteen… Don't move. You'll scare the census."),
        n("She finishes, climbs out, and offers you a dry towel and a firm handshake. Imani Okafor-Bell, keeper of the pond."),
        p("Every fish here has a name and a file. Stick around and you'll get one too. A name, I mean. The file depends on behavior."),
    ], choice: StoryChoice(prompt: "A fish rises and takes a fly, neat as a stitch.", options: [
        StoryOption(text: "“You really know every fish?”", response: "“Every one,” Imani says. “That was Gerald. He's showing off for you.”", points: 10),
        StoryOption(text: "Ask about the cabin.", response: "“Grandfather left it to me, and the hives to my brother. One of us got the better deal. We argue about which.”", points: 10),
    ]), rewards: [.coins(100)]),
    StoryEvent(id: "imani-2", personID: "imani", title: "Stripey Accountants", stage: .friend, path: .any, lines: [
        n("You find Imani at the shore, watching a bee drink from the water's edge with deep suspicion."),
        p("Look at it. Little stripey accountant, doing its rounds. My brother's staff, spying on my pond."),
        p("Bees. Honestly. A whole hobby of being stung by your own livestock, and he calls MY fish stupid."),
        n("She says it with the comfortable outrage of a speech she has given four hundred times, and clearly intends to give four hundred more."),
        p("He's a good brother. Don't tell him that either. It goes in the file."),
    ], choice: StoryChoice(prompt: "The bee circles Imani once, unbothered, and heads home.", options: [
        StoryOption(text: "“You two actually get along fine, don't you?”", response: "Imani snorts. “Course we do. Arguing IS how we get along. You should hear us at holidays.”", points: 10),
        StoryOption(text: "“Fish ARE better, though.”", response: "“Finally, a person of sense.” She writes something in the notebook. “That's going in your file. The good column.”", points: 10),
    ]), rewards: [.hint("oceanBunny")]),
    StoryEvent(id: "imani-3", personID: "imani", title: "What the Fish Saw", stage: .closeFriend, path: .any, lines: [
        n("Imani is waiting on the dock, staring at the far shore where something pale moved in the moonlight."),
        p("The fish go quiet when it comes. All of them, all at once, like the whole pond is holding its breath. Fish don't do that for weather."),
        p("And there's a bee that follows it. One bee, lavender stripe. My brother's little spy, moonlighting."),
        n("She looks at you for a long moment, deciding something."),
        p("Whatever that bunny is, keeper to keeper — it's yours, isn't it? …All right. The pond keeps your secrets. So do I."),
    ], choice: StoryChoice(prompt: "The water settles back into ordinary ripples.", options: [
        StoryOption(text: "“Thank you for not asking more.”", response: "“Asking's easy. Waiting's the skill.” She bumps your shoulder with hers. “I can wait.”", points: 10),
        StoryOption(text: "“The fish really go quiet?”", response: "“Every time. Animals know things first. My brother's bees know it too — ask his spy.”", points: 10),
    ]), rewards: [.coins(150)]),
    StoryEvent(id: "imani-r4", personID: "imani", title: "Dock Light", stage: .romanticInterest, path: .romance, lines: [
        n("Imani has strung the dock with lanterns — for the fish census, she claims, at an hour when fish cannot be counted."),
        p("Sit. The good spot. I keep saving it and pretending I don't."),
        n("The lanterns double themselves in the black water. Her hand finds yours like it was always on the way there."),
        p("I know this pond in the dark by heart. Lately I know where YOU are in it the same way. That's new. That's… you."),
    ], choice: StoryChoice(prompt: "A fish rises under the lantern light.", options: [
        StoryOption(text: "“Stay out here with me a while?”", response: "“Hours,” Imani says at once. “The census can wait. It can't, but it will.”", points: 10),
        StoryOption(text: "Just sit with her, quiet.", response: "She leans her head on your shoulder. “You're learning,” she murmurs. “Quiet suits you.”", points: 10),
    ]), rewards: [.coins(150)]),
    StoryEvent(id: "imani-r5", personID: "imani", title: "Night Water", stage: .dating, path: .romance, lines: [
        n("Night fishing, her note said. Bring nothing. Tell no one. Especially not the beekeeper."),
        p("He'd only send a bee to chaperone. She's on the payroll now, but still."),
        n("You catch nothing. She catches nothing. The lantern burns down to a coin of light and neither of you reaches to end the evening."),
        p("People fish for fish. Keepers fish for this. The waiting, with the right person in it."),
    ], choice: StoryChoice(prompt: "Imani reels in, finally — empty hook, enormous smile.", options: [
        StoryOption(text: "“Best catch of the season, this.”", response: "She laughs, startled and pleased. “Careful. Lines like that go in the file. The permanent file.”", points: 10),
        StoryOption(text: "“Same time tomorrow?”", response: "“Every tomorrow,” she says, like a promise the pond should witness. “Bring nothing. Tell no one.”", points: 10),
    ]), rewards: [.hint("auroraBunny")]),
    StoryEvent(id: "imani-r6", personID: "imani", title: "The Deep End", stage: .committed, path: .romance, lines: [
        n("Imani takes you to the deep water at dawn, where the pond is black and still and older than the village."),
        p("Everything I keep ends up back in this water eventually. Every census, every season, every secret."),
        p("I'm not releasing you, farmer. You're in the permanent file now. Front page."),
        n("On the far shore, unhurried, a golden bee with one lavender stripe inspects a flower and files a report of her own."),
        p("Let her tell him. He'll pretend to be surprised. He knew before the fish did."),
    ], choice: StoryChoice(prompt: "Dawn comes up over the pond you share.", options: [
        StoryOption(text: "“Front page. I like it there.”", response: "“Good.” She takes your hand for the walk home. “Because I'm not done writing it.”", points: 10),
        StoryOption(text: "“Does Silas really know?”", response: "“Silas knows everything by breakfast. It's the family curse. Ours too, now.”", points: 10),
    ]), rewards: [.coins(300)]),
    StoryEvent(id: "imani-f4", personID: "imani", title: "Pond Family", stage: .romanticInterest, path: .friendship, lines: [
        n("Imani has made a second keeper's log and written your name on the cover in her careful hand."),
        p("Pond family isn't blood. It's who shows up at dawn when the net's torn. You show up."),
        p("My brother says the bees choose their family. The pond's choosier. It chose you anyway."),
    ], choice: StoryChoice(prompt: "She hands you the log. The first page is Gerald's file.", options: [
        StoryOption(text: "“I'm honored. Truly.”", response: "“Don't be honored. Be punctual. Dawn, tomorrow, bring the good thermos.” But she's smiling into her collar.", points: 10),
        StoryOption(text: "“Gerald has a FILE?”", response: "“Gerald has a file, a file annex, and a warning. Gerald is a menace. You'll meet him.”", points: 10),
    ]), rewards: [.hint("crystalBunny")]),
    StoryEvent(id: "imani-f6", personID: "imani", title: "Keeper and Beekeeper", stage: .committed, path: .friendship, lines: [
        n("A jar of honey sits on Imani's cabin table with a note: FOR THE POND KEEPER. A year travelling, finally delivered."),
        p("He put a ribbon on it. A ribbon. He's impossible."),
        n("That evening she walks a jar of pond-pear preserves up to the apiary herself, and stays for tea, and the arguing is the fondest sound in the valley."),
        p("Fish and bees. Water and flowers. Grandfather knew what he was doing, splitting it between us. …Family's the whole pond, in the end. You're in it. Front page."),
    ], choice: StoryChoice(prompt: "Two keepers, one valley, no score kept anymore.", options: [
        StoryOption(text: "“Took you both long enough.”", response: "“A year for a jar of honey is FAST, for us.” She grins. “The next one only took a day. Progress.”", points: 10),
        StoryOption(text: "“Front page. I know.”", response: "“You do know.” She bumps your shoulder. “Pond family.”", points: 10),
    ]), rewards: [.coins(300)]),
]
