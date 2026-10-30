# Post-Intro "Let's Get Started" Pop-Up — Spec for Claude

## The intro videos (Merlin, 2026-10-30)
In `~/workspace/your_files/moonlit-intro-drama/`:
- `intro-drama-female.mp4` (88s) — farmer's internal-thought narration, female voice
- `intro-drama-male.mp4` (76s) — same cut, male voice
Individual narration lines are in `voice/intro-S1..S6-F/M.mp3` if per-line control is ever needed.

**Playback rule:** the intro plays AFTER farmer creation (name + look chosen). Pick the file
matching the farmer's gender. First-person anime throughout — the farmer is never shown.
Skippable on repeat plays (long-press or a skip button); never skippable mid-line on the
very first play if we want the story beats to land — your call, Michelle's word wins.

## The pop-up (the moment the intro ends)
1. Intro fades to black on the waving bunny → hard cut to the FARM, morning, farmer standing
   at the farm gate where the bunny appeared.
2. A centered pop-up card in the game's UI style (pale lavender card, pink pixel border):
   - Title: **"Let's get started!"**
   - One line under it: "Your meadow is waiting."
   - Bottom of the card: the **action button glyph** with the caption "Press to begin"
     (same adaptive action button used everywhere else).
3. The world is dimmed behind the card and input is locked to the action button only —
   same lock system as the tutorial (wrong tap → gentle pulse, no toast needed here).
4. Pressing the action button dismisses the card with the sparkle SFX and hands control
   straight into **The Tour** (see `moonlit-tutorial/tutorial-design.md` step 1: the D-pad
   highlight is already waiting).
5. One-time only: flag `intro_welcome_seen`. On later launches the game opens directly on
   the farm, no pop-up.

## Narration script (for reference / future re-records)
- S1 (arrival): "They say Moonlit Meadows chooses its farmers. I never believed that — until
  the trees opened, and there it was. My farm. My fresh start."
- S2 (farmhouse): "The farmhouse came with creaky floors, one big moon window, and a quiet I
  hadn't felt in years. Mine. All of it, mine."
- S3 (village): "The village never let me stay a stranger. June with her herbs, Roz with her
  strawberries, Sol laughing somewhere in between — everyone waved like they'd been
  expecting me."
- S4 (Rowan & Silas): "Rowan can fix anything with a heartbeat or a hinge. And Silas swears
  his bees know every secret in the valley. Maybe they do."
- S5 (pond & Theo): "Then there's the pond, hidden in the trees. Beautiful. Still. The kind
  of still that feels... familiar. Theo watches the moon from that shore. He barely looks at
  me — and I can't stop wondering why that hurts."
- S6 (the bunny): "I've never been here before. So why does my heart know the way home?
  Wait — what was that? ...Oh. Hello, little one. Have we met?"
