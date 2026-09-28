extends GutTest
## Three runs into one Register: recruits, tiers, age, bonds, descendants,
## the Road and the budget all touched by a policy player.


func _policy_run(reg: Register, seed: int) -> Run:
	var run := Run.new(seed)
	# Squad creation: playable heroes within budget, fresh levies to fill.
	var picks: Array = []
	var spent := 0
	var pool := reg.playable()
	pool.sort_custom(func(a, b): return a["tier"] > b["tier"])
	for h in pool:
		if picks.size() >= 3:
			break
		if spent + Register.tier_cost(h["tier"]) <= reg.budget():
			picks.append(h)
			spent += Register.tier_cost(h["tier"])
	var kinds := ["spear", "sling", "shield"]
	while picks.size() < 3:
		var k: String = kinds[picks.size()]
		picks.append(reg.new_hero(k, "Levy %d-%d" % [seed, picks.size()], "kessuwat", ["greaves", "bracers", "corselet"][picks.size()]))
	var roster: Array = []
	for h in picks:
		var rec := run.add_hero(h["kind"], h["name"], h["gear"])
		rec["scars"] = h["scars"].duplicate()
		rec["grafts"] = h["grafts"].duplicate()
		roster.append(h["id"])
	run.scaling = Register.scaling(spent)
	run.apply_world(reg.world)
	run.wanderers = reg.wanderers.duplicate(true)
	run.narrator = reg.narrator()
	var guard := 0
	while run.state == "ongoing" and guard < 80:
		guard += 1
		if not run.wanderer_here.is_empty():
			if guard % 2 == 0:
				run.wanderer_joins()
			else:
				run.wanderer_favour()
		if not run.pending_event.is_empty():
			run.choose(0)
		if run.pending_fight != "":
			var rb := run.road_battle()
			SimPolicy.run(rb)
			run.apply_battle(rb, false)
			continue
		if run.milestone_reached:
			var b := run.milestone_battle()
			SimPolicy.run(b)
			run.apply_battle(b, true)
			continue
		var ch: Dictionary = run.ambition["chapters"][run.chapter - 1]
		var path := WorldGen.route(run.world, run.at, WorldGen.find_node(run.world, ch["node"]))
		if path.is_empty():
			break
		var n := run.node()
		if (n["kind"] == "rest" or n["kind"] == "city") and run.fighters().size() > 0 and run.fighters()[0]["hp"] < run.fighters()[0]["max_hp"]:
			run.rest()
			run.testify()
		run.travel_to(path[0])
	reg.wanderers = run.wanderers
	var rep := reg.enter_from_run(run, roster)
	gut.p("gen %d: run %s day %d; tiered %s; dead %s; aged out %s; descendants %d; wanderers %d; budget %d" % [reg.generation, run.state, run.day, str(rep["tiered"]), str(rep["dead"]), str(rep["aged_out"]), rep["descendants"].size(), reg.wanderers.size(), reg.budget()])
	return run


func test_three_generations() -> void:
	var reg := Register.new()
	var seats_taken := 0
	for seed in [1, 2, 3]:
		_policy_run(reg, seed)
		# Retire one tiered survivor each generation: a seat if offered, else the Road.
		for h in reg.playable():
			if h["tier"] >= 1 and reg.wanderers.size() + seats_taken < reg.generation:
				var offers := reg.seat_offers(h)
				if not offers.is_empty() and reg.take_seat(h, offers[0])["taken"]:
					seats_taken += 1
				else:
					reg.retire_to_road(h)
				break
	assert_true(seats_taken >= 1, "a seat was taken across three generations")
	assert_true(reg.world.scores["law"] > 0, "the world ticked")
	gut.p("world after 3: %s; institutions %s; next unlock %s" % [str(reg.world.scores), str(reg.world.institutions["smiths"]["state"]), str(reg.next_unlock().get("name", "none"))])
	assert_eq(reg.generation, 3)
	assert_true(reg.heroes.size() >= 5, "recruits accumulate")
	var aged := 0
	for h in reg.heroes:
		if h["age_steps"] > 0:
			aged += 1
	assert_true(aged > 0, "the Register ages")
	assert_true(reg.save("user://test_register_journey.json"))
	var back := Register.load_from("user://test_register_journey.json")
	assert_eq(back.heroes.size(), reg.heroes.size())
	assert_eq(back.chronicle.size(), 3, "one chronicle entry per run")
