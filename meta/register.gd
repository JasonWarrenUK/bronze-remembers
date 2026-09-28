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
var founded_cities: Array = []    # world memory: cities raised by ambitions


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
			var eff: Dictionary = s.get("effects", {"budget": 1})
			var bonus: int = int(eff.get("budget", 0))
			if int(s.get("contested_until", 0)) > generation:
				bonus = bonus / 2
			b += bonus
	return b


func gates_open_cities() -> Dictionary:
	var out: Dictionary = {}
	for s in seats:
		if s["holder"] != -1 and s.get("effects", {"gates_open": true}).get("gates_open", false):
			out[s.get("city", "")] = true
	return out


func emeriti_for_run() -> Array:
	var out: Array = []
	for h in heroes:
		if h["status"] == "emeritus":
			out.append({"name": h["name"], "seat": h.get("seat", "a seat"), "appearances": 0})
	return out


## The world abroad: other empires falling raise mercenary availability until a final collapse removes them.
## Rises with the Tongue stage and the generation, falls to nothing once Tongue is Gone.
func mercenaries_available() -> int:
	if not has_unlock("reed_recruits"):
		return 0
	var tongue := world.stage_num("tongue")
	if tongue >= 4:
		return 0
	return mini(3, tongue + generation / 4)


func new_mercenary() -> Dictionary:
	var classes: Array = SimData.units()["origins"]["mercenary"]["classes"]
	var kind: String = classes[(next_id * 3) % classes.size()]
	if not SimData.units()["heroes"].has(kind):
		kind = "spear"
	var names := ["Ahhiyawa", "Sherden", "Lukka", "Peleset", "Denyen", "Tjeker"]
	var m := new_hero(kind, names[next_id % names.size()] + str(next_id), "mercenary", "", 1)
	m["traits"].append("Foreign spear")
	return m


func narrator() -> String:
	for s in seats:
		if s["holder"] != -1 and s.get("effects", {}).get("narrator", false):
			return hero_by_id(s["holder"]).get("name", "")
	return ""


func ambitions_available() -> Array:
	var out: Array = ["archive"]
	for pair in [["hold_ford_ambition", "ford"], ["ships_ambition", "ships"], ["drown_ambition", "drown"], ["found_ambition", "found"]]:
		if has_unlock(pair[0]):
			out.append(pair[1])
	if world.institutions["temple"]["state"] == "Burned":
		out.erase("drown")
	return out


func testimony_bonus() -> int:
	var n := 0
	for s in seats:
		if s["holder"] != -1:
			n += int(s.get("effects", {}).get("testimony_range", 0))
	return n


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
		h["traits"] = rec.get("traits", []).duplicate()
		h["ink"] = int(rec.get("ink", 0))
		h["campaigns"] += 1
		h["deeds"] += _deeds_for(run, rec["name"])
		h["tier"] += int(rec.get("tier_bonus", 0))
		for d in run.deeds:
			if d["recorded"]:
				for tag in d.get("tags", []):
					h["deed_tags"] = h.get("deed_tags", [])
					h["deed_tags"].append(tag)
					_earn_unlock(tag)
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
	var dealings := run.dealings()
	if not dealings.get("founded_city", {}).is_empty():
		founded_cities.append(dealings["founded_city"])
	world.record_run(dealings)
	for s in seats:
		if s["holder"] != -1 and s.get("holds", "") != "" and int(s.get("contested_until", 0)) <= generation:
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


# ---------------------------------------------------------------- unlocks

func _earn_unlock(tag: String) -> void:
	var data: Dictionary = SimData.load_json("unlocks")
	for key in data["order"]:
		var u: Dictionary = data["unlocks"][key]
		if tag == u["deed"] or tag.begins_with(u["deed"]):
			var progress: Dictionary = unlocks.get("progress", {})
			progress[key] = int(progress.get(key, 0)) + 1
			unlocks["progress"] = progress
			if progress[key] >= int(u["count"]) and not unlocks.get("earned", {}).has(key):
				var earned: Dictionary = unlocks.get("earned", {})
				earned[key] = generation
				unlocks["earned"] = earned


func next_unlock() -> Dictionary:
	var data: Dictionary = SimData.load_json("unlocks")
	for key in data["order"]:
		if not unlocks.get("earned", {}).has(key):
			var u: Dictionary = data["unlocks"][key].duplicate()
			u["progress"] = int(unlocks.get("progress", {}).get(key, 0))
			return u
	return {}


func has_unlock(key: String) -> bool:
	return unlocks.get("earned", {}).has(key)


# ---------------------------------------------------------------- seats

## Seats a hero may take now: pool seats they qualify for, recipes whose anchors they satisfy.
func seat_offers(h: Dictionary) -> Array:
	var data: Dictionary = SimData.load_json("seats")
	var out: Array = []
	var band := band_index(h["tier"])
	for key in data["pools"]:
		var pool: Dictionary = data["pools"][key]
		if band < int(pool["band"]):
			continue
		var req: Dictionary = pool.get("requires", {})
		if req.has("institution") and world.institutions[req["institution"]]["state"] == req.get("not_state", ""):
			continue
		if req.has("ink_min") and int(h.get("ink", 0)) < int(req["ink_min"]):
			continue
		if req.has("graft_min") and h["grafts"].size() < int(req["graft_min"]):
			continue
		if req.has("false_lines_max") and int(h.get("false_lines", 0)) > int(req["false_lines_max"]):
			continue
		var place: String = h["origin"] if pool["per"] == "city" else pool["per"]
		out.append({"id": key, "name": pool["name"].replace("{city}", place).replace("{landmark}", "the road"), "place": place, "effects": pool["effects"], "text": pool["text"], "holder": _holder(key, place), "recipe": false})
	for r in data["recipes"]:
		if band < int(r["band"]) or not _anchors_met(h, r["anchors"]) or not _world_met(r.get("world", {}), r["id"]):
			continue
		out.append({"id": r["id"], "name": r["name"].replace("{city}", h["origin"]), "place": h["origin"], "effects": r["effects"], "text": r["text"], "holder": _holder(r["id"], h["origin"]), "recipe": true})
	return out


