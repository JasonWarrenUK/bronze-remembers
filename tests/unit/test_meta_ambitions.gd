extends GutTest


func test_ships_needs_the_named_hero_alive() -> void:
	var r := Run.new(2, "ships")
	r.add_hero("spear", "Arnuwanda", "greaves")
	r.add_hero("shield", "Muwatti", "corselet")
	r.named_hero = "Arnuwanda"
	r.apply_world(WorldState.new())
	r.chapter = 3
	r.squad[0]["alive"] = false
	var b := Encounters.build(r, r.world["nodes"]["ugarit_lo"], {"type": "hold", "tile": [8, 4], "turns": 4}, ["sea"], true)
	r.at = "ugarit_lo"
	r.milestone_reached = true
	b.state = "won"
	b.round = 5
	r.apply_battle(b, true)
	assert_eq(r.state, "lost", "the ship sails without the named one")


func test_founding_persists_into_the_next_world() -> void:
	var reg := Register.new()
	var a := reg.new_hero("spear", "Arnuwanda", "kessuwat")
	var run := Run.new(3, "found")
	run.add_hero("spear", "Arnuwanda")
	run.apply_world(reg.world)
	run.chapter = 4
	run.at = "pallanta"
	run.milestone_reached = true
	var b := Encounters.build(run, run.node(), {"type": "hold", "tile": [5, 5], "turns": 6}, ["levies"], true)
	b.state = "won"
	b.round = 7
	run.apply_battle(b, true)
	assert_eq(run.state, "won")
	assert_eq(run.founded_city["name"], "New Pallanta")
	reg.enter_from_run(run, [a["id"]])
	assert_eq(reg.founded_cities.size(), 1)
	var next := Run.new(4, "archive", reg.founded_cities)
	assert_true(next.world["nodes"].has("pallanta_new"), "the founded city stands in the next run's world")
	assert_eq(next.world["nodes"]["pallanta_new"]["flags"]["founded_by"], "Arnuwanda")


func test_drowning_the_temple_burns_it() -> void:
	var w := WorldState.new()
	w.record_run({"ambition": "drown_temple"})
	assert_eq(w.institutions["temple"]["state"], "Burned")
