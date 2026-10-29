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

    static let all: [StoryEvent] = juneEvents + rozEvents + theoEvents + kaiEvents + solEvents + villagerEvents
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
