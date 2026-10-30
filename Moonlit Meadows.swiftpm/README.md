# Moonlit Meadows 🌙🐰

A cozy, pastel idle game for the iPhone Duo (and iPad). Grow crops, lure bunnies, discover all 50 breeds, and build friendships and romances with seven villagers (plus three friends in the village). You walk your farmer around the farm, the village and everyone's homes with the D-pad.

This is the expansion of **Bunny Meadows**. The farming, crafting, shop and idle systems are kept, and existing saves upgrade automatically.

## The gameplay loop

1. **Grow.** Plant crops on the farm. There are 57 crops across farm levels 1–20, from carrots, clover and dandelions up to thunder root, frost berries, nightshade, cotton and the starlight flower. Every bunny's favorite food from the Bunny Collection sheet is a real crop.
2. **Bake (optional).** Turn crops into treats in the Kitchen. Treats sell for more, make lovely gifts, and lure fancier bunnies.
3. **Lure.** In the Lures tab, put 1–3 items in a basket. A visitor starts walking over: you see a silhouette approaching in the world, then a ❗️ when it arrives.
4. **Discover.** Greet the visitor. New breeds get a sparkle animation and rewards, and go into your collection book. Repeat visits never count as new.
5. **Collect and care.** Bunnies join your habitat (shown in the world). You can name them, star favorites, pet them daily and dress them in accessories. Every 3 bunnies become farm helpers.
6. **Befriend.** Talk to June, Roz, Theo, Kai, Sol, Rowan and Silas daily (and Wes, Bree and Vi as friends), give gifts, show them new breeds, do activities, and finish their quests.
7. **Gift bunnies.** A favorite breed gives a big relationship boost and a special scene. The bunny moves in with them, and your collection book keeps the breed.
8. **Fall in love, or stay best friends.** Story chapters unlock at each stage. At Close Friend you choose a path, and you can change your mind later.
9. **Complete the book.** Milestones at 5, 10, 20, 35 and 50 breeds unlock decor, habitat space, outfits, accessories, and a finale scene.

Discovery is driven by clues, not luck. Each breed has a lure recipe (shown in the collection book once you reach its level or get a clue from a villager), and some need a time of day, weather or season. The most specific matching undiscovered breed always comes first, and baskets that almost match leave "sniff" clues. Seasons rotate weekly, so seasonal bunnies and festivals return every month. Nothing is missable.

## Characters

| | Pronouns | Role | Favorite breeds |
|---|---|---|---|
| **June** (Juniper Ashwell), woman | she/her | Shy herbalist at the Glasshouse | Lavender, Willow, Eucalyptus |
| **Roz** (Rosalind Okafor), woman | she/her | Bubbly baker at the Sweet Burrow | Strawberry, Honeybun, Sugarplum |
| **Theo** (Theodore Marchetti), man | he/him | Dry-humored astronomer | Midnight, Comet, Galaxy |
| **Kai** (Kai Nakamura-Hale), man | he/him | Sunny carpenter and hutch builder | Maple, Cocoa, Willowbark |
| **Sol** (Sol Rivera), **gender-fluid** | they/them | Musician and tailor at the Patchwork Atelier | Cherry Blossom, Pixel, Aurora |
| **Rowan** (Rowan Calloway), man | he/him | Blacksmith at the stone forge | Ember, Comet, Storm |
| **Silas** (Silas Okafor-Bell), man | he/him | Beekeeper at the apiary cottage | Honeybun, Daffodil, Golden |

Wes, Bree and Vi are friends you can grow close to (up to Close Friend), but not romance.

Each character has a backstory, a personality, a daily schedule (they visit your farm, stand at their spot in the village, or stay home; the Friends tab says where), loved, liked and disliked gifts, three quests, three activities (which become dates on the romance path), two dialogue questions, and **8 story chapters**: three shared, three romance and two friendship. Sol's outfit changes day to day. It's part of their style, while their story is about music and finally putting down roots.

**Relationship stages:** Stranger → Acquaintance → Friend → Close Friend → (crossroads) → Romantic Interest → Dating → Committed. On the friendship path, the last three are Best Friend → Kindred Spirit → Lifelong Friend.

**Fair-play rules:**
- Everything is earned through play. There are no purchases.
- Nothing decays, and missing days never costs anything.
- Disliked gifts give a little rather than a penalty.
- You can give one item and one bunny per person per day.
- Each bunny can only be given once.
- All 50 breeds can be collected without any romance (the self-check proves it).

## Project layout

Swift Playgrounds treats this whole folder as one app module.

