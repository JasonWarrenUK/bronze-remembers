# Enemy decks for the vertical slice

| Prop    | Value |
|---------|-------|
| Agreed  | 2026-09-27 |
| Model   | Stat card per unit type; eight-card deck per type, two marked shuffle; named types carry six-card personal decks. See `design.md` section 11 |

Card format: name, initiative, modifier, special. Lower initiative acts earlier. Heroes' base speeds run 2 to 5 on a different scale: the sim maps both onto one queue (open item 27).

## Outlaw levies (Law). Profile: hold lines, focus the closest

### Outlaw spear. Move 3, attack 2, reach 2, HP 6

| Card | Init | Modifier | Special |
|---|---|---|---|
| Rush | 15 | move +2, attack -1 | |
| Brace | 20 | no move | Overwatch: first hero to end a move adjacent takes a Thrust before acting |
| Thrust deep | 35 | attack +1 | Only at reach 2 |
| Shield line | 40 | move -1 | Adjacent spears take 1 less this round |
| Sweep | 50 | | Attack every hero in the front arc |
| Advance | 60 | move +1 | |
| Close ranks | 70 | | Move toward the nearest levy, then attack. Shuffle |
| Hold | 80 | no move | Cannot be pushed this round. Shuffle |

### Outlaw slinger. Move 3, attack 2, range 2 to 5, HP 4

| Card | Init | Modifier | Special |
|---|---|---|---|
| Pot shot | 15 | move +1, attack -1 | |
| Scatter | 25 | move +2, no attack | Move away from the nearest hero |
| Fall back | 30 | | Attack, then move 2 away |
| Loose | 45 | | |
| Skip | 55 | | Attack the target and one adjacent hero for 1 |
| Harry | 60 | | Attack and push the target 1 |
| Aim | 85 | no move | Attack +1 next round. Shuffle |
| Reload | 95 | no move, no attack | Shuffle |

### Named: Deserter Officer. Spear stats, HP 9. Six cards

| Card | Special |
|---|---|
| Rally | Levies within 3 move +1 |
| Order the line | Adjacent levies Brace |
| Cut down | Attack +2 |
| Fall back | Move 2 away |
| Hold the road | Cannot be pushed; adjacent levies take 1 less |
| Press | Levies within 3 attack +1 |

## Sea-things (Sea). Profile: focus whoever is nearest water, drag toward it

### Jointed. Move 4, attack 2, HP 5

| Card | Init | Modifier | Special |
|---|---|---|---|
| Surge | 10 | move +2 | Drag the target 1 tile toward water |
| Pull under | 20 | attack +2 | Only against Bound targets |
| Skitter | 30 | move +2, no attack | Toward the hero nearest water |
| Lurch | 40 | move +1, attack +1 | |
| Clutch | 50 | attack +1 | Bound |
| Rend | 65 | | Wound |
| Twist | 75 | no move | Attack every adjacent hero. Shuffle |
| Recede | 100 | | Move 2 toward water, no attack. Shuffle |

### Drowned. Move 2, attack 3, HP 8

| Card | Init | Modifier | Special |
|---|---|---|---|
| Drown | 25 | attack +2 | Only against targets in water |
| Sink | 30 | no move | Units in water cannot be targeted this round |
| Grasp | 45 | | Bound |
| Shamble | 60 | move +1 | |
| Rising tide | 70 | no attack | One tile adjacent to water becomes tide. Shuffle |
| Swell | 80 | no move | Takes 1 less this round |
| Wail | 90 | no attack | Dread to heroes within 2 |
| Surface | 100 | | Move 2 out of water. Shuffle |

### Named: Tide-caller. Drowned stats, HP 12. Six cards

| Card | Special |
|---|---|
| Call | Two tiles become tide |
| Chorus | Dread within 3 |
| Lash | Attack at range 3, drag 1 |
| Submerge | Untargetable while in water |
| Rise | Jointed within 3 move +2 |
| Wake | Adjacent sea-things attack +1 |
