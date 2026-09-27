extends GutTest


func test_world_is_deterministic_and_connected() -> void:
	var a := WorldGen.generate(5)
	var b := WorldGen.generate(5)
	assert_eq(a["nodes"].keys(), b["nodes"].keys())
	assert_eq(a["nodes"]["kessuwat-tarhuna-2"]["kind"], b["nodes"]["kessuwat-tarhuna-2"]["kind"])
	assert_true(a["nodes"].size() > 6, "fill nodes generated")
	var r := WorldGen.route(a, "kessuwat", "ugarit_lo")
	assert_true(r.size() > 0, "harbour reachable")
	assert_eq(r.back(), "ugarit_lo")


func test_landmarks_and_drowned_town_are_fixed() -> void:
	var w := WorldGen.generate(9)
	assert_eq(w["nodes"]["kessuwat-tarhuna-1"]["kind"], "landmark")
	assert_eq(w["nodes"]["kessuwat-tarhuna-1"]["name"], "The Kings' Ford")
	assert_eq(w["nodes"]["ashkelu-ugarit_lo-1"]["kind"], "drowned_town")
	assert_eq(WorldGen.find_node(w, "landmark:The Salt Crossing"), "pallanta-ashkelu-1")
