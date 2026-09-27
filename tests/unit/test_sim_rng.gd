extends GutTest


func test_same_seed_same_sequence() -> void:
	var a := SimRng.new(42)
	var b := SimRng.new(42)
	for i in 20:
		assert_eq(a.range_int(0, 1000), b.range_int(0, 1000), "draw %d diverged" % i)


func test_weighted_draw_respects_zero_weight() -> void:
	var rng := SimRng.new(7)
	for i in 200:
		assert_eq(rng.weighted({"scar": 1.0, "dead": 0.0}), "scar")


func test_debug_args_parse() -> void:
	var parsed := DebugApi.parse_user_args(PackedStringArray(["--scene=battle_smoke", "--debug-dump", "--shot=out.png"]))
	assert_eq(parsed["scene"], "battle_smoke")
	assert_true(parsed["debug-dump"])
	assert_eq(parsed["shot"], "out.png")
