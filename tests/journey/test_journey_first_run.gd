extends GutTest
## The whole first run through the meta sim: muster, travel to each milestone,
## fight road battles on the way, testify, fit or refuse grafts, end with a
## result and a Chronicle stub.


func _play_run(seed: int) -> Run:
	var r := Run.new(seed)
	r.add_hero("spear", "Arnuwanda", "greaves")
	r.add_hero("sling", "Tudhal", "bracers")
	r.add_hero("shield", "Muwatti", "corselet")
	var guard := 0
	while r.state == "ongoing" and guard < 60:
		guard += 1
		var ch: Dictionary = r.ambition["chapters"][r.chapter - 1]
		var target := WorldGen.find_node(r.world, ch["node"])
		# Injured and near a smith? Route there first.
		var needs_smith := false
		for h in r.squad:
			if h["alive"] and h["injury"].get("severity", "") == "severe":
				needs_smith = true
		var goal := target
		if needs_smith:
			var best := 99
			for id in r.world["nodes"]:
				var n: Dictionary = r.world["nodes"][id]
				if n["kind"] == "city" and n["flags"].get("smiths", false):
					var rt := WorldGen.route(r.world, r.at, id)
					if rt.size() < best:
						best = rt.size()
						goal = id
		if r.at == goal and needs_smith:
			for h in r.squad:
				if h["alive"] and h["injury"].get("severity", "") == "severe":
					var offers := r.graft_offers(h)
					if offers.is_empty():
						r.refuse_graft(h)
					else:
						r.fit_graft(h, offers[0])
			continue
		if r.milestone_reached:
			var b := r.milestone_battle()
			SimPolicy.run(b)
			r.apply_battle(b, true)
			continue
		var path := WorldGen.route(r.world, r.at, goal)
		if path.is_empty():
			break
		r.travel_to(path[0])
		var n := r.node()
		if n["kind"] == "battle":
			var b := r.road_battle()
			SimPolicy.run(b)
			r.apply_battle(b, false)
		elif n["kind"] == "rest" or n["kind"] == "city":
			r.rest()
			r.testify()
	return r


func test_first_run_completes() -> void:
	var results := {}
	for seed in [1, 2, 3]:
		var r := _play_run(seed)
		results[seed] = r.state
		assert_ne(r.state, "ongoing", "run %d ended" % seed)
		assert_true(r.day > 3, "days passed")
		var stub := r.chronicle_stub()
		assert_true(stub.length() > 80, "chronicle stub written")
		gut.p("seed %d: %s on day %d, chapter %d, %d deeds, %s" % [seed, r.state, r.day, r.chapter, r.deeds.size(), stub])
	assert_true(results.values().has("won") or results.values().has("lost"))


func test_run_replays_from_seed() -> void:
	var a := _play_run(4)
	var b := _play_run(4)
	assert_eq(a.day, b.day)
	assert_eq(a.state, b.state)
	assert_eq(a.log.size(), b.log.size())
