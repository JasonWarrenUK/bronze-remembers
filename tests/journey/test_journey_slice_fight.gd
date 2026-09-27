extends GutTest
## A scripted fight through the sim: three levy heroes against outlaws with a
## sea-thing wave, played by a simple policy. Proves the loop closes from
## deployment to result without a renderer.


func _policy_turn(b: SimBattle, h: SimUnit) -> void:
	# Move toward the nearest enemy, then use the best available attack on anything in range.
	var target: SimUnit = null
	var best := 999
	for e in b.enemies():
		var d := SimGrid.distance(h.pos, e.pos)
		if d < best:
			best = d
			target = e
	if target == null:
		b.end_turn()
		return
	var reach := b.movable_tiles(h)
	var goal := h.pos
	var goal_d := SimGrid.distance(h.pos, target.pos)
	var basic := SimData.ability(h.basic)
	for p in reach:
		var d := SimGrid.distance(p, target.pos)
		var fits: bool = d >= basic["range"][0] and d <= basic["range"][1]
		if fits and (not goal_d >= basic["range"][0] or d < goal_d):
			goal = p
			goal_d = d
	if goal != h.pos:
		b.hero_move(h, goal)
	for key in h.usable_abilities():
		var a := SimData.ability(key)
		if a.has("damage") and a.has("range"):
			for e in b.enemies():
				if b.hero_act(h, key, e.pos):
					b.end_turn()
					return
	b.end_turn()


func test_full_fight_resolves() -> void:
	var b := SimBattle.new(10, 8, 7)
	for x in 10:
		b.grid.set_tile(Vector2i(x, 7), SimGrid.Tile.WATER)
	b.add_hero("spear", Vector2i(1, 3), "greaves")
	b.add_hero("sling", Vector2i(0, 2), "bracers")
	b.add_hero("shield", Vector2i(1, 2), "corselet")
	b.add_enemy("outlaw_spear", Vector2i(7, 3))
	b.add_enemy("outlaw_spear", Vector2i(8, 2))
	b.add_enemy("outlaw_slinger", Vector2i(9, 4))
	b.waves = [{"round": 3, "units": [{"kind": "jointed", "pos": [5, 6]}, {"kind": "drowned", "pos": [8, 6]}]}]
	b.start_round()
	var guard := 0
	while b.state == "ongoing" and guard < 400:
		var u := b.current()
		if u != null and u.side == "hero":
			_policy_turn(b, u)
		guard += 1
	assert_ne(b.state, "ongoing", "fight ended within the guard")
	assert_true(b.round >= 3, "the wave round was reached (round %d)" % b.round)
	var spawned := 0
	for ev in b.events:
		if ev["type"] == "spawn":
			spawned += 1
	assert_eq(spawned, 2, "both wave units spawned")
	var types := {}
	for ev in b.events:
		types[ev["type"]] = true
	for needed in ["round_start", "turn_start", "move", "hit", "enemy_card", "battle_end"]:
		assert_true(types.has(needed), "event %s emitted" % needed)
	var results := b.resolve_downings()
	gut.p("result: %s after %d rounds, %d events, downings %s" % [b.state, b.round, b.events.size(), str(results)])


func test_hold_objective_wins() -> void:
	var b := SimBattle.new(6, 3, 3)
	b.objective = {"type": "hold", "tile": [3, 1], "turns": 2}
	var h := b.add_hero("shield", Vector2i(3, 1))
	b.add_enemy("outlaw_slinger", Vector2i(0, 0))
	b.start_round()
	var guard := 0
	while b.state == "ongoing" and guard < 40:
		if b.current() == h:
			b.end_turn()
		guard += 1
	assert_eq(b.state, "won", "held the tile for two rounds")
	assert_eq(b.hold_turns, 2)


func test_replay_is_identical() -> void:
	var a := SimBattle.new(8, 6, 11)
	var b := SimBattle.new(8, 6, 11)
	for bt: SimBattle in [a, b]:
		bt.add_hero("spear", Vector2i(0, 2))
		bt.add_enemy("jointed", Vector2i(6, 2))
		bt.add_enemy("outlaw_spear", Vector2i(7, 3))
		bt.start_round()
		var guard := 0
		while bt.state == "ongoing" and guard < 100:
			var u: SimUnit = bt.current()
			if u != null and u.side == "hero":
				_policy_turn(bt, u)
			guard += 1
	assert_eq(a.events.size(), b.events.size(), "same event count")
	assert_eq(a.events, b.events, "identical event stream from the same seed")
