# Moonlit Meadows — Story Bible: "The Moon Bunny"
### Locked by Michelle, 2026-10-30. The mix of Twist 1 (Moon Bunny) + Twist 2 (Forgotten Summer), with the tragedy set at the farm: the storm at the pond.

This document is the single source of truth for the plot twist, the dialogue pacing overhaul, and the beats Claude needs to implement. Merlin writes assets/lines; Claude implements.

---

## 1. The premise (what actually happened)

- One childhood summer, long before the game, the farmer (age ~8) stayed in Moonlit Meadows. Her two best friends that summer were a village boy — **the Friend** (see casting) — and a little moon-white bunny the two kids found, raised, and adored together.
- Near the summer's end, during a night storm, the kids were out by the **farm pond** chasing the bunny. The dock was slick. The farmer fell in, nearly drowned, and struck her head.
- The Friend pulled her out. She woke days later in a city hospital with the whole summer gone. Her frightened parents took her home, never brought her back, and never spoke of the valley again. His letters came back unopened (her parents' doing, not hers).
- The bunny lived out its life with the Friend and died shortly before the game opens.
- Now the farmer returns "for a fresh start," remembering nothing. The village remembers everything — and, following the old doctor's advice and then habit, says nothing.
- On clear moonlit nights, a small white bunny appears around the farm and the pond. **It is the spirit of that summer's bunny, and it came back because she did.**

## 2. Casting

- **The Friend** — the childhood best friend. Merlin's recommendation: **Theo, the tan, quiet, moon/observatory villager** — his theme is already the moon, he's already written as the guarded one, and of course *he's* the one who's also been seeing the bunny. (If Michelle prefers, Kai is the alternate; the bible works either way — swap the name throughout.)
- **The Host** (intro host, braid/cardigan/lantern) — recognizes the farmer the moment she arrives. Warm, a half-second too careful. She enforces the village's silence out of love, and she is the one who finally helps the truth surface.
- **The Confidant** — one villager close to the Friend (pick whoever has the warmest existing dynamic with him) who is mildly cool/protective toward the farmer early on: they've watched what her leaving did to him.
- Everyone else: genuinely warm, with occasional slips (see §6).

## 3. Why he is cold (the rule every writer/implementer must hold)

His coldness is **guilt wearing a mask**, not cruelty:
- He blames himself — he was the one who said "come on, just a little further."
- She smiles at him like a stranger. To him, she gets to be free of it; he never has been.
- So: short lines, flat gift reactions, conversations that end early, and **slower friendship gains than anyone else in the game** (see §5). He is never nasty. He's a kind person armored up. The player should feel "why does THIS one dislike me?" from the first hour.

## 4. Story beats (structure)

**Act 1 — The Hook (first ~7 in-game days)**
- Arrival; the Host's careful warmth; meeting the Friend lands wrong (he goes quiet, leaves early).
- First clear night: the **Moon Bunny** appears at the farm gate. It doesn't run from her. Journal/collection entry unlocks: "??? — a bunny that only comes out under the moon."
- Villager slips begin (§6). The player has two mysteries: the bunny, and him.

**Act 2 — Fragments (friendship building)**
- Bunny sightings continue at story spots: the gate, the big tree, and always back to **the pond**. It leaves tiny "kid treasure" gifts on the step: a ribbon, a smooth stone, a pressed flower.
- As the Friend's friendship stage rises (slowly), the farmer gets **memory fragments**: 5–10 second soft-focus flash scenes — two kids laughing, carved initials in a tree, small hands holding a bunny. No dialogue in fragments; just images and the bunny.
- Villagers' reactions to the bunny deepen ("It sits where you two — where *she* used to sit.").
- **Time capsule**: mid-game, the Friend (or the bunny, by digging spot) leads to the capsule the kids buried: kid drawings, a photo of two children (faces soft/blurred), and **his half of a pair of carved charms**. Hers is missing — lost the night of the storm.

**Act 3 — The Reveal (the pond, at night)**
- Trigger: after the capsule + the Friend at Companion stage, on a clear night the bunny waits at the pond dock and does not leave. Follow it.
- The memory returns in full: the storm, the water, his hand pulling her out. Cutscene/flash sequence, gentle, not graphic.
- The confrontation scene: he finally says it — "It was my fault. It was always my fault." She tells him the truth: it wasn't, and she didn't choose to forget him. This is the emotional peak of the game.
- His dialogue set fully unlocks from here (warm set + romance track finally possible).

**Finale — The Full-Moon Goodbye**
- On the next full moon, at the pond, with both of them present: the bunny does one last happy binky in the moonlight, hops into the glow, and is gone.
- It leaves behind **her half of the carved charms** on the dock.
- The pair of charms becomes a keepsake item; the collection book's "???" entry resolves to the bunny's name (the kids' name for it — Claude/Merlin to name on Michelle's approval; suggestion: **"Mochi"**).
- Post-finale: the Friend's full warm/romance dialogue, and a framed photo (the capsule photo, now clear) can be placed in the farmhouse.

## 5. Dialogue pacing overhaul (applies game-wide)

Michelle's direction: friendships and romance grow **gradually**; nobody flirts early; some villagers are deliberately shy, short, or harder to get close to.

**Warmth tiers (starting disposition):**
- **Warm** (most villagers): friendly from day one, but "friend" content still gates at Friend stage as before.
- **Shy** (2 villagers, Claude's pick from the quieter cast): short lines early, few words, longer pauses; their line count per stage starts low and grows the most — the reward is watching them open up.
- **Guarded** (the Confidant): polite but cool until mid-game.
- **The Friend**: his own track (below).

**Romance gating (all romanceable villagers):**
- No flirt lines, no blush scenes, no romantic gifts bonuses before **Companion** stage. Before that: friendship language only.
- Dating content only after the existing Together/date unlock; romance dialogue written as *deepening* something established, never instant.

**Address & affection ladder (Michelle, 2026-10-30 — applies to every villager, no exceptions):**
The relationship must *feel* like strangers growing close. How a villager addresses and talks to the farmer is locked to stage:
- **Stranger:** formal and a little distant. Full name or "the new farmer." No nicknames, no pet names, no sweet talk, no flirting — from anyone, however warm their tier. Polite small talk only.
- **Acquaintance:** first name. Friendly, still no pet names or sweetness.
- **Friend:** *friendship* warmth unlocks — teasing, inside jokes, and friendly nicknames are okay (e.g. "trouble," "sleepyhead"). Still NOT romantic: no pet names, no sweet/flirty lines.
- **Companion:** affection unlocks on the romance track only — this is the first stage where sweet talk, pet names (e.g. "honey," "love," character-specific ones), and flirt lines may appear, and only from a villager the player is actively romancing.
- **Dating / Beloved:** full pet names and sweetness, unique per character.
Implementation: every dialogue line and gift reaction carries a minimum-stage tag; pet-name/sweet/flirt lines are tagged Companion+ AND romance-track-only, so they can never surface early. The Friend follows the same ladder, just slower (and his early "distance" reads as the mystery, per §3).

**The Friend's special track:**
- Friendship point gain rate: **60% of normal** until the Reveal; normal after.
- Gift reactions: flat/neutral text for loved gifts until the Reveal ("...Thanks."), with ONE exception — anything bunny- or moon-related gets a visible crack (a longer pause, a surprised line) from the start. This is a deliberate breadcrumb.
- His chat is unavailable/ends early on stormy days before the Reveal (he won't be near the pond, and he won't talk). After the Reveal, stormy-day dialogue becomes some of his best lines.
- Stage names/progression stay the same; only his pacing and tone differ.

## 6. Villager reaction dialogue (themes + sample lines)

Written to slot into the existing per-villager daily/gift/chat pools. Merlin can record any of these as voice lines on request.

*About the bunny (early, mysterious):*
- Host: "That little one only shows itself on clear nights. It... likes you, I think."
- Villager: "Funny. It sits by the pond where you two — where *she* used to sit. Never mind me."
- Villager: "I've lived here all my life. That bunny is not in any of my books."

*About him (early, the player asks around):*
- Confidant: "He's not unkind. He's just... still waiting for an apology the world owes him. Don't push."
- Host: "Give him time, dear. Some folks take longer to thaw. He has his reasons — they aren't yours to carry. Not yet."

*Mid-game cracks (his lines, pre-Reveal):*
- Friend (given a moon/bunny item): "...You always did have a soft spot for—" *(stops)* "Nothing. Forget it."
- Friend (rainy day, rare line): "Stay off the dock when it storms. ...Just do it."

*Post-Reveal (samples):*
- Friend: "Fifteen years I carried that night. You carried it for one summer and it still found its way back to you. Maybe we can put it down together now."
- Host: "Oh, thank the moon. I hated keeping that secret from you, dear. Hated it every single day."

## 7. Claude implementation notes

- **Story flags:** `met_moon_bunny`, `bunny_sightings` (count), `memory_fragments` (count, gates at Friend-stage thresholds with the Friend), `capsule_opened`, `reveal_done`, `finale_done`. Persist in save like other story state; migration-safe defaults (all false/0) so existing saves start the arc cleanly.
- **Moon Bunny entity:** spawns on clear nights (weather Sunny/Clear-Night + moon phase any for sightings; finale requires full moon), at farm gate / big tree / pond on a rotation, pond-weighted. Interactable: feed (moonpetal treats), follow (it hops a short path and vanishes in sparkle). Collection book entry "???" until `finale_done`.
- **Fragment scenes:** reuse the bedtime/date video pipeline format (short FPV-leaning clips, farmer's face not shown — hands/childhood imagery only, consistent with the romance-scene FPV rule).
- **Reveal scene:** pond at night, gated as in §4 Act 3. Storm audio + flash frames; keep it gentle.
- **Pacing:** implement §5 as per-villager config (gain multiplier + disposition tier + romance gate), Friend's overrides keyed to `reveal_done`.
- **NO new paid assets needed to start:** Merlin supplies fragment/reveal/finale clips and any new voice lines as they're written. Intro/trailer are being re-cut to tease the bunny + pond + his coldness without spoiling the reveal.

## 8. Open micro-decisions (defaults chosen; Michelle can veto)

1. The bunny's childhood name: default **"Mochi"**.
2. The Friend = **Theo** (tan/moon villager). Alternate: Kai.
3. The charm pair: two halves of a carved wooden moon. Hers surfaces at the finale.
