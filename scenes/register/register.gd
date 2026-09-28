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
	if DebugApi.user_args.has("auto"):
		call_deferred("_start_run", [], 0, reg)


func _palette() -> Dictionary:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/palette.json"))
	var out: Dictionary = {}
	for key in raw:
		if key != "note":
			out[key] = Color.html(raw[key])
	return out


func _start_run(picks: Array, spent: int, reg: Register) -> void:
	var seed: int = int(DebugApi.user_args.get("seed", 100 + reg.generation))
	var run := Run.new(seed)
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
		roster.append(h["id"])
	run.scaling = Register.scaling(spent)
	run.wanderers = reg.wanderers.duplicate(true)
	for s in reg.seats:
		if s["holder"] != -1:
			run.elder_cities[s["city"]] = true
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
