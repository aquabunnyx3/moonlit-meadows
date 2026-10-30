# Moonlit Meadows — Tutorial System
### Requested by Michelle, 2026-10-30. Design for Claude. Rule zero: SHORT. One idea at a time, taught by doing, never a wall of text.

## 1. The two kinds of teaching

1. **The Tour** — one guided sequence right after the intro, ~60–90 seconds, covering movement + basic farming + where the main tabs live. Nothing else. Everything beyond this is taught later, in context.
2. **Moment tutorials** — tiny pop-ups and forced quests that fire the first time the player naturally reaches a system (§3). Each one teaches exactly one thing, at the moment it becomes relevant.

## 2. The lock mechanic (applies to the Tour and to forced tutorial steps)

- When a tutorial step is active, the screen **locks**: a soft dim overlay covers everything EXCEPT a glowing cutout spotlight on the one thing to tap (the D-pad, the action button, a tab, a plot).
- All other input is swallowed. If the player taps anywhere else, the target pulses and a gentle toast reads: **"Try tapping the [feature] to proceed."** (Michelle's wording: "Try tapping *insert feature* again to proceed" — use her version verbatim in-game: e.g. "Try tapping the Action Button again to proceed.")
- The correct tap advances instantly. No timers, no fail states, no way to get stuck.
- A single line of Host/narrator text per step, max ~12 words. Voice line optional (Merlin records on request).
- Implementation: `tutorialStep` state in the existing story-flag store; spotlight = overlay view with cutout + swallow-all gesture recognizer except the target's frame; toast component reused from the Moon Bunny "???" entry pop-up.

## 3. The Tour (post-intro, at the farm gate, Host present)

| # | Spotlight | Line (Host) | Teaches |
|---|---|---|---|
| 1 | D-pad | "Let's get you moving. Try the pad." | Movement — player walks a few steps (lock releases once she's moved) |
| 2 | A marked crop plot + Action Button | "This plot's ready. Tap to plant." | Action button plants (seed pre-chosen) |
| 3 | Same plot + Action Button | "Crops get thirsty. Once more — water it." | Watering; farming brief in one line: "Plant, water, wait, pick. That's farming, dear." |
| 4 | Pantry tab | "Your seeds and crops live in the Pantry." | Pantry opens once, closes on tap |
| 5 | Journal tab | "And this Journal keeps your quests." | Journal opens; the first quest is already inside: **"Settle In"** (meet 3 villagers) |
| — | (release) | "Off you go. The village is just through the trees." | Full control. Tour flag set; never repeats. |

Farming brief is deliberately minimal — the loop is learned by the first harvest (see First Sale, below), not explained here.

## 4. Moment tutorials (first-time triggers, in rough game order)

Each fires ONCE (flag), at the natural moment, with the lock mechanic only where a tap must be taught; otherwise a toast/pop-up.

1. **First chat with any villager** → after the conversation, spotlight the **Friends tab**: "Everyone you meet lives in Friends. Hearts show how close you are." Opens once. *(Michelle's example.)*
2. **First time entering the City Hub** → toast + marker: "Villagers' homes ring the plaza. Knock, and do come in." (Also quietly teaches that villagers move around — "Folks keep their own hours here.")
3. **First gift given** → pop-up: "Gifts grow hearts. Favorites grow them faster — Friends remembers what they love." Points at the Favorites line in the Friends tab.
4. **First crop harvested** → **FORCED QUEST "First Sale"** auto-starts (cannot be abandoned): "Sell a crop at the Shop." Journal marker leads to the Shop; in the Shop, spotlight the **Sell** flow. Completing it pays out + a warm Shop line. This is how selling is taught — by doing it. *(Michelle's example.)*
5. **First conversation with Theo** → he mentions fishing, flat as ever: "Pond's through the trees. Fish bite there. If you must." → **FORCED QUEST "Something Fishy"**: go to the Pond, catch any fish, bring it back to him. First arrival at the dock fires the fishing pop-up (action button → first-person → meter, taught in one line each as it happens). Completing the quest gives his first non-flat reaction — a beat of silence, then: "...You actually caught one." (Small gold reward; big story breadcrumb — this is many players' first crack in his armor.) *(Michelle's example, character and payoff hers by design of the bible.)*
6. **First bunny spotted (wild)** → spotlight the **Bunnies tab**: "Every bunny you meet joins the collection. Some are very rare…" 
7. **First Moon Bunny sighting** → special: no lock, just the "???" collection entry pop-up and one narrator line: "That bunny only comes out under the moon." (Story beat — see bible.)
8. **First evening (18:00) reached** → toast: "Getting late. Your bed saves the day and starts a new one." Marker on the farmhouse door until she sleeps once.
9. **First rain** → toast: "Rain waters every crop for you. And the pond fish love it…" (ties weather → farming → fishing in one breath).
10. **First festival day** → Journal spotlight + plaza marker: "Festival today! The whole village will be at the plaza."
11. **First purchase at the Shop** → one-line pop-up on gold: "Gold well spent. Selling crops and fish earns more."
12. **First Request accepted (Together/Requests)** → pop-up: "Requests are little jobs from villagers. Finishing them grows hearts."

## 5. Guardrails

- Never two tutorials at once: queue them; story beats (Moon Bunny) outrank system ones.
- Never lock the screen during a timed or emotional scene — moment tutorials wait for free play.
- Every flag lives in the save with migration-safe defaults (existing saves get the moment tutorials but NOT a replayed Tour).
- All tutorial text is data (id → line, target, quest link), so wording can be tuned without code changes. Lines above are final-draft quality; Michelle can veto any.
- Total locked-input time across the whole early game: under ~3 minutes. The game teaches by letting her play.
