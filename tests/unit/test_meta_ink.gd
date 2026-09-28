extends GutTest


func _run() -> Run:
	var r := Run.new(8)
	r.add_hero("spear", "Arnuwanda", "greaves")
	r.add_hero("shield", "Muwatti", "corselet")
	r.apply_world(WorldState.new())
	return r


func test_temple_heals_for_ink_and_the_throat_calls() -> void:
	var r := _run()
	r.squad[0]["hp"] = 2
	assert_true(r.temple_heal(), "Kessuwat has a Temple")
	assert_eq(r.squad[0]["hp"], 8)
	assert_eq(r.squad[0]["ink"], 1)
	assert_eq(r.squad[1]["ink"], 0, "the unhurt pay nothing")
	r.squad[0]["ink"] = 4
	r.squad[0]["hp"] = 1
	r.temple_heal()
	assert_true(r.squad[0]["called"], "five lines: the Temple calls")
	r.ignore_call(r.squad[0])
	assert_eq(r.tally["sin"], 1)
	r.squad[0]["called"] = true
	r.answer_call(r.squad[0])
	assert_true(r.squad[0]["left"])
	assert_eq(r.tally["faith"], 2 + 2, "two healings and an answered call")


func test_substitution_moves_a_death() -> void:
	var r := _run()
	assert_true(r.substitute(r.squad[0], r.squad[1]))
	assert_eq(r.squad[0]["ink"], 3)
	var b := Encounters.build(r, r.node(), {"type": "kill_all"}, ["levies"], false, true)
	var a := b.unit_by_id(r.squad[0]["unit_id"])
	a.downed = true
	a.overkill = 9
	a.downed_by = "officer"
	b.rng = SimRng.new(1)
	var forced_dead := false
	for i in 30:
		var probe := SimBattle.new(4, 4, i)
		probe.add_hero("spear", Vector2i(0, 0))
		var u := probe.heroes()[0]
		u.downed = true
		u.overkill = 9
		u.downed_by = "officer"
		if probe.resolve_downings()[0]["outcome"] == "dead":
			b.rng = SimRng.new(i)
			forced_dead = true
			break
	assert_true(forced_dead, "found a seed that draws death")
	r.apply_battle(b, false)
	assert_true(r.squad[0]["alive"], "the ink-bearer lives")
	assert_false(r.squad[1]["alive"], "the stand-in died instead")
	assert_true(r.squad[0]["scars"].has("substituted"))


func test_tithe_at_broken_rite() -> void:
	var r := _run()
	r.stages["rite"] = 2
	assert_true(r.tithe_demanded())
	r.refuse_tithe()
	assert_eq(r.tally["sin"], 1)
	assert_false(r.tithe_demanded(), "one demand per visit")
