class_name BattleView
extends Node2D
## The field: renders a SimBattle, takes input on hero turns, replays sim events
## with tweens and juice. Rules live in the sim; this node only asks and shows.

const CELL := 32
const TILE_TEX := {
	SimGrid.Tile.FLOOR: "res://art/tiles/floor.png", SimGrid.Tile.WALL: "res://art/tiles/wall.png",
	SimGrid.Tile.WATER: "res://art/tiles/water.png", SimGrid.Tile.TIDE: "res://art/tiles/tide.png",
	SimGrid.Tile.RUBBLE: "res://art/tiles/rubble.png",
}
const STEP_TIME := 0.11
const HIT_STOP := 0.11

var battle: SimBattle
var palette: Dictionary = {}
var views: Dictionary = {}          # unit id -> UnitView
var tiles: Node2D
var overlay: Node2D                 # highlights
var units_layer: Node2D
var fx_layer: Node2D
var camera: Camera2D
var ui: CanvasLayer
var events_played: int = 0
var playing: bool = false
var mode: String = "idle"           # idle | move | target | delay
var pending_ability: String = ""
var selected_cells: Dictionary = {}
var audio: Dictionary = {}
var sfx_player: AudioStreamPlayer
var shake_amount: float = 0.0
var shake_dir: Vector2 = Vector2.ZERO
var edge: ColorRect
var log_lines: Array[String] = []
var auto: bool = false
var on_finished: Callable = Callable()

# UI nodes
var queue_label: RichTextLabel
var cards_label: RichTextLabel
var status_label: Label
var ability_bar: HBoxContainer
var log_label: RichTextLabel
var end_button: Button
var delay_button: Button
var result_panel: PanelContainer
var result_label: RichTextLabel


func _ready() -> void:
	palette = _load_palette()
	_load_audio()
	tiles = Node2D.new()
	add_child(tiles)
	overlay = Node2D.new()
	add_child(overlay)
	units_layer = Node2D.new()
	units_layer.y_sort_enabled = true
	add_child(units_layer)
	fx_layer = Node2D.new()
	add_child(fx_layer)
	camera = Camera2D.new()
	camera.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	camera.position = Vector2(-8, -8)
	add_child(camera)
	camera.make_current()
	sfx_player = AudioStreamPlayer.new()
	add_child(sfx_player)
	_build_ui()
	DebugApi.register("battle", func(): return battle.snapshot() if battle != null else {})


func _load_palette() -> Dictionary:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/palette.json"))
	var out: Dictionary = {}
	for key in raw:
		if key == "note":
			continue
		out[key] = Color.html(raw[key])
	return out


func _load_audio() -> void:
	for name in ["hit_thud", "hit_bronze", "hit_wet", "whoosh", "step"]:
		audio[name] = load("res://audio/%s.wav" % name)


func sfx(name: String, pitch: float = 1.0) -> void:
	if not audio.has(name):
		return
	var p := AudioStreamPlayer.new()
	p.stream = audio[name]
	p.pitch_scale = pitch
	p.volume_db = -6.0
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()


# ---------------------------------------------------------------- setup

## Builds the field from a battle that has been set up but not started.
var weather_stages: Dictionary = {}


## Tints the world by the tracks: Sea pulls the field green and wet, Law dims the light.
func apply_weather(stages: Dictionary) -> void:
	weather_stages = stages
	var sea: float = float(stages.get("sea", 0)) / 4.0
	var law: float = float(stages.get("law", 0)) / 4.0
	var tint := Color.WHITE.lerp(palette["sea_accent"], sea * 0.45)
	tint = tint.darkened(law * 0.25)
	tiles.modulate = tint
	units_layer.modulate = Color.WHITE.lerp(palette["sea_accent"], sea * 0.2)


func present(b: SimBattle) -> void:
	battle = b
	for y in b.grid.height:
		for x in b.grid.width:
			_place_tile(Vector2i(x, y))
	for u in b.units:
		_add_unit(u)
	battle.start_round()
	await _playback()


