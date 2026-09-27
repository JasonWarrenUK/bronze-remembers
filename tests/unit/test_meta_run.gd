extends GutTest


func _run() -> Run:
	var r := Run.new(3)
	r.add_hero("spear", "Arnuwanda", "greaves")
	r.add_hero("sling", "Tudhal", "bracers")
	r.add_hero("shield", "Muwatti", "corselet")
	return r


func test_travel_costs_days_and_reaches_milestone() -> void:
	var r := _run()
	assert_eq(r.day, 0)
	assert_true(r.travel_to("kessuwat-tarhuna-1"))
	assert_eq(r.day, 1)
	assert_false(r.travel_to("ugarit_lo"), "not adjacent")
	for id in ["kessuwat-tarhuna-2", "tarhuna"]:
		assert_true(r.travel_to(id))
	assert_eq(r.day, 3)
	assert_true(r.milestone_reached, "Tarhuna is the chapter 1 milestone")
	var b := r.milestone_battle()
	assert_not_null(b)
	assert_eq(b.objective["type"], "kill_all")
	assert_eq(b.heroes().size(), 3)


func test_untreated_severe_injury_kills_on_the_road() -> void:
	var r := _run()
	r.squad[0]["injury"] = {"severity": "severe", "location": "arm", "days_left": 2, "by": "outlaw_spear"}
	r.travel_to("kessuwat-tarhuna-1")
	assert_true(r.squad[0]["alive"])
	r.travel_to("kessuwat-tarhuna-2")
	assert_false(r.squad[0]["alive"], "died after the timer ran out")
	assert_eq(r.fighters().size(), 2)


func test_smiths_offer_grafts_by_location_and_class() -> void:
	var r := _run()
	r.squad[1]["injury"] = {"severity": "severe", "location": "arm", "days_left": 6, "by": "outlaw_spear"}
	assert_eq(r.graft_offers(r.squad[1]).size(), 0, "no offers away from a Smiths' node? (kessuwat has smiths)")
	# Kessuwat has smiths, so the sling gets no bronze arm (forbidden) and nothing else for the arm.
	r.squad[2]["injury"] = {"severity": "severe", "location": "torso", "days_left": 6, "by": "drowned"}
	var offers := r.graft_offers(r.squad[2])
	assert_eq(offers, ["bronze_ribs"])
	r.fit_graft(r.squad[2], "bronze_ribs")
	assert_eq(r.squad[2]["grafts"], ["bronze_ribs"])
	assert_true(r.squad[2]["injury"].is_empty())
	var b := Encounters.build(r, r.node(), {"type": "kill_all"}, ["levies"], false)
	var shield := b.unit_by_id(r.squad[2]["unit_id"])
	assert_eq(shield.max_hp, 8, "ribs cost two max HP")
	assert_true(shield.permanent_stand)


func test_save_and_load_round_trip() -> void:
	var r := _run()
	r.travel_to("kessuwat-tarhuna-1")
	r.squad[0]["scars"].append("broken_nose")
	assert_true(r.save("user://test_run.json"))
	var r2 := Run.load_from("user://test_run.json")
	assert_eq(r2.at, "kessuwat-tarhuna-1")
	assert_eq(r2.day, 1)
	assert_eq(r2.squad[0]["scars"], ["broken_nose"])
	assert_eq(r2.rng.range_int(0, 1000), r.rng.range_int(0, 1000), "rng state restored")
