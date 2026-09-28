# Design: the four pillars

| Prop    | Value |
|---------|-------|
| Status  | Agreed with Jason, 2026-09-26 |
| Scope   | Character evolution, legacy, incentives, setting |
| Working title | Bronze Remembers |

Everything here came out of a question round on 2026-09-26. Rationale lines record why a choice beat its alternatives so later sessions do not relitigate.

## 1. Character evolution

Six visible layers on every hero, each a paper-doll sprite layer and a roster-card line:

| Layer | Source of change | Player agency |
|---|---|---|
| Gear | Loot, heirlooms, trade with the Tin Road | Full |
| Origin | Fixed at recruitment: levy, temple debt-slave, palace guard, Tin Road mercenary, remade veteran | Pick at squad creation |
| Class and promotion | Fire Emblem style trees. A second class opens once prerequisites are met (deeds, bonds, grafts) | Full, gated |
| Grafts | Imposed by injuries and events. Location fixed by what happened. Where a choice exists it is between types, filtered by origin and class | Type only, sometimes |
| Scars and quirks | Rolled when a hero drops below a threshold. Always a trade-off, never a pure penalty | None |
| Bond marks and age | Bonded pairs share an insignia or dye. Each chapter ages the roster: the old lose speed, gain command range, then retire | Indirect |

**Grafts.** Few per hero (two or three slots), each swaps a sprite layer, replaces one ability and adds one cost that bites in play. The Palace casts lost limbs in bronze (heavy strike, cannot swim). The Temple inks a debt-ledger into skin (spend debt to power abilities, can be called in by a creditor mid-campaign). The Sea adds joints (move through enemies, dread aura, the Sea can hear you). Sources: Miéville's Remade for the punitive framing, Wildermyth for the sprite-level payoff, Caves of Qud for mutations that change tactics rather than stats.

**Fixations.** Events plant an idea (a grudge, a heresy, a debt to collect). It sits unresolved for a few battles, then resolves into a trait or an event chain depending on what happened meanwhile. Source: Disco Elysium's Thought Cabinet.

**Bonds.** Pairs earn named bonds (kin, rival, creditor and debtor, lovers) that unlock a shared ability and branch events. Sources: XCOM 2 bonds, Fire Emblem supports.

Rationale: Jason rejected grafts and age as the only visible axes, so gear, class silhouette, scars and bond marks carry change too. Classes with promotion and multiclassing were kept because build-crafting is wanted underneath the imposed grafts.

## 2. Legacy: the Register

Every hero gets a Register entry at campaign end, alive or dead: grafts, scars, bonds, deeds, creditors, line.

### Playable heroes and tiers

A Register hero is playable until retired or dead. Tier rises by one per campaign survived and by one per fulfilled fixation. No cap. Bands name the tiers and unlock retirement pools:

| Band | Tiers | Reachable by |
|---|---|---|
| Levy | 0 to 4 | One life |
| Named | 5 to 9 | A long life with fixations fulfilled |
| Storied | 10 to 14 | Two generations |
| Dynast | 15 to 19 | Three or more |
| Founder | 20 plus | A lineage played across many Registers |

Squad creation spends a tier budget on the additive curve (tier 3 costs what tiers 1 and 2 cost together; tier 0 is always free). Difficulty rises with spend, but stays behind the power curve so veterans feel like veterans.

**Age.** Each campaign played is a generation step. A hero's fourth campaign is their last: finish it and they die of age at its end. Their only clean exit is retiring before it, or leaving mid-run at a rest node, which costs the squad the hero for the rest of that run. Mid-run retirement exists only for this case.

### Retirement: the cash-out

Retirement removes a hero from play for good and converts them into world state. The world effects are deliberately worth more than the piece, so the decision is when, not whether. Age forces the question by the fourth campaign.

At retirement the hero is offered two or three seats drawn from pools their history unlocks, so two retirements at the same tier never look alike. A Sea-grafted hero cannot take a Palace seat but can found a coastal cult; a Temple-inked hero can burn their own ledger. Higher bands draw from larger effects.

