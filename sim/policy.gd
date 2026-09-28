class_name SimPolicy
extends RefCounted
## A competent hero policy shared by tests and the --auto recordings. It reads
## the revealed cards, holds a line with the Shield, braces the Spear, keeps the
## Sling at range, uses gear when it pays and finishes the weakest target.


static func take_turn(b: SimBattle, h: SimUnit) -> void:
	var enemies := b.enemies()
	if enemies.is_empty():
		b.end_turn()
		return
	var threats := _threats(b)
	# Gear that pays this turn.
	if h.usable_abilities().has("stand") and _drag_incoming(b, h):
		b.hero_act(h, "stand", h.pos)
	# Move: pick the tile that best serves the class.
	if not b.turn.get("moved", false):
		var goal := _best_tile(b, h, threats)
		if goal != h.pos:
			b.hero_move(h, goal)
			if b.current() != h:
				return
	if b.turn.get("acted", false):
		if b.current() == h and b.state == "ongoing":
			b.end_turn()
		return
	# Class stance when no attack is available or the stance is worth more.
	var attackable := _attackable(b, h)
	if attackable.is_empty():
		var stance := _stance(b, h, threats)
		if stance != "":
			b.hero_act(h, stance, h.pos)
	else:
		# Finish the weakest reachable target with the strongest usable attack.
		attackable.sort_custom(func(x, y): return x.hp < y.hp)
		var used := false
		for key in _attacks_by_damage(h):
			for e in attackable:
				if b.hero_act(h, key, e.pos):
					used = true
					break
			if used:
				break
		if not used:
			var stance := _stance(b, h, threats)
			if stance != "":
				b.hero_act(h, stance, h.pos)
	if b.current() == h and b.state == "ongoing":
		b.end_turn()


## Enemy kinds whose card attacks this round, with their reach this round.
static func _threats(b: SimBattle) -> Dictionary:
	var out: Dictionary = {}
	for kind in b.cards:
		var card: Dictionary = b.cards[kind]
		var data: Dictionary = SimData.units()["enemies"][kind]
		var attacks: bool = not card.get("no_attack", false)
		var reach: int = data["move"] + int(card.get("move", 0)) + data["range"][1]
		if card.get("no_move", false):
			reach = data["range"][1]
		out[kind] = {"attacks": attacks, "reach": reach}
	return out


static func _drag_incoming(b: SimBattle, h: SimUnit) -> bool:
	for kind in b.cards:
		if b.cards[kind].get("special", "") == "drag":
			for e in b.enemies():
				if e.kind == kind and SimGrid.distance(e.pos, h.pos) <= e.move + 2:
					return true
	return false


static func _attacks_by_damage(h: SimUnit) -> Array:
	var keys: Array = []
	for key in h.usable_abilities():
		var a := SimData.ability(key)
		if a.has("damage") and a.has("range"):
			keys.append(key)
	keys.sort_custom(func(x, y): return int(SimData.ability(x)["damage"]) > int(SimData.ability(y)["damage"]))
	return keys


static func _attackable(b: SimBattle, h: SimUnit) -> Array:
	var out: Array = []
	var basic := SimData.ability(h.basic)
	for e in b.enemies():
		var d := SimGrid.distance(h.pos, e.pos)
		var max_r: int = basic["range"][1] + (h.reach_delta if basic.get("line", false) else 0)
		if d >= basic["range"][0] and d <= max_r and (not basic.get("line", false) or b.grid.in_line(h.pos, e.pos)):
			out.append(e)
	return out


static func _stance(b: SimBattle, h: SimUnit, threats: Dictionary) -> String:
	var usable := h.usable_abilities()
	var incoming := 0
	for e in b.enemies():
		var t: Dictionary = threats.get(e.kind, {})
		if t.get("attacks", false) and SimGrid.distance(e.pos, h.pos) <= int(t.get("reach", 0)):
			incoming += 1
	if incoming == 0:
		return ""
	if usable.has("wall") and _allies_behind(b, h) > 0:
		return "wall"
	if usable.has("brace"):
		return "brace"
	if usable.has("taunt") and h.hp > h.max_hp / 2:
		return "taunt"
	if usable.has("parry") and incoming > 0:
		return "parry"
	return ""


static func _allies_behind(b: SimBattle, h: SimUnit) -> int:
	var n := 0
	for a in b.heroes():
		if a != h and SimGrid.distance(a.pos, h.pos) <= 2:
			n += 1
	return n


## Scores every reachable tile for this class: range to targets, distance from threats, water, cover behind the Shield.
static func _best_tile(b: SimBattle, h: SimUnit, threats: Dictionary) -> Vector2i:
	var basic := SimData.ability(h.basic)
	var ranged: bool = basic["range"][0] >= 2
	var reach := b.movable_tiles(h)
	var best := h.pos
	var best_score := -1e9
	var nearest_enemy := _nearest(b.enemies(), h.pos)
	var shield := _shield_ally(b, h)
	for p in reach:
		var score := 0.0
		if b.grid.is_water(p) and not h.tide_immune:
			score -= 30.0
		if h.no_water and b.grid.is_water(p):
			continue
		# Targets in range from here.
		var in_range := 0
		var weakest_hp := 99
		for e in b.enemies():
			var d := SimGrid.distance(p, e.pos)
			var max_r: int = basic["range"][1] + (h.reach_delta if basic.get("line", false) else 0)
			if d >= basic["range"][0] and d <= max_r and (not basic.get("line", false) or b.grid.in_line(p, e.pos)):
				in_range += 1
				weakest_hp = mini(weakest_hp, e.hp)
		score += 25.0 * mini(in_range, 1) + 5.0 * mini(in_range, 3)
		if in_range > 0:
			score += (10.0 - weakest_hp)
		# Threat exposure this round.
		var exposed := 0
		for e in b.enemies():
			var t: Dictionary = threats.get(e.kind, {})
			if t.get("attacks", false) and SimGrid.distance(e.pos, p) <= int(t.get("reach", 0)):
				exposed += 1
		score -= (12.0 if ranged else 4.0) * exposed
		if h.hp <= 3:
			score -= 10.0 * exposed
		# Ranged units keep distance; melee close.
		if nearest_enemy != null:
			var d := SimGrid.distance(p, nearest_enemy.pos)
			if ranged:
				score += 3.0 * clampi(d, 0, 4) - (20.0 if d <= 1 else 0.0)
			else:
				score -= 2.0 * d
		# Stay near the Shield if you are not the Shield.
		if shield != null and shield != h:
			score += 4.0 - 2.0 * SimGrid.distance(p, shield.pos)
		# Cost of getting there.
		score -= 0.5 * float(reach[p])
		if score > best_score:
			best_score = score
			best = p
	return best


static func _nearest(units: Array, from: Vector2i) -> SimUnit:
	var best: SimUnit = null
	var best_d := 999
	for u in units:
		var d := SimGrid.distance(from, u.pos)
		if d < best_d:
			best_d = d
			best = u
	return best


static func _shield_ally(b: SimBattle, h: SimUnit) -> SimUnit:
	for a in b.heroes():
		if a.kind == "shield":
			return a
	return null


## Runs a battle to its end with this policy. Returns the final state.
static func run(b: SimBattle, guard: int = 600) -> String:
	if b.round == 0:
		b.start_round()
	var n := 0
	while b.state == "ongoing" and n < guard:
		var u := b.current()
		if u != null and u.side == "hero":
			take_turn(b, u)
		n += 1
	return b.state
