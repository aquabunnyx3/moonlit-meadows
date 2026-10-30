# Moonlit Meadows — The Pond & Fishing
### Requested by Michelle, 2026-10-30. Design + fish spec for Claude. Art by Merlin.

## 1. The Pond (new area)

- A third explorable area alongside the Farm and the City Hub: **the Pond** — the same pond from the story (see moon-bunny-story-bible.md). Scene art: `pond-scene.png` in moonlit-fishing/ — per Michelle (2026-10-30) it is a **forest pond**: ringed by pines, oaks and blossom trees, willow on the left bank, dock on the near shore, narrow footpath in through the trees; NO farm/fields/fences in frame (the first farm-edge version is kept as pond-scene-farm-version.png). Connections: Farm ↔ Pond (forest path). Its own collision map per the standing spec (water blocked except the dock; dock = walkable + fishing trigger zone; reeds/trees blocked; exit path as trigger).
- Story role: Moon Bunny sightings weight here; the Reveal and Finale scenes play on this dock (§4 of the bible). At night it uses the standard night lighting; fireflies + moon reflection are baked into the night variant later if wanted.
- Day use: fishing (below), forage spawns (reeds, lily), a bench. Keep it calm — this is the quiet place.

## 2. Fishing mini-game (Michelle's design, fleshed out)

**Flow:**
1. Player walks onto the dock, faces the water, presses the **action button** → fishing starts.
2. **The screen switches to a first-person view** (`fishing-fpv.png` mock in moonlit-fishing/): from the dock over the water, the farmer's hands holding the rod at the bottom of frame (first-person — hands only, consistent with the game's FPV scene rule), bobber on the water, lily pads, reeds, moonpetals on the bank.
3. Cast plays automatically (rod swing + line + splash SFX). A short random wait (2–6 s), bobber bobs… then a **bite**: bobber dips, splash, exclamation cue + bite SFX.
4. **The meter round (the core mechanic — CORRECTED by Michelle, 2026-10-30):** a meter bar appears with a marker that **sweeps BACK AND FORTH** along the bar, over and over — it does NOT fill once. The player **taps the action button to stop the marker**, and the catch is a **timing** test: stop it inside the zone. Zones on the meter:
   - **Gold zone** (narrow, near the top): *Perfect* — catch + size bonus (sell value ×1.5, "Perfect!" pop).
   - **Green zone**: catch.
   - **Red/grey (marker stopped anywhere outside the green/gold zones)**: the fish escapes (line-snap SFX, "It got away…").
   Zone widths shrink and sweep speed rises with rarity tier (see spec): Common = wide/slow, Legendary = sliver/fast. The marker keeps sweeping until the player taps — no time-out; the skill is purely timing. One attempt per bite; miss = back to cast.
5. **Catch pop-up** (`catch-popup.png` mock): the fish leaps/pops up center-screen with a **"pop" SFX + sparkle burst**, card showing: fish icon, name, rarity stars (game colors: 1 green, 2 blue, 3 lavender, 4 pink, 5 gold), one-line description, size, sell value. First-ever catch of a species adds a **Collection book entry** (new "Fish" collection, 50 — mirrors the bunny book) and a "New!" tag on the pop-up.
6. Fish goes to Pantry/inventory as an item (`fish-<id>`); sellable at the Shop like crops; a few are also giftable/cooking ingredients later (out of scope here).

**Feel targets:** bite→meter→tap loop under ~8 seconds; generous on Common so kids/new players succeed early; the pond at night/full moon is where the special fish live.

**SFX (Merlin synthesizes, in moonlit-fishing/sfx/):** `sfx-fish-cast.mp3`, `sfx-fish-bobber.mp3`, `sfx-fish-bite.mp3`, `sfx-fish-reel.mp3` (during meter), `sfx-fish-catch.mp3` (pop + sparkle chime), `sfx-fish-perfect.mp3`, `sfx-fish-escape.mp3`.

## 3. Fish spec — 50 species

Rarity uses the game's star colors. Value = base sell price (gold). Conditions: D = day, N = night, R = rain, FM = full-moon night, ★ = pond-only special. All fish are catchable at the Pond unless noted; a small subset also in the farm pondlet later (out of scope).

### Common (1★ green #B8D8B0) — 18 — meter: slow sweep, wide zones
| id | name | value | when | description |
|---|---|---|---|---|
| bluegill | Bluegill | 12 | D | A cheerful little sunfish, blue at the gills. |
| pumpkinseed | Pumpkinseed | 14 | D | Orange-spotted and round as a pumpkin seed. |
| pond-minnow | Pond Minnow | 8 | D/N | Tiny, silver, and always in a hurry. |
| golden-shiner | Golden Shiner | 15 | D | Flashes gold when it turns in the light. |
| creek-chub | Creek Chub | 10 | D | A plain, honest fish. The pond is full of them. |
| mosquitofish | Mosquitofish | 9 | D/N | Eats a hundred mosquitoes a day. A tiny hero. |
| baby-koi | Baby Koi | 20 | D | Somebody's koi got out years ago. Their grandkids stayed. |
| mud-loach | Mud Loach | 16 | N/R | A whiskery noodle that loves muddy weather. |
| dace | Dace | 11 | D | Quick and silver, gone before you blink. |
| silverside | Silverside | 10 | D | Nearly see-through, with a stripe of mirror. |
| pygmy-sunfish | Pygmy Sunfish | 18 | D | A sunfish, but fun-sized. |
| warmouth | Warmouth | 13 | D | Grumpy face, gentle heart. |
| green-sunfish | Green Sunfish | 12 | D | Green as pond water in June. |
| redear | Redear Sunfish | 14 | D | Has a little red ear and a big appetite for snails. |
| black-bullhead | Black Bullhead | 17 | N | A baby catfish with whiskers longer than its body. |
| fantail-darter | Fantail Darter | 15 | D | Darts between rocks, showing off its fancy tail. |
| swamp-guppy | Swamp Guppy | 10 | D/N | Rainbow-tailed and utterly unbothered. |
| honey-gourami-minnow | Honey Minnow | 16 | D | The color of the beekeeper's best jar. |

