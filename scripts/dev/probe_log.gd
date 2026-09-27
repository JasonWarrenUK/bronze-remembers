extends SceneTree
## Plays a run with the policy and prints its log, so the narration is grounded.

func _init() -> void:
	var r := Run.new(1)
	r.add_hero("spear", "Arnuwanda", "greaves")
	r.add_hero("sling", "Tudhal", "bracers")
	r.add_hero("shield", "Muwatti", "corselet")
	var guard := 0
	while r.state == "ongoing" and guard < 60:
		guard += 1
		var ch: Dictionary = r.ambition["chapters"][r.chapter - 1]
		var target := WorldGen.find_node(r.world, ch["node"])
		var n := r.node()
		var fitted := false
		for h in r.squad:
			if h["alive"] and h["injury"].get("severity", "") == "severe" and n["flags"].get("smiths", false):
				var offers := r.graft_offers(h)
				if offers.is_empty():
					r.refuse_graft(h)
				else:
					r.fit_graft(h, offers[0])
				fitted = true
		if fitted:
			continue
		if not r.pending_event.is_empty():
			print("  [event %s -> %s]" % [r.pending_event["name"], r.pending_event["options"][0]["label"]])
			r.choose(0)
		if r.pending_fight != "":
			var rb := r.road_battle()
			SimPolicy.run(rb)
			var rrep := r.apply_battle(rb, false)
			print("  [forced fight at %s (%s): %s in %d rounds, draws %s]" % [n["name"], r.pending_fight, rb.state, rb.round, str(rrep["draws"])])
			continue
		if r.milestone_reached:
			var b := r.milestone_battle()
			SimPolicy.run(b)
			var rep := r.apply_battle(b, true)
			print("  [milestone %s: %s in %d rounds, draws %s]" % [ch["title"], b.state, b.round, str(rep["draws"])])
			continue
		if (n["kind"] == "rest" or n["kind"] == "city") and r.fighters().size() > 0 and r.fighters()[0]["hp"] < r.fighters()[0]["max_hp"]:
			r.rest()
			r.testify()
		var path := WorldGen.route(r.world, r.at, target)
		if path.is_empty():
			break
		r.travel_to(path[0])
	for e in r.log:
		print("day %d: %s" % [e["day"], e["text"]])
	print("STATE %s day %d deeds %d" % [r.state, r.day, r.deeds.size()])
	for d in r.deeds:
		print("  deed: %s (%d) %s" % [d["text"], d["significance"], "recorded" if d["recorded"] else "unrecorded"])
	quit()
