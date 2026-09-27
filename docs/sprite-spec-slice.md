# Sprite pipeline instructions: vertical slice units

| Prop    | Value |
|---------|-------|
| Status  | Agreed 2026-09-27 |
| Units   | 3 hero classes, 3 outlaw levy types, 3 sea-thing types |
| Pipeline | `PLAN.md` Art pipeline; evidence in `docs/art-smoke/` |

## What every unit goes through

1. **Generate a 4x4 sheet** with FLUX.2 klein base 4B plus the svntax sprite-sheet LoRA at 512x512, 50 steps, guidance 4.0, LoRA scale 1.0, seed fixed per unit. The LoRA's sheet layout is fixed: row 1 three walking frames facing down plus arms raised; row 2 walking left plus jumping left; row 3 walking right plus jumping right; row 4 walking away plus lying on the floor.
2. **Map the sheet to animations.** Idle: walk frame 2 of each facing. Walk: the three frames. Attack: arms-raised frame (down facing) and jump frames (left and right), plus a code-made lunge frame. Hit: code-made from idle (white flash, 2px knockback, red tint). Downed: the lying frame. Facing up reuses the down-facing attack mirrored.
3. **Downscale and quantise** with unfake at scale 4 to 128x128, no palette, sixteen colours, transparent background, dominant mode. Then apply the unit's colour map (identifier to palette entry) with ImageMagick or Aseprite Lua.
4. **Cut to 36x36 cells** (32 sprite plus 2px margin) in Aseprite, one layer per sheet.
5. **Overlay layers** drawn once in Aseprite, not generated: the class's weapon and shield per facing (bodies are generated with no held items, because the generator drops large held objects in walk frames), heraldry stripe, ink lines, scar marks, graft overlays, ghost overlay. The slice needs the three class weapon overlays and the heraldry stripe, a single 2px mark on the shoulder.
6. **Review** at 8x nearest-neighbour: Claude reads the PNG, checks the acceptance list below, regenerates with the next seed on failure. Jason sees the accepted sheet.
7. **Pack** with Aseprite CLI to a sheet plus JSON, build `SpriteFrames` headless.

## Prompt template

The LoRA wants its own sentence structure. Only the bracketed parts change per unit.

```
A pixel art spritesheet of a [UNIT DESCRIPTION: role, build, clothing and colours, headgear, held items]. The spritesheet is a 4 by 4 grid of four rows of frames - first row is 3 walking frames facing down and 1 frame both arms raised, second row is 3 walking frames facing left and 1 frame jumping left, third row is 3 walking frames facing right and 1 frame jumping right, fourth row is 3 walking frames back view facing up and 1 frame lying on floor. Plain flat white background.
```

Style words that go into every hero and levy description: "Bronze Age", "linen", "hide", "bronze". Sea-things add "wet", "too many joints" or "drowned".

**Colour rule (revised 2026-09-27 after three sample passes).** The LoRA mutes colour by training: material words (ochre, hide, bronze) collapse to one brown, and small accents (a belt, trim) never render. What does render is a strongly distinct primary on each large region. So the prompt names an **identifier colour** per region (bright red tunic, bright blue shield, bright yellow helmet, green blade), the sheet is quantised without a palette to about sixteen colours, and a per-unit **colour map** then swaps each identifier to its real palette entry (tunic to linen, helmet to bronze, shield to hide). Evidence: `docs/art-smoke/shield-id-compare.png`, identifiers on the left, mapped on the right, sixteen colours in clean regions. Recolouring by rule is the standard pixel-art workflow and gives full control of the world and Sea palettes for free.

## Acceptance list per sheet

- Sixteen frames present, no frame cut off, headgear intact in all four facings.
- The unit's held item is visible in the down and side facings.
- Silhouette distinguishable from every other slice unit at 32x32 on the world palette (side by side check).
- Twelve to sixteen colours after quantisation, spanning at least three hue families.
- Background keyed cleanly: no fringe pixels in the review PNG.
- The lying frame reads as downed, not dead.

## Units

### Heroes (world palette, levy origin)

| Unit | Description for the prompt | Seed | Notes |
|---|---|---|---|
| Spear | a Bronze Age levy spearman, brown skin, black hair, bright red knee-length tunic, bright blue leather cap, bare arms, empty hands | 101 | Spear and hide shield are the class overlay |
| Sling | a Bronze Age levy slinger, lean, brown skin, bright red short tunic, bright yellow headband, bare feet, empty hands | 102 | Sling and pouch are the class overlay. Smallest silhouette |
| Shield | a Bronze Age levy shield-bearer, broad, brown skin, black hair, bright red tunic, bright yellow boar-tusk helmet, empty hands | 103 | Tower shield and short blade are the class overlay. Widest silhouette once the overlay is on |

