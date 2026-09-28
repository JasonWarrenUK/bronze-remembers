extends GutTest


func test_garble_only_past_broken_and_without_a_reader() -> void:
	var r := Run.new(3)
	r.add_hero("spear", "Arnuwanda")
	r.apply_world(WorldState.new())
	var text := "A grain cart with a broken axle, a Tin Road driver swearing at it in three tongues."
	assert_eq(r.garble(text), text, "Whole: nothing lost")
	r.stages["tongue"] = 3
	assert_true(r.garble(text).contains("[..]"), "Lost: words drop")
	r.squad[0]["sorcery_tier"] = 0
	assert_eq(r.garble(text), text, "a reader in the squad reads it")


func test_names_drift_at_lost() -> void:
	assert_eq(Chronicle.drift("Arnuwanda", 2, 1), "Arnuwanda")
	assert_ne(Chronicle.drift("Arnuwanda", 3, 1), "Arnuwanda")


func test_mismatched_recruit_bonds_slower_then_is_understood() -> void:
	var r := Run.new(4)
	var a := r.add_hero("spear", "Arnuwanda")
	var m := r.add_hero("sling", "Reed-born")
	m["origin"] = "zalpa"
	r.apply_world(WorldState.new())
	r.stages["tongue"] = 1
	r.apply_tongue()
	assert_true(m["mismatched"])
	var b := Encounters.build(r, r.node(), {"type": "kill_all"}, ["levies"], false, true)
	var ua := b.unit_by_id(a["unit_id"])
	var um := b.unit_by_id(m["unit_id"])
	um.pos = ua.pos + Vector2i(1, 0)
	for h in r.squad:
		h["unit_id_done"] = h["unit_id"]
	r._score_pairs(b)
	assert_eq(int(r.pair_scores["0:1"]), 1, "survive plus adjacent is 2, halved to 1 while mismatched")
	r._score_pairs(b)
	r._score_pairs(b)
	assert_true(int(r.pair_scores["0:1"]) >= 3)
	assert_false(m["mismatched"], "understood at a bond of 3")
