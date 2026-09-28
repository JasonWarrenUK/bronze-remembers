extends GutTest


func test_forgery_only_at_lost_with_a_tablet_hand() -> void:
	var r := Run.new(5)
	var h := r.add_hero("scribe", "Piyama")
	r.apply_world(WorldState.new())
	h["sorcery_tier"] = 1
	h["clay"] = 1
	assert_false(r.forge_report(h), "Law Whole: nothing to forge around")
	r.stages["law"] = 3
	r.writ["outlaw"] = true
	assert_true(r.forge_report(h))
	assert_false(r.writ["outlaw"])
	assert_eq(r.tally["lies"], 1)
	assert_eq(h["clay"], 0)


func test_emeritus_appears_at_a_city() -> void:
	var r := Run.new(6)
	r.add_hero("spear", "Arnuwanda")
	r.apply_world(WorldState.new())
	r.emeriti = [{"name": "Old Zida", "seat": "General of the Sun", "appearances": 0}]
	var seen := false
	for i in 12:
		r.rng = SimRng.new(i)
		r.pending_event = {}
		r.at = "kessuwat-tarhuna-2"
		r.travel_to("tarhuna")
		if not r.pending_event.is_empty() and r.pending_event["key"].begins_with("emeritus"):
			seen = true
			assert_true(r.pending_event["text"].contains("Old Zida"))
			break
	assert_true(seen, "the emeritus turned up within twelve arrivals")


func test_mercenaries_need_the_unlock_and_a_tongue() -> void:
	var reg := Register.new()
	assert_eq(reg.mercenaries_available(), 0)
	reg.unlocks = {"earned": {"reed_recruits": 1}}
	reg.world.scores["tongue"] = 25
	assert_eq(reg.mercenaries_available(), 1)
	var m := reg.new_mercenary()
	assert_eq(m["origin"], "mercenary")
	reg.world.scores["tongue"] = 100
	assert_eq(reg.mercenaries_available(), 0, "the world abroad has fallen")
