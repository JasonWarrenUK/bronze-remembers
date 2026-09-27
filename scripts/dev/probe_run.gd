extends SceneTree
## Headless probe: plays chapter 1 for a seed and prints what happened at each battle.


func _init() -> void:
	var seed := 2
	var r := Run.new(seed)
	r.add_hero("spear", "Arnuwanda", "greaves")
	r.add_hero("sling", "Tudhal", "bracers")
	r.add_hero("shield", "Muwatti", "corselet")
	for id in ["kessuwat-tarhuna-1", "kessuwat-tarhuna-2", "tarhuna"]:
		r.travel_to(id)
		var n := r.node()
		print("day %d at %s (%s)" % [r.day, n["name"], n["kind"]])
		var b: SimBattle = null
		var milestone := false
		if n["kind"] == "battle":
			b = r.road_battle()
		elif r.milestone_reached:
			b = r.milestone_battle()
			milestone = true
		if b != null:
			var hp := []
			for h in b.heroes():
				hp.append("%s %d/%d" % [h.name, h.hp, h.max_hp])
			var en := []
			for e in b.enemies():
				en.append("%s@%s" % [e.kind, str(e.pos)])
			print("  battle: heroes %s vs %s" % [str(hp), str(en)])
			SimPolicy.run(b)
			var hp2 := []
			for h in b.heroes(false):
				hp2.append("%s %d%s" % [h.name, h.hp, " DOWN" if h.downed else ""])
			var en2 := []
			for e in b.enemies(false):
				en2.append("%s %d%s" % [e.kind, e.hp, " down" if e.downed else ""])
			print("  -> %s after %d rounds; heroes %s; enemies %s" % [b.state, b.round, str(hp2), str(en2)])
			var rep := r.apply_battle(b, milestone)
			print("  draws %s state %s" % [str(rep["draws"]), r.state])
		if r.state != "ongoing":
			break
	quit()
