extends GutTest


func _scribe_battle() -> SimBattle:
	var b := SimBattle.new(8, 5, 3)
	var s := b.add_hero("scribe", Vector2i(1, 2))
	s.clay = 3
	s.sorcery_tier = 2
	b.add_enemy("outlaw_spear", Vector2i(4, 2))
	return b


func _to_hero(b: SimBattle, h: SimUnit) -> void:
	b.start_round()
	while b.current() != h and b.state == "ongoing":
		b.end_turn()


func test_writing_a_name_stands_an_enemy_down() -> void:
	var b := _scribe_battle()
	var s := b.heroes()[0]
	var e := b.enemies()[0]
	_to_hero(b, s)
	assert_true(s.usable_abilities().has("write_name"), "clay and tier allow Names")
	assert_true(b.hero_act(s, "write_name", e.pos))
	assert_eq(s.clay, 2)
	assert_eq(s.false_lines, 1)
	assert_true(e.flags.has("stands_down"))


func test_an_officer_contests_the_writing() -> void:
	var b := _scribe_battle()
	var s := b.heroes()[0]
	var o := b.add_enemy("officer", Vector2i(3, 3))
	_to_hero(b, s)
	assert_true(b.hero_act(s, "write_name", b.enemies()[0].pos))
	var contested := false
	for ev in b.events:
		if ev["type"] == "contested":
			contested = true
	assert_true(contested, "the officer within 3 struck the tablet")
	assert_eq(s.clay, 2, "the clay is still spent")


func test_recorded_dead_dies_at_round_end() -> void:
	var b := _scribe_battle()
	var s := b.heroes()[0]
	var e := b.enemies()[0]
	_to_hero(b, s)
	assert_true(b.hero_act(s, "write_death", e.pos))
	b.end_turn()
	var guard := 0
	while b.round == 1 and b.state == "ongoing" and guard < 10:
		if b.current() != null and b.current().side == "hero":
			b.end_turn()
		guard += 1
	assert_true(e.downed, "recorded dead at the round's end")


func test_bronze_memory_full_and_echo() -> void:
	var b := SimBattle.new(6, 3, 4)
	var h := b.add_hero("sling", Vector2i(0, 1))
	h.memory = {"ancestor": "Arnuwanda", "ability": "thrust", "charges": 1, "full": false}
	var e := b.add_enemy("outlaw_spear", Vector2i(2, 1))
	_to_hero(b, h)
	assert_true(h.usable_abilities().has("invoke"))
	assert_true(b.hero_act(h, "invoke", e.pos))
	assert_eq(e.hp, 5 - 2, "an echo: half of thrust's 3, rounded up")
	assert_eq(h.memory["charges"], 0)
	assert_false(h.usable_abilities().has("invoke"), "no charges left")
