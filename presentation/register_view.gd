class_name RegisterView
extends Node
## The Register screen: roster with bands, retirement, wanderers, seats, and
## squad creation within the tier budget. Emits when a run should start.

signal run_requested(picks: Array, spent: int)
signal ambition_chosen(key: String)

var reg: Register
var palette: Dictionary
var theme_ui: Theme
var picks: Array = []
var layer: CanvasLayer
var roster_box: VBoxContainer
var side_box: VBoxContainer
var status: RichTextLabel


func setup(r: Register, pal: Dictionary, thm: Theme) -> void:
	reg = r
	palette = pal
	theme_ui = thm
	layer = CanvasLayer.new()
	add_child(layer)
	var panel := PanelContainer.new()
	panel.theme = theme_ui
	panel.position = Vector2(8, 8)
	panel.size = Vector2(624, 344)
	var style := StyleBoxFlat.new()
	style.bg_color = palette["surface_raised"]
	style.border_color = palette["accent_2"]
	style.set_border_width_all(2)
	style.set_content_margin_all(8)
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var left := VBoxContainer.new()
	left.custom_minimum_size = Vector2(380, 0)
	row.add_child(left)
	status = RichTextLabel.new()
	status.bbcode_enabled = true
	status.custom_minimum_size = Vector2(380, 40)
	status.add_theme_color_override("default_color", palette["ink"])
	left.add_child(status)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(380, 270)
	left.add_child(scroll)
	roster_box = VBoxContainer.new()
	scroll.add_child(roster_box)
	var side_scroll := ScrollContainer.new()
	side_scroll.custom_minimum_size = Vector2(220, 320)
	side_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	row.add_child(side_scroll)
	side_box = VBoxContainer.new()
	side_box.custom_minimum_size = Vector2(205, 0)
	side_scroll.add_child(side_box)
	refresh()


func spent() -> int:
	var s := 0
	for h in picks:
		s += Register.tier_cost(h["tier"])
	return s


func refresh() -> void:
	var fallen_line := "  [color=#%s]THE REGISTER HAS FALLEN[/color]" % palette["danger"].to_html(false) if reg.fallen else ""
	status.text = "[b]The Register[/b]  generation %d, %d tracks gone%s\nBudget %d, spent %d, %d picked" % [reg.generation, reg.world.gone_count(), fallen_line, reg.budget(), spent(), picks.size()]
	for c in roster_box.get_children():
		c.queue_free()
	for h in reg.heroes:
		var line := HBoxContainer.new()
		var lbl := RichTextLabel.new()
		lbl.bbcode_enabled = true
		lbl.fit_content = true
		lbl.custom_minimum_size = Vector2(250, 0)
		lbl.add_theme_color_override("default_color", palette["ink"] if h["status"] == "playable" else palette["ink_muted"])
		var marks := ""
		if h["grafts"].size() > 0:
			marks += " bronze:%d" % h["grafts"].size()
		if h["scars"].size() > 0:
			marks += " scars:%d" % h["scars"].size()
		if h["line"]["parents"].size() > 0:
			marks += " line"
		lbl.text = "%s%s [color=#%s]%s t%d, %s, %d campaigns%s[/color]" % ["> " if picks.has(h) else "", h["name"], palette["ink_muted"].to_html(false), Register.band_name(h["tier"]), h["tier"], h["status"], h["campaigns"], marks]
		line.add_child(lbl)
		if h["status"] == "playable" and not reg.fallen:
			var pick := Button.new()
			pick.text = "Drop" if picks.has(h) else "Pick"
			pick.pressed.connect(_toggle.bind(h))
			line.add_child(pick)
			var retire := Button.new()
			retire.text = "Retire"
			retire.pressed.connect(_retirement_scene.bind(h))
			line.add_child(retire)
		roster_box.add_child(line)
	for c in side_box.get_children():
		c.queue_free()
	var side := RichTextLabel.new()
	side.bbcode_enabled = true
	side.fit_content = true
	side.custom_minimum_size = Vector2(210, 0)
	side.add_theme_color_override("default_color", palette["ink"])
	var text := "[b]Ambition[/b]\n"
	var text_pre := text
	var unlock := reg.next_unlock()
	text = "[b]Seats[/b]\n"
	for s in reg.seats:
		var holder := reg.hero_by_id(s["holder"]) if s["holder"] != -1 else {}
		text += "%s: %s\n" % [s.get("name", s["kind"]), holder.get("name", "empty")]
	if reg.seats.is_empty():
		text += "none\n"
	if not unlock.is_empty():
		text += "\n[b]Next unlock[/b]\n%s (%d of %d)\n%s\n" % [unlock["name"], unlock["progress"], int(unlock["count"]), unlock["text"]]
	text += "\n[b]The Road[/b]\n"
	for w in reg.wanderers:
		text += "%s%s\n" % [w["name"], " (dead)" if w["dead"] else " (%d)" % w["appearances"]]
	if reg.wanderers.is_empty():
		text += "nobody\n"
	text += "\n[b]The weather[/b]\n"
	for line in reg.world.weather():
		text += line + "\n"
	text += "\n[b]Institutions[/b]\n"
	for key in reg.world.institutions:
		var inst: Dictionary = reg.world.institutions[key]
		text += "%s: %s%s\n" % [key, inst["state"], (" %d" % inst["step"]) if inst["step"] > 0 else ""]
	text += "\n[b]Chronicle[/b]\n"
	for c in reg.chronicle.slice(maxi(0, reg.chronicle.size() - 3)):
		text += "gen %d: %s, day %d\n" % [c["generation"], c["state"], c["day"]]
	side.text = text
	side_box.add_child(side)
	if not reg.fallen and reg.mercenaries_available() > 0:
		var hire := Button.new()
		hire.text = "Hire a foreign spear (%d abroad)" % reg.mercenaries_available()
		hire.pressed.connect(func(): reg.new_mercenary(); reg.save(); refresh())
		side_box.add_child(hire)
	if not reg.fallen:
		for key in reg.ambitions_available():
			var amb := Button.new()
			amb.text = "Writ: " + SimData.load_json("ambitions")[key]["name"]
			amb.pressed.connect(func(): ambition_chosen.emit(key))
			side_box.add_child(amb)
		var go := Button.new()
		go.text = "Muster (%d picked, fresh levies fill the rest)" % picks.size()
		go.pressed.connect(func(): run_requested.emit(picks.duplicate(), spent()))
		side_box.add_child(go)
	else:
		var anew := Button.new()
		anew.text = "Begin a new Register"
		anew.pressed.connect(func(): reg = Register.begin_anew(reg); reg.save(); refresh())
		side_box.add_child(anew)
	var save := Button.new()
	save.text = "Save Register"
	save.pressed.connect(func(): reg.save())
	side_box.add_child(save)


