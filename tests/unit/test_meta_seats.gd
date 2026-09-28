extends GutTest


func test_pool_offers_by_band_and_requirements() -> void:
	var reg := Register.new()
	var h := reg.new_hero("spear", "Arnuwanda", "kessuwat", "greaves", 0)
	var ids: Array = []
	for o in reg.seat_offers(h):
		ids.append(o["id"])
	assert_true(ids.has("elder"), "tier 0 may be Elder")
	assert_false(ids.has("general"), "General needs Named band")
	h["tier"] = 5
	h["grafts"] = ["bronze_arm"]
	ids = []
	for o in reg.seat_offers(h):
		ids.append(o["id"])
	assert_true(ids.has("general") and ids.has("master_of_moulds"))
	assert_false(ids.has("high_priest"), "no ink, no Voice")


func test_recipe_needs_every_anchor() -> void:
	var reg := Register.new()
	var h := reg.new_hero("shield", "Muwatti", "kessuwat", "corselet", 6)
	h["deed_tags"] = ["held:The Kings' Ford"]
	var names: Array = []
	for o in reg.seat_offers(h):
		names.append(o["id"])
	assert_false(names.has("ford_keeper"), "held once is not twice")
	h["deed_tags"] = ["held:The Kings' Ford", "held:The Kings' Ford"]
	names = []
	for o in reg.seat_offers(h):
		names.append(o["id"])
	assert_true(names.has("ford_keeper"))


func test_succession_by_deed_and_contested_effects() -> void:
	var reg := Register.new()
	var a := reg.new_hero("spear", "Arnuwanda", "kessuwat", "", 5)
	var b := reg.new_hero("sling", "Tudhal", "kessuwat", "", 5)
	a["deeds"] = 2
	b["deeds"] = 6
	var offer: Dictionary = {}
	for o in reg.seat_offers(a):
		if o["id"] == "general":
			offer = o
	assert_true(reg.take_seat(a, offer)["taken"])
	var res := reg.take_seat(b, offer, "deed")
	assert_true(res["taken"], "more deeds unseats the holder")
	assert_eq(res["emeritus"], a["id"])
	assert_eq(a["status"], "emeritus")
	assert_true(a["grudges"][0].begins_with("unseated"))
	assert_eq(reg.budget(), Register.BASE_BUDGET, "a contested seat's effects are halved this generation")


func test_unlocks_from_deed_tags() -> void:
	var reg := Register.new()
	var a := reg.new_hero("spear", "Arnuwanda", "kessuwat")
	var run := Run.new(12)
	run.add_hero("spear", "Arnuwanda")
	run.deeds.append({"text": "Held the ford", "significance": 2, "day": 1, "node": "x", "recorded": true, "tags": ["held:The Kings' Ford"]})
	run.state = "lost"
	reg.enter_from_run(run, [a["id"]])
	assert_true(reg.has_unlock("bow_class"))
	assert_eq(reg.next_unlock()["name"], "The Knife")


func test_fixation_resolves_or_curdles() -> void:
	var r := Run.new(13)
	var h := r.add_hero("spear", "Arnuwanda", "greaves")
	r.apply_world(WorldState.new())
	r._plant_fixation(h, "downed:levies")
	assert_eq(h["fixations"].size(), 1)
	r._deed("Killed the officer", 3, {"deeds": []}, ["kill_named:levies"])
	assert_eq(h["fixations"].size(), 0)
	assert_eq(h["traits"], ["Deserter's bane"])
	assert_eq(h["tier_bonus"], 1)
	r._plant_fixation(h, "downed:sea")
	h["fixations"][0]["fights"] = 3
	r._curdle_fixations()
	assert_true(h["traits"].has("Hears the tide"))
