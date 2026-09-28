class_name MapView
extends Node2D
## The region map: nodes, roads, the squad marker, fog. Emits travel and node
## action requests; RunFlow decides what they mean.

signal travel_requested(node_id: String)
signal action_requested(action: String, payload: Dictionary)

const SCALE := 30          # world grid units to pixels
const ORIGIN := Vector2(20, 30)

var run: Run
var palette: Dictionary
var font: Font
var theme_ui: Theme
var nodes_layer: Node2D
var roads_layer: Node2D
var marker: Polygon2D
var ui: CanvasLayer
var info: RichTextLabel
var squad_label: RichTextLabel
var actions: VBoxContainer
var log_label: RichTextLabel


func setup(r: Run, pal: Dictionary, fnt: Font, thm: Theme) -> void:
	run = r
	palette = pal
	font = fnt
	theme_ui = thm
	var bands := Node2D.new()
	add_child(bands)
	for band in [["upland", 6, 8, palette["line"]], ["coast", 8, 12, palette["sea_accent"]]]:
		var band_rect := ColorRect.new()
		band_rect.position = ORIGIN + Vector2(-20, band[1] * SCALE - 15)
		band_rect.size = Vector2(400, (band[2] - band[1]) * SCALE + 30)
		band_rect.color = Color(band[3], 0.12)
		bands.add_child(band_rect)
	roads_layer = Node2D.new()
	add_child(roads_layer)
	nodes_layer = Node2D.new()
	add_child(nodes_layer)
	var sea: float = float(run.stages.get("sea", 0)) / 4.0
	var law: float = float(run.stages.get("law", 0)) / 4.0
	modulate = Color.WHITE.lerp(palette["sea_accent"], sea * 0.3).darkened(law * 0.2)
	marker = Polygon2D.new()
	marker.polygon = PackedVector2Array([Vector2(0, -12), Vector2(6, -2), Vector2(-6, -2)])
	marker.color = palette["accent"]
	add_child(marker)
	_build_ui()
	refresh()


func node_pos(id: String) -> Vector2:
	var p: Array = run.world["nodes"][id]["pos"]
	return ORIGIN + Vector2(p[0] * SCALE, p[1] * SCALE)


func refresh() -> void:
	for c in roads_layer.get_children():
		c.queue_free()
	for c in nodes_layer.get_children():
		c.queue_free()
	var seen := run.visited
	var adjacent := {}
	for id in run.revealed:
		adjacent[id] = true
	for n in run.options():
		adjacent[n["id"]] = true
	for e in run.world["edges"]:
		if not (seen.has(e["a"]) or seen.has(e["b"])):
			continue
		var line := Line2D.new()
		line.points = PackedVector2Array([node_pos(e["a"]), node_pos(e["b"])])
		line.width = 2.0
		line.default_color = palette["line"] if (seen.has(e["a"]) and seen.has(e["b"])) else Color(palette["line"], 0.4)
		roads_layer.add_child(line)
	for id in run.world["nodes"]:
		var n: Dictionary = run.world["nodes"][id]
		var known: bool = seen.has(id) or adjacent.has(id)
		if not known:
			continue
		var dot := Polygon2D.new()
		var r := 7.0 if n["kind"] == "city" else 4.5
		var pts := PackedVector2Array()
		var sides := 4 if n["kind"] == "city" else 6
		for i in sides:
			var a := TAU * i / sides + (PI / 4 if sides == 4 else 0.0)
			pts.append(Vector2(cos(a), sin(a)) * r)
		dot.polygon = pts
		dot.position = node_pos(id)
		dot.color = _node_colour(n, seen.has(id))
		nodes_layer.add_child(dot)
		if n["kind"] == "city" and n["flags"].get("walled", false):
			var wall := Line2D.new()
			wall.points = PackedVector2Array([Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10), Vector2(-10, -10)])
			wall.width = 1.5
			wall.default_color = Color(palette["ink_muted"], 0.8 if seen.has(id) else 0.4)
			wall.position = node_pos(id)
			nodes_layer.add_child(wall)
		if n["kind"] == "city" and n["flags"].get("harbour", false):
			var anchor := Line2D.new()
			anchor.points = PackedVector2Array([Vector2(-6, 14), Vector2(6, 14)])
			anchor.width = 2.0
			anchor.default_color = palette["sea_accent"]
			anchor.position = node_pos(id)
			nodes_layer.add_child(anchor)
		if n["kind"] == "city" or n["kind"] == "landmark" or n["kind"] == "drowned_town" or adjacent.has(id):
			var l := Label.new()
			l.theme = theme_ui
			l.text = n["name"] if seen.has(id) or n["kind"] == "city" else "?"
			l.position = node_pos(id) + Vector2(-20, 6)
			l.add_theme_color_override("font_color", palette["ink"] if seen.has(id) else palette["ink_muted"])
			nodes_layer.add_child(l)
	marker.position = node_pos(run.at)
	_refresh_ui()