## The retirement scene: the seats this hero may take, what each does, who holds it, and the Road.
func _retirement_scene(h: Dictionary) -> void:
	for c in side_box.get_children():
		c.queue_free()
	var head := RichTextLabel.new()
	head.bbcode_enabled = true
	head.fit_content = true
	head.custom_minimum_size = Vector2(210, 0)
	head.add_theme_color_override("default_color", palette["ink"])
	head.text = "[b]%s retires[/b]\n%s, tier %d, %d testified deeds." % [h["name"], Register.band_name(h["tier"]), h["tier"], h["deeds"]]
	side_box.add_child(head)
	var offers := reg.seat_offers(h)
	for o in offers:
		var holder := reg.hero_by_id(o["holder"]) if o["holder"] != -1 else {}
		var lbl := RichTextLabel.new()
		lbl.bbcode_enabled = true
		lbl.fit_content = true
		lbl.custom_minimum_size = Vector2(210, 0)
		lbl.add_theme_color_override("default_color", palette["ink_muted"])
		lbl.text = "[color=#%s]%s[/color]%s\n%s" % [palette["accent"].to_html(false), o["name"], (" (held by %s)" % holder["name"]) if not holder.is_empty() else "", o["text"]]
		side_box.add_child(lbl)
		if holder.is_empty():
			var take := Button.new()
			take.text = "Take the seat"
			take.pressed.connect(func(): reg.take_seat(h, o); picks.erase(h); reg.save(); refresh())
			side_box.add_child(take)
		else:
			var deed := Button.new()
			deed.text = "Claim by deed"
			deed.pressed.connect(func():
				var res := reg.take_seat(h, o, "deed")
				if res["taken"]:
					picks.erase(h)
					reg.save()
				refresh())
			side_box.add_child(deed)
			var writ := Button.new()
			writ.text = "Claim by writ"
			writ.disabled = reg.world.stage_num("law") > 2
			writ.pressed.connect(func():
				var res := reg.take_seat(h, o, "writ")
				if res["taken"]:
					picks.erase(h)
					reg.save()
				refresh())
			side_box.add_child(writ)
	var road := Button.new()
	road.text = "No seat: take the Road"
	road.pressed.connect(func(): reg.retire_to_road(h); picks.erase(h); reg.save(); refresh())
	side_box.add_child(road)
	var back := Button.new()
	back.text = "Back"
	back.pressed.connect(refresh)
	side_box.add_child(back)


func _toggle(h: Dictionary) -> void:
	if picks.has(h):
		picks.erase(h)
	elif picks.size() < 3 and spent() + Register.tier_cost(h["tier"]) <= reg.budget():
		picks.append(h)
	refresh()
