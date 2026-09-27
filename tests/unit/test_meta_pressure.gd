extends GutTest


func _run() -> Run:
	var r := Run.new(3)
	r.add_hero("spear", "Arnuwanda", "greaves")
	r.add_hero("shield", "Muwatti", "corselet")
	return r


func test_landmark_forces_a_fight() -> void:
	var r := _run()
	r.travel_to("kessuwat-tarhuna-1")
	assert_eq(r.pending_fight, "levies", "the Kings' Ford hosts levies")
	var b := r.road_battle()
	assert_true(b.enemies().size() > 0)


func test_missed_report_makes_outlaw_and_shuts_gates() -> void:
	var r := _run()
	r.writ["report_due"] = 1
	r.travel_to("kessuwat-tarhuna-1")
	r.pending_fight = ""
	r.travel_to("kessuwat-tarhuna-2")
	assert_true(r.writ["outlaw"], "report missed")
	r.pending_event = {}
	r.travel_to("tarhuna")
	assert_true(r.gates_shut(), "walled city shut to outlaws")
	assert_eq(r.testify(), 0, "no testimony inside shut gates")


func test_ship_sails_and_the_run_is_lost() -> void:
	var r := _run()
	r.day = 24
	r.rest()
	assert_eq(r.state, "lost")


func test_event_choice_applies_effects() -> void:
	var r := _run()
	r.pending_event = SimData.load_json("events")["stopped_cart"].duplicate(true)
	r.pending_event["key"] = "stopped_cart"
	r.squad[0]["hp"] = 2
	var before := r.day
	r.choose(0)
	assert_eq(r.day, before + 1, "fixing the cart costs a day")
	assert_eq(r.squad[0]["hp"], 5, "and heals three")
	assert_eq(r.deeds.size(), 1)
