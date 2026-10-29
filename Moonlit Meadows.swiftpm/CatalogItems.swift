import Foundation

/// Something you can grow on a farm plot. Magical crops reuse a base emoji with a hue shift
/// and a soft glow (see `CropIcon`) until real artwork is drawn.
struct Crop: Identifiable {
    let id: String
    let name: String
    let emoji: String
    let unlockLevel: Int
    let seedCost: Int
    let growSeconds: TimeInterval
    let sellPrice: Int
    let xp: Int
    /// Degrees to rotate the emoji's hue, for magical variants. `0` for none.
    var hueShift: Double = 0
    var glow: RGB?

    var isMagical: Bool { glow != nil }

    static let all: [Crop] = [
        // Levels 1–4: everyday veggies and flowers (common bunnies).
        Crop(id: "carrot", name: "Carrot", emoji: "🥕", unlockLevel: 1, seedCost: 2, growSeconds: 30, sellPrice: 6, xp: 1),
        Crop(id: "clover", name: "Clover", emoji: "☘️", unlockLevel: 1, seedCost: 1, growSeconds: 20, sellPrice: 4, xp: 1),
        Crop(id: "dandelion", name: "Dandelion", emoji: "🌼", unlockLevel: 1, seedCost: 1, growSeconds: 18, sellPrice: 4, xp: 1, hueShift: -25),
        Crop(id: "lettuce", name: "Lettuce", emoji: "🥬", unlockLevel: 2, seedCost: 8, growSeconds: 75, sellPrice: 20, xp: 2),
        Crop(id: "peas", name: "Sweet Peas", emoji: "🫛", unlockLevel: 2, seedCost: 6, growSeconds: 50, sellPrice: 15, xp: 2),
        Crop(id: "wheat", name: "Wheat", emoji: "🌾", unlockLevel: 2, seedCost: 7, growSeconds: 55, sellPrice: 16, xp: 2),
        Crop(id: "honey", name: "Honeycomb", emoji: "🍯", unlockLevel: 2, seedCost: 6, growSeconds: 45, sellPrice: 14, xp: 2),
        Crop(id: "greens", name: "Spring Greens", emoji: "🥦", unlockLevel: 2, seedCost: 5, growSeconds: 40, sellPrice: 12, xp: 2),
        Crop(id: "strawberry", name: "Strawberry", emoji: "🍓", unlockLevel: 3, seedCost: 10, growSeconds: 90, sellPrice: 28, xp: 3),
        Crop(id: "chamomile", name: "Chamomile", emoji: "🌼", unlockLevel: 3, seedCost: 9, growSeconds: 80, sellPrice: 24, xp: 3),
        Crop(id: "sunflower", name: "Sunflower", emoji: "🌻", unlockLevel: 3, seedCost: 12, growSeconds: 100, sellPrice: 30, xp: 3),
        Crop(id: "radish", name: "Radish", emoji: "🥕", unlockLevel: 3, seedCost: 9, growSeconds: 70, sellPrice: 22, xp: 3, hueShift: -45),
        Crop(id: "pumpkin", name: "Pumpkin", emoji: "🎃", unlockLevel: 4, seedCost: 25, growSeconds: 240, sellPrice: 70, xp: 5),
        Crop(id: "mint", name: "Mint", emoji: "🌿", unlockLevel: 4, seedCost: 15, growSeconds: 150, sellPrice: 42, xp: 4),
        Crop(id: "blackberry", name: "Blackberries", emoji: "🫐", unlockLevel: 4, seedCost: 16, growSeconds: 140, sellPrice: 40, xp: 4, hueShift: 50),
        Crop(id: "daffodil", name: "Daffodil", emoji: "🏵️", unlockLevel: 4, seedCost: 14, growSeconds: 120, sellPrice: 36, xp: 4, hueShift: 20),
        // Levels 5–9: berries, herbs, and specialty crops (uncommon and rare bunnies).
        Crop(id: "lavender", name: "Lavender", emoji: "🪻", unlockLevel: 5, seedCost: 35, growSeconds: 300, sellPrice: 95, xp: 6),
        Crop(id: "sweetPotato", name: "Sweet Potato", emoji: "🍠", unlockLevel: 5, seedCost: 30, growSeconds: 270, sellPrice: 85, xp: 6),
        Crop(id: "thistle", name: "Thistle", emoji: "🪻", unlockLevel: 5, seedCost: 30, growSeconds: 260, sellPrice: 82, xp: 6, hueShift: 330),
        Crop(id: "cabbage", name: "Cabbage", emoji: "🥬", unlockLevel: 5, seedCost: 28, growSeconds: 240, sellPrice: 78, xp: 6, hueShift: 60),
        Crop(id: "blueberry", name: "Blueberries", emoji: "🫐", unlockLevel: 6, seedCost: 50, growSeconds: 420, sellPrice: 140, xp: 8),
        Crop(id: "cherry", name: "Cherries", emoji: "🍒", unlockLevel: 6, seedCost: 45, growSeconds: 390, sellPrice: 130, xp: 8),
        Crop(id: "basil", name: "Basil", emoji: "🍃", unlockLevel: 6, seedCost: 40, growSeconds: 360, sellPrice: 115, xp: 7),
        Crop(id: "coconut", name: "Coconut", emoji: "🥥", unlockLevel: 6, seedCost: 48, growSeconds: 400, sellPrice: 130, xp: 8),
        Crop(id: "nutmeg", name: "Nutmeg", emoji: "🥜", unlockLevel: 6, seedCost: 44, growSeconds: 380, sellPrice: 125, xp: 8),
        Crop(id: "rose", name: "Rose", emoji: "🌹", unlockLevel: 7, seedCost: 70, growSeconds: 540, sellPrice: 200, xp: 10),
        Crop(id: "peach", name: "Peach", emoji: "🍑", unlockLevel: 7, seedCost: 65, growSeconds: 510, sellPrice: 190, xp: 10),
        Crop(id: "eggplant", name: "Eggplant", emoji: "🍆", unlockLevel: 7, seedCost: 60, growSeconds: 480, sellPrice: 170, xp: 9),
        Crop(id: "starberry", name: "Starberry", emoji: "🍓", unlockLevel: 7, seedCost: 70, growSeconds: 540, sellPrice: 210, xp: 10, hueShift: 250, glow: RGB(0xE2C8FF)),
        Crop(id: "crystalCarrot", name: "Crystal Carrot", emoji: "🥕", unlockLevel: 7, seedCost: 75, growSeconds: 560, sellPrice: 220, xp: 11, hueShift: 165, glow: RGB(0xB8F4F0)),
        Crop(id: "hazelnut", name: "Hazelnut", emoji: "🌰", unlockLevel: 8, seedCost: 90, growSeconds: 660, sellPrice: 260, xp: 12),
        Crop(id: "pear", name: "Pear", emoji: "🍐", unlockLevel: 8, seedCost: 85, growSeconds: 630, sellPrice: 250, xp: 12),
        Crop(id: "corn", name: "Corn", emoji: "🌽", unlockLevel: 8, seedCost: 85, growSeconds: 620, sellPrice: 245, xp: 12),
        Crop(id: "lilac", name: "Lilacs", emoji: "🌸", unlockLevel: 8, seedCost: 80, growSeconds: 600, sellPrice: 240, xp: 12, hueShift: 250),
        Crop(id: "melon", name: "Honey Melon", emoji: "🍈", unlockLevel: 9, seedCost: 120, growSeconds: 840, sellPrice: 350, xp: 14),
        Crop(id: "moonflower", name: "Moonflower", emoji: "🌼", unlockLevel: 9, seedCost: 160, growSeconds: 900, sellPrice: 460, xp: 17, hueShift: 185, glow: RGB(0xBFD8FF)),
        Crop(id: "turnip", name: "Turnip", emoji: "🧅", unlockLevel: 9, seedCost: 100, growSeconds: 720, sellPrice: 300, xp: 14, hueShift: 250),
        Crop(id: "sugarcane", name: "Sugarcane", emoji: "🎋", unlockLevel: 9, seedCost: 105, growSeconds: 740, sellPrice: 310, xp: 14, hueShift: 300),
        // Levels 10–20: rare and magical crops (rare, epic, and legendary bunnies).
        Crop(id: "willowBark", name: "Willow Bark", emoji: "🪵", unlockLevel: 10, seedCost: 130, growSeconds: 860, sellPrice: 380, xp: 16),
        Crop(id: "wisteria", name: "Wisteria", emoji: "🪻", unlockLevel: 10, seedCost: 140, growSeconds: 900, sellPrice: 400, xp: 17, hueShift: 200),
        Crop(id: "thunderRoot", name: "Thunder Root", emoji: "🫚", unlockLevel: 11, seedCost: 170, growSeconds: 1000, sellPrice: 480, xp: 19, hueShift: 0, glow: RGB(0xFFE58A)),
        Crop(id: "pixelBerry", name: "Pixel Berry", emoji: "🍒", unlockLevel: 11, seedCost: 180, growSeconds: 1040, sellPrice: 500, xp: 20, hueShift: 180, glow: RGB(0xF5C6F0)),
        Crop(id: "seaweed", name: "Seaweed", emoji: "🪸", unlockLevel: 12, seedCost: 210, growSeconds: 1150, sellPrice: 580, xp: 22, hueShift: 120),
        Crop(id: "mushroom", name: "Mushroom", emoji: "🍄", unlockLevel: 12, seedCost: 200, growSeconds: 1100, sellPrice: 560, xp: 21),
        Crop(id: "poppy", name: "Poppies", emoji: "🌺", unlockLevel: 12, seedCost: 220, growSeconds: 1200, sellPrice: 600, xp: 23),
        Crop(id: "frostBerry", name: "Frost Berry", emoji: "🫐", unlockLevel: 13, seedCost: 260, growSeconds: 1300, sellPrice: 700, xp: 25, hueShift: -30, glow: RGB(0xDDF0FF)),
        Crop(id: "chili", name: "Chili Pepper", emoji: "🌶️", unlockLevel: 13, seedCost: 250, growSeconds: 1260, sellPrice: 680, xp: 24),
        Crop(id: "bamboo", name: "Bamboo", emoji: "🎍", unlockLevel: 14, seedCost: 300, growSeconds: 1440, sellPrice: 820, xp: 28),
        Crop(id: "eucalyptus", name: "Eucalyptus", emoji: "🌿", unlockLevel: 14, seedCost: 310, growSeconds: 1480, sellPrice: 840, xp: 28, hueShift: 60),
        Crop(id: "dreamPlum", name: "Dream Plum", emoji: "🍑", unlockLevel: 14, seedCost: 360, growSeconds: 1620, sellPrice: 1100, xp: 32, hueShift: 250, glow: RGB(0xD9C6FF)),
        Crop(id: "rainbowBerry", name: "Rainbow Berry", emoji: "🍓", unlockLevel: 15, seedCost: 380, growSeconds: 1680, sellPrice: 1000, xp: 32, hueShift: 120, glow: RGB(0xFFD6F5)),
        Crop(id: "auroraTulip", name: "Aurora Tulip", emoji: "🌷", unlockLevel: 15, seedCost: 430, growSeconds: 1800, sellPrice: 1320, xp: 36, hueShift: 150, glow: RGB(0xC3F5DC)),
        Crop(id: "goldenClover", name: "Golden Clover", emoji: "☘️", unlockLevel: 16, seedCost: 450, growSeconds: 1860, sellPrice: 1200, xp: 36, hueShift: -70, glow: RGB(0xFFE7A0)),
        Crop(id: "nightshade", name: "Nightshade", emoji: "🍇", unlockLevel: 17, seedCost: 520, growSeconds: 2040, sellPrice: 1400, xp: 40, hueShift: 30, glow: RGB(0xC9A8FF)),
        Crop(id: "cotton", name: "Cotton", emoji: "☁️", unlockLevel: 18, seedCost: 600, growSeconds: 2200, sellPrice: 1600, xp: 44),
        Crop(id: "cometCorn", name: "Comet Corn", emoji: "🌽", unlockLevel: 19, seedCost: 680, growSeconds: 2300, sellPrice: 1800, xp: 47, hueShift: 190, glow: RGB(0xCFE4FF)),
        Crop(id: "starlightFlower", name: "Starlight Flower", emoji: "🌸", unlockLevel: 20, seedCost: 750, growSeconds: 2400, sellPrice: 2000, xp: 50, hueShift: 30, glow: RGB(0xFFF2B0)),
    ]

