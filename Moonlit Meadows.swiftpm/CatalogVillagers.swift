import Foundation

// MARK: - Villagers

/// Friendly townsfolk. They can be befriended up to Close Friend, with three story chapters
/// each, but aren't romance options.
extension Person {
    static let villagers: [Person] = [wes, bree, vi]

    private static let wes = Person(
        id: "wes",
        name: "Wes",
        fullName: "Wesley Barlow",
        pronouns: "he/him",
        gender: "Man",
        role: "Seed keeper at the Old Mill",
        personality: "Steady, dry-witted, and endlessly patient. Answers most questions with “depends on the soil.”",
        backstory: "Wes farmed your cottage's land for thirty years before handing it over. He moved into the Old Mill, where he keeps a library of seeds in hundreds of tiny paper envelopes, and pretends he isn't checking on how your crops are doing. He is.",
        interests: "Saving heirloom seeds, weather lore, a good stew after a long day",
        looks: [
            PersonLook(skin: RGB(0xF0C9A8), hair: RGB(0x6B4630), hairStyle: .messy, eyes: RGB(0x6B4630),
                       outfit: RGB(0x7B5A44), outfitAccent: RGB(0x9DB07A), accessory: .cap, accessoryColor: RGB(0x7E9554),
                       styleNote: "A moss-green cap, a rolled-sleeve work shirt, well-loved brown overalls, and muddy boots"),
        ],
        favoriteBreeds: ["hazelBunny", "nutmegBunny", "pumpkinBunny"],
        lovedGifts: ["campfireStew", "hazelnutBread", "pumpkin"],
        likedGifts: ["corn", "wheat", "turnip", "pie"],
        dislikedGifts: ["mintyFizz", "crystalCake"],
        schedule: [
            ScheduleSlot(time: .dawn, place: "Early rounds in the village", emoji: "🌾", inMeadow: true),
            ScheduleSlot(time: .day, place: "Old Mill seed library", emoji: "🌱", inMeadow: false),
            ScheduleSlot(time: .dusk, place: "Evening rounds in the village", emoji: "👀", inMeadow: true),
            ScheduleSlot(time: .night, place: "Porch at the Old Mill", emoji: "🪵", inMeadow: false),
        ],
        activities: [
            SharedActivity(name: "Seed sorting", emoji: "🌱",
                           friendLine: "Wes shows you how to sort bean seeds by color. He hums an old tune the whole time and denies humming.",
                           dateLine: "Wes labels a new seed envelope with your farm's name. “Heirloom,” he says. “Means it's worth keeping.”"),
            SharedActivity(name: "Read the sky", emoji: "☁️",
                           friendLine: "Wes squints at the clouds. “Rain by supper.” It rains at supper. He looks unbearably smug.",
                           dateLine: "You and Wes watch a storm roll in from the porch. He tells you about the year the creek flooded and the bunnies rode it out in his hat."),
            SharedActivity(name: "Fix the fence", emoji: "🔨",
                           friendLine: "You mend a fence rail together. Wes does it in three swings. You take eleven. He says that's about right for a first fence.",
                           dateLine: "Wes carves your initials next to his on the fence post. “So the land remembers both of us.”"),
        ],
        lines: DailyLines(
            early: [
                "Mornin'. Soil's looking better than it did in my day. Don't let it go to your head.",
                "Plant your carrots a finger apart. They like elbow room, same as people.",
                "The bunnies used to steal my lettuce too. Just plant extra. That's the whole secret.",
            ],
            friend: [
                "Saved you a packet of my grandmother's pumpkin seeds. Don't make a fuss about it.",
                "I was worried about handing this place over. I'm not worried anymore.",
                "Come by the mill sometime. I'll put the kettle on. Probably burn the toast.",
            ],
            romance: [
                "You've made this old farm feel young again. That's no small thing.",
                "Glad you're here. I mean that.",
                "Best neighbor I ever had. And I've had a lot of neighbors.",
            ],
            bestie: [
                "You've made this old farm feel young again. That's no small thing.",
                "Glad you're here. I mean that.",
                "Best neighbor I ever had. And I've had a lot of neighbors.",
            ]
        ),
        questions: [
            Question(id: "wes-q1", prompt: "“What's the best part of farming, you reckon?”", answers: [
                Answer(text: "Watching something grow from nothing.", response: "Wes nods slowly. “That's it. That's the whole of it.”", points: 15),
                Answer(text: "Harvest day.", response: "“Can't argue. Nothing like a full basket.”", points: 10),
                Answer(text: "The bunnies, honestly.", response: "He chuckles. “Can't argue with that either.”", points: 10),
                Answer(text: "Nothing. It's dirt and chores.", response: "Wes grunts and tips his cap down. “Suit yourself.”", points: 0, isRude: true),
            ]),
        ],
        quests: [
            Quest(id: "wes-1", personID: "wes", title: "Seed Stock",
                  description: "Wes is restocking the seed library and needs good wheat to save.", requiredStage: .acquaintance,
                  items: [ItemCount(itemID: "wheat", count: 6)], points: 30, rewards: [.coins(70)]),
            Quest(id: "wes-2", personID: "wes", title: "Pie for the Mill",
                  description: "The mill's old oven still works, and Wes misses pumpkin pie.", requiredStage: .friend,
                  items: [ItemCount(itemID: "pumpkin", count: 4)], points: 40, rewards: [.gems(2), .hint("pumpkinBunny")]),
            Quest(id: "wes-3", personID: "wes", title: "The Nutmeg Rumor",
                  description: "Wes swears a spice-colored bunny raids his pantry every autumn. Bring corn and a hazelnut loaf to set a friendly trap.",
                  requiredStage: .closeFriend,
                  items: [ItemCount(itemID: "corn", count: 4), ItemCount(itemID: "hazelnutBread", count: 1)], points: 50,
                  rewards: [.gems(3), .hint("nutmegBunny")]),
        ],
        favoriteBunnyReaction: "Wes takes off his cap. “Well, I'll be. A {breed}.” He holds {bunny} like it's made of glass. “Thirty years I tried to find one of these. Thank you, friend.”",
        bunnyReaction: "Wes scratches {bunny} behind the ears. “Welcome to the mill. Mind the flour.”",
        showFavoriteReaction: "Wes stops mid-sentence. “Is that a {breed}? Haven't seen one since I was a boy.”",
        lovedGiftReaction: "“Now that's a proper gift.” Wes almost smiles. Almost.",
        likedGiftReaction: "“Good stuff. Thank you.”",
        neutralGiftReaction: "“Appreciate it.”",
        dislikedGiftReaction: "“Ah. That's… colorful. Thank you anyway.”",
        isVillager: true
    )

