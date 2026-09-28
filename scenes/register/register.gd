extends Node
## The Register screen. Loads user://register.json (or starts one), lets the
## player pick a squad within budget, then starts a run that ends back here.


func _ready() -> void:
	var reg := Register.load_from()
	var palette := _palette()
	var theme_ui := Theme.new()
	theme_ui.default_font = load("res://fonts/Silkscreen-Regular.ttf")
	theme_ui.default_font_size = 8
	var bs := StyleBoxFlat.new()
	bs.bg_color = palette["surface"]
	bs.border_color = palette["accent"]
	bs.set_border_width_all(1)
	bs.set_content_margin_all(3)
	theme_ui.set_stylebox("normal", "Button", bs)
	theme_ui.set_color("font_color", "Button", palette["ink"])
	var view := RegisterView.new()
	add_child(view)
	view.setup(reg, palette, theme_ui)
	view.run_requested.connect(_start_run.bind(reg))
	view.ambition_chosen.connect(func(key): chosen_ambition = key)
	if DebugApi.user_args.has("auto"):
		# Auto picks the highest-tier playable heroes the budget allows, so recordings show the Register at work.
		var picks: Array = []
		var spent := 0
		var pool := reg.playable()
		pool.sort_custom(func(a, b): return a["tier"] > b["tier"])
		for h in pool:
			if picks.size() < 3 and spent + Register.tier_cost(h["tier"]) <= reg.budget():
				picks.append(h)
				spent += Register.tier_cost(h["tier"])
		call_deferred("_start_run", picks, spent, reg)


func _palette() -> Dictionary:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/palette.json"))
	var out: Dictionary = {}
	for key in raw:
		if key != "note":
			out[key] = Color.html(raw[key])
	return out


var chosen_ambition: String = "archive"


func _start_run(picks: Array, spent: int, reg: Register) -> void:
	var seed: int = int(DebugApi.user_args.get("seed", 100 + reg.generation))
	var run := Run.new(seed, chosen_ambition if reg.ambitions_available().has(chosen_ambition) else "archive", reg.founded_cities)
	run.narrator = reg.narrator()
	var kinds := ["spear", "sling", "shield"]
	var gear := ["greaves", "bracers", "corselet"]
	var roster: Array = []
	var chosen := picks.duplicate()
	while chosen.size() < 3:
		var i := chosen.size()
		chosen.append(reg.new_hero(kinds[i], _levy_name(reg), "kessuwat", gear[i]))
	for h in chosen:
		var rec := run.add_hero(h["kind"], h["name"], h["gear"])
		rec["scars"] = h["scars"].duplicate()
		rec["grafts"] = h["grafts"].duplicate()
		rec["memory"] = h.get("memory", {}).duplicate()
		if not rec["memory"].is_empty():
			rec["memory"]["charges"] = int(rec["memory"].get("base_charges", 1))
			rec["memory"]["used"] = 0
		rec["sorcery_tier"] = int(h.get("sorcery_tier", -1))
		rec["false_lines"] = int(h.get("false_lines", 0))
		rec["origin"] = h.get("origin", "kessuwat")
		roster.append(h["id"])
	run.emeriti = reg.emeriti_for_run()
	if run.ambition.get("named", false) and run.squad.size() > 0:
		run.named_hero = run.squad[0]["name"]
	run.scaling = Register.scaling(spent)
	run.apply_world(reg.world)
	run.wanderers = reg.wanderers.duplicate(true)
	run.elder_cities = reg.gates_open_cities()
	run.testimony_bonus = reg.testimony_bonus()
	reg.save()
	var flow_scene := preload("res://scenes/run/run.tscn").instantiate()
	flow_scene.set_meta("run", run)
	flow_scene.set_meta("register", reg)
	flow_scene.set_meta("roster", roster)
	flow_scene.set_meta("spent", spent)
	get_tree().root.add_child(flow_scene)
	get_tree().current_scene.queue_free()
	get_tree().current_scene = flow_scene


func _levy_name(reg: Register) -> String:
	var stems := ["Hattu", "Zida", "Kantu", "Piyama", "Tarhu", "Ammu", "Halpa", "Kurunta", "Mursi", "Alalu"]
	return stems[(reg.next_id * 7) % stems.size()] + str(reg.next_id)
