extends GutTest


func test_chronicle_has_gaps_and_voice() -> void:
	var r := Run.new(2)
	r.add_hero("spear", "Arnuwanda", "greaves")
	r.apply_world(WorldState.new())
	r.deeds.append({"text": "Held the ford", "significance": 2, "day": 3, "node": "kessuwat-tarhuna-1", "recorded": true, "tags": []})
	r.deeds.append({"text": "Unseen deed", "significance": 1, "day": 4, "node": "tarhuna", "recorded": false, "tags": []})
	r.narrator = "Zida the Elder"
	r.state = "lost"
	r.day = 9
	var text := r.chronicle_stub()
	assert_true(text.contains("Zida the Elder"), "the narrator is named")
	assert_true(text.contains(Chronicle.GAP), "an unrecorded deed leaves a gap")
	assert_true(text.contains("Held the ford") or text.contains("held the ford"))
	assert_true(text.contains("9th day"))
	assert_false(text.contains("Unseen deed"), "unrecorded deeds are not written")
