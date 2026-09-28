extends GutTest


func test_stages_and_curves() -> void:
	var w := WorldState.new()
	assert_eq(w.stage("law"), "Whole")
	w.tick_generation()
	assert_eq(w.scores["law"], 9)
	assert_eq(w.scores["tongue"], 3)
	for i in 4:
		w.tick_generation()
	assert_eq(w.stage("law"), "Broken", "law reaches Broken in about five generations")
	assert_true(w.scores["tongue"] < 20, "tongue barely moves early")


func test_a_register_lasts_twelve_to_fifteen_generations() -> void:
	var w := WorldState.new()
	var n := 0
	while not w.fallen() and n < 40:
		w.tick_generation()
		n += 1
	assert_true(n >= 12 and n <= 15, "fell after %d generations" % n)


func test_reports_kept_restore_the_palace() -> void:
	var w := WorldState.new()
	for i in 3:
		w.record_run({"reports_kept": 3, "reports_defaulted": 0})
		w.tick_generation()
	assert_eq(w.institutions["palace"]["state"], "Restored")
	assert_true(w.scores["law"] < 27, "Restored Palace slows Law: %d" % w.scores["law"])


func test_sin_makes_a_cult_that_burns_its_temple() -> void:
	var w := WorldState.new()
	for i in 6:
		w.record_run({"faith": 0, "sin": 3})
		w.tick_generation()
	assert_eq(w.institutions["temple"]["state"], "Burned")
	assert_true(w.stage_num("rite") >= 3, "the fire drops Rite two stages")


func test_seat_hold_stops_a_track_for_a_generation() -> void:
	var w := WorldState.new()
	w.holds["sea"] = true
	w.tick_generation()
	assert_eq(w.scores["sea"], 0)
	w.tick_generation()
	assert_eq(w.scores["sea"], 8)


func test_round_trip() -> void:
	var w := WorldState.new()
	w.record_run({"grafts_fitted": 2})
	w.tick_generation()
	var back := WorldState.from_dict(JSON.parse_string(JSON.stringify(w.to_dict())))
	assert_eq(back.scores, w.scores)
	assert_eq(back.institutions["smiths"]["moulds"], 2)
