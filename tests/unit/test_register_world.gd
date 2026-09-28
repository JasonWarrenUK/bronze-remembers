extends GutTest


func test_run_reports_dealings_and_the_register_ticks() -> void:
	var reg := Register.new()
	var a := reg.new_hero("spear", "Arnuwanda", "kessuwat", "greaves")
	var run := Run.new(5)
	run.add_hero("spear", "Arnuwanda", "greaves")
	run.apply_world(reg.world)
	assert_eq(run.stages["law"], 0)
	assert_true(run.weather.size() == 5, "five weather lines")
	run.travel_to("kessuwat-tarhuna-1")
	run.pending_fight = ""
	run.travel_to("kessuwat-tarhuna-2")
	run.pending_event = {}
	run.travel_to("tarhuna")
	assert_eq(run.tally["reports_kept"], 1)
	run.state = "lost"
	var rep := reg.enter_from_run(run, [a["id"]])
	assert_true(rep.has("world"))
	assert_eq(reg.world.scores["law"], 8, "9 from the curve minus 1 for the report kept")
	assert_false(reg.fallen)


func test_world_stages_shape_the_next_run() -> void:
	var reg := Register.new()
	reg.world.scores["sea"] = 45
	reg.world.scores["law"] = 25
	var run := Run.new(6)
	run.apply_world(reg.world)
	assert_eq(run.stages["sea"], 2)
	assert_eq(int(run.season["tide_floods"]), 12, "the tide floods six days earlier at Sea Broken")
	assert_eq(int(run.season["report_every"]), 5, "reports come due faster at Law Strained")


func test_mould_debt_defaults_call_the_bronze_back() -> void:
	var run := Run.new(7)
	var h := run.add_hero("shield", "Muwatti", "corselet")
	h["injury"] = {"severity": "severe", "location": "torso", "days_left": 6, "by": "drowned"}
	run.fit_graft(h, "bronze_ribs")
	assert_true(h.has("mould_debt"))
	h["mould_debt"]["days"] = 1
	run.travel_to("kessuwat-tarhuna-1")
	assert_eq(run.tally["moulds_defaulted"], 1)
	assert_eq(h["grafts"], [], "the bronze is called back")
	assert_eq(h["injury"]["severity"], "severe")