func _place_tile(p: Vector2i) -> void:
	var s := Sprite2D.new()
	s.texture = load(TILE_TEX[battle.grid.get_tile(p)])
	s.centered = false
	s.scale = Vector2(2, 2)
	s.position = Vector2(p.x * CELL, p.y * CELL)
	s.name = "tile_%d_%d" % [p.x, p.y]
	tiles.add_child(s)


func _refresh_tile(p: Vector2i) -> void:
	var s: Sprite2D = tiles.get_node("tile_%d_%d" % [p.x, p.y])
	s.texture = load(TILE_TEX[battle.grid.get_tile(p)])


func _add_unit(u: SimUnit) -> void:
	var v := UnitView.new()
	v.setup(u, palette)
	units_layer.add_child(v)
	views[u.id] = v


# ---------------------------------------------------------------- UI

var font: Font
var theme_ui: Theme


func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	font = load("res://fonts/Silkscreen-Regular.ttf")
	theme_ui = Theme.new()
	theme_ui.default_font = font
	theme_ui.default_font_size = 8
	var button_style := StyleBoxFlat.new()
	button_style.bg_color = palette["surface_raised"]
	button_style.border_color = palette["accent"]
	button_style.set_border_width_all(1)
	button_style.set_content_margin_all(3)
	theme_ui.set_stylebox("normal", "Button", button_style)
	var hover := button_style.duplicate()
	hover.bg_color = palette["line"]
	theme_ui.set_stylebox("hover", "Button", hover)
	var disabled := button_style.duplicate()
	disabled.border_color = palette["line"]
	theme_ui.set_stylebox("disabled", "Button", disabled)
	theme_ui.set_color("font_color", "Button", palette["ink"])
	theme_ui.set_color("font_disabled_color", "Button", palette["ink_muted"])
	var panel := PanelContainer.new()
	panel.theme = theme_ui
	panel.position = Vector2(336, 0)
	panel.size = Vector2(304, 360)
	var style := StyleBoxFlat.new()
	style.bg_color = palette["surface_raised"]
	style.border_color = palette["accent_2"]
	style.set_border_width_all(2)
	style.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", style)
	ui.add_child(panel)
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	panel.add_child(col)
	status_label = _label(col, "Round 0")
	queue_label = _rich(col, 84)
	cards_label = _rich(col, 96)
	ability_bar = HBoxContainer.new()
	col.add_child(ability_bar)
	var row := HBoxContainer.new()
	col.add_child(row)
	delay_button = Button.new()
	delay_button.text = "Delay"
	delay_button.pressed.connect(_on_delay_pressed)
	row.add_child(delay_button)
	end_button = Button.new()
	end_button.text = "End turn"
	end_button.pressed.connect(_on_end_turn)
	row.add_child(end_button)
	log_label = _rich(col, 96)
	result_panel = PanelContainer.new()
	result_panel.theme = theme_ui
	result_panel.position = Vector2(60, 100)
	result_panel.size = Vector2(240, 140)
	result_panel.add_theme_stylebox_override("panel", style)
	result_panel.visible = false
	ui.add_child(result_panel)
	result_label = RichTextLabel.new()
	result_label.bbcode_enabled = true
	result_label.fit_content = true
	result_panel.add_child(result_label)


