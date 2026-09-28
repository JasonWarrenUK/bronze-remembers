class_name WorldState
extends RefCounted
## The Collapse and the institutions. Five hidden track scores with stages, four
## state machines with their own counters, ticked once per generation. Lives
## inside the Register and is saved with it.

const TRACKS := ["law", "rite", "custom", "tongue", "sea"]
const STAGES := ["Whole", "Strained", "Broken", "Lost", "Gone"]
const STAGE_SIZE := 20
const CURVES := {
	"law":    {"early": 9, "late": 5},
	"rite":   {"early": 7, "late": 7},
	"custom": {"early": 5, "late": 9},
	"tongue": {"early": 3, "late": 12},
	"sea":    {"early": 8, "late": 8},
}

var scores: Dictionary = {"law": 0, "rite": 0, "custom": 0, "tongue": 0, "sea": 0}
var holds: Dictionary = {}                  # track -> true when a seat holds it this generation
var institutions: Dictionary = {
	"palace": {"state": "Standing", "step": 0, "kept_runs": 0, "defaulted_runs": 0},
	"temple": {"state": "Standing", "step": 0, "faith_answers": 0, "sin_answers": 0, "sin_after_cult": 0},
	"scribes": {"state": "Standing", "step": 0, "truth_generations": 0, "lie_generations": 0, "archive_lost": 0, "archive_won": 0},
	"smiths": {"state": "Standing", "step": 0, "moulds": 0, "honoured": 0, "defaulted": 0, "coastal_callbacks": 0},
}
var last_report: Dictionary = {}
var pending: Dictionary = {}                # track -> points from the last run, applied with the tick


static func stage_index(score: int) -> int:
	return clampi(score / STAGE_SIZE, 0, STAGES.size() - 1)


func stage(track: String) -> String:
	return STAGES[stage_index(int(scores[track]))]


func stage_num(track: String) -> int:
	return stage_index(int(scores[track]))


func gone_count() -> int:
	var n := 0
	for t in TRACKS:
		if stage(t) == "Gone":
			n += 1
	return n


func fallen() -> bool:
	return gone_count() >= 3


func nudge(track: String, points: int) -> void:
	scores[track] = clampi(int(scores[track]) + points, 0, 100)


## Run dealings queue their effect so a good run subtracts from this generation's tick rather than from zero.
func queue(track: String, points: int) -> void:
	pending[track] = int(pending.get(track, 0)) + points


func drop_stage(track: String) -> void:
	scores[track] = maxi(0, int(scores[track]) - STAGE_SIZE)


func set_gone(track: String) -> void:
	scores[track] = 100


## Folds one run's dealings into the counters. `dealings` is produced by Run.dealings().
func record_run(dealings: Dictionary) -> void:
	var pal: Dictionary = institutions["palace"]
	if dealings.get("reports_defaulted", 0) == 0 and dealings.get("reports_kept", 0) > 0:
		pal["kept_runs"] += 1
		pal["defaulted_runs"] = 0
	elif dealings.get("reports_defaulted", 0) > 0:
		pal["defaulted_runs"] += 1
		pal["kept_runs"] = 0
	queue("law", -int(dealings.get("reports_kept", 0)) + 2 * int(dealings.get("reports_defaulted", 0)))
	var tem: Dictionary = institutions["temple"]
	var faith: int = dealings.get("faith", 0)
	var sin: int = dealings.get("sin", 0)
	if faith > sin:
		tem["faith_answers"] += 1
		tem["sin_answers"] = 0
	elif sin > faith:
		tem["sin_answers"] += 1
		tem["faith_answers"] = 0
		if tem["state"] == "Cult" and tem["step"] >= 3:
			tem["sin_after_cult"] += 1
	var scr: Dictionary = institutions["scribes"]
	if dealings.get("truth", 0) > dealings.get("lies", 0):
		scr["truth_generations"] += 1
		scr["lie_generations"] = 0
	elif dealings.get("lies", 0) > dealings.get("truth", 0):
		scr["lie_generations"] += 1
		scr["truth_generations"] = 0
	scr["archive_won"] += int(dealings.get("archive_won", 0))
	scr["archive_lost"] += int(dealings.get("archive_lost", 0))
	var smi: Dictionary = institutions["smiths"]
	smi["moulds"] += int(dealings.get("grafts_fitted", 0))
	smi["honoured"] += int(dealings.get("moulds_honoured", 0))
	smi["defaulted"] += int(dealings.get("moulds_defaulted", 0))
	smi["coastal_callbacks"] += int(dealings.get("coastal_callbacks", 0))
	queue("sea", int(dealings.get("grafts_fitted", 0)))
	queue("custom", int(dealings.get("grafts_fitted", 0)))
	for t in dealings.get("nudges", {}):
		queue(t, int(dealings["nudges"][t]))
	if dealings.get("mixed_graft", false) or smi["coastal_callbacks"] >= 2:
		_enter("smiths", "Armourers of the Sea")
	if dealings.get("ambition", "") == "drown_temple":
		_enter("temple", "Burned")
	if dealings.get("ambition", "") == "dissolve_palace":
		_enter("palace", "Dissolved")


