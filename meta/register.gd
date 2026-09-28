class_name Register
extends RefCounted
## The Register: what outlives a run. Heroes with tiers, age and lines; the
## dead; wanderers on the Road; the civic seats; the generation count.
## Saved as JSON at user://register.json.

const PATH := "user://register.json"
const BANDS := [["Levy", 0], ["Named", 5], ["Storied", 10], ["Dynast", 15], ["Founder", 20]]
const LAST_CAMPAIGN := 4          # the fourth campaign played is a hero's last
const FALL_GENERATIONS := 8
const BASE_BUDGET := 6

var generation: int = 0
var heroes: Array = []            # records, see new_hero
var wanderers: Array = []         # {name, kind, tier, scars, grafts, gear, appearances}
var seats: Array = []             # {kind: "elder", city, holder, since}
var fallen: bool = false
var next_id: int = 1
var chronicle: Array = []         # one entry per run
var world: WorldState = WorldState.new()
var unlocks: Dictionary = {}      # carried into the next Register


static func tier_cost(tier: int) -> int:
	if tier <= 0:
		return 0
	var costs := [0, 1, 2]
	while costs.size() <= tier:
		costs.append(costs[-1] + costs[-2])
	return costs[tier]


static func band_name(tier: int) -> String:
	var name := "Levy"
	for b in BANDS:
		if tier >= b[1]:
			name = b[0]
	return name


func new_hero(kind: String, name: String, origin: String, gear: String = "", tier: int = 0) -> Dictionary:
	var h := {
		"id": next_id, "kind": kind, "name": name, "origin": origin, "gear": gear,
		"tier": tier, "campaigns": 0, "age_steps": 0, "status": "playable",
		"scars": [], "grafts": [], "traits": [], "grudges": [], "heirloom": "",
		"line": {"parents": []}, "deeds": 0, "bonds": {}, "memory": {}, "sorcery_tier": -1, "false_lines": 0,
	}
	next_id += 1
	heroes.append(h)
	return h


func playable() -> Array:
	var out: Array = []
	for h in heroes:
		if h["status"] == "playable":
			out.append(h)
	return out


func hero_by_id(id: int) -> Dictionary:
	for h in heroes:
		if h["id"] == id:
			return h
	return {}


func budget() -> int:
	var b := BASE_BUDGET
	for s in seats:
		if s["holder"] != -1:
			b += 1
	return b


## Difficulty scaling from tier points spent: extra enemies and HP.
static func scaling(points_spent: int) -> Dictionary:
	return {"extra_enemies": points_spent / 5, "extra_hp": points_spent / 3}


# ---------------------------------------------------------------- run end