func _node_colour(n: Dictionary, seen: bool) -> Color:
	var base: Color
	match n["kind"]:
		"city": base = palette["accent"]
		"drowned_town": base = palette["sea_accent"]
		"battle": base = palette["danger"]
		"rest": base = palette["ok"]
		"landmark": base = palette["accent_2"]
		"market": base = palette["warn"]
		_: base = palette["ink_muted"]
	return base if seen else Color(base, 0.5)


func _build_ui() -> void:
	ui = CanvasLayer.new()
	add_child(ui)
	var panel := PanelContainer.new()
	panel.theme = theme_ui
	panel.position = Vector2(400, 0)
	panel.size = Vector2(240, 360)
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
	info = RichTextLabel.new()
	info.bbcode_enabled = true
	info.custom_minimum_size = Vector2(228, 90)
	info.add_theme_color_override("default_color", palette["ink"])
	col.add_child(info)
	squad_label = RichTextLabel.new()
	squad_label.bbcode_enabled = true
	squad_label.custom_minimum_size = Vector2(228, 70)
	squad_label.add_theme_color_override("default_color", palette["ink"])
	col.add_child(squad_label)
	actions = VBoxContainer.new()
	col.add_child(actions)
	log_label = RichTextLabel.new()
	log_label.bbcode_enabled = true
	log_label.custom_minimum_size = Vector2(228, 70)
	log_label.add_theme_color_override("default_color", palette["ink_muted"])
	col.add_child(log_label)