    static func find(_ id: String) -> Crop? {
        all.first { $0.id == id }
    }
}

/// A treat you make from crops in the kitchen. Treats sell for more, make good gifts,
/// and lure fancier bunnies.
struct Recipe: Identifiable {
    struct Ingredient {
        let itemID: String
        let count: Int
    }

    let id: String
    let name: String
    let emoji: String
    let unlockLevel: Int
    let ingredients: [Ingredient]
    let sellPrice: Int
    let xp: Int
    /// Character recipes are taught to you in their story; they don't unlock by level alone.
    var taughtBy: String?

    static let all: [Recipe] = [
        Recipe(id: "cloverCookie", name: "Clover Cookies", emoji: "🍪", unlockLevel: 1,
               ingredients: [.init(itemID: "clover", count: 3)], sellPrice: 18, xp: 3),
        Recipe(id: "carrotCake", name: "Carrot Cake", emoji: "🍰", unlockLevel: 2,
               ingredients: [.init(itemID: "carrot", count: 3), .init(itemID: "clover", count: 2)], sellPrice: 45, xp: 5),
        Recipe(id: "salad", name: "Garden Salad", emoji: "🥗", unlockLevel: 2,
               ingredients: [.init(itemID: "lettuce", count: 2), .init(itemID: "carrot", count: 2)], sellPrice: 70, xp: 6),
        Recipe(id: "jam", name: "Strawberry Jam", emoji: "🥫", unlockLevel: 3,
               ingredients: [.init(itemID: "strawberry", count: 4)], sellPrice: 130, xp: 8),
        Recipe(id: "chamomileTea", name: "Chamomile Tea", emoji: "🫖", unlockLevel: 3,
               ingredients: [.init(itemID: "chamomile", count: 2), .init(itemID: "clover", count: 2)], sellPrice: 75, xp: 6),
        Recipe(id: "pie", name: "Pumpkin Pie", emoji: "🥧", unlockLevel: 4,
               ingredients: [.init(itemID: "pumpkin", count: 2), .init(itemID: "strawberry", count: 1)], sellPrice: 200, xp: 12),
        Recipe(id: "mintyFizz", name: "Minty Fizz", emoji: "🥤", unlockLevel: 4,
               ingredients: [.init(itemID: "mint", count: 2), .init(itemID: "strawberry", count: 1)], sellPrice: 130, xp: 9),
        Recipe(id: "tea", name: "Lavender Tea", emoji: "🍵", unlockLevel: 5,
               ingredients: [.init(itemID: "lavender", count: 2), .init(itemID: "chamomile", count: 1)], sellPrice: 260, xp: 14),
        Recipe(id: "sweetPotatoPudding", name: "Sweet Potato Pudding", emoji: "🍮", unlockLevel: 5,
               ingredients: [.init(itemID: "sweetPotato", count: 2), .init(itemID: "clover", count: 2)], sellPrice: 210, xp: 12),
        Recipe(id: "muffin", name: "Blueberry Muffin", emoji: "🧁", unlockLevel: 6,
               ingredients: [.init(itemID: "blueberry", count: 3), .init(itemID: "carrot", count: 2)], sellPrice: 470, xp: 18),
        Recipe(id: "cherrySundae", name: "Cherry Sundae", emoji: "🍨", unlockLevel: 6,
               ingredients: [.init(itemID: "cherry", count: 3), .init(itemID: "strawberry", count: 1)], sellPrice: 430, xp: 18),
        Recipe(id: "roseMacaron", name: "Rose Macarons", emoji: "🍬", unlockLevel: 7,
               ingredients: [.init(itemID: "rose", count: 2), .init(itemID: "strawberry", count: 2)], sellPrice: 480, xp: 22),
        Recipe(id: "peachIce", name: "Peach Ice", emoji: "🍧", unlockLevel: 7,
               ingredients: [.init(itemID: "peach", count: 2), .init(itemID: "mint", count: 1)], sellPrice: 440, xp: 20),
        Recipe(id: "hazelnutBread", name: "Hazelnut Bread", emoji: "🍞", unlockLevel: 8,
               ingredients: [.init(itemID: "hazelnut", count: 2), .init(itemID: "carrot", count: 2)], sellPrice: 560, xp: 25),
        Recipe(id: "melonParfait", name: "Melon Parfait", emoji: "🍹", unlockLevel: 9,
               ingredients: [.init(itemID: "melon", count: 1), .init(itemID: "blueberry", count: 2)], sellPrice: 690, xp: 28),
        Recipe(id: "moonMochi", name: "Moon Mochi", emoji: "🍡", unlockLevel: 10,
               ingredients: [.init(itemID: "moonflower", count: 2), .init(itemID: "clover", count: 3)], sellPrice: 1_100, xp: 40),
        Recipe(id: "starJam", name: "Starberry Jam", emoji: "🫙", unlockLevel: 11,
               ingredients: [.init(itemID: "starberry", count: 3)], sellPrice: 1_900, xp: 55),
        Recipe(id: "crystalCake", name: "Crystal Carrot Cake", emoji: "🎂", unlockLevel: 12,
               ingredients: [.init(itemID: "crystalCarrot", count: 2), .init(itemID: "starberry", count: 1)], sellPrice: 2_400, xp: 70),
        Recipe(id: "goldenLoaf", name: "Golden Clover Loaf", emoji: "🥐", unlockLevel: 16,
               ingredients: [.init(itemID: "goldenClover", count: 3), .init(itemID: "hazelnut", count: 1)], sellPrice: 3_000, xp: 85),
        Recipe(id: "dreamParfait", name: "Dream Parfait", emoji: "🥛", unlockLevel: 14,
               ingredients: [.init(itemID: "dreamPlum", count: 2), .init(itemID: "moonflower", count: 1)], sellPrice: 3_600, xp: 100),
        // Character gift recipes, taught during each character's first story chapter.
        Recipe(id: "herbalPosy", name: "Herbal Posy", emoji: "💐", unlockLevel: 3,
               ingredients: [.init(itemID: "chamomile", count: 2), .init(itemID: "clover", count: 2)], sellPrice: 85, xp: 7, taughtBy: "june"),
        Recipe(id: "sunriseShortcake", name: "Sunrise Shortcake", emoji: "🧇", unlockLevel: 3,
               ingredients: [.init(itemID: "strawberry", count: 2), .init(itemID: "carrot", count: 1)], sellPrice: 100, xp: 7, taughtBy: "roz"),
        Recipe(id: "stargazerCocoa", name: "Stargazer Cocoa", emoji: "☕", unlockLevel: 3,
               ingredients: [.init(itemID: "chamomile", count: 2), .init(itemID: "clover", count: 2)], sellPrice: 90, xp: 7, taughtBy: "theo"),
        Recipe(id: "campfireStew", name: "Campfire Stew", emoji: "🍲", unlockLevel: 2,
               ingredients: [.init(itemID: "carrot", count: 2), .init(itemID: "peas", count: 2), .init(itemID: "lettuce", count: 1)],
               sellPrice: 95, xp: 7, taughtBy: "kai"),
        Recipe(id: "melodyMacarons", name: "Melody Macarons", emoji: "🍭", unlockLevel: 3,
               ingredients: [.init(itemID: "strawberry", count: 2), .init(itemID: "chamomile", count: 1)], sellPrice: 110, xp: 7, taughtBy: "sol"),
    ]

    static func find(_ id: String) -> Recipe? {
        all.first { $0.id == id }
    }
}

/// Looks up crops and treats by ID, so the basket, gifts, quests, and lures treat them alike.
enum ItemInfo {
    static func emoji(_ id: String) -> String {
        Crop.find(id)?.emoji ?? Recipe.find(id)?.emoji ?? "❓"
    }

    static func name(_ id: String) -> String {
        Crop.find(id)?.name ?? Recipe.find(id)?.name ?? id
    }

    static func basePrice(_ id: String) -> Int {
        Crop.find(id)?.sellPrice ?? Recipe.find(id)?.sellPrice ?? 1
    }

    static func xp(_ id: String) -> Int {
        Crop.find(id)?.xp ?? Recipe.find(id)?.xp ?? 1
    }

    static func unlockLevel(_ id: String) -> Int {
        Crop.find(id)?.unlockLevel ?? Recipe.find(id)?.unlockLevel ?? 1
    }

    static func exists(_ id: String) -> Bool {
        Crop.find(id) != nil || Recipe.find(id) != nil
    }

    /// Every item ID, crops first, in shop order.
    static let allIDs: [String] = Crop.all.map(\.id) + Recipe.all.map(\.id)
}
