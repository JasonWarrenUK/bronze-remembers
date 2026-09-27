class_name Run
extends RefCounted
## One campaign run: the squad, the days, the writ, the deeds, the injuries,
## the chapters of the ambition. Pure data; saved as JSON between nodes.

const ROAD_KILLS_DAYS := 6          # untreated severe injury is fatal after this many days
const TESTIMONY_RANGE_BASE := 2     # days a deed travels per point of significance

var seed: int
var rng: SimRng
var world: Dictionary
var ambition: Dictionary
var chapter: int = 1
var day: int = 0
var at: String                      # node id
var visited: Dictionary = {}
var squad: Array = []               # hero records
var deeds: Array = []               # {text, significance, day, node, recorded}
var writ: Dictionary = {"issued_by": "kessuwat", "reports_due": [], "outlaw": false}
var tablets: bool = false
var log: Array = []
var state: String = "ongoing"       # ongoing | won | lost
var milestone_reached: bool = false
var pending_fitting: Array = []     # hero indices waiting at a Smiths' node


func _init(seed_: int = 1, ambition_key: String = "archive") -> void:
	seed = seed_
	rng = SimRng.new(seed_)
	world = WorldGen.generate(seed_)
	ambition = SimData.load_json("ambitions")[ambition_key]
	at = "kessuwat"
	visited[at] = true
	_log("Mustered at %s under writ. The archive at Tarhuna is named." % world["nodes"][at]["name"])


func _log(text: String) -> void:
	log.append({"day": day, "text": text})


# ---------------------------------------------------------------- squad

func add_hero(kind: String, name: String, gear: String = "") -> Dictionary:
	var d: Dictionary = SimData.units()["heroes"][kind]
	var h := {"kind": kind, "name": name, "gear": gear, "hp": d["hp"], "max_hp": d["hp"], "alive": true, "left": false, "scars": [], "grafts": [], "injury": {}, "deeds": 0}
	squad.append(h)
	return h


func fighters() -> Array:
	var out: Array = []
	for h in squad:
		if h["alive"] and not h["left"] and h["injury"].get("severity", "") != "severe":
			out.append(h)
	return out


# ---------------------------------------------------------------- travel

func node(id: String = "") -> Dictionary:
	return world["nodes"][id if id != "" else at]


func options() -> Array:
	return WorldGen.neighbours(world, at)


## Moves to an adjacent node. Days pass; injuries and reports tick. Returns false if not adjacent.
func travel_to(id: String) -> bool:
	var days := -1
	for n in options():
		if n["id"] == id:
			days = n["days"]
	if days < 0:
		return false
	day += days
	at = id
	visited[id] = true
	for h in fighters():
		h["hp"] = mini(h["max_hp"], h["hp"] + 2 * days)
	for h in squad:
		if h["injury"].get("severity", "") == "severe" and h["alive"]:
			h["injury"]["days_left"] = h["injury"].get("days_left", ROAD_KILLS_DAYS) - days
			if h["injury"]["days_left"] <= 0:
				h["alive"] = false
				_log("%s died on the road of an untreated wound." % h["name"])
	_log("Day %d: reached %s." % [day, node()["name"]])
	if node()["kind"] == "city" and writ["reports_due"].size() > 0:
		writ["reports_due"] = []
		_log("Report made at %s." % node()["name"])
	for r in writ["reports_due"]:
		if r["day"] < day:
			writ["outlaw"] = true
			_log("A report went unmade. The squad is outlaw to the Palace.")
	_check_milestone()
	return true


func _check_milestone() -> void:
	var ch: Dictionary = ambition["chapters"][chapter - 1]
	var target := WorldGen.find_node(world, ch["node"])
	milestone_reached = (at == target)


## The current chapter's battle, if the squad stands at the milestone node.
func milestone_battle() -> SimBattle:
	if not milestone_reached:
		return null
	var ch: Dictionary = ambition["chapters"][chapter - 1]
	return Encounters.build(self, node(), ch["objective"], ch["families"], ch.get("grafted_variant", false))