func _refresh_ui() -> void:
	var n := run.node()
	var ch: Dictionary = run.ambition["chapters"][mini(run.chapter, run.ambition["chapters"].size()) - 1]
	var writ_line := "Outlaw: the gates are shut" if run.writ["outlaw"] else "Report owed by day %d" % int(run.writ["report_due"])
	var season_line := "Ship sails day %d%s" % [int(run.season["ship_sails"]), ", the Mile is flooded" if run.flooded else ""]
	if not run.weather.is_empty():
		season_line += "\n" + run.weather[0]
	info.text = "[b]Day %d of %d[/b]  chapter %d\n%s\n[color=#%s]%s\n%s\n%s[/color]\n%s" % [run.day, int(run.season["days"]), run.chapter, n["name"], palette["ink_muted"].to_html(false), n["kind"], writ_line, season_line, ch["title"]]
	var sq := ""
	for h in run.squad:
		var status := ""
		if not h["alive"]:
			status = " dead"
		elif h["left"]:
			status = " left"
		elif h["injury"].get("severity", "") == "severe":
			status = " HURT %s (%dd)" % [h["injury"]["location"], h["injury"].get("days_left", 0)]
		var ink_mark := (" ink:%d" % h["ink"]) if h["ink"] > 0 else ""
		sq += "%s %d/%d%s%s%s\n" % [h["name"], h["hp"], h["max_hp"], status, (" +" + str(h["grafts"].size()) + " bronze") if h["grafts"].size() > 0 else "", ink_mark]
	squad_label.text = sq
	for c in actions.get_children():
		c.queue_free()
	if run.state != "ongoing":
		_button("Read the tablets", func(): action_requested.emit("result", {}))
		return
	# Pending events and fights hold the squad: no travel until resolved.
	if not run.pending_event.is_empty():
		var ev: Dictionary = run.pending_event
		var t := RichTextLabel.new()
		t.bbcode_enabled = true
		t.fit_content = true
		t.custom_minimum_size = Vector2(228, 40)
		t.add_theme_color_override("default_color", palette["ink"])
		t.text = "[b]%s[/b]\n%s" % [ev["name"], run.garble(ev["text"])]
		actions.add_child(t)
		for i in range(ev["options"].size()):
			_button(ev["options"][i]["label"], func(): action_requested.emit("choose", {"option": i}))
		return
	if run.pending_fight != "":
		_button("Fight: %s hold the %s" % ["sea-things" if run.pending_fight == "sea" else "outlaws", n["kind"]], func(): action_requested.emit("road_battle", {}))
		return
	if run.milestone_reached:
		_button("Face the chapter: " + ch["title"], func(): action_requested.emit("milestone", {}))
	match n["kind"]:
		"rest":
			_button("Rest a day", func(): action_requested.emit("rest", {}))
		"city":
			_button("Rest a day", func(): action_requested.emit("rest", {}))
			if n["flags"].get("scribal", false):
				_button("Testify", func(): action_requested.emit("testify", {}))
				_button("Buy clay (a day)", func(): action_requested.emit("buy_clay", {}))
				for i in range(run.squad.size()):
					var hs: Dictionary = run.squad[i]
					if hs["alive"] and not hs["left"] and int(hs["sorcery_tier"]) < 2:
						_button("Apprentice %s (four days)" % hs["name"], func(): action_requested.emit("apprentice", {"hero": i}))
			if n["flags"].get("temple", false):
				_button("Temple healing (ink)", func(): action_requested.emit("temple_heal", {}))
				if run.tithe_demanded():
					_button("Pay the tithe", func(): action_requested.emit("pay_tithe", {}))
					_button("Refuse the tithe", func(): action_requested.emit("refuse_tithe", {}))
				for i in range(run.squad.size()):
					var hh: Dictionary = run.squad[i]
					if hh["alive"] and not hh["left"] and hh["ink"] > 0 and not hh.has("substitute"):
						for j in range(run.squad.size()):
							if j != i and run.squad[j]["alive"] and not run.squad[j]["left"]:
								_button("Rite: %s's death to %s" % [hh["name"], run.squad[j]["name"]], func(): action_requested.emit("substitute", {"hero": i, "stand_in": j}))
								break
			for i in range(run.squad.size()):
				var hc: Dictionary = run.squad[i]
				if hc["alive"] and not hc["left"] and hc["called"]:
					_button("%s answers the ink" % hc["name"], func(): action_requested.emit("answer_call", {"hero": i}))
					_button("%s ignores the call" % hc["name"], func(): action_requested.emit("ignore_call", {"hero": i}))
				if hc["alive"] and not hc["left"] and hc["ink"] > 0:
					_button("%s burns the ink" % hc["name"], func(): action_requested.emit("burn_ink", {"hero": i}))
			if n["flags"].get("smiths", false):
				for i in range(run.squad.size()):
					var h: Dictionary = run.squad[i]
					if h["alive"] and h["injury"].get("severity", "") == "severe":
						for g in run.graft_offers(h):
							_button("Fit %s: %s" % [h["name"], SimData.load_json("grafts")[g]["name"]], func(): action_requested.emit("fit", {"hero": i, "graft": g}))
						_button("%s refuses the bronze" % h["name"], func(): action_requested.emit("refuse", {"hero": i}))
	if run.stages["law"] >= 3:
		for i in range(run.squad.size()):
			var hf: Dictionary = run.squad[i]
			if hf["alive"] and not hf["left"] and int(hf["sorcery_tier"]) >= 1 and int(hf["clay"]) >= 1:
				_button("%s forges a report" % hf["name"], func(): action_requested.emit("forge", {"hero": i}))
	for opt in run.options():
		var target: Dictionary = run.world["nodes"][opt["id"]]
		var name: String = target["name"] if (run.visited.has(opt["id"]) or target["kind"] == "city") else "the road (%s)" % target["kind"]
		_button("Go: %s (%dd)" % [name, opt["days"]], func(): travel_requested.emit(opt["id"]))
	_button("Save", func(): action_requested.emit("save", {}))
	var lg := ""
	for entry in run.log.slice(maxi(0, run.log.size() - 4)):
		lg += entry["text"] + "\n"
	log_label.text = lg


func _button(text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.pressed.connect(cb)
	actions.add_child(b)