## Folds a finished run into the Register. `roster` maps run squad index to hero id.
func enter_from_run(run: Run, roster: Array) -> Dictionary:
	generation += 1
	var report := {"tiered": [], "aged_out": [], "dead": [], "descendants": [], "wanderer_deaths": []}
	var survivors: Array = []
	for i in range(run.squad.size()):
		var rec: Dictionary = run.squad[i]
		var h := hero_by_id(roster[i]) if i < roster.size() else {}
		if h.is_empty():
			continue
		h["scars"] = rec["scars"].duplicate()
		h["grafts"] = rec["grafts"].duplicate()
		h["campaigns"] += 1
		h["deeds"] += _deeds_for(run, rec["name"])
		if not rec["alive"]:
			h["status"] = "dead"
			h["died"] = {"generation": generation, "by": rec.get("injury", {}).get("by", "the road")}
			report["dead"].append(h["name"])
			continue
		if rec.get("taken", false):
			h["status"] = "taken"
			h["died"] = {"generation": generation, "by": "the bronze"}
			report["dead"].append(h["name"] + " (taken)")
			continue
		if rec.get("answered", false):
			h["status"] = "temple"
			continue
		if rec.get("left", false):
			h["status"] = "road"
			_add_wanderer(h)
			continue
		h["memory"] = rec.get("memory", {})
		h["sorcery_tier"] = int(rec.get("sorcery_tier", -1))
		h["false_lines"] = int(rec.get("false_lines", 0))
		h["tier"] += 1
		report["tiered"].append(h["name"])
		survivors.append(h)
	# Bonds from the run's pair scores.
	for key in run.pair_scores:
		var ids: Array = key.split(":")
		var a := hero_by_id(roster[int(ids[0])]) if int(ids[0]) < roster.size() else {}
		var b := hero_by_id(roster[int(ids[1])]) if int(ids[1]) < roster.size() else {}
		if a.is_empty() or b.is_empty():
			continue
		a["bonds"][str(b["id"])] = int(a["bonds"].get(str(b["id"]), 0)) + int(run.pair_scores[key])
		b["bonds"][str(a["id"])] = int(b["bonds"].get(str(a["id"]), 0)) + int(run.pair_scores[key])
	# Everyone ages, played or not.
	for h in heroes:
		if h["status"] == "playable":
			h["age_steps"] += 1
	# Fourth campaign played is the last: the hero dies of age at its end.
	for h in survivors:
		if h["campaigns"] >= LAST_CAMPAIGN:
			h["status"] = "dead"
			h["died"] = {"generation": generation, "by": "age"}
			report["aged_out"].append(h["name"])
	# Descendants: greedy matching of bonded pairs among this run's survivors, then origin-house fallback for retirees.
	report["descendants"] = _descendants(survivors, run)
	# Seats and wanderers tick.
	for s in seats:
		if s["holder"] != -1 and generation - s["since"] >= 3:
			var holder := hero_by_id(s["holder"])
			if not holder.is_empty():
				holder["status"] = "dead"
				holder["died"] = {"generation": generation, "by": "age, in office"}
			s["holder"] = -1
	for w in run.wanderer_deaths:
		report["wanderer_deaths"].append(w)
	chronicle.append({"generation": generation, "state": run.state, "day": run.day, "text": run.chronicle_stub()})
	world.record_run(run.dealings())
	for s in seats:
		if s["holder"] != -1 and s.get("holds", "") != "":
			world.holds[s["holds"]] = true
	report["world"] = world.tick_generation()
	if world.fallen():
		fallen = true
	return report


func _deeds_for(run: Run, name: String) -> int:
	var n := 0
	for d in run.deeds:
		if d["recorded"]:
			n += 1
	return n


func _descendants(survivors: Array, run: Run) -> Array:
	var out: Array = []
	var used: Dictionary = {}
	var pairs: Array = []
	for a in survivors:
		for b in survivors:
			if a["id"] < b["id"]:
				var score := int(a["bonds"].get(str(b["id"]), 0))
				if score >= 5:
					pairs.append([score, a, b])
	pairs.sort_custom(func(x, y): return x[0] > y[0])
	for p in pairs:
		var a: Dictionary = p[1]
		var b: Dictionary = p[2]
		if used.has(a["id"]) or used.has(b["id"]):
			continue
		used[a["id"]] = true
		used[b["id"]] = true
		out.append(_child([a, b]))
	# Unbonded retirees (leaving play this generation by age) get a house child.
	for h in survivors:
		if h["status"] == "dead" and h.get("died", {}).get("by", "") == "age" and not used.has(h["id"]):
			out.append(_child([h]))
	return out