    private static let bree = Person(
        id: "bree",
        name: "Bree",
        fullName: "Brielle Moss",
        pronouns: "she/her",
        gender: "Woman",
        role: "Grows the blueberry brambles by the creek",
        personality: "Sunny, outdoorsy, and a tiny bit chaotic. Always has berry stains on her fingers and a new plan for the creek.",
        backstory: "Bree grew up in the meadow and never wanted to leave. She took over her aunt's wild blueberry patch at sixteen and has been expanding it one bramble at a time ever since. She knows every frog in the creek by name, and most of them have opinions.",
        interests: "Berry picking, creek wading, making jam that's mostly sugar",
        looks: [
            PersonLook(skin: RGB(0xF8DCC8), hair: RGB(0x8FB08F), hairStyle: .wavy, eyes: RGB(0x6E8F6E),
                       outfit: RGB(0x8FAE8C), outfitAccent: RGB(0xF2E6D0), accessory: .blueberryClip, accessoryColor: RGB(0x4A5AA8),
                       styleNote: "Sage overalls with a blueberry pin, a puff-sleeve cream tee, a hair clip, and brown lace-ups"),
        ],
        favoriteBreeds: ["mintBunny", "oceanBunny", "fernBunny"],
        lovedGifts: ["blueberry", "muffin", "peachIce"],
        likedGifts: ["blackberry", "honey", "mint", "salad"],
        dislikedGifts: ["chili", "eggplant"],
        schedule: [
            ScheduleSlot(time: .dawn, place: "Picking blueberries by her cottage", emoji: "🫐", inMeadow: false),
            ScheduleSlot(time: .day, place: "Wandering the village lanes", emoji: "🌿", inMeadow: true),
            ScheduleSlot(time: .dusk, place: "Wading in the creek", emoji: "🐸", inMeadow: false),
            ScheduleSlot(time: .night, place: "Home with a cup of blueberry tea", emoji: "🫖", inMeadow: false),
        ],
        activities: [
            SharedActivity(name: "Berry picking", emoji: "🫐",
                           friendLine: "You and Bree pick berries. Your basket fills up. Hers somehow stays half-empty, and her mouth is very blue.",
                           dateLine: "Bree saves you the plumpest berry of the season. “The good ones are for good people.”"),
            SharedActivity(name: "Creek wading", emoji: "🐸",
                           friendLine: "Bree introduces you to Admiral Puddles, the creek's largest frog. He is unimpressed with you.",
                           dateLine: "You skip stones with Bree until sunset. She wins. She always wins. She cheats a little."),
            SharedActivity(name: "Jam day", emoji: "🍯",
                           friendLine: "You make jam together. There is jam on the ceiling. Neither of you knows how.",
                           dateLine: "Bree labels a jar “for my favorite neighbor” and hands it over before you can say anything."),
        ],
        lines: DailyLines(
            early: [
                "Hi hi! Want a blueberry? I have, um, pockets full of them.",
                "Watch out for the third stepping stone in the creek. It's a frog.",
                "Your bunnies keep sneaking into my brambles. I'm not mad. I'm honored.",
            ],
            friend: [
                "I named a new bramble after you! It's very prickly but it means well. Like you! Kidding.",
                "Come wading later? The creek's perfect today.",
                "My aunt would've loved you. She loved anyone who loved the meadow.",
            ],
            romance: [
                "You're officially an honorary creek person. There's no badge. I'll make one.",
                "Best friends share berries. That's the rule.",
                "I'm so glad you moved here. The meadow's brighter with you in it.",
            ],
            bestie: [
                "You're officially an honorary creek person. There's no badge. I'll make one.",
                "Best friends share berries. That's the rule.",
                "I'm so glad you moved here. The meadow's brighter with you in it.",
            ]
        ),
        questions: [
            Question(id: "bree-q1", prompt: "“Okay, important question: sweet berries or tart berries?”", answers: [
                Answer(text: "Tart. They have personality.", response: "“YES. Finally, someone who gets it!”", points: 15),
                Answer(text: "Sweet, always.", response: "“Valid. I'll pick you the ripe ones.”", points: 10),
                Answer(text: "Whatever's in jam.", response: "“Ha! Jam is the great equalizer.”", points: 10),
                Answer(text: "Who cares about berries?", response: "Bree's face falls. “Oh. I… care. A lot, actually.”", points: 0, isRude: true),
            ]),
        ],
        quests: [
            Quest(id: "bree-1", personID: "bree", title: "Bramble Mulch",
                  description: "Bree's brambles need clover to keep the soil happy.", requiredStage: .acquaintance,
                  items: [ItemCount(itemID: "clover", count: 6)], points: 30, rewards: [.coins(60)]),
            Quest(id: "bree-2", personID: "bree", title: "Honey for the Jam",
                  description: "Bree's trying a less-sugary jam (allegedly). She needs honey and mint.", requiredStage: .friend,
                  items: [ItemCount(itemID: "honey", count: 3), ItemCount(itemID: "mint", count: 3)], points: 40,
                  rewards: [.gems(2), .hint("mintBunny")]),
            Quest(id: "bree-3", personID: "bree", title: "Splash at the Creek",
                  description: "Bree spotted a sea-blue bunny splashing in the shallows. Muffins might lure it out again.",
                  requiredStage: .closeFriend,
                  items: [ItemCount(itemID: "muffin", count: 1), ItemCount(itemID: "blueberry", count: 4)], points: 50,
                  rewards: [.gems(3), .hint("oceanBunny")]),
        ],
        favoriteBunnyReaction: "Bree squeals so loudly a frog jumps into the creek. “A {breed}! For me?!” She spins {bunny} around very gently. “You're going to love the brambles. I'll build you a little house. Two houses!”",
        bunnyReaction: "Bree boops {bunny}'s nose. “Welcome to the creek crew!”",
        showFavoriteReaction: "Bree gasps. “A {breed}! Can I hold them? Please? I'll be so careful!”",
        lovedGiftReaction: "“No way! This is my absolute favorite!” Bree hugs it.",
        likedGiftReaction: "“Ooh, thanks! That's so sweet.”",
        neutralGiftReaction: "“Aw, thank you!”",
        dislikedGiftReaction: "Bree's nose wrinkles. “Oh! Um. The frogs might like it?”",
        isVillager: true
    )

