// MARK: - Fish catalog (added by Merlin, 2026-10-30)

/// When a fish can be caught. Day/night follow the game's time blocks; rain
/// adds the rain-loving species to the pool; full-moon nights unlock the two
/// moon legendaries. `duskOnly` narrows a night fish to the dusk block.
enum FishCondition: String, Codable, Equatable, Hashable {
    case day, night, rain, fullMoon, duskOnly
}

/// One catchable species at the Pond. `id` is also its inventory item id
/// suffix: the item is `fish-<id>`, and its icon lives in the `fish-<id>`
/// image set.
struct Fish: Identifiable {
    let id: String
    let name: String
    let rarity: Rarity
    /// Base sell price in coins (the shop's coziness bonus applies on top,
    /// and a Perfect catch pays half again at the pond).
    let value: Int
    let conditions: Set<FishCondition>
    let description: String
    /// Plausible size range in cm; each catch rolls inside it.
    let sizeCM: (min: Int, max: Int)

    static func find(_ id: String) -> Fish? { all.first { $0.id == id } }

    /// The species in the pool right now, given the time block, the weather
    /// and the moon. The Old Dockmaster leaves the pool forever once caught.
    static func pool(isNight: Bool, isDusk: Bool, isRaining: Bool, isFullMoon: Bool, dockmasterCaught: Bool) -> [Fish] {
        all.filter { fish in
            if fish.id == "old-dockmaster" && dockmasterCaught { return false }
            if fish.conditions.contains(.fullMoon) && !isFullMoon { return false }
            if fish.conditions.contains(.duskOnly) && !isDusk { return false }
            let dayOK = fish.conditions.contains(.day) && !isNight
            // Full-moon fish swim at night, on their nights (gated above).
            let nightOK = (fish.conditions.contains(.night) || fish.conditions.contains(.fullMoon)) && (isNight || isDusk)
            let rainOK = fish.conditions.contains(.rain) && isRaining
            return dayOK || nightOK || rainOK
        }
    }

    /// Rarity weights for the bite roll: commons dominate; legendaries are a
    /// sliver. Returns a random species from the pool, weighted by tier.
    static func roll(in pool: [Fish]) -> Fish? {
        guard !pool.isEmpty else { return nil }
        func weight(_ fish: Fish) -> Double {
            switch fish.rarity {
            case .common: return 62
            case .uncommon: return 24
            case .rare: return 9
            case .epic: return 4
            case .legendary: return 1
            }
        }
        let total = pool.reduce(0) { $0 + weight($1) }
        var ticket = Double.random(in: 0..<total)
        for fish in pool {
            ticket -= weight(fish)
            if ticket <= 0 { return fish }
        }
        return pool.last
    }