func _child(parents: Array) -> Dictionary:
	var first: Dictionary = parents[0]
	var tier: int = int(first["tier"]) / 2
	if parents.size() > 1:
		var hi: int = maxi(parents[0]["tier"], parents[1]["tier"])
		var lo: int = mini(parents[0]["tier"], parents[1]["tier"])
		tier = hi / 2 + lo / 4
	var kind: String = parents[parents.size() - 1]["kind"]
	var child := new_hero(kind, _child_name(first["name"]), first["origin"], "", tier)
	child["line"]["parents"] = []
	for p in parents:
		child["line"]["parents"].append(p["id"])
		# One inherited property per parent: heirloom gear first, else a grudge, else a trait.
		if p["gear"] != "" and child["gear"] == "":
			child["gear"] = p["gear"]
			child["heirloom"] = "%s's %s" % [p["name"], p["gear"]]
			# Bronze remembers: the heirloom carries the parent's basic ability, charges by band.
			var charges: int = 1 + mini(2, int(p["tier"]) / 5)
			child["memory"] = {"ancestor": p["name"], "ability": SimData.units()["heroes"].get(p["kind"], {}).get("basic", "thrust"), "charges": charges, "base_charges": charges, "used": 0, "full": true}
		elif p.get("died", {}).has("by") and p["died"]["by"] != "age":
			child["grudges"].append(p["died"]["by"])
		elif not p["scars"].is_empty():
			child["traits"].append("child of the %s" % SimData.load_json("scars")[p["scars"][0]]["name"].to_lower())
	return child


func _child_name(parent_name: String) -> String:
	var stems := ["Ari", "Tudh", "Muwa", "Hatt", "Zid", "Kant", "Piya", "Suppi", "Arnu", "Telip"]
	var ends := ["nda", "aliya", "tti", "usili", "anta", "uzzi", "ma", "ili"]
	var seed := parent_name.hash() + generation
	return stems[seed % stems.size()] + ends[(seed / 7) % ends.size()]


# ---------------------------------------------------------------- retirement and seats

func retire_to_road(h: Dictionary) -> void:
	h["status"] = "road"
	_add_wanderer(h)


func _add_wanderer(h: Dictionary) -> void:
	wanderers.append({"hero_id": h["id"], "name": h["name"], "kind": h["kind"], "tier": h["tier"], "scars": h["scars"].duplicate(), "grafts": h["grafts"].duplicate(), "gear": h["gear"], "appearances": 0, "dead": false})


func elder_seat(city: String) -> Dictionary:
	for s in seats:
		if s["kind"] == "elder" and s["city"] == city:
			return s
	var s := {"kind": "elder", "city": city, "holder": -1, "since": 0}
	seats.append(s)
	return s


## A fallen Register begins again: unlocks carry, nothing else.
static func begin_anew(old: Register) -> Register:
	var r := Register.new()
	r.unlocks = old.unlocks.duplicate()
	r.unlocks["registers_fallen"] = int(r.unlocks.get("registers_fallen", 0)) + 1
	return r


## Retires a hero into the Elder seat of their origin city if it is empty.
func retire_to_seat(h: Dictionary) -> bool:
	var s := elder_seat(h["origin"])
	if s["holder"] != -1:
		return false
	s["holder"] = h["id"]
	s["since"] = generation
	h["status"] = "seated"
	return true


func seat_holds(city: String) -> bool:
	for s in seats:
		if s["kind"] == "elder" and s["city"] == city and s["holder"] != -1:
			return true
	return false


# ---------------------------------------------------------------- save and load

func to_dict() -> Dictionary:
	return {"generation": generation, "heroes": heroes, "wanderers": wanderers, "seats": seats, "fallen": fallen, "next_id": next_id, "chronicle": chronicle, "world": world.to_dict(), "unlocks": unlocks}


func save(path: String = PATH) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(to_dict(), "\t"))
	f.close()
	return true


static func load_from(path: String = PATH) -> Register:
	var r := Register.new()
	var text := FileAccess.get_file_as_string(path)
	if text == "":
		return r
	var d: Dictionary = JSON.parse_string(text)
	r.generation = int(d["generation"])
	r.heroes = d["heroes"]
	r.wanderers = d["wanderers"]
	r.seats = d["seats"]
	r.fallen = d["fallen"]
	r.next_id = int(d["next_id"])
	r.chronicle = d.get("chronicle", [])
	r.world = WorldState.from_dict(d.get("world", {}))
	r.unlocks = d.get("unlocks", {})
	for h in r.heroes:
		h["id"] = int(h["id"])
		h["tier"] = int(h["tier"])
		h["campaigns"] = int(h["campaigns"])
		h["age_steps"] = int(h["age_steps"])
	return r
