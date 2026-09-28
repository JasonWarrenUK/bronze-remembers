extends GutTest


func test_apprenticeship_and_clay_at_tarhuna() -> void:
	var r := Run.new(9)
	var h := r.add_hero("sling", "Tudhal", "bracers")
	r.apply_world(WorldState.new())
	assert_false(r.apprentice(h), "Kessuwat is not scribal")
	for id in ["kessuwat-tarhuna-1", "kessuwat-tarhuna-2", "tarhuna"]:
		r.pending_fight = ""
		r.pending_event = {}
		r.travel_to(id)
	var before := r.day
	assert_true(r.apprentice(h))
	assert_eq(r.day, before + 4)
	assert_eq(h["sorcery_tier"], 0)
	assert_true(r.buy_clay())
	assert_eq(h["clay"], 2)
	var b := r.milestone_battle()
	var u := b.unit_by_id(h["unit_id"])
	assert_eq(u.clay, 2)
	assert_true(u.usable_abilities().has("write_count"), "a Copyist can write Counts")


func test_heirloom_carries_the_ancestor() -> void:
	var reg := Register.new()
	var a := reg.new_hero("spear", "Arnuwanda", "kessuwat", "greaves")
	a["tier"] = 6
	a["campaigns"] = 3
	var run := Run.new(10)
	run.add_hero("spear", "Arnuwanda", "greaves")
	run.state = "won"
	var rep := reg.enter_from_run(run, [a["id"]])
	assert_eq(rep["aged_out"], ["Arnuwanda"])
	var child: Dictionary = rep["descendants"][0]
	assert_eq(child["memory"]["ancestor"], "Arnuwanda")
	assert_eq(child["memory"]["ability"], "thrust")
	assert_eq(child["memory"]["charges"], 2, "one charge plus one per five tiers")


func test_lies_reach_the_ledger() -> void:
	var r := Run.new(11)
	var h := r.add_hero("scribe", "Piyama", "")
	h["sorcery_tier"] = 2
	h["clay"] = 2
	r.apply_world(WorldState.new())
	var b := Encounters.build(r, r.node(), {"type": "kill_all"}, ["levies"], false, true)
	var u := b.unit_by_id(h["unit_id"])
	b.start_round()
	while b.current() != u and b.state == "ongoing":
		b.end_turn()
	assert_true(b.hero_act(u, "write_name", b.enemies()[0].pos))
	r.apply_battle(b, false)
	assert_eq(r.tally["lies"], 1)
	assert_eq(int(r.tally["nudges"]["law"]), 1, "every lie costs Law")
	assert_eq(h["false_lines"], 1)
