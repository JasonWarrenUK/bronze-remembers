extends GutTest


func _battle() -> SimBattle:
	var b := SimBattle.new(10, 10, 42)
	b.add_hero("spear", Vector2i(1, 5), "greaves")
	b.add_hero("sling", Vector2i(0, 4))
	b.add_hero("shield", Vector2i(1, 4), "corselet")
	b.add_enemy("outlaw_spear", Vector2i(8, 5))
	b.add_enemy("outlaw_slinger", Vector2i(9, 4))
	return b


func test_queue_orders_by_initiative() -> void:
	var b := _battle()
	b.start_round()
	assert_eq(b.round, 1)
	assert_eq(b.queue.size(), 5)
	for i in range(1, b.queue.size()):
		assert_true(b.queue[i - 1]["init"] <= b.queue[i]["init"], "queue sorted")
	assert_true(b.cards.has("outlaw_spear") and b.cards.has("outlaw_slinger"), "one card per type")


func test_same_seed_same_fight() -> void:
	var a := _battle()
	var b := _battle()
	a.start_round()
	b.start_round()
	assert_eq(a.cards["outlaw_spear"]["name"], b.cards["outlaw_spear"]["name"])
	assert_eq(a.queue, b.queue)


func test_hero_move_and_thrust() -> void:
	var b := SimBattle.new(6, 3, 1)
	var h := b.add_hero("spear", Vector2i(0, 1))
	var e := b.add_enemy("outlaw_spear", Vector2i(4, 1))
	b.start_round()
	# Spear speed 4 -> init 30; outlaw card init between 15 and 80, so order varies. Find the hero turn.
	while b.current() != h and b.state == "ongoing":
		b.end_turn()
	assert_true(b.hero_move(h, Vector2i(2, 1)), "move within 3")
	assert_true(b.hero_act(h, "thrust", Vector2i(4, 1)), "thrust reach 2 in line")
	assert_eq(e.hp, 4)
	assert_false(b.hero_act(h, "thrust", Vector2i(4, 1)), "one action per turn")


func test_push_into_wall_wounds_and_stand_resists() -> void:
	var b := SimBattle.new(6, 3, 1)
	var h := b.add_hero("sling", Vector2i(0, 1))
	var e := b.add_enemy("outlaw_spear", Vector2i(3, 1))
	b.grid.set_tile(Vector2i(4, 1), SimGrid.Tile.WALL)
	b.start_round()
	while b.current() != h and b.state == "ongoing":
		b.end_turn()
	assert_true(b.hero_act(h, "harry", Vector2i(3, 1)))
	assert_true(e.has("wound"), "pushed into a wall: Wound")
	assert_eq(e.pos, Vector2i(3, 1))
	assert_eq(h.cooldowns["harry"], 3, "cooldown set (ticks at turn end)")


func test_downing_and_resolution() -> void:
	var b := SimBattle.new(4, 1, 5)
	var h := b.add_hero("sling", Vector2i(0, 0))
	h.hp = 1
	var e := b.add_enemy("outlaw_spear", Vector2i(1, 0))
	b.start_round()
	# Run until the enemy has acted or the battle ends.
	var guard := 0
	while b.state == "ongoing" and guard < 20:
		if b.current() == h:
			b.end_turn()
		guard += 1
	assert_true(h.downed, "hero downed by the outlaw")
	assert_eq(b.state, "lost")
	var results := b.resolve_downings()
	assert_eq(results.size(), 1)
	assert_true(["scar", "severe", "dead"].has(results[0]["outcome"]))


func test_wall_blocks_enemy_path() -> void:
	var b := SimBattle.new(5, 3, 2)
	var h := b.add_hero("shield", Vector2i(2, 1))
	var e := b.add_enemy("jointed", Vector2i(4, 1))
	b.start_round()
	while b.current() != h and b.state == "ongoing":
		b.end_turn()
	assert_true(b.hero_act(h, "wall", h.pos))
	var tiles := b.wall_tiles()
	assert_true(tiles.has(Vector2i(3, 0)) and tiles.has(Vector2i(3, 2)), "diagonals walled")
	var reach := b.movable_tiles(e)
	assert_false(reach.has(Vector2i(3, 0)), "enemy cannot enter walled diagonal")
