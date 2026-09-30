# Bronze Remembers Beyond MVP: Roadmap Overview

**89 tasks across 15 milestones.** Files: `.claude/roadmaps.json` (machine-readable), `docs/roadmaps/BEYOND_MVP.md` (full task list with Mermaid dependency diagram).

> Built 2026-09-30 from a structured interview. Every open question in `docs/open-questions.md` that was still open is placed on a task, tagged with its number (Q1 to Q51).

---

## What we're building

The MVP loop exists: combat, a campaign, the Register, four institutions, five tracks. What it lacks is a worked answer to how those systems press on each other. Does a Sea graft change which roads a hero can take? Does an institution's arc change who turns up to a fight? This phase starts by answering those questions pair by pair, then builds what the answers ask for.

Integrating narrative flavour with mechanical play is the priority. The Chronicle, hero voice, rumours and the event deck exist so that story beats change rules and rules leave story behind.

The phase is tiered. Core (M1 to M8) builds the playable, extended narrative game. Secondary (M9 to M14) tunes what Core built. Tertiary (M15) makes the game shippable. Art advances at every tier: legible sprites and tiles in Core, portraits, palettes and UI style in Secondary, final art in Tertiary.

## Milestone sequence and the reasoning behind it

**M1 Interplay.** Seven systems (Field, Road, Body, Register, Institutions, Collapse, Chronicle) give 21 pairs, one spike each. Each spike writes a `design.md` section, fills its cell in `docs/interplay.md` and proposes build tasks. 1DS.23 reconciles them and grows the roadmap. The six Field pairs wait on Jason's first playthrough (G1) and its triage (1TR.1), since play notes may reshape combat.

**M2 The Field.** Combat mechanics: classes and multiclass prerequisites, the 12 tier-1 promotions, enemy families, named unit pools, the speed formula's shape and the deployment rules. It also owns the tile list and tile art.

**M3 The Road.** The twelve capitals, seasons, ships, day costs, ambition tables and the event deck. It also owns the ward event and the map, node and edge art.

**M4 The Body Remembers.** Traits, Sea and Temple grafts, quirks, fixations, bonds and grudges, with the overlay layers they need.

**M5 The Register.** Seat recipes, the Custom Gone contest, emeritus variants, the retirement scene, ward lineage and the unlock tree.

**M6 The Institutions.** Arc transitions to their end states and substitution failure at Broken Rite. The rest arrives from Interplay.

**M7 The Collapse.** One placeholder that Interplay's consolidation fills.

**M8 The Chronicle.** Templates, testimony reach, hero voice, rumours and the name generator.

**M9 to M14 (Secondary).** Each tunes its Core twin: combat values and hit feel, road costs, content lists filled to their design targets, tick curves, deed significance, palettes, portraits and UI style.

**M15 Shippable (Tertiary).** It opens with a scope spike to decide what shipping needs, starting from the old phase 5 list, then the final art pass.

## Decisions that shaped the structure

- **Minimum-content rule.** Core builds each content list to the smallest size where every Interplay edge it touches has content exercising it; Secondary fills it to the design target. The event deck is exempt and reaches a healthy size in Core.
- **Rule and values split.** Questions 27, 33 and 46 split into a rule-shape task in Core and a values task in Secondary.
- **Question 6 split.** Classes and multiclass prerequisites sit in The Field; the Register unlock tree sits in The Register, depending on them.
- **Wards are not a separate feature.** They are a road event (3CT.4) plus a Register lineage rule (5SY.3).
- **Tier gating without release gates.** Every Secondary root task depends on M2 to M8; M1 is implied through M7. Tertiary depends on M9 to M14. No edge is redundant.
- **Combat feel is Secondary.** Hit weight, juice and timing tune what Core builds (9TN.8, 9AR.2).
- **No estimates.**

## External blockers (flag early)

- **G1: Jason's first full MVP playthrough.** It blocks 1TR.1 and, through it, the six Field spikes and everything they feed.