| Pool | Examples |
|---|---|
| Map | A rest node becomes permanent. A road is held open. A ruin is refounded as a named city. A coast is ceded to the Sea, ending its inland raids for a generation |
| Institutions | Advance or set back an arc step. Change levy terms. A Temple forgives one paper per campaign. A new Tin Road route changes the shop |
| Roster | A new origin unlocks (the retiree's cult, guild or house). A class prerequisite drops for the retiree's line |
| Rules | A Collapse rule is softened or hardened. A graft type becomes offerable. A new ambition appears |
| Chronicle | The retiree narrates future Chronicles for their institution. Their name attaches to a rite, a road or a weapon type |

**Cities as origins.** Origin is a walk of life (levy, debt-slave, guard, mercenary, remade veteran) and a city. A city founded by a retiree carries a house trait from its founder: a graft affinity, a dropped class prerequisite, a standing bond to the founder's institution, a dye. Recruits from that city carry it while the city stands. A fallen city is a map scar with the founder's name on it.

**Graft lineage.** Every retirement of a hero carrying graft type X raises X's quality one step for all future recipients: a stronger ability, a lighter cost or a second minor effect. The Register shows each type's step and who raised it.

### Descendants

Whether a descendant exists comes from the hero's life, never their tier: a kin or lover bond, a ward taken in, an origin that carries a house. Unbonded retirees still produce a descendant.

Inheritance is one generation deep and comes from every parent or caregiver. Each contributes one inherited property from this set, never a graft or a scar, which are earned:

- Paper: debts and creditors transfer. A Temple that inked the parent already holds the child's name.
- Heirlooms: gear with a history line and bronze memory charges.
- Grudges: an enemy, an institution or a Register encounter owed a scene.
- Traits: the non-injury kind, from resolved fixations.
- Affinity: institutions deal with the child on the parents' terms, so graft offers skew the same way.
- Heraldry: house colours from each caregiver line, one stripe each.

**Starting tier.** Half the higher parent's retirement tier plus a quarter of the other's, rounded down. One parent at tier 8 gives tier 4; two at tier 8 give tier 6. Lines climb fastest when two long-played retirees pair.

**Wards.** A rare random event. A ward's caregivers are their two highest bonds among heroes at least one generation older. One if only one qualifies; none gives a tier 0 with a grudge and no line. Not to be elaborated further yet.

### The dead

The dead return four ways: as descendants (inheriting the scar and the grudge in place of gear and affinity), as encounters (grafted dead return as enemies, shrines or events), as heirlooms and as institutional memory (cults, warrants, songs). None of these banks a tier. Only retirement does.

### World memory

Institutions and map scars persist. Cities saved or lost, temples dealt with, roads burned. Each campaign is a generation later in the same collapse.

Rationale: Wildermyth's tiers made late campaigns easy; scaling difficulty against spend keeps the pull without a calcified roster. Retirement had to be worth more than the piece or it is a chore. Descendants decoupled from tier so that a line's existence is about the hero's life and its strength is about their play.

## 3. Incentives

**Win state.** At squad creation you pick an ambition: found a city in the ruins, drown the Temple, get one named hero to the ships, carry the archive out, break the Smiths' moulds. The campaign is also a set of obligations: the levy was raised under a writ, heroes carry ink, bronze was cast from moulds the Smiths keep and nothing counts until a scribe records it. The ambition is what you are buying; the obligations are what it costs. Each institution's hold has its own mechanic (section 5).

**Continue this campaign.**
1. The Collapse clock: each chapter ends with a choice that reshapes the map and advances the clock. Enemies graft too.
2. Obligations come due: writs owe reports, ink climbs toward the throat, moulds can be called back, deeds need a scribe. Fixations resolve, bonds mature, grudges get their scene.
3. The retirement window: a hero's fourth campaign kills them at its end. Retire them before it and cash out the tier, or play it and take the tier's last growth at the price of a clean exit.

**Start a new one.**
1. The Register as a shop window: tiers, budget, descendants and heirlooms with history lines.
2. One deed-gated unlock always visible.
3. The Chronicle: each run ends as a generated short chronicle in the setting's voice, shareable as text.
4. Short seedable runs: three chapters, about three hours, with map scars from last time.

**Difficulty.** The Collapse (section 5) sets the baseline and only ever rises. Tier budget spent at squad creation positions a run higher or lower within it. Within a run, chapters escalate and enemies graft.

**Meta story.** Four institutions with branching arcs to end states (section 5). No single villain.

## 4. Setting brief

**Pitch.** Palace economies are failing. Tin has stopped arriving, the scribes' tablets lie about the granaries and something with too many joints is walking up out of the sea lanes. Squads of levy soldiers, temple debt-slaves, remade veterans and Tin Road mercenaries hold the last roads between cities that no longer answer letters. Transformations are Remade in the Miéville sense: the bureaucracy grafts, the Sea grafts, the gods graft, and none of them ask. Legacy is genealogy: your heroes' children inherit their grafts, their grudges and their bronze.

**Institutions.** Four, each with its own kind of hold over a squad and a cross-campaign arc (section 5).
- The Palace raises the levy and delegates authority by writ.
- The Temple feeds and heals on terms, paid in ink on skin.
- The Scribes decide what is true: nothing counts until recorded, and they carry every letter and draw every map.
- The Smiths are the only people who can still cast bronze. They keep the moulds.

**The Sea** is not an institution. It is the threat: a force with no arc and no dial, felt through the Sea track, the drowned-town nodes and the things that walk inland. It can be bargained with only at those nodes, by giving it something.

**Tin Road functions** (supply, hire, brokerage) are spread across the Smiths (gear, repair, bronze trade), the Palace (requisition by writ) and the markets of friendly nodes. Mercenaries are a foreign origin whose Tongue mismatch is the price.

**Weirdness, three dials at once.**
- Restraint that breaks: a fresh Register starts near-historical with one wrong thing. Each Collapse level and each arc step lets more in, until the top level is full Bas-Lag.
- Two weirds: the institutions' weird is bureaucratic and hidden (ink that binds, bronze that remembers, tablets that lie on purpose). The Sea's weird is overt and bodily. Player-side power stays restrained.
- Weird by geography: the coast is already strange, inland is still history. Map scars push the strange inland each generation.

**Magic on the player side.** Grafts, tablet sorcery and bronze memory. Nothing else. Enemies and institutions have more. Full system in section 6.

**Names.** Invented, with Ugaritic and Hittite phonetics. No real places.

**Writing pillars.** Institutional horror over jump scares. Wonder and disgust in the same sentence. Every faction has a ledger. Nobody is chosen.

**Sources.** The Ugarit tablets (the last letter before the city burned asks for grain), Linear B (the surviving writing is inventories), Miéville's Remade and The Scar, Kentucky Route Zero for debt as horror, Kenshi for a world that does not care about you, Sunless Sea for ambitions.

## 5. Meta progress: the Collapse and the institutions

Agreed 2026-09-26, second question round.

### The world clock

Every campaign is a generation. The Collapse advances on its own each generation; retirements, institution end states and ambitions bend it: slow it, redirect it, and under extraordinary circumstances reverse a track. A Register always ends in the fall. What you built before it is the score.

### The Collapse: five hidden tracks

Scores are hidden. The player sees named weather in the world, never a number. Tracks are read at run start and frozen for the run; within-run events nudge the hidden scores for the next generation.

| Track | What is failing | Named for |
|---|---|---|
| Law | How far the Palace's authority reaches: whether letters are answered, whether roads have law, whether a writ is honoured | Decline |
| Rite | The Temple's hold: cults, heresies, whether rest still heals, whether ink is still feared | Decline |
| Custom | Kinship and the rules people keep without law: guest-right, bride price, burial, who may leave a household | Decline |
| Tongue | The shared language and script. Early: one lingua franca and most people literate. Late: a dialect in nearly every city and most heroes illiterate. Divergence, never silence | Decline |
| Sea | The threat. How far inland the weird has come and what walks the roads | Threat |

Reversal only by a Founder-band seat, an institution end state or an ambition of the right kind. The Sea is the only track with no seat behind its reversal: bargains with it happen at drowned-town nodes.

### Difficulty

The Collapse composite sets a run's baseline and only rises across the Register. Tier budget spent at squad creation positions the run higher or lower within that baseline, staying behind the power curve. Within a run, chapters escalate and enemies graft: what you fought in chapter 1 returns changed in chapter 3.

### Institutions and their arcs

Four institutions. Each has a relationship dial, a branching arc to two or three end states, and minor path variants set by the dial and by retirees who take a seat inside it. Arcs are moved by obligations kept or defaulted, by ambitions that involve the institution and, most strongly, by retiree seats. Arcs do not move each other; they move the Collapse:

| Institution | Mechanic | Track it moves | Direction |
|---|---|---|---|
| Palace | The Writ | Law | Decays with the Collapse |
| Temple | The Ink | Rite | Decays with the Collapse |
| Scribes | Testimony and the Letters | Tongue | Decays with the Collapse |
| Smiths | The Mould | Sea (hostile end state) | Rises as Law falls. Whoever still casts bronze is power. Their hostile end state is casting for the Sea, which accelerates the Sea track. The one institution that can change sides |

**The Writ (Palace).** Delegated authority. A writ lets a hero requisition at friendly nodes, conscript recruits and judge in an event. Every writ used owes a report at the next city; unreported writs make the holder outlaw, and outlaws cannot enter walled cities. Interplay with Law: at high Law writs are issued freely and honoured everywhere; as Law falls they are honoured only near the city and cost more reports; at low Law the Palace cannot enforce, but a writ in hand is a piece of the old order that nodes may honour as the nearest thing to law, or kill the holder for. Writs can be forged by tablet sorcery. A retiree holding the last honoured writ can take a seat as the authority the Palace no longer is.

**The Ink (Temple).** The Temple feeds and heals on terms and payment is lines of ink on a hero's skin, visible on the sprite. Each favour or rite adds lines. When the lines reach the throat the hero is called to the Temple for the run or for good. Ink can be burned off, which is a scar and an enemy.

**Testimony and the Letters (Scribes).** Only recorded deeds count, for everything: tiers, fixations, ambitions, the Register and the Chronicle. A run without testimony banks nothing. A scribe in the squad is not the main protection: scribal services live at nodes, so routing through them is a priority, and events of high significance find their way to a scribe if one is near enough. Scribes can be bribed to record lies or to erase. They also carry every letter and draw every map: good standing means an accurate map and honest news, bad standing means a map that lies and letters that go unanswered whatever the Law track says. Tablet sorcery is theirs.

**The Mould (Smiths).** Every bronze graft and every heirloom repair needs a mould the Smiths keep. Default and they call the bronze back: the graft fails, the heirloom cracks.

### Tongue in play

Reading and speaking is a hero capability by origin and class, learnable through bonds with a foreign hero, and its weight scales with the track. Effects, always in-world and never a corrupted UI:
- Letters and event texts arrive partly untranslated; a capable hero reads fully, others get gaps and can misread.
- Recruits from far cities arrive with a mismatched tongue: bonds form slower, orders in battle can be misheard until a bond exists.
- Institution offers become mistranslatable: the terms accepted are not always the terms meant.
- The Register and the Chronicle drift: names respell across generations.
- Late stage: regional dialects nearly everywhere; trade at unfamiliar nodes becomes gesture and hostage. Nodes never go silent from Tongue; silence is a Law failure.

### Three information failures

Each needs its own UI tell. Silent (Law): letters unanswered, nothing arrives. Garbled (Tongue): text arrives with gaps. False (Scribes): text arrives clean and wrong.

### How the tracks are felt

| Channel | Law | Rite | Custom | Tongue | Sea | Institution standing |
|---|---|---|---|---|---|---|
| Map generation | Roads lose law: bandit nodes, tolls | Shrines become cult sites | Feud nodes between kin groups | Dialect regions | Coast lost, tide nodes inland | Scribes' letters: the accuracy of the map shown |
| Enemy roster and grafting | Outlaw levies, deserted garrisons | Ink-maddened, cult bodies | Feuding kin, blood-price hunters | none | Sea-things, joint-grafted | Smiths' end state: who they cast for |
| Information | Silent | none | none | Garbled | none | False |
| Recruitment | Levy still delivers bodies | Temple sends debt-slaves | Who may leave a household | Foreign recruits arrive mismatched | Coast folk with early joints | Palace writ conscripts; Smiths apprentices |
| Rest and recovery | none | Temple healing reach | Guest-right at ordinary nodes | none | Coastal rests unsafe | Temple ink terms |
| Friendly node behaviour | Allegiance shifts | Demands (ink, tithe) | Hospitality withdraws | Dialect: partial comprehension, worse terms | Empties, drowns | Scribes decide what the node has heard of you |
| Visual weather | Banners fall, gates unmanned | Shrine palette | Hearths dark, no feasts | Signs in unfamiliar script | Palette drifts green and wet | none |

Friendly nodes change in four ways as tracks move: hospitality withdraws, allegiance shifts, nodes make demands as the price of staying friendly, nodes empty or drown.

Custom is not felt inside the squad: battle behaviour stays under player control. Its extra channels, all outside the squad:
- **Burial and the dead.** Custom governs whether the dead are buried right. Low Custom: unburied dead return sooner and angrier as encounters, and heirlooms are looted rather than inherited.
- **Origin-city kin ties.** A node's hospitality depends on kin ties between it and your heroes' origin cities. High Custom: guest-right everywhere. Low Custom: only your own city's kin feed you, and feuds bar you from others.
- **Event deck.** The share of events about guest-right, feuds, blood price and inheritance rises as Custom falls.

## 6. Magic

Agreed 2026-09-27.

**Principles.** No mana. Every magic on the player side is a transaction with an institution or the dead, is visible on the sprite or the card, and gets more available and more dangerous as the Collapse advances.

### Grafts (the body)

Section 1. The Smiths cast bronze, the Sea adds joints, the Temple's rites mark. Permanent abilities with permanent costs. The only magic every hero can end up carrying.

### Tablet sorcery (the Scribes)

What is written is true, within what tablets record.

| Element | Rule |
|---|---|
| Who | The Scribe class line (Copyist, Tablet-hand, Archivist), learned by apprenticing a hero at a scribal node for a chapter. Promotion widens what can be written |
| Resource | Blank clay. Each writing consumes a tablet. Bought at scribal nodes, looted from archives, never made in the field |
| Categories | Six, unlocked by promotion. **Counts:** an inventory changes: a spear exists, an enemy's shield does not. **Names:** what a thing is: an enemy recorded as levy stands down a turn, a hero struck from the roll goes unseen. **Places:** what a place is: a ford recorded as a bridge, a wall as a gate. One tile, contested. **Debts:** an obligation written onto an enemy forces a move or a target. **Time:** what day it is: a muster owed tomorrow is recorded as owed next chapter. Obligation deferral only, never in battle. **Deaths:** a death is recorded and happens at the round's end. Archivist only, always contested |
| Contest | A written lie can be read and struck out by an enemy scribe, a Temple priest or a Palace officer on the field. High Law: lies are checked, contests common. Low Law: nobody checks, lies stick. High Tongue drift: a writing can misfire, because the tablet-hand's script is no longer the field's |
| Cost | Three at once, on every lie. The tablet goes to the Scribes' archive, so every lie is held over you. A false line is added to the sorcerer's own Register entry; past a threshold the Register doubts them, tier growth slows and seats are refused. The Law track is nudged down, because administration has lost truth |
| Self-recording | Sorcery is writing, so its deeds always count as testified. A run with a sorcerer never banks nothing |

### Bronze memory (the Smiths and the dead)

Bronze remembers what it was cast from.

| Element | Rule |
|---|---|
| Who | Any hero holding an heirloom with charges. A descendant of the line or a hero bonded to the retiree gets the full ability. Anyone else gets an echo at half strength |
| What | Invoke the dead hero's signature ability once per charge per battle. The ancestor shows as a ghost overlay on the sprite for the action |
| Charges | Set by the retiree's tier at retirement (one to three). Recharge at a rest node with a burial rite, or never if Custom is low enough that nobody remembers the rite |
| Wear | Each use wears the heirloom. Repair needs a Smiths' mould |
| Overuse, first threshold | Use an heirloom past its charges in one run and the memory acts on its own: the ancestor takes one action per battle on their old grudges |
| Overuse, second threshold | Keep going and the ancestor takes the hero. The hero leaves the Register as a retiree into the ancestor's grudge and returns as an encounter |
| Recasting | The Smiths can recast an heirloom with a new dead hero's bronze, merging memories. The old memory dims; the new one may not like the company |
| Custom and Sea | Unburied dead give angrier bronze: stronger echo, faster possession. Sea-grafted dead give wet bronze: the ability works, and the Sea can hear it used |

### Not player magic

Temple rites are services bought with ink at Temple nodes (healing, a blessing, calling an inked hero home), never cast in battle. The Sea's magic is the enemy's: joint-grafting on hit, the drowned returning, tide terrain. Cult bodies and ink-maddened enemies belong to Rite.

### Restraint that breaks

At a fresh Register, tablet sorcery is Counts only and bronze memory needs a direct descendant. The other categories and the echo rule open as tracks fall and as institution arcs step, so early campaigns stay near-historical.

## 7. Seats

Agreed 2026-09-27.

**What a seat is.** A named position in the world a retiree occupies: institutional (general, high priest, archivist, master of moulds), civic (founder of a city, warden of a road, elder of a node), sacred (keeper of a shrine, voice of a cult) or Chronicle (narrator, namesake of a rite or road). Each carries a standing effect every later campaign, a one-shot world edit on taking it, an arc bias for its institution and sometimes a track hold.

**Capacity.** Few and named. Each institution branch has two or three, each standing city one or two, shrines and cults one. Named seats hold one. Never hereditary: every seat is earned fresh.

**Unlock.** A seat exists if the world has it (the institution's current branch, a city that stands) and the hero qualifies: band minimum plus prerequisites from history (a graft type, an origin city, a class, a dial threshold, a testified deed, an ambition). Institutional seats need standing; the Smiths will not seat a mould defaulter.

**Time.** A seated hero ages a generation per campaign. Tenure is three generations; at its end the holder dies in office and the effect lapses or fossilises (a road keeps the name, loses the toll-free effect). A seat is lost early when its institution's branch changes or its city falls: a scene and a grudge for the line.

**Succession** (all qualifying seats filled). Two routes:
- By deed: testified deeds compared against the holder's. Win and the holder goes emeritus with a bond between lines; lose and the retiree founds or takes the Road.
- By writ: Palace confirmation. Needs Law high enough to be honoured, costs a report and a favour.

Unseating a living holder has consequences: the emeritus becomes a named actor in the next campaign with an event chain (bitter but honourable by deed, blaming Palace and newcomer by writ); the seat is contested for a generation, its effect halved until an event resolves the claim either way; the holder's descendants inherit a grudge and may try to retake the seat at their own retirement, the one line-based claim on any seat; dials move by route (writ raises the Palace, lowers the seat's institution; deed raises the seat's institution).

**Founding.** No cost, but hard. Generated seats come only from authored recipes: two or three anchor slots that must all be filled from the retiree's testified deeds, grafts and scars, and origin city, plus a world condition that the seat does not already exist. Example: killed a sea-thing, carries a Sea graft, coastal origin city, city has no warden gives Warden of the Drowned Gate at that city. Recipes number in the dozens and some unlock only after an institution end state or a Founder-band retirement. Founded seats are real: named, one holder, contestable, subject to tenure. Names and effects derive from the anchors so they read as pre-made.

**No seat fits: the Road.** The retiree wanders and appears as a named encounter in later campaigns (helps once, sells a secret, asks a favour) until they die of age on the road.

## 8. Origins, cities and starting tier

Agreed 2026-09-27.

### Walk of life

Five: levy, temple debt-slave, palace guard, foreign mercenary, remade veteran. Each carries:
- **Kit** and **open base classes.** Base classes are set by origin, overlap between origins, and a class must also be unlocked on the Register before it is available.
- **Institution affinity.** Who deals with you and on what terms.
- **One trait** drawn from a pool per origin, non-injury.

No starting obligation. Mercenary availability rises as Tongue falls and they are worse understood as it does. It is also tied to rumours of other empires falling: greater chaos abroad raises availability, until a final collapse abroad removes mercenaries from the world entirely.

### Cities

A hero's origin is also a city. A city carries up to three traits, accrued by age: a young city has one, an old one with seat history three. Traits are one regional (coast, river, upland), one custom (a local rule, such as a burial variant that changes bronze memory) and, for old cities, one from its seat holders' anchors. A hero from the city gets its dye, guest-right there and its traits.

City effects change only on events: the city falls, is refounded, gains or loses a patron institution or a seat is founded or lost there. Otherwise stable. Heroes keep what they were born with.

### Starting tier without grafts

A high-tier hero at creation has no grafts or scars. Tier shows as:
- **Class head start.** Named band starts promoted; Storied starts with a second class open; Dynast starts multiclassed.
- **Reputation.** Institution dials start shifted by the line's history, both ways: favours and grudges. The Register already knows them.
- **Bearing.** Heraldry stripes, better gear layers, a retainer at Dynast and above. The sprite says who they are.

No stat baseline by tier. Power comes from capability and standing, not numbers.

## 9. The early game society

Agreed 2026-09-27. Tone: functioning and rotten, Hittite flavoured.

At a fresh Register the world works, and it works by debt bondage, conscription and a priesthood that owns bodies. Walled cities with a scribe at every gate. Seasonal musters under writ. Temples feeding the poor for lines of ink. The Smiths casting for the Palace under sealed moulds. Roads with law and tolls. Guest-right honoured. One lingua franca and most people able to read a tablet. The Sea is a rumour of strange catches on the coast. Everyone believes the tablets absolutely. The weird is normal: ink binds, bronze remembers, and nobody finds that strange. The Collapse is a judgment on this society, not a tragedy that happens to it.

**The squad** at the start is a levied band under a writ: raised by the Palace for a season, sent down a road with a purpose. Legitimate, obligated, expendable.

**Warfare** is human-scale. Spears, shields, slings, composite bows, bronze scale for the few. No chariots, no cavalry.

**Hittite textures the writing leans on.** The Great King is addressed as My Sun and his writs are sealed with it; when Law falls, nodes stop using the title. Cities are bound by sworn treaty with curses attached and conquered populations are moved wholesale: deportee origin cities exist, and oath-breaking is a Custom event. Every city's gods are collected into the Palace's pantheon, and rituals can substitute a stand-in for a doomed king or hero: a Temple rite that moves a death to someone else, paid in ink. Kings write to the gods asking what sin caused the plague and the gods answer through oracles: the Rite track's voice is institutions asking what they did wrong, and the answer being you.

**The gods** are never shown and always effective. Rites work, oracles answer, substitutions take. Whether the Temple is right or the ink is doing it is never settled.

**Track visibility.** Never a number. The run-start Chronicle page names the weather in prose ("the roads have no law past the ford"). Everything else is inferred in play. Each track has five stages: Whole, Strained, Broken, Lost, Gone.

## 10. The tracks in play: five stages each

Agreed 2026-09-27. Rules are cumulative down each column. One rule per cell so every stage can be authored by hand.

| Stage | Law | Rite | Custom | Tongue | Sea |
|---|---|---|---|---|---|
| Whole | Writs honoured everywhere. Roads have law and tolls. Outlawry checked at every walled city | Temple heals fully for ink. Substitution rites available | Guest-right everywhere. Burial always possible | One lingua franca. Everything readable. Mercenaries rare and understood | Rumour. Coastal nodes normal |
| Strained | Writs honoured within two nodes of a city. Bandit nodes on outer roads. Reports cost double | Healing costs more lines. First cult sites at shrines. Ink-called heroes return slower | Guest-right needs a kin tie beyond one node from a city. Feud nodes appear. Burial needs a rest | Far-city recruits mismatched. Dialect region at the map edge | Strange catches. Coastal rests risky. First sea-things on the coast. Joint exposure at coastal nodes |
| Broken | Writs honoured only inside walls. Outlaw levies as an enemy family. Tolls become extortion | Cult bodies as an enemy family. Some Temple nodes demand tithe. Substitution can fail | Blood-price hunters as an enemy family. Bonds with non-kin form slower. Unburied heirlooms looted | Dialect regions across the map. Offers mistranslatable. Sorcery misfires outside home region. Mercenaries common | Tide nodes one step inland. Drowned-town bargains open. Sea-grafted dead return |
| Lost | No new writs. Forgery possible. Each node decides whether a writ-holder is law or prey. Palace letters silent | Temple stops healing. Ink no longer compels. Shrines hostile | Hospitality withdraws at non-kin nodes. Burial needs a rare elder. The dead return sooner and angrier | Most recruits illiterate. A Scribe needed to read any letter. Register names drift. Mercenaries flood, terms unreadable | Tide reaches river cities. Coastal cities drown (map scars). The Sea hears bronze memory. Smiths' hostile branch opens |
| Gone | No Palace. The last-writ seat is the only law. Gates closed to all | No Temple. Cults make the demands. Rites still work when cults perform them | No guest-right. Nobody buries. Bronze memory cannot recharge. Descendants contest inheritance | A dialect per city. Trade by gesture and hostage. Mercenaries gone: the world abroad has fallen too | Tide at the upland |

**Under the hood.** Each track is a hidden 0 to 100 score with stage thresholds. Every generation adds a tick on a curve authored per track (Law fast early and slow late, Tongue slow early and fast late, and so on). Within-run events nudge the score for the next generation. Seats and institution end states can hold a track for a generation or drop it one stage.

**Tracks and arcs.** A track reaching Gone forces its institution's arc to a terminal state if it is not there already. An institution end state moves its track but never forces a stage. The world wins ties.

**The fall.** The Register ends when any three tracks reach Gone. Which three is the shape of that Register's ending, and the Chronicle writes it accordingly.

## 11. Combat

Agreed 2026-09-27.

| Decision | Value |
|---|---|
| Squad size | Three heroes in chapter 1, up to six by chapter 3 as the writ conscripts |
| Grid | Square, 10x10 upwards |
| Action economy | One move and one action per hero per turn, either order |
| Turn order | Individual initiative: each unit acts on its own speed |
| Randomness | Fully deterministic. No hit rolls, no damage ranges. Scars, grafts and contests need deterministic triggers |
| Terrain | Flat grid with tile types: walls, water, rubble, shrine, tide. Tiles affect movement, cover and exposure. No height |
| Initiative details | Speed sets the order. The next enemy to act telegraphs its intent. A hero can delay to act after a chosen unit. Speed changes with the body: grafts, scars, age, ink lines, armour |
| Downed | At zero a hero is downed and out of the fight. Battles do not kill directly except by overkill (below) |
| The road kills | A severe injury untreated after N nodes without a fitting facility kills. The lack of a smith and the distance to a temple do the killing |
| Retreat | None. Every fight is to the end |
| Objectives | Kill everything; hold or reach a tile for N turns; kill a named target; survive N turns; recover or protect an object (tablets, an heirloom, a body to bury) |
| Downing injures | Determinism covers battle actions only. The outcome of a downing is a weighted draw between scar, severe injury and death, weighted by the overkill margin and the strength of the enemy that did it |
| Kit | A basic attack with no cooldown, two class abilities, and one gear slot that any gear item can fill; every gear item gives a class-agnostic ability. Grafts add an ability, replace one, or interact only with node and inter-battle features |
| Fight length | Six to ten hero turns, under ten minutes. Three or four fights per chapter |
| Enemy AI | Frosthaven-derived. Each enemy unit type has a stat card (move, attack, range, HP) and its own eight-card ability deck, two cards marked shuffle. One card is drawn per unit type present each round; it sets that type's initiative and modifies its stats (move plus 1, attack minus 1) and adds a special. All units of a type act the card. A family is a grouping of unit types that share a focus profile. Named units (named types, emeritus, grudges, bosses) carry a personal deck |
| Reveal | Enemy cards are revealed at round start. Heroes choose their action when their turn arrives, with full knowledge of every enemy card |
| Focus | Deterministic, per family profile (levies the closest, hunters the most wounded, cults the inked, sea-things whoever is nearest water). Ties: closest by unblocked path, then most ink |
| No focus | A unit with no reachable focus does not move or attack; it performs any other ability on its card |
| Ability usage | Cooldowns in turns. The basic attack has none |
| Conditions | Wound (damage each turn until treated; bronze and teeth), Bound (cannot move; ink, nets, written debts), Dread (acts last, cannot delay; sea-things and cults) |
| Sorcery contests | On the field: an enemy scribe, priest or officer contests any writing within reach at their next activation, no roll. Between fights: institutions can strike lies afterwards at a cost in testimony or standing |
| Downed bodies | Remain on the field. Their tile is passable but slows movement |
| Conscription | Squads grow only at friendly nodes, where a writ adds a recruit from that city's pool. There is never a battle at a friendly node |
| Morale | None. Every enemy fights to the end, as every squad does |
| Deployment | Heroes place within a marked zone. Every enemy on the field is visible before placement, and announced reinforcement waves arrive on later rounds, tied to survive objectives |
| Deeds | Every notable act (named kill, objective, a hero's first graft use, a sorcery) is a deed with a significance value. It is recorded by any of three channels: it travels to the nearest scribal node within a range set by its significance; it queues until the squad next visits a scribal node; or a scribe in the squad records it at once. Deeds unrecorded by chapter end fade |
| Enemy grafting | Grafted variants are new unit types with their own stat card and deck, added as chapters pass. A battle that used two decks for a group early on may contain several grafted variants later, each acting its own card |
| Severe injury | The hero cannot fight until a graft is fitted, and grafts are fitted only at nodes with the facilities or expertise (Smiths for bronze, Temple for marks, drowned nodes for joints). They can travel |
| Terrain exposure | Ending a turn in tide water, on a shrine tile or in a mould-fire exposes the hero; exposure counts toward a graft |

## 12. Roster and enemy families

Agreed 2026-09-27.

**Base classes**, six, weapon-defined: Spear (spear and hide shield, line holder, reach 2), Sling (cheap ranged, ignores cover at range 3 plus), Bow (composite bow, long and slow), Shield (tower shield and short blade, anchor, blocks paths, protects adjacent), Knife (knife and net, skirmisher, Bound on hit, fast), Scribe (stylus and tablets, support, testimony, later sorcery; apprenticeship only). 
**Origin links.** Mercenaries may take any base class except Scribe. Scribe is apprenticeship only, open to every other origin. The other four origins open three classes each, overlapping evenly:

| Origin | Opens |
|---|---|
| Levy | Spear, Sling, Shield |
| Temple debt-slave | Sling, Knife, Spear |
| Palace guard | Shield, Bow, Spear |
| Remade veteran | Bow, Knife, Shield |

**Promotion.** Two tiers, two branches at each: two tier-1 forms and four tier-2 forms per class, seven forms per class, forty-two in all. Each form adds one ability and changes the silhouette.

**Enemy families**, one per track plus institution troops when hostile:

| Family | Track | Profile | Units |
|---|---|---|---|
| Outlaw levies | Law | Hold lines, focus closest | Spear, sling, named deserters |
| Cult bodies | Rite | Focus the inked, self-harm for power | Flagellant, chanter, named ink-maddened |
| Blood-price hunters | Custom | Focus the most wounded, drag off the edge | Tracker, netter, named kin-elders |
| Sea-things | Sea | Focus whoever is nearest water, drag toward it | Jointed, drowned, named tide-callers |
| Institution troops | none | By institution, when hostile | Palace guard, Temple warden, Smiths' castbound |

Each family has a pool of named unit types, each with a personal deck. A run draws two or three from the pool; names are generated dynamically; pools are large enough that many runs pass before every type has appeared. Institution troops arrive as enemies at the first Register stage, when arcs can go hostile. The vertical slice ships outlaw levies and sea-things.

## 13. Campaign map

Agreed 2026-09-27.

| Decision | Value |
|---|---|
| Shape | One continuous world map. Twelve starting cities, each the capital of a small city-region with its own weather; foundations can take that to about twenty. Coast, river plain and upland are terrain bands across the regions, not regions themselves. Cities connected by roads; the player picks a destination and the road generates its nodes. Cities are persistent across Registers (standing places or map scars); roads and their nodes are generated per run from the tracks |
| Fog | A fresh Register begins fully fogged. In later runs, explored areas sit under a soft fog: the player sees what they saw last time, not the current state. Changes are discovered by going there |
| Sea travel | Harbour cities connect by ship in fewer days, at the Sea's price: exposure, and the tide-caller's attention |
| Roads | Each road has one or two fixed landmarks (the ford, the pass, the tomb) whose state changes with the tracks; the rest of its nodes generate per run by length in days and track weather |
| Route variety | Roads open and close with weather and season. Obligations pull (a report due, a smith needed, a deed to carry). Milestones reveal chapter by chapter. Scribes' letters and rumours give reasons to detour |
| Letters and fog | A letter marks a fogged place with what it claims is there, tagged as a claim. Accuracy depends on Scribes standing and Law. Going there is the only proof |
| Node types | Battle, friendly city (writ conscription, market, seats), scribal, rest (guest-right), Temple, Smiths, drowned town (Sea bargains), shrine, event. Friendly nodes are safe by rule; danger is on the road |
| Chapter end | Ambition milestones. The ambition chosen at squad creation defines what ends each chapter. Runs are two to four chapters by ambition: short ambitions are easier and carry lower meta rewards |
| Time | Days. Roads cost days by length; rest restores. Injuries, writ reports, ink calls and musters are owed on dates |
| Run start | The raiser assigns the muster point, and who the raiser is depends on Law. The raiser sets the start city, the squad's identity and its first obligation, so a run's opening scene says which world it is in |
| Milestones | Revealed chapter by chapter. Only the next milestone city is known; the ambition unfolds |
| First run | Generated from every track at Whole, with one wrong thing: a single drowned-town node near the coast |

**The raiser by Law stage.** The Palace's range of muster points shrinks as Law wanes.

| Law stage | Raiser | Muster point | First obligation |
|---|---|---|---|
| Whole | The Palace, by writ | Any city in the world | A report due at the next city |
| Strained | The Palace, by writ | Cities that still answer letters: the capital's region and its neighbours | A report due, costing double |
| Broken | The Palace, by writ | The Palace city only | A report due, and outlawry unchecked beyond the walls |
| Lost | A city that still answers, or a seated retiree holding one of the last honoured writs | That city or seat | The raiser's demands: loyalty to a place or a person, not a crown |
| Gone | Whoever still has power, in order of what survives: the last-writ seat; the Smiths if warlord; a Temple or cult; failing those, the squad's own origin city as a household band | The raiser's seat or city | The raiser's mechanic: a mould debt, ink, or a kin obligation |

## 14. Art direction

Agreed 2026-09-27. The pipeline is in `PLAN.md`; this is what it produces.

| Decision | Value |
|---|---|
| Palettes | Two. A warm world palette (bronze, fired clay, ochre, bitumen black, ink blue-black, salt white, blood) and a cold Sea palette that bleeds in as the Sea track rises. Both derived through the theme skill and verified for contrast, so sprites, tiles and UI share them. The Sea palette bleeds in by region and by stage: each city-region's distance from the coast and the Sea stage set how much of its ramps come from the Sea palette, so inland stays warm longest |
| Unit sprites | 32x32 on a 36x36 canvas (2px margin), four facings. Layers in Aseprite: body, gear, graft overlays, ink lines, scars, heraldry stripe, ghost overlay. Animations: idle, walk, attack, hit, downed |
| Tiles | 16x16 |
| Visual weather | Palette ramps shift by track stage (Sea pulls hues green and wet, Custom desaturates, Law dims banners). Tile variants per stage (dark hearths, unmanned gates, drowned streets). Tongue changes the glyphs on signs and tablets |
| Portraits and UI | Decided after the vertical slice. Placeholders until the hit lands |

### Class abilities (agreed for the slice, 2026-09-27)

Basic attacks have no cooldown. Cooldowns in turns. Base speed: Knife and Sling 5, Spear 4, Bow 3, Shield and Scribe 2. Speed with two classes: the average of the two base speeds, rounded down.

| Class | Basic | Ability 1 | Ability 2 |
|---|---|---|---|
| Spear | Thrust: hit 1 or 2 tiles in a line | Brace (2): the first enemy to end a move adjacent takes a Thrust before it acts | Sweep (3): hit every enemy in a two-tile arc in front |
| Sling | Loose: range 2 to 5, never adjacent, ignores cover at 3 plus | Skip shot (3): hit a target and one adjacent enemy for less | Harry (2): hit and push the target one tile away |
| Bow | Shoot: range 3 to 7, line of sight; range 3 to 4 if you moved this turn | Pin (3): Bound for one turn | Volley (4): hit every enemy in a 2x2 area |
| Shield | Strike: adjacent | Wall (2): enemies cannot pass your tile or its diagonals; adjacent allies cannot be targeted from the far side | Taunt (3): enemies within two tiles must focus you next round |
| Knife | Cut: adjacent | Net (3): range 2, Bound for one turn | Slip (2): move through enemies this turn |
| Scribe | Stylus: adjacent, weak | Witness (3): one deed this round by an adjacent ally is recorded at full significance | Read (2): reveal a chosen family's next card a round early |

The slice builds Spear, Sling and Shield. Gear is never a weapon: class identity is the weapon. Gear is worn or carried and makes sense alongside any class's weapon. One slot per hero, any item, each giving a class-agnostic ability. Nothing in gear touches the downing draw, so the injury loop stays intact.

| Gear | Ability | Cooldown |
|---|---|---|
| Bronze greaves | Stride: plus one move this turn | 2 |
| Rope | Haul: pull an adjacent ally or downed body one tile toward you | 2 |
| Salt pouch | Cleanse: remove one condition from an adjacent unit | 3 |
| Ram's horn | Rally: an adjacent ally's cooldowns drop by one | 3 |
| Wool cloak | Shroud: you cannot be targeted from range 3 or more this turn | 3 |
| Boar-tusk helm | Ward: ignore the next condition applied to you | 3 |
| Scale corselet | Stand: you cannot be pushed, pulled or dragged this round | 4 |
| Bronze bracers | Parry: the next adjacent attack against you this round deals half | 2 |

The slice ships greaves, corselet and bracers.

## 15. First run: the ambition

Agreed 2026-09-27. The first run ships one ambition, **Carry the archive out**, three chapters:

| Chapter | Milestone node | Battle objective |
|---|---|---|
| 1 | Reach the scribal city and take the tablets under writ | Kill all: the city's outlaw problem, the price of the tablets |
| 2 | Escort the tablets through outlaw roads to the river crossing | Protect the object: the tablets on the field |
| 3 | Reach the harbour before the tide takes it | Survive the waves until the ship is ready |

A chapter milestone is reaching a node (often a city, not always) and then fulfilling a battle objective at a landmark on that node's road; the battle is the chapter's climax. The run ends with a result screen (outcome, downings, deeds testified and unrecorded) plus a Chronicle stub: a short generated paragraph in the setting's voice. The Chronicle proper arrives in phase 4.

### Bronze grafts for the first run

A severe injury names a location from the attacker and the overkill. The hero cannot fight until fitted at a Smiths' node, where the Smiths offer one or two types for that location, filtered by origin and class, and name the mould debt. The player picks or refuses; refusing means the hero leaves the run.

**Why refuse: the meta cost of bronze.** Every graft fitted steps the Smiths' arc toward their hostile branch and, through them, feeds the Sea track: a Register that grafts freely arms the thing that ends it. And the remade are outside kin: a grafted hero loses guest-right at their origin city and kin nodes, and each graft nudges Custom down. The hearth does not feed bronze. Refusing keeps the Smiths weaker and the hearth open, at the price of a hero.

| Graft | Replaces on the sprite | Ability | Cost |
|---|---|---|---|
| Bronze arm | Arm | Basic attack becomes Cast Blow: damage 4, adjacent only. Cannot use Sling | Speed minus 1; the Smiths hold the mould |
| Bronze leg | Leg | Adds Stamp: end your move to Bind every adjacent enemy for a turn | Cannot enter water or tide, ever |
| Bronze jaw | Jaw | Adds Unyielding: Dread and Wound cannot be applied | Cannot testify or speak for the squad in events; Tongue mismatch with every recruit |
| Bronze ribs | Torso | Permanent Stand: cannot be pushed, pulled or dragged | Max HP minus 2; each further downing draws one step harsher |

### Scars for the first run

A downing that draws scar picks one by damage source and location. Every scar is a trade-off.

| Scar | Trade-off |
|---|---|
| Crushed hand | Reach minus 1 on line attacks; a free Parry each round |
| Torn ear | Cannot be Bound; Dread lasts one turn longer |
| Broken nose | Speed plus 1; max HP minus 1 |
| Salt-scarred lungs (sea-thing) | Immune to tide exposure; move minus 1 |
| Lamed | Move minus 1; ends every move facing the nearest enemy, so Brace and Sweep point right |
| Shield-shoulder | Adjacent allies take 1 less from the front; this hero takes 1 more from behind |
| Bitten (sea-thing) | Wound lasts one turn longer; plus 1 damage to sea-things |

### Pressures on the road (added 2026-09-27 after the first playthrough read as free)

Numbers are first-run defaults for tuning in play.

| Pressure | Rule |
|---|---|
| The writ's report | A report is owed at a walled city every six days. Missed, the squad is outlaw: walled cities shut their gates, so no full rest, no testimony and no Smiths inside walls until a report is made at an unwalled city or by a judgement event |
| The season | The run has 24 days. The ship at Lower Ugra sails on day 24, and the run is lost after that. The Drowned Mile floods on day 18: after it, Kinza-under-water hosts a sea fight |
| Landmarks fight | A ford or a pass hosts levies, a marsh or tide road hosts sea-things, a tomb hosts nothing. The fight cannot be walked past. A landmark that is also a chapter milestone hosts only the milestone fight |
| Events hold the squad | An event node presents a two-way choice before travel continues: fix the cart (a day, healing, a deed) or walk on; go up to the smoke under the writ (a fight, a deed) or keep to the road; read the tablet (reveal two nodes) or carry it; judge the goat (report deadline extended) or take the hearth's thanks (healing); let the road smith cast (a graft now, the Smiths' arc steps) or send him on |
| Rest costs | A day, counted against the season and the report |

## 16. First Register decisions

Agreed 2026-09-28.

- **Age.** Every hero on the Register ages one step per campaign elapsed, played or not. A shelved hero still dies of age; the Register is a clock.
- **Difficulty against tier budget.** Each tier point spent at squad creation adds one enemy HP per three points and one extra enemy per five points. Tuned in play.
- **The Road.** A retiree with no seat wanders and appears in later runs at rest nodes and cities: fights beside the squad once at their old kit, or asks a favour (a small errand on the route that is a testified deed when done). After three appearances they are found dead at a rest node, with their heirloom and a scene.
- **Descendants before bonds.** Comrade bonds form between heroes from shared fights (pairing rule below). A bonded pair at run end yields a descendant on the Register inheriting one property from each parent (heirloom gear, a grudge against what downed them, a trait). Unbonded retirees yield one descendant by origin house.
- **Pairing.** Bonds are scored per pair. Every fight both survive adds 1; ending a fight adjacent adds 1; one carrying, interposing for or avenging the other adds 2. A pair bonds at 5. Bonds are not exclusive. At run end, descendants come from greedy matching by score: strongest pair first, each hero used once, unmatched retirees fall to the origin-house rule.
- **Tier cost curve.** Tier 1 costs 1, tier 2 costs 2, and each tier after costs the sum of the two before (3, 5, 8, 13). Tier 0 is free.
- **First Register's seat pool.** One civic pool: Elder of an origin city, one per city, tenure three generations. Effect: that city's gates never shut to the squad and the tier budget rises by one while the seat is held.
- **The fall, stand-in.** Until the tracks move (phase 4), a Register falls after eight generations.