    private static let vi = Person(
        id: "vi",
        name: "Vi",
        fullName: "Violet Hollis",
        pronouns: "she/her",
        gender: "Woman",
        role: "Florist at the Petal Cart",
        personality: "Dreamy, soft-spoken, and quietly romantic about everything. Knows what every flower means and will tell you.",
        backstory: "Vi pushes a little flower cart along the meadow paths, trading bouquets for stories. She moved here after reading about the meadow in an old book of pressed flowers and decided it must be real. It was. She writes poems on the backs of flower tags and leaves them for strangers.",
        interests: "The language of flowers, poetry, sunset walks",
        looks: [
            PersonLook(skin: RGB(0xFBE4D8), hair: RGB(0xC6B2E6), hairStyle: .long, eyes: RGB(0x9A7CC8),
                       outfit: RGB(0xC9B5E8), outfitAccent: RGB(0xE8DCF6), accessory: .flowerClip, accessoryColor: RGB(0xA98AD8),
                       styleNote: "A long lilac dress with lace and embroidered flowers, a lavender bouquet, flower earrings, and a brown belt"),
        ],
        favoriteBreeds: ["lilacBunny", "wisteriaBunny", "roseBunny"],
        lovedGifts: ["lilac", "roseMacaron", "wisteria"],
        likedGifts: ["lavender", "rose", "poppy", "tea"],
        dislikedGifts: ["radish", "mushroom"],
        schedule: [
            ScheduleSlot(time: .dawn, place: "Gathering dewy blooms", emoji: "💐", inMeadow: false),
            ScheduleSlot(time: .day, place: "Selling flowers at the plaza stall", emoji: "🌸", inMeadow: false),
            ScheduleSlot(time: .dusk, place: "Sunset walk", emoji: "🌅", inMeadow: true),
            ScheduleSlot(time: .night, place: "Writing poems", emoji: "📝", inMeadow: true),
        ],
        activities: [
            SharedActivity(name: "Flower meanings", emoji: "🌸",
                           friendLine: "Vi tells you what each flower in her cart means. Apparently you've been gifting people “jealousy” for weeks.",
                           dateLine: "Vi tucks a sprig of lilac into your pocket. “It means first friendship,” she says. “Keep it.”"),
            SharedActivity(name: "Sunset walk", emoji: "🌅",
                           friendLine: "You walk the meadow path at sunset. Vi stops every few steps to say hello to a flower.",
                           dateLine: "Vi reads you a poem at the top of the hill. It's about the meadow. Somewhere in the middle, it's about you."),
            SharedActivity(name: "Bouquet making", emoji: "💐",
                           friendLine: "Vi helps you make a bouquet. Yours is lopsided. She calls it “expressive.”",
                           dateLine: "Vi ties your bouquet with a ribbon from her own hair."),
        ],
        lines: DailyLines(
            early: [
                "Good evening. Would you like a flower? This one means “a new beginning.”",
                "Lilacs bloom best near people who are kind to them. I think they'd bloom for you.",
                "I left a poem tied to your fence. You don't have to read it. But you can.",
            ],
            friend: [
                "I made you a little bouquet. Lavender for calm, and daisy for… well. For you.",
                "The sunsets here are like watercolors. I'm glad I have someone to watch them with.",
                "I wrote a poem about your bunnies. It's mostly about their ears.",
            ],
            romance: [
                "Every flower in my cart reminds me of a friend. Most of them remind me of you.",
                "You're the kind of person a whole bouquet is named after.",
                "Walk with me again tonight? The moon's supposed to be lovely.",
            ],
            bestie: [
                "Every flower in my cart reminds me of a friend. Most of them remind me of you.",
                "You're the kind of person a whole bouquet is named after.",
                "Walk with me again tonight? The moon's supposed to be lovely.",
            ]
        ),
        questions: [
            Question(id: "vi-q1", prompt: "“If you were a flower, what would you hope you meant?”", answers: [
                Answer(text: "Kindness.", response: "Vi smiles. “Pink camellia, then. It suits you.”", points: 15),
                Answer(text: "Adventure.", response: "“Hmm. Snapdragon. A little bold. I like it.”", points: 10),
                Answer(text: "Snacks.", response: "Vi laughs. “I'll invent a flower for that.”", points: 10),
                Answer(text: "Flowers don't mean anything. That's silly.", response: "Vi's hands still on her bouquet. “I suppose that's one way to see it.”", points: 0, isRude: true),
            ]),
        ],
        quests: [
            Quest(id: "vi-1", personID: "vi", title: "Bouquet Basics",
                  description: "Vi's cart is low on cheerful flowers. Dandelions will do nicely.", requiredStage: .acquaintance,
                  items: [ItemCount(itemID: "dandelion", count: 6)], points: 30, rewards: [.coins(60)]),
            Quest(id: "vi-2", personID: "vi", title: "A Fragrant Order",
                  description: "Someone ordered a calming bouquet. Vi needs lavender and chamomile.", requiredStage: .friend,
                  items: [ItemCount(itemID: "lavender", count: 3), ItemCount(itemID: "chamomile", count: 3)], points: 40,
                  rewards: [.gems(2), .hint("lilacBunny")]),
            Quest(id: "vi-3", personID: "vi", title: "The Wisteria Poem",
                  description: "Vi saw a bunny with drooping purple ears asleep under the wisteria. She wants roses and lilacs to tempt it back.",
                  requiredStage: .closeFriend,
                  items: [ItemCount(itemID: "rose", count: 3), ItemCount(itemID: "lilac", count: 3)], points: 50,
                  rewards: [.gems(3), .hint("wisteriaBunny")]),
        ],
        favoriteBunnyReaction: "Vi's eyes fill with tears. “A {breed}…” She cradles {bunny} and tucks a tiny flower behind its ear. “There's a flower that means ‘you've made me happy.’ I'll grow a whole field of it for you.”",
        bunnyReaction: "Vi gives {bunny} a little daisy crown. “Welcome, sweet thing.”",
        showFavoriteReaction: "Vi presses a hand to her heart. “A {breed}. They're like a poem with ears.”",
        lovedGiftReaction: "“Oh… you remembered.” Vi holds it close. “Thank you.”",
        likedGiftReaction: "“How lovely. Thank you.”",
        neutralGiftReaction: "“That's kind of you.”",
        dislikedGiftReaction: "“Oh. Well — every gift means something.” She smiles politely.",
        isVillager: true
    )
}