## A road battle at a battle node.
func road_battle() -> SimBattle:
	var families := ["levies"]
	if node().get("landmark", "") == "tide_road" or node()["kind"] == "drowned_town":
		families = ["sea"]
	return Encounters.build(self, node(), {"type": "kill_all"}, families, false, true)


# ---------------------------------------------------------------- results

## Applies a finished battle: HP, deeds, downing draws, injuries. Advances the chapter on a milestone win.
func apply_battle(b: SimBattle, milestone: bool) -> Dictionary:
	var draws := b.resolve_downings()
	var report := {"result": b.state, "rounds": b.round, "draws": draws, "deeds": []}
	for h in squad:
		if not h.has("unit_id"):
			continue
		var u := b.unit_by_id(h["unit_id"])
		if u == null:
			continue
		h["hp"] = maxi(1, u.hp) if not u.downed else 1
		h.erase("unit_id")
	for d in draws:
		var u := b.unit_by_id(d["unit"])
		var h := _hero_named(u.name)
		if h.is_empty():
			continue
		match d["outcome"]:
			"scar":
				var scar := _pick_scar(u, d["by"])
				h["scars"].append(scar)
				_log("%s carries a new scar: %s." % [h["name"], SimData.load_json("scars")[scar]["name"]])
			"severe":
				var loc := _pick_location(d["by"], d["overkill"])
				h["injury"] = {"severity": "severe", "location": loc, "days_left": ROAD_KILLS_DAYS, "by": d["by"]}
				_log("%s is badly hurt: the %s. A smith is needed within %d days." % [h["name"], loc, ROAD_KILLS_DAYS])
			"dead":
				h["alive"] = false
				_log("%s died at %s." % [h["name"], node()["name"]])
	var named_kills := 0
	for e in b.enemies(false):
		if e.downed and e.named:
			named_kills += 1
	if b.state == "won":
		_deed("Held %s against %d" % [node()["name"], b.enemies(false).size()], 2 + named_kills, report)
		if milestone:
			var ch: Dictionary = ambition["chapters"][chapter - 1]
			_deed(ch["title"], 4, report)
			if ch.get("on_complete", "") == "take_tablets":
				tablets = true
				_log("The tablets of Tarhuna are under seal in the squad's keeping.")
			chapter += 1
			milestone_reached = false
			if chapter > ambition["chapters"].size():
				state = "won"
				_log("The archive is out. The ship takes it, and whoever is left.")
			else:
				_check_milestone()
	else:
		if milestone and ambition["chapters"][chapter - 1]["objective"]["type"] == "protect":
			tablets = false
			_log("The tablets are lost to the water.")
			state = "lost"
	if fighters().is_empty():
		state = "lost"
		_log("Nobody left standing.")
	return report


func _deed(text: String, significance: int, report: Dictionary) -> void:
	var d := {"text": text, "significance": significance, "day": day, "node": at, "recorded": false}
	deeds.append(d)
	report["deeds"].append(d)
	# Channel 1: the deed travels to a scribal node within reach.
	if _scribal_within(significance * TESTIMONY_RANGE_BASE):
		d["recorded"] = true


func _scribal_within(days: int) -> bool:
	for id in world["nodes"]:
		var n: Dictionary = world["nodes"][id]
		if n["kind"] == "city" and n["flags"].get("scribal", false):
			if id == at:
				return true
			var r := WorldGen.route(world, at, id)
			if not r.is_empty() and r.size() <= days:
				return true
	return false


## Channel 2: visiting a scribal node records every queued deed.
func testify() -> int:
	if not node()["flags"].get("scribal", false):
		return 0
	var n := 0
	for d in deeds:
		if not d["recorded"]:
			d["recorded"] = true
			n += 1
	if n > 0:
		_log("%d deeds testified at %s." % [n, node()["name"]])
	return n


func _hero_named(name: String) -> Dictionary:
	for h in squad:
		if h["name"] == name:
			return h
	return {}


func _pick_scar(u: SimUnit, by: String) -> String:
	var fam: String = SimData.units()["enemies"].get(by, {}).get("family", "levies")
	var pool: Array = []
	var scars: Dictionary = SimData.load_json("scars")
	for key in scars:
		if scars[key]["sources"].has(fam) and not u.scars.has(key):
			pool.append(key)
	if pool.is_empty():
		pool = scars.keys()
	return pool[rng.range_int(0, pool.size() - 1)]


