# Claude prompt — everything since the intro redo request (2026-10-30)

Paste everything below the line into Claude.

---

Work through this list in order. All art/audio/video assets are Merlin-made files Michelle
will hand you (folder names given per item). Push to main as usual. Everything new must be
migration-safe: old saves get the new flags with the defaults noted, nothing resets.

## 1. Asset swaps (quick installs)
- **Bedtime videos redo:** replace all 12 bedtime datasets with the clips in
  `moonlit-bedtime-scenes/moonlit-bedtime-scenes-redo.zip` (folder `redo/`). Same dataset
  names as the current ones — straight swap, no code change.
- **Clear-night weather icon:** `moonlit-icons/weather-clearnight.png` replaces the last
  remaining weather emoji (clear night), same as the other four weather icons you installed.
- **Bunny breeds:** all 50 final icons are in `moonlit-breeds/`, named `breed-<breedID>.png`
  matched to the IDs in `breed-spec-from-code.swift` (also in that folder). Install all 50.
  **Cocoa/Nutmeg fix:** the brown lop is **Cocoa** (`cocoaBunny` — chocolate lop per spec).
  Nutmeg is upright ears + leaf sprout — use `breed-nutmegBunny.png` for Nutmeg and
  `breed-cocoaBunny.png` for Cocoa.
- **Sol's daily outfits:** in `moonlit-sol-outfits/`, outfit 2 (lavender pinafore) and
  outfit 3 (mint overalls) each have front/back/walk-left/walk-right sprites + a chat scene.
  Add them to Sol's daily outfit rotation alongside her default look. For the chat scenes
  use `sol-outfit2-chat.png` and `sol-outfit3-chat.png` (the ANIME versions — do NOT use
  the `-pixel` files).

## 2. Glass door mechanism (June + Silas)
Only these two homes have outdoor areas (June's patio, Silas's porch). Final interiors:
`interior-june-v3.png` and `interior-silas-v7.png` (in `moonlit-city-hub/interiors/`).
- The glass door sits in the SIDE wall at an angle (Silas v7: a double glass door filling
  the porch-side opening). The doorway is a **walk-through trigger zone — never in the
  blocked collision set**, inside or outside.
- When the farmer enters the approach zone on either side, the door panel slides open
  (crop the panel from the art as its own sprite and slide it along the wall) and plays
  `sfx-glass-door-open.mp3`; when she leaves the zone it slides shut and plays
  `sfx-glass-door-close.mp3` (both in `moonlit-sfx/`).
- No action-button press needed — walking through is enough. Villagers don't use these
  doors. Keep the slide quick (~0.35s) and don't let it block movement mid-slide.

## 3. City hub v2 + Friends tab + villager locations
- Replace the hub map with `city-hub-map-v2.png` (`moonlit-city-hub/`): fences removed,
  wide paths, one big obvious main route, plaza center clean. Re-derive the hub collision
  from the new art per the standing spec (per-scene map, feet-only collision box,
  slide-along-walls, doors/exits as trigger zones). The debug overlay stays dev-only.
- **Friends tab:** remove the Chat and Apologize buttons from the bottom of the tab —
  chatting and apologizing happen in-world only. Move the info block (name / stage /
  hearts / Favorites) to the BOTTOM of the tab.
- **Villager locations:** stop rendering everyone in the hub at once. Roughly half the
  villagers are home and half are out, rotating by day-block, with walking transitions
  between places (cap ~6 villagers rendered in the hub). Villagers at Friend stage or
  higher occasionally visit the farm.

## 4. Pond area + fishing (full spec is authoritative)
Read `moonlit-fishing/fishing-design-and-fish-spec.md` — it has the complete design and
all 50 fish (IDs, rarity, sell values, day/night/rain/full-moon conditions, pop-up text).
- New third area, **the Pond**: forest pond, art `pond-scene.png`, path in from the farm.
  (This is also the story pond for §5.) Ignore `pond-scene-farm-version.png`.
