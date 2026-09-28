extends GutTest


func test_tier_costs_and_bands() -> void:
	assert_eq(Register.tier_cost(0), 0)
	assert_eq(Register.tier_cost(1), 1)
	assert_eq(Register.tier_cost(2), 2)
	assert_eq(Register.tier_cost(3), 3)
	assert_eq(Register.tier_cost(4), 5)
	assert_eq(Register.tier_cost(5), 8)
	assert_eq(Register.band_name(4), "Levy")
	assert_eq(Register.band_name(5), "Named")
	assert_eq(Register.band_name(20), "Founder")
	assert_eq(Register.scaling(7), {"extra_enemies": 1, "extra_hp": 2})


func _register_and_run(seed: int) -> Array:
	var reg := Register.new()
	var a := reg.new_hero("spear", "Arnuwanda", "kessuwat", "greaves")
	var b := reg.new_hero("sling", "Tudhal", "kessuwat", "bracers")
	var c := reg.new_hero("shield", "Muwatti", "tarhuna", "corselet")
	var run := Run.new(seed)
	for h in [a, b, c]:
		var rec := run.add_hero(h["kind"], h["name"], h["gear"])
	return [reg, run, [a["id"], b["id"], c["id"]]]


func test_survivors_tier_up_and_everyone_ages() -> void:
	var parts := _register_and_run(1)
	var reg: Register = parts[0]
	var run: Run = parts[1]
	var shelf := reg.new_hero("spear", "Shelved", "zalpa")
	run.state = "won"
	run.squad[2]["alive"] = false
	var rep := reg.enter_from_run(run, parts[2])
	assert_eq(reg.generation, 1)
	assert_eq(reg.hero_by_id(parts[2][0])["tier"], 1)
	assert_eq(reg.hero_by_id(parts[2][2])["status"], "dead")
	assert_eq(shelf["age_steps"], 1, "unplayed heroes age too")
	assert_eq(rep["dead"], ["Muwatti"])


func test_fourth_campaign_is_the_last() -> void:
	var parts := _register_and_run(2)
	var reg: Register = parts[0]
	var run: Run = parts[1]
	reg.hero_by_id(parts[2][0])["campaigns"] = 3
	run.state = "won"
	var rep := reg.enter_from_run(run, parts[2])
	assert_eq(rep["aged_out"], ["Arnuwanda"])
	assert_eq(reg.hero_by_id(parts[2][0])["status"], "dead")
	assert_eq(rep["descendants"].size(), 1, "an aged-out retiree leaves a house child")
	var child: Dictionary = rep["descendants"][0]
	assert_eq(child["line"]["parents"], [parts[2][0]])
	assert_eq(child["gear"], "greaves", "inherits the heirloom")


func test_bonded_pair_yields_a_descendant_with_tier() -> void:
	var parts := _register_and_run(3)
	var reg: Register = parts[0]
	var run: Run = parts[1]
	reg.hero_by_id(parts[2][0])["tier"] = 8
	reg.hero_by_id(parts[2][1])["tier"] = 4
	run.pair_scores = {"0:1": 5}
	run.state = "won"
	var rep := reg.enter_from_run(run, parts[2])
	assert_eq(rep["descendants"].size(), 1)
	var child: Dictionary = rep["descendants"][0]
	assert_eq(child["tier"], 9 / 2 + 5 / 4, "half the higher parent plus a quarter of the other, after the run's tier-up")
	assert_eq(child["line"]["parents"].size(), 2)


func test_seats_and_road() -> void:
	var reg := Register.new()
	var a := reg.new_hero("spear", "Arnuwanda", "kessuwat")
	var b := reg.new_hero("shield", "Muwatti", "kessuwat")
	assert_true(reg.retire_to_seat(a))
	assert_false(reg.retire_to_seat(b), "one Elder per city")
	assert_true(reg.seat_holds("kessuwat"))
	assert_eq(reg.budget(), Register.BASE_BUDGET + 1)
	reg.retire_to_road(b)
	assert_eq(reg.wanderers.size(), 1)
	assert_eq(reg.playable().size(), 0)


func test_save_and_load() -> void:
	var reg := Register.new()
	reg.new_hero("sling", "Tudhal", "tarhuna", "bracers", 3)
	reg.generation = 2
	assert_true(reg.save("user://test_register.json"))
	var r2 := Register.load_from("user://test_register.json")
	assert_eq(r2.generation, 2)
	assert_eq(r2.heroes[0]["tier"], 3)
	assert_eq(r2.heroes[0]["name"], "Tudhal")