## One generation passes: tracks tick on their curves with institution modifiers, arcs step.
func tick_generation() -> Dictionary:
	var report := {"before": scores.duplicate(), "arcs": []}
	for t in TRACKS:
		if holds.get(t, false):
			continue
		var curve: Dictionary = CURVES[t]
		var points: int = curve["early"] if stage_num(t) < 2 else curve["late"]
		match t:
			"law":
				if institutions["palace"]["state"] == "Restored":
					points -= 4
			"rite":
				if institutions["temple"]["state"] == "Reformed":
					points -= 3
			"tongue":
				if institutions["scribes"]["state"] == "Archive kept":
					points -= 3
			"sea":
				if institutions["smiths"]["state"] == "Guild":
					points -= 2
				if institutions["smiths"]["state"] == "Armourers of the Sea":
					points += 4
		nudge(t, maxi(0, points + int(pending.get(t, 0))))
	pending.clear()
	holds.clear()
	_step_palace(report)
	_step_temple(report)
	_step_scribes(report)
	_step_smiths(report)
	# Track Gone forces the terminal state; end states set tracks Gone.
	if stage("law") == "Gone" and institutions["palace"]["state"] != "Dissolved":
		_enter("palace", "Dissolved", report)
	if stage("tongue") == "Gone" and institutions["scribes"]["state"] != "Scattered":
		_enter("scribes", "Scattered", report)
	if institutions["palace"]["state"] == "Dissolved":
		set_gone("law")
	if institutions["temple"]["state"] == "Burned":
		nudge("rite", 2 * STAGE_SIZE)
	if institutions["scribes"]["state"] == "Scattered":
		set_gone("tongue")
	report["after"] = scores.duplicate()
	report["fallen"] = fallen()
	last_report = report
	return report


func _enter(key: String, state: String, report: Dictionary = {}) -> void:
	var inst: Dictionary = institutions[key]
	if inst["state"] == state:
		return
	inst["state"] = state
	inst["step"] = 1
	if report.has("arcs"):
		report["arcs"].append("%s: %s" % [key, state])


func _advance(key: String, report: Dictionary) -> void:
	var inst: Dictionary = institutions[key]
	if inst["step"] < 3:
		inst["step"] += 1
		report["arcs"].append("%s: %s step %d" % [key, inst["state"], inst["step"]])


func _step_palace(report: Dictionary) -> void:
	var p: Dictionary = institutions["palace"]
	match p["state"]:
		"Standing":
			if p["kept_runs"] >= 2:
				_enter("palace", "Restored", report)
			elif institutions["smiths"]["state"] == "Warlords" and stage_num("law") >= 2:
				_enter("palace", "Usurped", report)
		"Restored":
			if p["kept_runs"] > 0:
				_advance("palace", report)
			elif p["defaulted_runs"] >= 2:
				p["state"] = "Standing"
				p["step"] = 0
				report["arcs"].append("palace: back to Standing")
		"Usurped":
			if p["kept_runs"] >= 2:
				p["state"] = "Standing"
				p["step"] = 0
				report["arcs"].append("palace: back to Standing")
			else:
				_advance("palace", report)


func _step_temple(report: Dictionary) -> void:
	var t: Dictionary = institutions["temple"]
	match t["state"]:
		"Standing":
			if t["faith_answers"] >= 2:
				_enter("temple", "Reformed", report)
			elif t["sin_answers"] >= 2:
				_enter("temple", "Cult", report)
		"Reformed":
			if t["faith_answers"] > 0:
				_advance("temple", report)
			elif t["sin_answers"] >= 2:
				t["state"] = "Standing"
				t["step"] = 0
				report["arcs"].append("temple: back to Standing")
		"Cult":
			if t["sin_answers"] > 0:
				_advance("temple", report)
			if t["step"] >= 3 and t["sin_after_cult"] >= 1:
				_enter("temple", "Burned", report)


