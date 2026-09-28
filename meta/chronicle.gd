class_name Chronicle
extends RefCounted
## The Chronicle in the Scribes' voice: templated sentences from what was
## recorded. Unrecorded deeds leave a gap line. A Chronicle-seat holder narrates.

const OPENINGS := [
	"In the year the tin stopped, a levy was raised at %s under the seal of the Sun.",
	"The tablets of %s record a levy raised in the season of the late rains.",
	"It is written at %s that a band went out under writ.",
]
const GAP := "[a line here is broken and cannot be read]"


static func for_run(run: Run, narrator: String = "") -> String:
	var seed := run.seed
	var lines: Array[String] = []
	var raiser: String = run.world["nodes"][run.writ["issued_by"]]["name"]
	lines.append(OPENINGS[seed % OPENINGS.size()] % raiser)
	if narrator != "":
		lines.append("So says %s, who keeps this Chronicle." % narrator)
	if not run.weather.is_empty():
		lines.append(run.weather[0] + " " + run.weather[4])
	var names: Array = []
	for h in run.squad:
		names.append(h["name"])
	lines.append("They were %s." % _join(names))
	var wrote_any := false
	for d in run.deeds:
		if d["recorded"]:
			lines.append(_deed_line(d, run))
			wrote_any = true
		else:
			lines.append(GAP)
	if not wrote_any:
		lines.append("No scribe recorded what they did, so the tablets say they did nothing.")
	for h in run.squad:
		if not h["alive"]:
			lines.append("%s did not come back." % h["name"])
		elif h.get("taken", false):
			lines.append("%s came back, and the bronze came back in them." % h["name"])
		elif h.get("answered", false):
			lines.append("%s went to the Temple, as the ink asked." % h["name"])
		elif h.get("left", false):
			lines.append("%s stayed behind at a smith's door and would not be remade." % h["name"])
		elif not h["grafts"].is_empty():
			lines.append("%s came back with %s." % [h["name"], _join(_graft_names(h["grafts"]))])
	if run.state == "won":
		lines.append("The %s was done on the %s day." % [run.ambition["name"].to_lower(), _ordinal(run.day)])
	else:
		lines.append("On the %s day the road had them, and the tablets stop." % _ordinal(run.day))
	return " ".join(lines)


static func _deed_line(d: Dictionary, run: Run) -> String:
	var text: String = d["text"]
	var node_name: String = run.world["nodes"].get(d["node"], {}).get("name", "the road")
	var templates := [
		"On the %s day, at %s: %s.",
		"%s, on the %s day, at %s.",
		"At %s, the %s day: %s.",
	]
	match (d["day"] + text.length()) % 3:
		0: return templates[0] % [_ordinal(d["day"]), node_name, text.to_lower()]
		1: return templates[1] % [text, _ordinal(d["day"]), node_name]
		_: return templates[2] % [node_name, _ordinal(d["day"]), text.to_lower()]


static func _graft_names(keys: Array) -> Array:
	var out: Array = []
	for k in keys:
		out.append("a " + SimData.load_json("grafts")[k]["name"].to_lower())
	return out


static func _join(items: Array) -> String:
	if items.is_empty():
		return "nobody"
	if items.size() == 1:
		return str(items[0])
	return ", ".join(items.slice(0, items.size() - 1)) + " and " + str(items.back())


static func _ordinal(n: int) -> String:
	var suffix := "th"
	if n % 100 < 11 or n % 100 > 13:
		match n % 10:
			1: suffix = "st"
			2: suffix = "nd"
			3: suffix = "rd"
	return "%d%s" % [n, suffix]


## The Register's own chronicle: one paragraph per generation, the fall at the end.
static func for_register(reg: Register) -> String:
	var parts: Array[String] = []
	for c in reg.chronicle:
		parts.append("Generation %d. %s" % [int(c["generation"]), c["text"]])
	if reg.fallen:
		var gone: Array = []
		for t in WorldState.TRACKS:
			if reg.world.stage(t) == "Gone":
				gone.append(t)
		parts.append("Here the Register ends. %s were gone, and nobody wrote after that." % _join(gone).capitalize())
	return "\n\n".join(parts)