### Uncommon (2★ blue #9CC8F0) — 14 — meter: a touch faster, zones a bit narrower
| id | name | value | when | description |
|---|---|---|---|---|
| yellow-perch | Yellow Perch | 45 | D | Striped like a tiny tiger. |
| white-crappie | White Crappie | 48 | D/N | Pale and speckled, a morning-mist fish. |
| rainbow-dace | Rainbow Dace | 55 | D | Breeding colors: a sunset in fish form. |
| rosy-barb | Rosy Barb | 50 | D | Blushes pink when it's happy. It's often happy. |
| golden-tench | Golden Tench | 60 | D | Smooth, golden, and slippery as soap. |
| speckled-bass | Speckled Bass | 65 | D | The pond's middleweight champion. |
| lily-trout | Lily Trout | 70 | D | Sleeps under the lily pads, dreams in green. |
| glass-catfish | Glass Catfish | 58 | N | You can see its heartbeat. Be gentle. |
| pearl-gourami | Pearl Gourami | 62 | D | Covered in tiny pearls, trailing ribbons. |
| ember-tetra | Ember Tetra | 52 | N | Glows faintly orange, like a coal that learned to swim. |
| violet-goby | Violet Goby | 57 | N/R | Purple, shy, and fond of rainy nights. |
| bumblebee-catfish | Bumblebee Catfish | 66 | N | Striped black and gold. Silas swears it hums. |
| sakura-koi | Sakura Koi | 85 | D | Petal-pink scales, drifts like falling blossom. |
| reed-pikelet | Reed Pikelet | 54 | D/R | A sliver of a pike, hiding in the reeds. |

### Rare (3★ lavender #C3A6F2) — 9 — meter: fast, green zone narrow
| id | name | value | when | description |
|---|---|---|---|---|
| moonlit-koi | Moonlit Koi | 140 | N | Its scales hold a little of the moon. |
| starfin-trout | Starfin Trout | 150 | N | Fins speckled with stars. Only bites after dark. |
| crystal-carp | Crystal Carp | 165 | D | Scales like cut glass; handle with care. |
| opal-betta | Opal Betta | 130 | D | A jewel with a temper. Keep it in its own bucket. |
| twilight-eel | Twilight Eel | 175 | N | Comes out for exactly one hour at dusk. |
| velvet-sturgeon | Velvet Sturgeon | 190 | N/R | Young, soft as velvet, older than it looks. |
| glimmerfin | Glimmerfin | 155 | D | Leaves a trail of sparkles in the water. |
| dream-guppy | Dream Guppy | 145 | N | Looking at it makes you a little sleepy. |
| lavender-carp | Lavender Carp | 160 | D | The exact lavender of the meadow in spring. |

### Epic (4★ pink #F59BC4) — 6 — meter: very fast, gold zone tiny
| id | name | value | when | description |
|---|---|---|---|---|
| royal-sakura-koi | Royal Sakura Koi | 320 | D | The Sakura Koi's grandmother. She knows it, too. |
| prism-trout | Prism Trout | 380 | R | Only appears in rain, bending the light. |
| ghost-carp | Ghost Carp | 420 | N | Half the village says it isn't real. It is. |
| thunder-loach | Thunder Loach | 350 | R | Arrives with the storm, gone before it ends. |
| celestial-angel | Celestial Angelfish | 460 | N | Fins like a comet's tail. |
| aurora-sturgeon | Aurora Sturgeon | 500 | N | Its back shimmers green and violet in the dark. |

### Legendary (5★ gold #F5C95B) — 3 — meter: fastest, a sliver of gold
| id | name | value | when | description |
|---|---|---|---|---|
| moonkoi | The Moonkoi | 1200 | FM ★ | Said to be the moon's reflection, learned how to swim. Appears only under a full moon. |
| old-dockmaster | The Old Dockmaster | 1000 | N ★ | An ancient catfish who has watched the dock for fifty years. He lets you catch him once. |
| seraphin | Seraphin | 1500 | FM ★ | White and gold, with fins like little wings. Nobody knows where it came from. |

**Story tie-ins (quiet, no spoilers in text):** the Old Dockmaster's "once" = one catch ever (flag), and he is catchable pre-Reveal — his description is written to ache a little on a second read. The Moonkoi/Seraphin only exist on full-moon nights, the same nights the Moon Bunny is strongest.

## 4. Assets

- Merlin (in moonlit-fishing/): pond scene art, FPV fishing screen, catch pop-up mock, 50 fish icons (`fish-<id>.png`, transparent, style matched to the game's icon sets), the 7 SFX above.
- Claude: area + collision, mini-game state machine (idle → cast → wait → bite → meter → resolve), meter difficulty per rarity tier, pop-up UI (mirror the mock), Fish collection page, inventory/sell wiring, story flags for Dockmaster/Moonkoi.