static func band_index(tier: int) -> int:
	var idx := 0
	for i in range(BANDS.size()):
		if tier >= BANDS[i][1]:
			idx = i
	return idx


func _anchors_met(h: Dictionary, anchors: Array) -> bool:
	var tags: Array = h.get("deed_tags", [])
	var counts: Dictionary = {}
	for t in tags:
		counts[t] = int(counts.get(t, 0)) + 1
	var needed: Dictionary = {}
	for a in anchors:
		var parts: Array = a.split(":")
		match parts[0]:
			"deed":
				var tag: String = a.substr(5)
				if tag.begins_with("testified:"):
					if h["deeds"] < int(tag.substr(10)):
						return false
				else:
					needed[tag] = int(needed.get(tag, 0)) + 1
			"graft":
				if parts[1] == "bronze" and h["grafts"].is_empty():
					return false
				if parts[1] == "sea_or_bronze" and h["grafts"].is_empty() and not _has_sea_scar(h):
					return false
			"scar":
				if parts[1] == "sea" and not _has_sea_scar(h):
					return false
			"origin":
				if parts[1] == "coast" and not _origin_band(h) == "coast":
					return false
			"false_lines":
				if int(h.get("false_lines", 0)) > int(parts[1]):
					return false
			"ink":
				if int(h.get("ink", 0)) < int(parts[1]):
					return false
	for tag in needed:
		var have := 0
		for t in counts:
			if t == tag or t.begins_with(tag):
				have += counts[t]
		if have < needed[tag]:
			return false
	return true


func _has_sea_scar(h: Dictionary) -> bool:
	for sc in h["scars"]:
		if SimData.load_json("scars").get(sc, {}).get("sources", []).has("sea"):
			return true
	return false


func _origin_band(h: Dictionary) -> String:
	return SimData.load_json("world")["cities"].get(h["origin"], {}).get("band", "coast" if h["origin"] == "mercenary" else "river")


func _world_met(cond: Dictionary, recipe_id: String) -> bool:
	if cond.has("no_seat") and _holder(cond["no_seat"], "") != -1:
		return false
	if cond.has("smiths_not") and world.institutions["smiths"]["state"] == cond["smiths_not"]:
		return false
	if cond.has("sea_stage_min") and world.stage_num("sea") < int(cond["sea_stage_min"]):
		return false
	return true


func _holder(seat_id: String, place: String) -> int:
	for s in seats:
		if s["kind"] == seat_id and (place == "" or s.get("city", "") == place):
			return int(s["holder"])
	return -1


## Takes a seat. If held, succession by deed (more testified deeds wins) or by writ (Law at most Broken).
func take_seat(h: Dictionary, offer: Dictionary, route: String = "deed") -> Dictionary:
	var result := {"taken": false, "route": route, "contested": false, "emeritus": -1}
	var seat: Dictionary = {}
	for s in seats:
		if s["kind"] == offer["id"] and s.get("city", "") == offer["place"]:
			seat = s
	if seat.is_empty():
		seat = {"kind": offer["id"], "city": offer["place"], "holder": -1, "since": 0, "effects": offer["effects"], "name": offer["name"], "contested_until": 0, "holds": offer["effects"].get("hold", "")}
		seats.append(seat)
	if seat["holder"] != -1:
		var holder := hero_by_id(seat["holder"])
		var wins := false
		if route == "writ":
			wins = world.stage_num("law") <= 2
			if wins:
				world.institutions["palace"]["kept_runs"] = maxi(0, world.institutions["palace"]["kept_runs"] - 1)
		else:
			wins = h["deeds"] > int(holder.get("deeds", 0))
		if not wins:
			return result
		holder["status"] = "emeritus"
		holder["grudges"] = holder.get("grudges", [])
		holder["grudges"].append("unseated by %s" % h["name"])
		result["emeritus"] = holder["id"]
		result["contested"] = true
		seat["contested_until"] = generation + 1
	seat["holder"] = h["id"]
	seat["since"] = generation
	seat["effects"] = offer["effects"]
	seat["name"] = offer["name"]
	seat["holds"] = offer["effects"].get("hold", "")
	h["status"] = "seated"
	h["seat"] = offer["name"]
	if offer["effects"].has("arc_step"):
		var key: String = offer["effects"]["arc_step"]
		var inst: Dictionary = world.institutions[key]
		if inst["state"] != "Standing" and inst["step"] < 3:
			inst["step"] += 1
	result["taken"] = true
	return result


func elder_seat(city: String) -> Dictionary:
	for s in seats:
		if s["kind"] == "elder" and s["city"] == city:
			return s
	var s := {"kind": "elder", "city": city, "holder": -1, "since": 0, "effects": {"gates_open": true, "budget": 1}, "name": "Elder of %s" % city, "contested_until": 0, "holds": ""}
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
	return {"generation": generation, "heroes": heroes, "wanderers": wanderers, "seats": seats, "fallen": fallen, "next_id": next_id, "chronicle": chronicle, "world": world.to_dict(), "unlocks": unlocks, "founded_cities": founded_cities}


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
	r.founded_cities = d.get("founded_cities", [])
	for h in r.heroes:
		h["id"] = int(h["id"])
		h["tier"] = int(h["tier"])
		h["campaigns"] = int(h["campaigns"])
		h["age_steps"] = int(h["age_steps"])
	return r
