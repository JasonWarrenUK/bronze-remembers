class_name SimPolicy
extends RefCounted
## A naive hero policy shared by tests and the --auto recording: close on the
## nearest enemy, attack with the first usable attack, end the turn.


static func take_turn(b: SimBattle, h: SimUnit) -> void:
	var target: SimUnit = null
	var best := 999
	for e in b.enemies():
		var d := SimGrid.distance(h.pos, e.pos)
		if d < best:
			best = d
			target = e
	if target != null and not b.turn.get("moved", false):
		var basic := SimData.ability(h.basic)
		var goal := h.pos
		var goal_d := SimGrid.distance(h.pos, target.pos)
		var goal_fits: bool = goal_d >= basic["range"][0] and goal_d <= basic["range"][1]
		for p in b.movable_tiles(h):
			var d := SimGrid.distance(p, target.pos)
			var fits: bool = d >= basic["range"][0] and d <= basic["range"][1]
			if fits and (not goal_fits or d < goal_d):
				goal = p
				goal_d = d
				goal_fits = true
		if goal != h.pos:
			b.hero_move(h, goal)
			if b.current() != h:
				return
	if not b.turn.get("acted", false):
		# Prefer the weakest enemy in range of each attack.
		var by_hp := b.enemies().duplicate()
		by_hp.sort_custom(func(x, y): return x.hp < y.hp)
		for key in h.usable_abilities():
			var a := SimData.ability(key)
			if a.has("damage") and a.has("range"):
				for e in by_hp:
					if b.hero_act(h, key, e.pos):
						break
				if b.turn.get("acted", false):
					break
	if b.current() == h and b.state == "ongoing":
		b.end_turn()


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