func _step_scribes(report: Dictionary) -> void:
	var s: Dictionary = institutions["scribes"]
	match s["state"]:
		"Standing":
			if s["truth_generations"] >= 2 and s["archive_won"] >= 1:
				_enter("scribes", "Archive kept", report)
			elif s["lie_generations"] >= 2:
				_enter("scribes", "Sold", report)
			elif s["archive_lost"] >= 2:
				_enter("scribes", "Scattered", report)
		"Archive kept":
			if s["truth_generations"] > 0:
				_advance("scribes", report)
		"Sold":
			if s["lie_generations"] > 0:
				_advance("scribes", report)
			if s["archive_lost"] >= 2:
				_enter("scribes", "Scattered", report)


func _step_smiths(report: Dictionary) -> void:
	var m: Dictionary = institutions["smiths"]
	match m["state"]:
		"Standing", "Guild":
			if stage_num("law") >= 3 and m["moulds"] >= 4:
				_enter("smiths", "Warlords", report)
			elif stage_num("law") <= 2 and m["moulds"] > 0 and m["defaulted"] < m["honoured"]:
				if m["state"] == "Standing":
					_enter("smiths", "Guild", report)
				else:
					_advance("smiths", report)
		"Warlords":
			if stage_num("law") >= 3:
				_advance("smiths", report)


func weather() -> Array[String]:
	var lines: Array[String] = []
	match stage("law"):
		"Whole": lines.append("The Sun's writs are honoured on every road.")
		"Strained": lines.append("Writs are read twice past the second milestone.")
		"Broken": lines.append("Beyond the walls, a writ is a piece of clay.")
		"Lost": lines.append("The Palace issues nothing. What is held is held by hand.")
		"Gone": lines.append("There is no Palace. The gates are shut to everyone.")
	match stage("rite"):
		"Whole": lines.append("The Temple heals for ink and the rites take.")
		"Strained": lines.append("Ink costs more lines than it did.")
		"Broken": lines.append("There are cult marks on the shrine stones.")
		"Lost": lines.append("The Temple has stopped healing. The ink no longer compels.")
		"Gone": lines.append("The cults make the demands now.")
	match stage("custom"):
		"Whole": lines.append("Guest-right holds at every hearth.")
		"Strained": lines.append("Strangers are fed only where kin vouch for them.")
		"Broken": lines.append("Blood-price hunters walk the roads. Heirlooms are looted.")
		"Lost": lines.append("Nobody buries anyone without an elder, and the elders are few.")
		"Gone": lines.append("There is no guest-right. Nobody buries the dead.")
	match stage("tongue"):
		"Whole": lines.append("One tongue from the coast to the upland.")
		"Strained": lines.append("At the map's edge the words come out wrong.")
		"Broken": lines.append("Every region has its own dialect now.")
		"Lost": lines.append("Most of the levy cannot read a letter.")
		"Gone": lines.append("Every city speaks its own tongue. Trade is by gesture.")
	match stage("sea"):
		"Whole": lines.append("Strange catches on the coast, nothing more.")
		"Strained": lines.append("Things have been seen on the beaches at dusk.")
		"Broken": lines.append("The tide comes a mile inland, and it brings company.")
		"Lost": lines.append("The river cities hear the sea in their wells.")
		"Gone": lines.append("The tide is at the upland.")
	return lines


func to_dict() -> Dictionary:
	return {"scores": scores, "institutions": institutions, "holds": holds}


static func from_dict(d: Dictionary) -> WorldState:
	var w := WorldState.new()
	if d.is_empty():
		return w
	for t in w.scores:
		w.scores[t] = int(d.get("scores", {}).get(t, 0))
	var inst: Dictionary = d.get("institutions", {})
	for key in w.institutions:
		if inst.has(key):
			for field in w.institutions[key]:
				var v: Variant = inst[key].get(field, w.institutions[key][field])
				w.institutions[key][field] = int(v) if (v is float) else v
	w.holds = d.get("holds", {})
	return w