func _label(parent: Node, text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_color_override("font_color", palette["ink"])
	parent.add_child(l)
	return l


func _rich(parent: Node, min_h: float) -> RichTextLabel:
	var r := RichTextLabel.new()
	r.bbcode_enabled = true
	r.scroll_active = false
	r.custom_minimum_size = Vector2(296, min_h)
	r.add_theme_color_override("default_color", palette["ink"])
	parent.add_child(r)
	return r


func _refresh_ui() -> void:
	status_label.text = "Round %d   %s" % [battle.round, battle.state]
	var q := ""
	for i in range(battle.queue.size()):
		var u := battle.unit_by_id(battle.queue[i]["id"])
		if u == null or u.downed:
			continue
		var marker := "> " if i == battle.queue_index else "  "
		var colour: String = palette["accent"].to_html(false) if u.side == "hero" else palette["ink_muted"].to_html(false)
		q += "[color=#%s]%s%s (%d)[/color]\n" % [colour, marker, u.name, battle.queue[i]["init"]]
	queue_label.text = q
	var c := "[color=#%s]Enemy cards[/color]\n" % palette["ink_muted"].to_html(false)
	for kind in battle.cards:
		var card: Dictionary = battle.cards[kind]
		var mods := ""
		if card.has("move"):
			mods += " move%+d" % card["move"]
		if card.has("attack"):
			mods += " atk%+d" % card["attack"]
		if card.get("no_move", false):
			mods += " no move"
		if card.get("no_attack", false):
			mods += " no attack"
		if card.has("special"):
			mods += " " + str(card["special"])
		c += "%s: [b]%s[/b] (%d)%s\n" % [SimData.units()["enemies"][kind]["name"], card["name"], card["init"], mods]
	cards_label.text = c
	for child in ability_bar.get_children():
		child.queue_free()
	var cur := battle.current()
	if cur != null and cur.side == "hero" and battle.state == "ongoing":
		for key in cur.usable_abilities():
			var b := Button.new()
			var a := SimData.ability(key)
			b.text = a["name"]
			b.disabled = battle.turn.get("acted", false) and a.get("effect", "") != "stride"
			b.pressed.connect(_on_ability_pressed.bind(key))
			ability_bar.add_child(b)
	var lg := ""
	for line in log_lines.slice(maxi(0, log_lines.size() - 5)):
		lg += line + "\n"
	log_label.text = lg


func _log(line: String) -> void:
	log_lines.append(line)


# ---------------------------------------------------------------- input

func _unhandled_input(event: InputEvent) -> void:
	if playing or battle == null or battle.state != "ongoing":
		return
	var cur := battle.current()
	if cur == null or cur.side != "hero":
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var cell := _cell_at(get_global_mouse_position())
		if not battle.grid.in_bounds(cell):
			return
		match mode:
			"target":
				if battle.hero_act(cur, pending_ability, cell):
					_log("%s: %s" % [cur.name, SimData.ability(pending_ability)["name"]])
					mode = "idle"
					pending_ability = ""
					await _playback()
				else:
					mode = "idle"
					_clear_overlay()
					_show_move_range(cur)
			"delay":
				var target := battle.unit_at(cell)
				if target != null and battle.hero_delay(cur, target):
					_log("%s delays after %s" % [cur.name, target.name])
					mode = "idle"
					await _playback()
				else:
					mode = "idle"
			_:
				if battle.hero_move(cur, cell):
					await _playback()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE:
			_on_end_turn()
		elif event.keycode == KEY_ESCAPE:
			mode = "idle"
			pending_ability = ""
			_clear_overlay()
			_show_move_range(cur)
		elif event.keycode >= KEY_1 and event.keycode <= KEY_5:
			var idx: int = event.keycode - KEY_1
			var keys := cur.usable_abilities()
			if idx < keys.size():
				_on_ability_pressed(keys[idx])


func _cell_at(world: Vector2) -> Vector2i:
	return Vector2i(floori(world.x / CELL), floori(world.y / CELL))


func _on_ability_pressed(key: String) -> void:
	if playing:
		return
	var cur := battle.current()
	if cur == null or cur.side != "hero":
		return
	var a := SimData.ability(key)
	var effect: String = a.get("effect", "")
	if effect in ["brace", "wall", "taunt", "stride", "stand", "parry", "arc"]:
		if battle.hero_act(cur, key, cur.pos):
			_log("%s: %s" % [cur.name, a["name"]])
			await _playback()
		return
	mode = "target"
	pending_ability = key
	_clear_overlay()
	_show_targets(cur, a)


func _on_delay_pressed() -> void:
	if playing:
		return
	mode = "delay"
	_clear_overlay()
	_log("Pick a unit to act after")


func _on_end_turn() -> void:
	if playing or battle == null or battle.state != "ongoing":
		return
	var cur := battle.current()
	if cur == null or cur.side != "hero":
		return
	mode = "idle"
	battle.end_turn()
	await _playback()


# ---------------------------------------------------------------- highlights

func _clear_overlay() -> void:
	for c in overlay.get_children():
		c.queue_free()


func _highlight(cell: Vector2i, colour: Color) -> void:
	var r := ColorRect.new()
	r.position = Vector2(cell.x * CELL + 2, cell.y * CELL + 2)
	r.size = Vector2(CELL - 4, CELL - 4)
	r.color = Color(colour, 0.35)
	overlay.add_child(r)


func _show_move_range(u: SimUnit) -> void:
	if battle.turn.get("moved", false):
		return
	for cell in battle.movable_tiles(u):
		if cell != u.pos:
			_highlight(cell, palette["move_highlight"])


func _show_targets(u: SimUnit, a: Dictionary) -> void:
	if not a.has("range"):
		return
	for e in battle.enemies():
		var d := SimGrid.distance(u.pos, e.pos)
		if d >= a["range"][0] and d <= a["range"][1] and (not a.get("line", false) or battle.grid.in_line(u.pos, e.pos)):
			_highlight(e.pos, palette["attack_highlight"])


# ---------------------------------------------------------------- playback

## Plays every sim event not yet shown, in order, then refreshes the UI.
func _playback() -> void:
	playing = true
	_clear_overlay()
	while events_played < battle.events.size():
		var ev: Dictionary = battle.events[events_played]
		events_played += 1
		await _play_event(ev)
	playing = false
	_refresh_ui()
	var cur := battle.current()
	for id in views:
		views[id].set_active(cur != null and cur.id == id)
	if battle.state != "ongoing":
		_show_result()
		if on_finished.is_valid():
			on_finished.call(battle)
	elif cur != null and cur.side == "hero":
		_show_move_range(cur)
		if auto:
			await get_tree().create_timer(0.35).timeout
			_auto_turn(cur)


## Auto mode plays the shared policy, one hero action at a time so the playback shows it.
func _auto_turn(h: SimUnit) -> void:
	var before := battle.events.size()
	SimPolicy.take_turn(battle, h)
	if battle.events.size() > before or battle.current() != h:
		await _playback()


func _play_event(ev: Dictionary) -> void:
	match ev["type"]:
		"move":
			var v: UnitView = views[ev["unit"]]
			await v.play_move(ev["path"], STEP_TIME, sfx)
		"forced_move":
			var v: UnitView = views[ev["unit"]]
			sfx("whoosh", 0.8)
			await v.play_forced_move(ev["to"], 0.12)
		"ability", "enemy_card":
			pass
		"hit":
			await _play_hit(ev)
		"downed":
			var v: UnitView = views[ev["unit"]]
			var u := battle.unit_by_id(ev["unit"])
			_log("%s is down" % u.name)
			await v.play_downed()
		"condition":
			var u := battle.unit_by_id(ev["unit"])
			_log("%s: %s" % [u.name, ev["condition"]])
		"spawn":
			var u := battle.unit_by_id(ev["unit"])
			_add_unit(u)
			_log("%s rises" % u.name)
			sfx("hit_wet", 0.6)
			await get_tree().create_timer(0.2).timeout
		"tide":
			_refresh_tile(Vector2i(ev["pos"][0], ev["pos"][1]))
			sfx("hit_wet", 0.5)
		"round_start":
			_log("Round %d" % ev["round"])
			_refresh_ui()
			await get_tree().create_timer(0.25).timeout
		"turn_start":
			var u := battle.unit_by_id(ev["unit"])
			for id in views:
				views[id].set_active(id == ev["unit"])
			_refresh_ui()
			if u.side == "enemy":
				await get_tree().create_timer(0.2).timeout
		"overwatch":
			_log("Brace!")
		"battle_end":
			pass
		_:
			pass


func _play_hit(ev: Dictionary) -> void:
	var target := battle.unit_by_id(ev["unit"])
	var tv: UnitView = views[ev["unit"]]
	var source := battle.unit_by_id(ev["by"]) if ev["by"] != -1 else null
	var dir := Vector2i(0, 1)
	if source != null:
		dir = (target.pos - source.pos).sign()
		if dir == Vector2i.ZERO:
			dir = Vector2i(0, 1)
		var sv: UnitView = views[source.id]
		await sv.play_attack(dir, 0.22)
	# Hit-stop: the world pauses for a few frames on contact.
	var damage: int = ev["damage"]
	if DebugApi.user_args.has("trace"):
		print("TRACE hit frame=%d target=%s damage=%d" % [Engine.get_process_frames(), target.name, damage])
	var wet: bool = target.family == "sea" or (source != null and source.family == "sea")
	sfx("hit_wet" if wet else ("hit_bronze" if damage >= 3 else "hit_thud"), randf_range(0.95, 1.05))
	_spawn_particles(tv.position, dir, damage, palette["sea_ink"] if wet else palette["surface"])
	_show_damage_number(tv.position, damage)
	shake_dir = Vector2(dir.x, dir.y)
	shake_amount = 3.0 + damage * 2.0
	Engine.time_scale = 0.02
	await get_tree().create_timer(HIT_STOP * 0.02, true, false, true).timeout
	Engine.time_scale = 1.0
	if target.side == "hero":
		_edge_flash(palette["danger"])
	if source != null:
		var sv2: UnitView = views[source.id]
		sv2.recover(0.16)
	await tv.play_hit(dir, damage, ev["hp"], palette["flash_sea"] if wet else palette["flash_hit"], palette["surface"])


func _spawn_particles(at: Vector2, dir: Vector2i, damage: int, colour: Color) -> void:
	var p := CPUParticles2D.new()
	p.position = at + Vector2(0, -4)
	p.amount = 8 + damage * 5
	p.lifetime = 0.4
	p.one_shot = true
	p.explosiveness = 1.0
	p.direction = Vector2(dir.x, dir.y)
	p.spread = 40.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 90.0
	p.gravity = Vector2(0, 220)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 3.5
	p.color = colour
	p.emitting = true
	fx_layer.add_child(p)
	get_tree().create_timer(0.6).timeout.connect(p.queue_free)


func _show_damage_number(at: Vector2, damage: int) -> void:
	var l := Label.new()
	l.theme = theme_ui
	l.add_theme_font_size_override("font_size", 16)
	l.text = str(damage)
	l.position = at + Vector2(-6, -30)
	l.add_theme_color_override("font_color", palette["ink"])
	l.add_theme_color_override("font_outline_color", palette["surface"])
	l.add_theme_constant_override("outline_size", 3)
	fx_layer.add_child(l)
	var tw := create_tween()
	tw.tween_property(l, "position", l.position + Vector2(0, -14), 0.45).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(l, "modulate:a", 0.0, 0.45).set_delay(0.15)
	tw.tween_callback(l.queue_free)


func _process(delta: float) -> void:
	if shake_amount > 0.0:
		var along := shake_dir * randf_range(-shake_amount, shake_amount)
		var across := Vector2(-shake_dir.y, shake_dir.x) * randf_range(-shake_amount * 0.4, shake_amount * 0.4)
		camera.offset = along + across
		shake_amount = maxf(0.0, shake_amount - delta * 40.0)
	else:
		camera.offset = Vector2.ZERO


func _edge_flash(colour: Color) -> void:
	if edge == null:
		edge = ColorRect.new()
		edge.size = Vector2(336, 360)
		edge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ui.add_child(edge)
	edge.color = Color(colour, 0.35)
	var tw := create_tween()
	tw.tween_property(edge, "color:a", 0.0, 0.25)


func _show_result() -> void:
	var results := battle.resolve_downings()
	var text := "[b]%s[/b] after %d rounds\n" % ["Held the road" if battle.state == "won" else "The road took them", battle.round]
	for r in results:
		var u := battle.unit_by_id(r["unit"])
		text += "%s: %s (by %s)\n" % [u.name, r["outcome"], r["by"]]
	result_label.text = text
	result_panel.visible = true
