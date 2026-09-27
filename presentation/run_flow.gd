class_name RunFlow
extends Node
## Owns a Run and swaps between the map, battles and the result screen.
## Applies battle results to the run. This is the only place the two sims meet.

const SAVE_PATH := "user://run.json"

var run: Run
var palette: Dictionary
var font: Font
var theme_ui: Theme
var map: MapView
var battle_view: BattleView
var pending_milestone: bool = false
var auto: bool = false


func start(r: Run, auto_: bool = false) -> void:
	run = r
	auto = auto_
	palette = _load_palette()
	font = load("res://fonts/Silkscreen-Regular.ttf")
	theme_ui = Theme.new()
	theme_ui.default_font = font
	theme_ui.default_font_size = 8
	var bs := StyleBoxFlat.new()
	bs.bg_color = palette["surface_raised"]
	bs.border_color = palette["accent"]
	bs.set_border_width_all(1)
	bs.set_content_margin_all(3)
	theme_ui.set_stylebox("normal", "Button", bs)
	theme_ui.set_color("font_color", "Button", palette["ink"])
	DebugApi.register("run", func(): return run.to_dict() if run != null else {})
	_show_map()


func _load_palette() -> Dictionary:
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/palette.json"))
	var out: Dictionary = {}
	for key in raw:
		if key != "note":
			out[key] = Color.html(raw[key])
	return out


func _show_map() -> void:
	if battle_view != null:
		battle_view.queue_free()
		battle_view = null
	if run.state != "ongoing":
		_show_result()
		return
	map = MapView.new()
	add_child(map)
	map.setup(run, palette, font, theme_ui)
	map.travel_requested.connect(_on_travel)
	map.action_requested.connect(_on_action)
	if auto:
		call_deferred("_auto_step")


func _on_travel(id: String) -> void:
	if run.travel_to(id):
		if run.node()["kind"] == "battle" and not run.node().get("cleared", false):
			run._log("Spears on the road.")
		map.refresh()


func _on_action(action: String, payload: Dictionary) -> void:
	match action:
		"rest":
			run.rest()
		"testify":
			run.testify()
		"fit":
			run.fit_graft(run.squad[payload["hero"]], payload["graft"])
		"refuse":
			run.refuse_graft(run.squad[payload["hero"]])
		"choose":
			run.choose(payload["option"])
			if run.pending_fight != "":
				_start_battle(run.road_battle(), false)
				return
		"save":
			run.save(SAVE_PATH)
			run._log("Saved.")
		"road_battle":
			_start_battle(run.road_battle(), false)
			return
		"milestone":
			_start_battle(run.milestone_battle(), true)
			return
		"result":
			_show_result()
			return
	map.refresh()


func _start_battle(b: SimBattle, milestone: bool) -> void:
	pending_milestone = milestone
	map.queue_free()
	map = null
	battle_view = BattleView.new()
	battle_view.auto = auto
	battle_view.on_finished = _on_battle_finished
	add_child(battle_view)
	await battle_view.present(b)


func _on_battle_finished(b: SimBattle) -> void:
	var report := run.apply_battle(b, pending_milestone)
	await get_tree().create_timer(1.2 if auto else 2.5).timeout
	_show_map()


var result_shown: bool = false


func _show_result() -> void:
	if result_shown:
		return
	result_shown = true
	if map != null:
		map.queue_free()
		map = null
	var layer := CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.theme = theme_ui
	panel.position = Vector2(40, 30)
	panel.size = Vector2(560, 300)
	var style := StyleBoxFlat.new()
	style.bg_color = palette["surface_raised"]
	style.border_color = palette["accent_2"]
	style.set_border_width_all(2)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var text := RichTextLabel.new()
	text.bbcode_enabled = true
	text.add_theme_color_override("default_color", palette["ink"])
	var body := "[b]%s[/b]\n\n" % ("The archive is out" if run.state == "won" else "The road has the archive")
	body += "Day %d. Chapter %d of %d.\n\n" % [run.day, mini(run.chapter, 3), run.ambition["chapters"].size()]
	var recorded := 0
	for d in run.deeds:
		body += "%s %s (%d)\n" % ["[color=#%s]testified[/color]" % palette["ok"].to_html(false) if d["recorded"] else "[color=#%s]unrecorded[/color]" % palette["ink_muted"].to_html(false), d["text"], d["significance"]]
	body += "\n" + run.chronicle_stub()
	text.text = body
	panel.add_child(text)


## Auto mode: a policy walks the run for recordings and smoke tests.
func _auto_step() -> void:
	if run.state != "ongoing":
		_show_result()
		return
	await get_tree().create_timer(0.6).timeout
	if map == null:
		return
	var ch: Dictionary = run.ambition["chapters"][run.chapter - 1]
	var target := WorldGen.find_node(run.world, ch["node"])
	var n := run.node()
	for h in run.squad:
		if h["alive"] and h["injury"].get("severity", "") == "severe" and n["flags"].get("smiths", false):
			var offers := run.graft_offers(h)
			if offers.is_empty():
				run.refuse_graft(h)
			else:
				run.fit_graft(h, offers[0])
			map.refresh()
			call_deferred("_auto_step")
			return
	if not run.pending_event.is_empty():
		run.choose(0)
		map.refresh()
	if run.pending_fight != "":
		_start_battle(run.road_battle(), false)
		return
	if run.milestone_reached:
		_start_battle(run.milestone_battle(), true)
		return
	if n["kind"] == "rest" or n["kind"] == "city":
		run.rest()
		run.testify()
	var path := WorldGen.route(run.world, run.at, target)
	if path.is_empty():
		return
	run.travel_to(path[0])
	map.refresh()
	call_deferred("_auto_step")