### Outlaw levies (world palette, desaturated variant for enemies)

| Unit | Description for the prompt | Seed | Notes |
|---|---|---|---|
| Outlaw spear | a ragged Bronze Age deserter spearman, brown skin, bright red torn tunic, no cap, bright blue rag around one arm, empty hands | 201 | Spear overlay shared with the hero Spear, chipped variant. Colour map goes grey and desaturated |
| Outlaw slinger | a ragged Bronze Age deserter slinger, thin, brown skin, bright red torn tunic, bright yellow cloth wrapped around the head, empty hands | 202 | Sling overlay shared with the hero Sling |
| Deserter Officer | a Bronze Age deserter officer, brown skin, bright green scale corselet over a bright red tunic, bright yellow helmet with a broken crest, empty hands | 203 | Named: corselet and helmet mark him after the map. Spear overlay plus a sword-at-hip overlay |

### Sea-things (Sea palette)

| Unit | Description for the prompt | Seed | Notes |
|---|---|---|---|
| Jointed | a drowned Bronze Age fisherman turned into a thing, bright white skin, bright blue torn rags, bright red rope belt, black hollow eyes, long bent fingers, empty hands | 301 | Extra joints do not render (tested); an Aseprite overlay adds a second elbow per arm. Colour map goes bone-white and teal |
| Drowned | a bloated drowned Bronze Age soldier, bright green skin, bright red waterlogged tunic, bright yellow seaweed in the hair, arms hanging heavy, empty hands | 302 | Slow: heavy stance. Map goes grey-green skin, dark linen |
| Tide-caller | a tall drowned Bronze Age priest, bright green skin, bright blue long robes, bright yellow full-face mask, empty hands | 303 | Named: mask and robes after the map (dark blue robes, corroded bronze mask). The arms-raised frame becomes its Call pose |

## Palettes for this pass

Until the theme skill derives the two palettes in phase 0, the slice uses Endesga 32 for both, with the Sea units quantised to Endesga's cool half (the blues, greens and greys) to fake the Sea palette. Regenerating with the real palettes is a re-quantise, not a regenerate.

## Sample results (2026-09-27, `docs/art-smoke/spec-*.png`)

- **Shield, seed 103.** Boar-tusk helmet reads in all four facings. Tower shield is clear in the arms-raised and jump frames but sits behind the body in the walk frames, so the side-facing item check fails. Fix for the next pass: describe the shield as "held in front, covering the body from shoulder to knee" and try seeds 104 to 106. Eight colours.
- **Jointed, seed 301.** A pale grey-green drowned humanoid with a large smooth head and hollow eyes: eerie and on tone, but no extra joints, as predicted. The overlay fallback (a second elbow per arm drawn in Aseprite) is confirmed as the route. Five colours, which is thin; the Sea palette pass will widen it.

## Full pass results (2026-09-27, `docs/art-smoke/pass2/`)

All nine units generated with identifier prompts at their fixed seeds, quantised to sixteen colours, colour-mapped. `contact-identifiers.png` shows the raw identifiers, `contact-mapped.png` the mapped result, and each unit has a 4x review sheet.

- Identifiers took on every unit: tunics, caps, helmets, the officer's corselet, the Jointed's white skin and blue rags, the Drowned's green skin, the Tide-caller's blue robes and mask.
- After mapping: heroes read as linen and bronze on brown skin; outlaws go grey; the Jointed is bone and teal; the Tide-caller is teal-robed with a corroded mask. Thirteen to sixteen colours each.
- Lesson: colour maps are per unit, not per family. The Drowned's red tunic first mapped to the Sea family's rope orange and had to be remapped to dark waterlogged linen.
- Lesson: the fuzz on identifier matching leaves a few shaded pixels unmapped on some frames; the Aseprite version of the map step should match by index after quantisation rather than by fuzz.
- Still to do: class weapon overlays, the Jointed's second-elbow overlay, hair colour variation per hero.

## Open

- Shield walk frames: solved by the overlay decision.
- Whether the deserter officer's corselet survives the 4x downscale.
- Ink lines and scars are not in the slice; item 51.
