# Art assets: what's placeholder and what's missing

Saved for later: `MenuArt/` holds three large bunny illustrations for a future main menu.

Characters use only the illustrated art (the old shape-drawn characters are gone). Heads are matched in size across characters by scaling each image inside its canvas, so new character art should keep the same head size as the existing art. The list below tracks what's added and what's still missing.

## Highest impact

| Asset | Count | Where it's drawn now | Suggested format |
|---|---|---|---|
| Bunny breed illustrations (collection book) | 50 — **added** from the Bunny Collection sheet, but low resolution (about 100 px per bunny, upscaled to 512) | `Assets.xcassets/breed-<id>.imageset`; replace a file to upgrade it | 512×512 or larger PNG per breed, transparent |
| Bunny idle animation frames | 50 × ~4–8 | `Motion` in `BunnyView.swift` animates the shape art | Sprite sheets or Lottie, one per behavior (12 behaviors) |
| Character portraits | **Added** for all five main characters and the villagers Wes, Bree and Vi. `person-<id>` is the big portrait in dialogs and profiles; `face-<id>` is the head crop for small icons. Expressions (happy, blushing) would be a nice extra | `Assets.xcassets`, used by `PersonPortrait` and the dialog stage in `StoryView.swift` | Full-body PNG, transparent |
| Sol's daily outfits | 1 of 3 — Sol now has one illustrated outfit. Add `person-sol` variants to bring back daily style changes | `Person.looks` | Same style as the other portraits |
| Character walking sprites | **Added** for Theo, June, Kai and Sol: `walk-<id>-left/right/back` (Theo and Kai also have `-front`). everyone now has a front frame too | `PersonFigure(facing:)` | One frame per direction, transparent |
| Farmer (player) | **Added**: female and male, 2 hairstyles each. Each pose is `farmer-<female|male>-s<0|1>-<person|face|front|back|left|right>` plus a matching `-labels` image that marks skin, hair, eyes, jacket, top, pants, and boots. The game recolors those parts live for the 4 skin tones, 10 hair colors, 5 eye colors, and every outfit. To add a new hairstyle or a new outfit shape, add the same set of images (the labels can be made from the art with the scratchpad `seg.py` tool) | `FarmerRenderer` in `PersonView.swift`, creator in `Presenters.swift` | Same style as the default set |
| Chat scenes | **Added** for June, Roz, Kai, Sol, Wes, Bree, Vi and both farmers (`chat-<id>`, text removed; the game writes names and lines into the boxes). every character and every farmer look now has one (Theo included) | `ChatScene` in `StoryView.swift`; box positions in `ChatLayout` | 2000×1136, box in the same style |
| Story chapter illustrations (CGs) | 40 (optional: 10 finales and dates first) | `StoryPlayer` shows the portrait over a gradient | 16:9 illustrations |
| Collection-complete scene | 1 | `CompletionView` | Full illustration |

## World and UI

| Asset | Where now |
|---|---|
| Meadow background | **Added**: `world-meadow`, the pixel-art meadow (2096×1184). Night, dawn and dusk are a soft tint over it. Layout spots for beds, the field, the lure garden, the bunny habitat and all 26 decorations are in `WorldLayout` and `Decor` |
| Cottage, trees, beds, field, and lure garden | **Part of the world art**; a drawn fallback (`DrawnScenery`) is used only if the art is missing |
| Lure garden and baskets | `LureGarden` (🧺 emoji) |
| Farmer outfits | All 10 outfits are color schemes on the leather-jacket-and-jeans art. New outfit *shapes* (a hoodie, a dress, overalls) need their own art set |
| 7 magical crop icons (moonflower, starberry, crystal carrot, golden clover, dream plum, aurora tulip, comet corn) | `ItemIcon` hue-shifts a base emoji and adds a glow |
| 26 decorations | Emoji in `DecorSprite` |
| 7 bunny accessories, 11 keepsakes, 8 outfit icons | Emoji |
| App icon | Swift Playgrounds placeholder (heart) |

| Control deck background | **Added**: `panel-paper` (lavender pixel paper, mockup buttons and text removed). The tiles, chips, plots and buttons are restyled in code to match the mockup (`pixelPanel` in `Theme.swift`) |

## Notes

- Emoji look different on other platforms, but on iPhone and iPad they're consistent.
- Accessibility: art views are hidden from VoiceOver, and the surrounding labels describe them. Keep that when you replace the art.
