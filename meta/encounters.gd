class_name Encounters
extends RefCounted
## Turns a node visit into a SimBattle. Families and counts come from the node,
## the chapter and the ambition; scars and grafts from the run's hero records.


static func build(run: Run, node: Dictionary, objective: Dictionary, families: Array, grafted: bool, road: bool = false) -> SimBattle:
	var b := SimBattle.new(10, 10, run.rng.range_int(1, 1 << 30))
	var coastal: bool = families.has("sea") or node.get("landmark", "") == "tide_road" or node["kind"] == "drowned_town"
	_terrain(b, coastal, run.rng)
	# Heroes deploy on the west edge.
	var y := 2
	for h in run.squad:
		if not h["alive"] or h.get("injury", {}).get("severity", "") == "severe" or h.get("left", false):
			continue
		var u := b.add_hero(h["kind"], Vector2i(1, y), h.get("gear", ""))
		u.name = h["name"]
		u.ink = int(h.get("ink", 0))
		u.clay = int(h.get("clay", 0))
		u.sorcery_tier = maxi(u.sorcery_tier, int(h.get("sorcery_tier", -1)))
		u.false_lines = int(h.get("false_lines", 0))
		u.misfires = run.sorcery_misfires_here(h)
		u.mismatched = bool(h.get("mismatched", false))
		if not h.get("memory", {}).is_empty():
			u.memory = h["memory"].duplicate()
			u.possessed = bool(h["memory"].get("possessed", false))
		u.hp = mini(u.max_hp, h["hp"])
		for sc in h.get("scars", []):
			u.apply_scar(sc)
		for g in h.get("grafts", []):
			u.apply_graft(g)
		h["unit_id"] = u.id
		y += 1
	if not run.wanderer_ally.is_empty():
		var w: Dictionary = run.wanderer_ally
		var ally := b.add_hero(w["kind"], Vector2i(0, y), w.get("gear", ""))
		ally.name = w["name"]
		for sc in w.get("scars", []):
			ally.apply_scar(sc)
		for g in w.get("grafts", []):
			ally.apply_graft(g)
	if objective["type"] == "protect":
		b.add_object("tablets", Vector2i(2, 4))
	var chapter: int = run.chapter
	var count: int = (1 if road else 2) + chapter + int(run.scaling.get("extra_enemies", 0))
	var x := 7
	var ey := 2
	for i in count:
		var fam: String = families[i % families.size()]
		var kind := _pick(fam, i, chapter, grafted, run.rng)
		while b.unit_at(Vector2i(x, ey)) != null or not b.grid.passable(Vector2i(x, ey)):
			ey += 1
		var e := b.add_enemy(kind, Vector2i(x, ey))
		e.max_hp += int(run.scaling.get("extra_hp", 0))
		e.hp = e.max_hp
		ey += 2
		if ey > 8:
			ey = 1
			x += 1
	if objective["type"] == "survive" or objective["type"] == "protect":
		var wave_kind := "jointed" if families.has("sea") else "outlaw_spear"
		b.waves = [{"round": 3, "units": [{"kind": wave_kind, "pos": [8, 8]}, {"kind": wave_kind, "pos": [9, 6]}]}]
	b.objective = objective.duplicate()
	return b


static func _pick(family: String, i: int, chapter: int, grafted: bool, rng: SimRng) -> String:
	match family:
		"sea":
			if grafted and i == 0:
				return "jointed_bronzed"
			if chapter >= 3 and i == 1:
				return "tidecaller"
			return "drowned" if i % 3 == 2 else "jointed"
		_:
			if chapter >= 2 and i == 0:
				return "officer"
			return "outlaw_slinger" if i % 3 == 1 else "outlaw_spear"


static func _terrain(b: SimBattle, coastal: bool, rng: SimRng) -> void:
	if coastal:
		for x in 10:
			b.grid.set_tile(Vector2i(x, 9), SimGrid.Tile.WATER)
		for i in 3:
			b.grid.set_tile(Vector2i(rng.range_int(2, 8), 8), SimGrid.Tile.TIDE)
	for i in 4:
		var p := Vector2i(rng.range_int(3, 7), rng.range_int(1, 7))
		b.grid.set_tile(p, SimGrid.Tile.WALL)
	for i in 3:
		var p := Vector2i(rng.range_int(2, 8), rng.range_int(1, 7))
		if b.grid.get_tile(p) == SimGrid.Tile.FLOOR:
			b.grid.set_tile(p, SimGrid.Tile.RUBBLE)