    static let all: [Fish] = [
        Fish(id: "bluegill", name: "Bluegill", rarity: .common, value: 12, conditions: [.day], description: "A cheerful little sunfish, blue at the gills.", sizeCM: (min: 8, max: 25)),
        Fish(id: "pumpkinseed", name: "Pumpkinseed", rarity: .common, value: 14, conditions: [.day], description: "Orange-spotted and round as a pumpkin seed.", sizeCM: (min: 8, max: 25)),
        Fish(id: "pond-minnow", name: "Pond Minnow", rarity: .common, value: 8, conditions: [.day, .night], description: "Tiny, silver, and always in a hurry.", sizeCM: (min: 3, max: 9)),
        Fish(id: "golden-shiner", name: "Golden Shiner", rarity: .common, value: 15, conditions: [.day], description: "Flashes gold when it turns in the light.", sizeCM: (min: 3, max: 9)),
        Fish(id: "creek-chub", name: "Creek Chub", rarity: .common, value: 10, conditions: [.day], description: "A plain, honest fish. The pond is full of them.", sizeCM: (min: 3, max: 9)),
        Fish(id: "mosquitofish", name: "Mosquitofish", rarity: .common, value: 9, conditions: [.day, .night], description: "Eats a hundred mosquitoes a day. A tiny hero.", sizeCM: (min: 3, max: 9)),
        Fish(id: "baby-koi", name: "Baby Koi", rarity: .common, value: 20, conditions: [.day], description: "Somebody's koi got out years ago. Their grandkids stayed.", sizeCM: (min: 25, max: 60)),
        Fish(id: "mud-loach", name: "Mud Loach", rarity: .common, value: 16, conditions: [.night, .rain], description: "A whiskery noodle that loves muddy weather.", sizeCM: (min: 3, max: 9)),
        Fish(id: "dace", name: "Dace", rarity: .common, value: 11, conditions: [.day], description: "Quick and silver, gone before you blink.", sizeCM: (min: 3, max: 9)),
        Fish(id: "silverside", name: "Silverside", rarity: .common, value: 10, conditions: [.day], description: "Nearly see-through, with a stripe of mirror.", sizeCM: (min: 3, max: 9)),
        Fish(id: "pygmy-sunfish", name: "Pygmy Sunfish", rarity: .common, value: 18, conditions: [.day], description: "A sunfish, but fun-sized.", sizeCM: (min: 3, max: 9)),
        Fish(id: "warmouth", name: "Warmouth", rarity: .common, value: 13, conditions: [.day], description: "Grumpy face, gentle heart.", sizeCM: (min: 8, max: 25)),
        Fish(id: "green-sunfish", name: "Green Sunfish", rarity: .common, value: 12, conditions: [.day], description: "Green as pond water in June.", sizeCM: (min: 8, max: 25)),
        Fish(id: "redear", name: "Redear Sunfish", rarity: .common, value: 14, conditions: [.day], description: "Has a little red ear and a big appetite for snails.", sizeCM: (min: 8, max: 25)),
        Fish(id: "black-bullhead", name: "Black Bullhead", rarity: .common, value: 17, conditions: [.night], description: "A baby catfish with whiskers longer than its body.", sizeCM: (min: 8, max: 25)),
        Fish(id: "fantail-darter", name: "Fantail Darter", rarity: .common, value: 15, conditions: [.day], description: "Darts between rocks, showing off its fancy tail.", sizeCM: (min: 3, max: 9)),
        Fish(id: "swamp-guppy", name: "Swamp Guppy", rarity: .common, value: 10, conditions: [.day, .night], description: "Rainbow-tailed and utterly unbothered.", sizeCM: (min: 3, max: 9)),
        Fish(id: "honey-gourami-minnow", name: "Honey Minnow", rarity: .common, value: 16, conditions: [.day], description: "The color of the beekeeper's best jar.", sizeCM: (min: 3, max: 9)),
        Fish(id: "yellow-perch", name: "Yellow Perch", rarity: .uncommon, value: 45, conditions: [.day], description: "Striped like a tiny tiger.", sizeCM: (min: 20, max: 45)),
        Fish(id: "white-crappie", name: "White Crappie", rarity: .uncommon, value: 48, conditions: [.day, .night], description: "Pale and speckled, a morning-mist fish.", sizeCM: (min: 20, max: 45)),
        Fish(id: "rainbow-dace", name: "Rainbow Dace", rarity: .uncommon, value: 55, conditions: [.day], description: "Breeding colors: a sunset in fish form.", sizeCM: (min: 3, max: 9)),
        Fish(id: "rosy-barb", name: "Rosy Barb", rarity: .uncommon, value: 50, conditions: [.day], description: "Blushes pink when it's happy. It's often happy.", sizeCM: (min: 8, max: 25)),
        Fish(id: "golden-tench", name: "Golden Tench", rarity: .uncommon, value: 60, conditions: [.day], description: "Smooth, golden, and slippery as soap.", sizeCM: (min: 20, max: 45)),
        Fish(id: "speckled-bass", name: "Speckled Bass", rarity: .uncommon, value: 65, conditions: [.day], description: "The pond's middleweight champion.", sizeCM: (min: 20, max: 45)),
        Fish(id: "lily-trout", name: "Lily Trout", rarity: .uncommon, value: 70, conditions: [.day], description: "Sleeps under the lily pads, dreams in green.", sizeCM: (min: 20, max: 45)),
        Fish(id: "glass-catfish", name: "Glass Catfish", rarity: .uncommon, value: 58, conditions: [.night], description: "You can see its heartbeat. Be gentle.", sizeCM: (min: 35, max: 80)),
        Fish(id: "pearl-gourami", name: "Pearl Gourami", rarity: .uncommon, value: 62, conditions: [.day], description: "Covered in tiny pearls, trailing ribbons.", sizeCM: (min: 8, max: 25)),
        Fish(id: "ember-tetra", name: "Ember Tetra", rarity: .uncommon, value: 52, conditions: [.night], description: "Glows faintly orange, like a coal that learned to swim.", sizeCM: (min: 3, max: 9)),
        Fish(id: "violet-goby", name: "Violet Goby", rarity: .uncommon, value: 57, conditions: [.night, .rain], description: "Purple, shy, and fond of rainy nights.", sizeCM: (min: 8, max: 25)),
        Fish(id: "bumblebee-catfish", name: "Bumblebee Catfish", rarity: .uncommon, value: 66, conditions: [.night], description: "Striped black and gold. Silas swears it hums.", sizeCM: (min: 35, max: 80)),
        Fish(id: "sakura-koi", name: "Sakura Koi", rarity: .uncommon, value: 85, conditions: [.day], description: "Petal-pink scales, drifts like falling blossom.", sizeCM: (min: 25, max: 60)),
        Fish(id: "reed-pikelet", name: "Reed Pikelet", rarity: .uncommon, value: 54, conditions: [.day, .rain], description: "A sliver of a pike, hiding in the reeds.", sizeCM: (min: 8, max: 25)),
        Fish(id: "moonlit-koi", name: "Moonlit Koi", rarity: .rare, value: 140, conditions: [.night], description: "Its scales hold a little of the moon.", sizeCM: (min: 25, max: 60)),
        Fish(id: "starfin-trout", name: "Starfin Trout", rarity: .rare, value: 150, conditions: [.night], description: "Fins speckled with stars. Only bites after dark.", sizeCM: (min: 20, max: 45)),
        Fish(id: "crystal-carp", name: "Crystal Carp", rarity: .rare, value: 165, conditions: [.day], description: "Scales like cut glass; handle with care.", sizeCM: (min: 25, max: 60)),
        Fish(id: "opal-betta", name: "Opal Betta", rarity: .rare, value: 130, conditions: [.day], description: "A jewel with a temper. Keep it in its own bucket.", sizeCM: (min: 8, max: 25)),
        Fish(id: "twilight-eel", name: "Twilight Eel", rarity: .rare, value: 175, conditions: [.night, .duskOnly], description: "Comes out for exactly one hour at dusk.", sizeCM: (min: 40, max: 70)),
        Fish(id: "velvet-sturgeon", name: "Velvet Sturgeon", rarity: .rare, value: 190, conditions: [.night, .rain], description: "Young, soft as velvet, older than it looks.", sizeCM: (min: 60, max: 120)),
        Fish(id: "glimmerfin", name: "Glimmerfin", rarity: .rare, value: 155, conditions: [.day], description: "Leaves a trail of sparkles in the water.", sizeCM: (min: 8, max: 25)),
        Fish(id: "dream-guppy", name: "Dream Guppy", rarity: .rare, value: 145, conditions: [.night], description: "Looking at it makes you a little sleepy.", sizeCM: (min: 3, max: 9)),
        Fish(id: "lavender-carp", name: "Lavender Carp", rarity: .rare, value: 160, conditions: [.day], description: "The exact lavender of the meadow in spring.", sizeCM: (min: 25, max: 60)),
        Fish(id: "royal-sakura-koi", name: "Royal Sakura Koi", rarity: .epic, value: 320, conditions: [.day], description: "The Sakura Koi's grandmother. She knows it, too.", sizeCM: (min: 25, max: 60)),
        Fish(id: "prism-trout", name: "Prism Trout", rarity: .epic, value: 380, conditions: [.rain], description: "Only appears in rain, bending the light.", sizeCM: (min: 20, max: 45)),
        Fish(id: "ghost-carp", name: "Ghost Carp", rarity: .epic, value: 420, conditions: [.night], description: "Half the village says it isn't real. It is.", sizeCM: (min: 25, max: 60)),
        Fish(id: "thunder-loach", name: "Thunder Loach", rarity: .epic, value: 350, conditions: [.rain], description: "Arrives with the storm, gone before it ends.", sizeCM: (min: 3, max: 9)),
        Fish(id: "celestial-angel", name: "Celestial Angelfish", rarity: .epic, value: 460, conditions: [.night], description: "Fins like a comet's tail.", sizeCM: (min: 20, max: 45)),
        Fish(id: "aurora-sturgeon", name: "Aurora Sturgeon", rarity: .epic, value: 500, conditions: [.night], description: "Its back shimmers green and violet in the dark.", sizeCM: (min: 60, max: 120)),
        Fish(id: "moonkoi", name: "The Moonkoi", rarity: .legendary, value: 1200, conditions: [.fullMoon], description: "Said to be the moon's reflection, learned how to swim. Appears only under a full moon.", sizeCM: (min: 30, max: 55)),
        Fish(id: "old-dockmaster", name: "The Old Dockmaster", rarity: .legendary, value: 1000, conditions: [.night], description: "An ancient catfish who has watched the dock for fifty years. He lets you catch him once.", sizeCM: (min: 90, max: 140)),
        Fish(id: "seraphin", name: "Seraphin", rarity: .legendary, value: 1500, conditions: [.fullMoon], description: "White and gold, with fins like little wings. Nobody knows where it came from.", sizeCM: (min: 25, max: 40)),
    ]
}