func _pick_location(by: String, overkill: int) -> String:
	var fam: String = SimData.units()["enemies"].get(by, {}).get("family", "levies")
	var locations := ["arm", "leg", "jaw", "torso"]
	if fam == "sea":
		return "leg" if overkill < 2 else "torso"
	return locations[rng.range_int(0, locations.size() - 1)]


# ---------------------------------------------------------------- Smiths

## Grafts the Smiths will offer this hero here: one or two for the injury's location.
func graft_offers(h: Dictionary) -> Array:
	if node()["flags"].get("smiths", false) == false or h["injury"].get("severity", "") != "severe":
		return []
	var out: Array = []
	var grafts: Dictionary = SimData.load_json("grafts")
	for key in grafts:
		if grafts[key]["location"] == h["injury"]["location"] and not grafts[key].get("forbids_class", []).has(h["kind"]):
			out.append(key)
	return out


func fit_graft(h: Dictionary, key: String) -> void:
	h["grafts"].append(key)
	h["injury"] = {}
	h["hp"] = h["max_hp"]
	_log("%s is fitted: %s. %s" % [h["name"], SimData.load_json("grafts")[key]["name"], SimData.load_json("grafts")[key]["text"]])
	_deed("%s remade in bronze" % h["name"], 3, {"deeds": []})


func refuse_graft(h: Dictionary) -> void:
	h["left"] = true
	_log("%s refuses the bronze and stays behind at %s." % [h["name"], node()["name"]])


# ---------------------------------------------------------------- rest

func rest() -> void:
	if node()["kind"] != "rest" and node()["kind"] != "city":
		return
	for h in fighters():
		h["hp"] = h["max_hp"]
	day += 1
	_log("Rested a day at %s." % node()["name"])


# ---------------------------------------------------------------- save, load, chronicle

func to_dict() -> Dictionary:
	return {
		"seed": seed, "rng_state": rng.state(), "chapter": chapter, "day": day, "at": at, "visited": visited,
		"squad": squad, "deeds": deeds, "writ": writ, "tablets": tablets, "log": log, "state": state,
		"milestone_reached": milestone_reached,
	}


func save(path: String) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(to_dict(), "\t"))
	f.close()
	return true


static func load_from(path: String) -> Run:
	var text := FileAccess.get_file_as_string(path)
	if text == "":
		return null
	var d: Dictionary = JSON.parse_string(text)
	var r := Run.new(int(d["seed"]))
	r.rng._rng.state = int(d["rng_state"])
	r.chapter = int(d["chapter"])
	r.day = int(d["day"])
	r.at = d["at"]
	r.visited = d["visited"]
	r.squad = d["squad"]
	r.deeds = d["deeds"]
	r.writ = d["writ"]
	r.tablets = d["tablets"]
	r.log = d["log"]
	r.state = d["state"]
	r.milestone_reached = d["milestone_reached"]
	return r


## A short paragraph in the setting's voice, from what was testified.
func chronicle_stub() -> String:
	var recorded: Array = []
	var lost := 0
	for d in deeds:
		if d["recorded"]:
			recorded.append(d["text"])
		else:
			lost += 1
	var names: Array = []
	var dead: Array = []
	for h in squad:
		if h["alive"]:
			names.append(h["name"])
		else:
			dead.append(h["name"])
	var text := "In the year the tin stopped, a levy was raised at Kessuwat under the seal of the Sun. "
	if recorded.is_empty():
		text += "No scribe recorded what they did, so the tablets say they did nothing. "
	else:
		text += "The tablets record: %s. " % "; ".join(recorded)
	if lost > 0:
		text += "%d things they did were never written and are not remembered. " % lost
	if not dead.is_empty():
		text += "%s did not come back. " % ", ".join(dead)
	if state == "won":
		text += "The archive went out by ship with %s." % ", ".join(names)
	else:
		text += "The archive stayed where it was. The road has it now."
	return text
