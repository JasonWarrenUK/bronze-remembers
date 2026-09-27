# Phase 1: vertical slice checklist

| Prop    | Value |
|---------|-------|
| Started | 2026-09-27 |
| Proves  | A hit feels right and a fight is a puzzle |

## Sim (headless, tested)

- [x] 1. Data files: units, abilities, gear, decks (`data/*.json`)
- [x] 2. Grid: tile types, passability, movement cost, downed bodies slow, pathfinding with reach
- [x] 3. Units and battle state: HP, speed, cooldowns, conditions, facing, downed
- [x] 4. Rounds and initiative: hero speed and enemy card initiative on one queue, delay
- [x] 5. Hero actions: move, basic attacks, class abilities, gear abilities, cooldowns
- [x] 6. Conditions and forces: Wound, Bound, Dread; push, pull, drag with wall, water and unit outcomes; Brace; Wall; Taunt
- [x] 7. Enemy decks and AI: card draw per type, stat modifiers, specials, focus profiles, no-focus rule, named decks
- [x] 8. Downing: bodies on the field, overkill margin, weighted draw at fight end (scar, severe, dead)
- [x] 9. Objectives and waves: kill all, hold tile, reinforcements; win and lose
- [x] 10. Event log and journey test: a scripted fight from deployment to result

## Presentation

- [ ] 11. Battle scene: tiles, unit sprites from mapped sheets, camera, deployment zone
- [ ] 12. Input: select, move preview, ability targeting, confirm, delay, end turn
- [ ] 13. Initiative queue and enemy card panel (revealed at round start)
- [ ] 14. The hit: hit-stop, shake, flash, knockback tween, particles, sound
- [ ] 15. Result screen with the downing draws and deeds

## Art

- [ ] 16. Weapon and shield overlays per class and facing; Jointed second elbow
- [ ] 17. Tile set: floor, wall, water, tide, rubble in bronze and tide palettes
- [ ] 18. Index-based colour map in the Aseprite step