**Model** (Foundation only, no SwiftUI):
- `Core.swift`: RGB colors, seeded random generator, day, time-of-day, season and weather
- `CatalogItems.swift`: 57 crops and 25 recipes (including 5 character recipes)
- `CatalogBreeds.swift`: the 50 breeds from the Bunny Collection sheet (names, rarities, favorite foods), plus looks, behaviors and lure conditions. Clover and Snowflake are the starters
- `CatalogPeople.swift`: the 5 characters, stages, schedules, dialogue, questions and quests
- `CatalogStories.swift`: 40 story chapters
- `CatalogProgress.swift`: rewards, decor, outfits, accessories, keepsakes, milestones, achievements and festivals
- `GameState.swift`: saved data (tolerant, versioned decoding) and the save stores
- `Meadow.swift`: game state, time, offline catch-up, saving
- `MeadowFarm.swift`: farming, kitchen, selling and shop (the original farm loop, extended)
- `MeadowBunnies.swift`: lures, discovery, habitat and milestones
- `MeadowPeople.swift`: talking, gifts, showing breeds, activities, quests and story chapters
- `MeadowRewards.swift`: reward granting, achievements and festivals
- `SelfTests.swift`: 20 rule tests, run from Journal → Self-check

**Views:**
- `ContentView.swift`: layouts (Laptop mode split, side-by-side, stacked)
- `WorldScene.swift` and `WorldScenery.swift`: the top-screen world
- `BunnyView.swift`: draws all 50 breeds and their idle animations
- `PersonView.swift`: character portraits and walking figures
- `ControlPanel.swift`: the tab rail
- One file per tab: `FarmTab`, `PantryTab`, `LureTab`, `CollectionTab`, `FriendsTab`, `JournalTab`, `ShopTab`
- `StoryView.swift`: story chapters, moments, the collection finale and the discovery celebration
- `Presenters.swift`: presents scenes and toasts from the topmost layer
- `Theme.swift`: palette, item icons and shared controls

### What changed from Bunny Meadows, and why

- **Kept and extended:**
  - `MeadowFarm.swift` (was part of `Meadow.swift`): same planting, harvest-and-replant, watering can and offline growth. Helpers now come from owned bunnies.
  - `FarmTab`: more crops, magical crop icons, and how many breeds each crop lures.
  - `ShopTab`: new Bunny Garden upgrades.
  - `WorldScene`: adds the lure garden, habitat, villagers and your farmer.
- **Merged:** `BasketTab` and `CraftTab` became `PantryTab`.
- **Replaced:**
  - The six bunny villagers and their request system in `Catalog.swift` are replaced by the 50-breed collection and the human characters' quests.
  - `BunniesTab` is replaced by `CollectionTab` and `FriendsTab`.
- **Saving:** v2 format under a new key. Old `bunnyMeadows.save.v1` saves are read and upgraded: coins, level, inventory, plots, decor and upgrades are kept, and the two starter breeds are added. The bundle ID is unchanged so your progress carries over.

## Artwork

- **Bunnies:** all 50 come from the Bunny Collection sheet, cut out with transparent backgrounds. They're stored in `Assets.xcassets` as `breed-<id>` (for example `breed-cloverBunny`). `BreedBunnyView` uses them automatically and falls back to the drawn placeholder for any breed without an image. The sheet art is low resolution (about 100 px per bunny), so sharper versions can replace these files one-for-one later.
- **`MenuArt/`:** three larger bunny illustrations (peach and mint, lavender, and honey with a strawberry), saved for a future main menu. They aren't used in the game yet.

## Running it

- **iPad (Swift Playgrounds):** unzip, open `Moonlit Meadows`, press ▶︎ Run. Tap **💻 Laptop mode** to split the screen like the folded phone.
- **iPhone Duo (Xcode 27.1+, needs a Mac):** open `MoonlitMeadows/MoonlitMeadows.xcodeproj`. That version detects the real fold with `reservedRegions(kind: .division)` and `onHingeChange`, and shares every other file.

## Testing

Swift Playgrounds can't run XCTest, so the tests run inside the app. Turn on developer mode first (Settings → tap **Version** 5 times), then **Journal → Self-check → Run tests**. Players never see the self-check or the collision overlay. They use a separate in-memory test save and cover:
- Catalog integrity (50 unique breeds and the rarity spread, every character and chapter, every reward reference)
- That **every breed can be discovered** by following clues alone
- Starters, new versus repeat discoveries, and time-of-day conditions
- Lure validation and cancelling
- Bunny gifting (removal, no double gifts, discovery kept) and favorite gifts
- Daily talk with no punishment for missed days, and item gift limits
- Stages, the crossroads, both paths, and changing your mind
- One-time chapters, quests, milestones and achievements
- Offline progress
- Save and load round-trip, and v1 save migration