- Mechanic: stand on the dock, press the action button → view switches to the first-person
  fishing view (`fishing-fpv.png` — exactly ONE bobber, on the line; don't draw another).
  Cast (`sfx-fish-cast`, bobber `sfx-fish-bobber`; loop `fishing-anim-wait.mp4`) → bite
  (`sfx-fish-bite`) → **the timing meter: a marker sweeps BACK AND FORTH across the bar
  repeatedly; the player taps the action button to STOP the marker.** Gold sliver =
  Perfect (×1.5 value, `sfx-fish-perfect`), green zone = catch (`sfx-fish-reel` +
  `fishing-anim-catch.mp4`, silhouette fish), anywhere else = escape (`sfx-fish-escape`).
  No time-out — the marker keeps sweeping until tapped. Sweep speed rises and zone width
  shrinks with rarity.
- On a catch, the fish pops up on screen: name, TRUE rarity stars (game star colors),
  description, size, value (`catch-popup.png` is only a layout mock — render real stars).
- 50 icons in `moonlit-fishing/icons/fish-<id>.png`; 7 SFX in `moonlit-fishing/sfx/`.
  Add a **Fish collection (50)** mirroring the bunny book. The Old Dockmaster is catchable
  exactly once ever (flag). Moonkoi and Seraphin: full-moon nights only.

## 5. Story: The Moon Bunny + dialogue pacing (bible is authoritative)
Read `moonlit-story/moon-bunny-story-bible.md` end to end before touching dialogue.
Locked story: the farmer spent one childhood summer here; her best friend was **Theo**
(existing villager — no new character) and together they raised a white bunny, **Mochi**.
During a night storm at the farm pond she fell off the dock, nearly drowned, hit her head,
and forgot the whole summer; her parents took her home and never spoke of the valley.
Theo pulled her out and has blamed himself ever since — that guilt + being forgotten is
why he is cold. Mochi lived out her life with him, died just before the game opens, and
her spirit (the Moon Bunny) now appears at the pond on clear moonlit nights.
Implement per the bible: sightings + "???" collection entry, kid-treasure gifts, memory
fragments tied to Theo's friendship, the buried time capsule (drawings, blurred photo,
his half of a carved moon charm — hers was lost in the storm), the night reveal scene on
the pond dock, and the full-moon finale (bunny leaves her charm half; the capsule photo
becomes a placeable farmhouse item, now clear).
Flags, all defaulting false on old saves: `met_moon_bunny`, `bunny_sightings`,
`memory_fragments`, `capsule_opened`, `reveal_done`, `finale_done`.
**Pacing overhaul (bible §5) applies game-wide:** warmth tiers (most villagers warm, two
shy/slower, one Guarded confidant close to Theo, Theo on a special track — 60% friendship
gain until the reveal, flat gift reactions EXCEPT bunny/moon items which crack him from
day one, won't talk on stormy days before the reveal, his storm lines become his best
after it). **Address & Affection Ladder:** every dialogue line carries a min-stage tag —
Strangers get full names / "the new farmer" and NO nicknames, pet names, or flirting from
anyone; first names at Acquaintance; friendly nicknames/teasing at Friend; pet names and
sweet/flirty lines ONLY at Companion+ and only on the romance track.

## 6. New intro + "Let's get started" + tutorial
- Install `moonlit-intro-drama/intro-drama-female.mp4` (88s) and `intro-drama-male.mp4`
  (76s). The intro plays AFTER farmer creation; pick the file matching the farmer's
  gender. It REPLACES the old intro / key-handover sequence entirely. (First-person anime;
  narration is the farmer's internal thoughts; the videos carry their own ducked music.)
- When the intro ends: cut to the farm, farmer at the gate, and show the **"Let's get
  started!"** pop-up exactly per `moonlit-intro-drama/lets-get-started-popup.md` — action
  button dismisses it (flag `intro_welcome_seen`, one-time) and hands straight into the
  tutorial.
- Build the tutorial system per `moonlit-tutorial/tutorial-design.md`: the short locked
  post-intro **Tour** (D-pad → plant → water → Pantry → Journal; screen locked to the
  highlighted control, wrong tap shows "Try tapping the [feature] again to proceed"), then
  the 12 first-time **Moment** tutorials as they occur — including the two forced quests:
  first harvest → **"First Sale"** (must sell a crop at the Shop) and the first real
  conversation with Theo, where he mentions fishing → **"Something Fishy"** (catch any
  fish at the pond and bring it back to him).

Commit per section so Michelle can test in chunks in Playgrounds.