// MARK: - Villager stories

private func n(_ text: String) -> StoryLine { StoryLine(speaker: .narrator, text: text) }
private func p(_ text: String) -> StoryLine { StoryLine(speaker: .person, text: text) }
private func y(_ text: String) -> StoryLine { StoryLine(speaker: .you, text: text) }

extension StoryEvent {
    static let villagerEvents: [StoryEvent] = [
        // Wes
        StoryEvent(id: "wes-1", personID: "wes", title: "The Old Farmer", stage: .acquaintance, path: .any, lines: [
            n("You find Wes leaning on your fence at dawn, studying your carrots like a newspaper."),
            p("Don't mind me. Habit. I farmed this land for thirty years."),
            p("You're doing all right. Better than all right. Here — the first seeds I ever saved off this field. They belong here."),
        ], choice: StoryChoice(prompt: "What do you say?", options: [
            StoryOption(text: "“Teach me everything you know?”", response: "Wes snorts. “That'd take thirty years. We'll start Tuesday.”", points: 10),
            StoryOption(text: "“I'll take good care of it.”", response: "“I know you will. That's why I'm not worried.”", points: 10),
        ]), rewards: [.items("pumpkin", 3), .coins(80)]),
        StoryEvent(id: "wes-2", personID: "wes", title: "The Seed Library", stage: .friend, path: .any, lines: [
            n("Wes lets you into the Old Mill. Every wall is covered in tiny drawers, each labeled in careful handwriting."),
            p("Every seed in here has a story. This one came over the mountains in my grandmother's coat pocket."),
            p("I'm adding a drawer. For whatever you grow best."),
            y("You're giving me a drawer?"),
            p("Don't make it a thing."),
        ], choice: StoryChoice(prompt: "Wes is very carefully not looking at you.", options: [
            StoryOption(text: "“It's a thing. I'm making it a thing.”", response: "Wes sighs, but his ears go pink.", points: 10),
            StoryOption(text: "Quietly label the drawer yourself.", response: "Wes watches you write. “Good handwriting. Better than mine.”", points: 10),
        ]), rewards: [.gems(3), .hint("hazelBunny")]),
        StoryEvent(id: "wes-3", personID: "wes", title: "Harvest Moon Porch", stage: .closeFriend, path: .any, lines: [
            n("Under a huge orange moon, Wes waves you up onto the mill's porch. Two mugs of cocoa are already waiting."),
            p("I almost sold the farm to a developer, you know. Before you came. Couldn't bring myself to."),
            p("Glad I waited. Land knows who loves it."),
            p("That old seed pouch I carried every season? It's yours now. Fill it with something good."),
        ], choice: StoryChoice(prompt: "The moon rises over your farm.", options: [
            StoryOption(text: "“Thank you for trusting me with it.”", response: "“Thank you for proving me right.”", points: 15),
            StoryOption(text: "“It's our farm, really.”", response: "Wes is quiet for a long moment. “…Yeah. I suppose it is.”", points: 15),
        ]), rewards: [.gems(5), .coins(300), .hint("nutmegBunny")]),

        // Bree
        StoryEvent(id: "bree-1", personID: "bree", title: "Berry Stained", stage: .acquaintance, path: .any, lines: [
            n("A girl with green hair pops out of a bramble bush, covered in leaves and holding a basket."),
            p("Oh! Hi! You're the new farmer! I'm Bree. These are my brambles. Well, they're everybody's brambles. But I'm in charge."),
            p("Here, a welcome basket. Blueberries! Careful, they stain. Everything. Forever."),
        ], choice: StoryChoice(prompt: "Bree is beaming at you.", options: [
            StoryOption(text: "Eat a berry right away.", response: "“Yes! A berry person! I knew it.”", points: 10),
            StoryOption(text: "“Can I help with the brambles sometime?”", response: "“Can you? Will you? I'll get you gloves!”", points: 10),
        ]), rewards: [.items("blueberry", 6), .coins(60)]),
        StoryEvent(id: "bree-2", personID: "bree", title: "Admiral Puddles", stage: .friend, path: .any, lines: [
            n("Bree drags you down to the creek. A very large frog sits on a very flat rock."),
            p("This is Admiral Puddles. He's the oldest frog in the creek. If he likes you, you're in."),
            n("Admiral Puddles stares at you. You stare back. After a long moment, he croaks once."),
            p("HE LIKES YOU! Oh, this is the best day. Here — you get a creek crew badge. I made it from a bottle cap."),
        ], choice: StoryChoice(prompt: "Admiral Puddles is still watching you.", options: [
            StoryOption(text: "Salute the Admiral.", response: "Bree laughs so hard she has to sit down in the creek.", points: 10),
            StoryOption(text: "Pin the badge on proudly.", response: "“It looks so good on you!” Bree beams.", points: 10),
        ]), rewards: [.gems(3), .hint("fernBunny")]),
        StoryEvent(id: "bree-3", personID: "bree", title: "Stars on the Dock", stage: .closeFriend, path: .any, lines: [
            n("At night, Bree shows you the old dock where she watches the stars. Fireflies drift over the water."),
            p("My aunt used to bring me here. She said the creek carries wishes to the sea."),
            p("I wished for a friend who'd love the meadow as much as I do. And then you showed up. So. Creek magic is real."),
            p("I want you to have her old berry basket. It's the best one. It never spills."),
        ], choice: StoryChoice(prompt: "Bree swings her feet over the water.", options: [
            StoryOption(text: "“I wished for a friend like you, too.”", response: "Bree sniffles and bumps your shoulder with hers. “Best creek crew ever.”", points: 15),
            StoryOption(text: "Make a wish together.", response: "You both close your eyes. Bree peeks. You both laugh.", points: 15),
        ]), rewards: [.gems(5), .coins(250), .hint("oceanBunny")]),

        // Vi
        StoryEvent(id: "vi-1", personID: "vi", title: "A Flower for a Story", stage: .acquaintance, path: .any, lines: [
            n("A woman in a lilac dress pushes a flower cart along the path at sunset."),
            p("Good evening. I trade flowers for stories. Do you have one?"),
            y("I moved here to grow things, I guess."),
            p("That's a lovely story. It's only just beginning, so it's my favorite kind. Here — sweet peas. They mean “thank you for a lovely time.”"),
        ], choice: StoryChoice(prompt: "Vi waits, smiling.", options: [
            StoryOption(text: "“Can I hear one of your stories?”", response: "Vi's eyes light up. “Oh, I have so many. Walk with me.”", points: 10),
            StoryOption(text: "“What do lilacs mean?”", response: "“First friendship,” Vi says softly. “Appropriate, don't you think?”", points: 10),
        ]), rewards: [.items("lavender", 4), .coins(60)]),
        StoryEvent(id: "vi-2", personID: "vi", title: "The Pressed Flower Book", stage: .friend, path: .any, lines: [
            n("Vi shows you an old book, its pages full of pressed flowers and tiny handwritten notes."),
            p("I found this in a secondhand shop. Every flower in it came from this meadow. That's why I came here. To see if it was real."),
            p("Look — this page is blank. I think it's waiting for something from your farm."),
        ], choice: StoryChoice(prompt: "Vi holds out the book.", options: [
            StoryOption(text: "Press a clover from your field.", response: "Vi writes underneath it: “From a friend.” She underlines it twice.", points: 10),
            StoryOption(text: "“You should press something too.”", response: "Vi presses a lilac beside your page. “There. Now we're both in the story.”", points: 10),
        ]), rewards: [.gems(3), .hint("roseBunny")]),
        StoryEvent(id: "vi-3", personID: "vi", title: "The Poem on the Hill", stage: .closeFriend, path: .any, lines: [
            n("Vi leads you to the top of the hill as the sky turns gold. She's holding a folded paper."),
            p("I write poems for strangers. I've never written one for a friend. I was too nervous to read it."),
            n("She reads it anyway. It's about the meadow, and the bunnies, and the way the light lands on your farm in the evening."),
            p("I tied it to a bouquet for you. Wisteria — it means “I'm glad you're here.”"),
        ], choice: StoryChoice(prompt: "The sun sets behind you both.", options: [
            StoryOption(text: "“That was beautiful, Vi.”", response: "Vi hides her face behind the bouquet, smiling. “Thank you for listening.”", points: 15),
            StoryOption(text: "“Will you write another one?”", response: "“A whole book,” she promises.", points: 15),
        ]), rewards: [.gems(5), .coins(250), .hint("wisteriaBunny")]),
    ]
}
