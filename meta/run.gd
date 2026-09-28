class_name Run
extends RefCounted
## One campaign run: the squad, the days, the writ, the deeds, the injuries,
## the chapters of the ambition. Pure data; saved as JSON between nodes.

const ROAD_KILLS_DAYS := 6          # untreated severe injury is fatal after this many days
const TESTIMONY_RANGE_BASE := 2     # days a deed travels per point of significance
const THROAT := 5                   # ink lines at which the Temple calls

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
var writ: Dictionary = {"issued_by": "kessuwat", "report_due": 6, "outlaw": false, "reports": 0}
var season: Dictionary = {}
var flooded: bool = false
var revealed: Dictionary = {}       # node ids revealed by events
var pending_event: Dictionary = {}  # event awaiting a choice at this node
var pending_fight: String = ""      # family of a fight forced by an event or a landmark
var pair_scores: Dictionary = {}    # "i:j" squad indices -> bond score this run
var scaling: Dictionary = {"extra_enemies": 0, "extra_hp": 0}
var wanderers: Array = []           # from the Register: {name, kind, tier, scars, grafts, gear, appearances, dead}
var wanderer_here: Dictionary = {}  # a wanderer met at this node
var wanderer_ally: Dictionary = {}  # a wanderer fighting the next battle
var wanderer_deaths: Array = []
var favours: Array = []             # {wanderer, node, done}
var emeriti: Array = []             # {name, seat, appearances} unseated holders with a grudge
var tablets: bool = false
var log: Array = []
var state: String = "ongoing"       # ongoing | won | lost
var milestone_reached: bool = false
var pending_fitting: Array = []     # hero indices waiting at a Smiths' node


func _init(seed_: int = 1, ambition_key: String = "archive", founded: Array = []) -> void:
	seed = seed_
	rng = SimRng.new(seed_)
	world = WorldGen.generate(seed_, "Whole", founded)
	ambition = SimData.load_json("ambitions")[ambition_key].duplicate(true)
	ambition["key"] = ambition_key
	season = SimData.load_json("world")["season"].duplicate()
	writ["report_due"] = int(season["report_every"])
	at = "kessuwat"
	visited[at] = true
	_log("Mustered at %s under writ. The archive at Tarhuna is named." % world["nodes"][at]["name"])


func _log(text: String) -> void:
	log.append({"day": day, "text": text})


## Applies the world's stages at run start: the writ's range, the season's tide, what the road holds.
func apply_world(w: WorldState) -> void:
	for t in WorldState.TRACKS:
		stages[t] = w.stage_num(t)
	weather = w.weather()
	# Law: reports come due faster as the writ's range shrinks; at Lost the Palace issues nothing.
	var every: int = int(season["report_every"]) - stages["law"]
	season["report_every"] = maxi(2, every)
	writ["report_due"] = season["report_every"]
	if stages["law"] >= 3:
		writ["report_due"] = 999
		writ["raiser"] = "a city that still answers"
	# Sea: the tide floods earlier and the ship leaves sooner.
	season["tide_floods"] = maxi(6, int(season["tide_floods"]) - 3 * stages["sea"])
	season["ship_sails"] = maxi(12, int(season["ship_sails"]) - 2 * stages["sea"])
	# Custom: guest-right shrinks; rest at ordinary hearths heals less past Strained.
	# Rite: Temple healing costs more; handled where healing is bought.
	_log("The weather: " + " ".join(weather))
	apply_tongue()


## Tongue: recruits from another band of the country arrive mismatched from Strained on; bonds form slower until they are understood.
func apply_tongue() -> void:
	if stages["tongue"] < 1:
		return
	var home_band: String = SimData.load_json("world")["cities"]["kessuwat"]["band"]
	for h in squad:
		var band: String = SimData.load_json("world")["cities"].get(h.get("origin", "kessuwat"), {}).get("band", home_band)
		if band != home_band or h.get("origin", "") == "mercenary":
			h["mismatched"] = true
			_log("%s speaks the coast tongue. Orders will be slow until the squad learns it." % h["name"])


## Garbled text: from Tongue Broken on, letters and event texts lose words for a squad with no reader.
func garble(text: String) -> String:
	if stages["tongue"] < 2 or _has_reader():
		return text
	var words := text.split(" ")
	var out: Array = []
	for i in range(words.size()):
		if (i * 7 + seed) % (5 - mini(stages["tongue"] - 2, 2)) == 0 and words[i].length() > 3:
			out.append("[..]")
		else:
			out.append(words[i])
	return " ".join(out)


func _has_reader() -> bool:
	for h in fighters():
		if int(h.get("sorcery_tier", -1)) >= 0 or h.get("origin", "") == "mercenary":
			return true
	return false


## Away from the sorcerer's own band of the country, at Tongue Broken on, a writing can misfire: the field's script is not theirs.
func sorcery_misfires_here(h: Dictionary) -> bool:
	if stages["tongue"] < 2:
		return false
	var here: String = node().get("flags", {}).get("band", "")
	if here == "":
		var road: Array = node().get("road", [])
		if road.size() == 2:
			here = SimData.load_json("world")["cities"][road[0]]["band"]
	var home: String = SimData.load_json("world")["cities"].get(h.get("origin", "kessuwat"), {}).get("band", "river")
	return here != "" and here != home


## What this run did, for the institutions.
func dealings() -> Dictionary:
	var d := tally.duplicate(true)
	d["ambition"] = tally.get("ambition_done", "")
	d["founded_city"] = founded_city
	return d


# ---------------------------------------------------------------- squad

func add_hero(kind: String, name: String, gear: String = "") -> Dictionary:
	var d: Dictionary = SimData.units()["heroes"][kind]
	var h := {"kind": kind, "name": name, "gear": gear, "hp": d["hp"], "max_hp": d["hp"], "alive": true, "left": false, "scars": [], "grafts": [], "injury": {}, "deeds": 0, "ink": 0, "called": false, "clay": 0, "sorcery_tier": -1, "memory": {}, "false_lines": 0, "origin": "kessuwat", "mismatched": false}
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
		if h.has("mould_debt") and h["alive"]:
			h["mould_debt"]["days"] -= days
			if at == h["mould_debt"]["owed_at"]:
				tally["moulds_honoured"] += 1
				h.erase("mould_debt")
				_log("%s returns to the Smiths and the mould is honoured." % h["name"])
				_deed("%s honoured the mould" % h["name"], 2, {"deeds": []}, ["mould_honoured"])
			elif h["mould_debt"]["days"] <= 0:
				tally["moulds_defaulted"] += 1
				if node().get("flags", {}).get("band", "") == "coast":
					tally["coastal_callbacks"] += 1
				_log("%s did not return to the Smiths. The bronze is called back: the %s fails." % [h["name"], SimData.load_json("grafts")[h["mould_debt"]["graft"]]["name"]])
				h["grafts"].erase(h["mould_debt"]["graft"])
				h["injury"] = {"severity": "severe", "location": SimData.load_json("grafts")[h["mould_debt"]["graft"]]["location"], "days_left": ROAD_KILLS_DAYS, "by": "smiths"}
				h.erase("mould_debt")
	for h in squad:
		if h["injury"].get("severity", "") == "severe" and h["alive"]:
			h["injury"]["days_left"] = h["injury"].get("days_left", ROAD_KILLS_DAYS) - days
			if h["injury"]["days_left"] <= 0:
				h["alive"] = false
				_log("%s died on the road of an untreated wound." % h["name"])
	_log("Day %d: reached %s." % [day, node()["name"]])
	var n := node()
	# The writ: a report is owed at a walled city by the due day.
	if n["kind"] == "city" and n["flags"].get("walled", false) and not writ["outlaw"]:
		writ["reports"] += 1
		tally["reports_kept"] += 1
		writ["report_due"] = day + int(season["report_every"])
		_log("Report made at %s. The next is owed by day %d." % [n["name"], writ["report_due"]])
	elif day > int(writ["report_due"]) and not writ["outlaw"]:
		writ["outlaw"] = true
		tally["reports_defaulted"] += 1
		_log("A report went unmade. The squad is outlaw to the Palace: the gates are shut to it.")
	# The season: the tide floods the Drowned Mile, the ship sails.
	if not flooded and day >= int(season["tide_floods"]):
		flooded = true
		_log("Word comes up the road: the tide has taken the Drowned Mile.")
	if day > int(season["ship_sails"]) and state == "ongoing":
		state = "lost"
		_log("The ship has sailed from Lower Ugra. The archive stays.")
		return true
	# Landmarks host their own kind of fight; events wait for a choice.
	pending_fight = ""
	pending_event = {}
	_check_milestone()
	if n["kind"] == "landmark" and not n.get("cleared", false) and not milestone_reached:
		var fam: String = SimData.load_json("world")["landmark_fights"].get(n.get("landmark", ""), "none")
		if fam != "none":
			pending_fight = fam
	if n["kind"] == "drowned_town" and flooded and not n.get("cleared", false):
		pending_fight = "sea"
	if n["kind"] == "battle" and not n.get("cleared", false):
		pending_fight = "levies"
	if n["kind"] == "event" and not n.get("cleared", false):
		pending_event = _draw_event()
	wanderer_here = {}
	if n["kind"] == "city" and not emeriti.is_empty() and pending_event.is_empty() and rng.range_int(1, 2) == 1:
		var em: Dictionary = emeriti[0]
		if em["appearances"] < 2:
			em["appearances"] += 1
			var key := "emeritus_levy" if em["appearances"] == 1 else "emeritus_deal"
			var e: Dictionary = SimData.load_json("events")[key].duplicate(true)
			e["key"] = key
			e["text"] = e["text"].replace("{emeritus}", em["name"])
			for opt in e["options"]:
				if opt["effects"].has("deed"):
					opt["effects"]["deed"][0] = opt["effects"]["deed"][0].replace("{emeritus}", em["name"])
			pending_event = e
			_log("%s, who held %s, is at the gate of %s." % [em["name"], em["seat"], n["name"]])
	if (n["kind"] == "rest" or n["kind"] == "city") and not wanderers.is_empty() and rng.range_int(1, 3) == 1:
		for w in wanderers:
			if not w["dead"] and w["appearances"] < 3:
				wanderer_here = w
				w["appearances"] += 1
				_log("%s, once of the levy, is here at %s." % [w["name"], n["name"]])
				break
			elif not w["dead"] and w["appearances"] >= 3:
				w["dead"] = true
				wanderer_deaths.append(w["name"])
				_log("%s is found dead at %s, wrapped in a cloak, the old %s beside them." % [w["name"], n["name"], w["gear"] if w["gear"] != "" else "kit"])
				if w["gear"] != "":
					for h in fighters():
						if h["gear"] == "":
							h["gear"] = w["gear"]
							_log("%s takes up %s's %s." % [h["name"], w["name"], w["gear"]])
							break
				break
	for f in favours:
		if not f["done"] and f["node"] == at:
			f["done"] = true
			_deed("Kept a promise to %s" % f["wanderer"], 2, {"deeds": []})
	return true


## The wanderer here fights beside the squad in its next battle.
func wanderer_joins() -> void:
	if wanderer_here.is_empty():
		return
	wanderer_ally = wanderer_here
	_log("%s will stand with the squad once more." % wanderer_here["name"])
	wanderer_here = {}


## The wanderer asks a favour: visit a named node before the run ends.
func wanderer_favour() -> void:
	if wanderer_here.is_empty():
		return
	var candidates: Array = []
	for id in world["nodes"]:
		var n: Dictionary = world["nodes"][id]
		if (n["kind"] == "landmark" or n["kind"] == "rest") and id != at:
			candidates.append(id)
	if candidates.is_empty():
		return
	var target: String = candidates[rng.range_int(0, candidates.size() - 1)]
	favours.append({"wanderer": wanderer_here["name"], "node": target, "done": false})
	_log("%s asks the squad to go by %s, for their sake." % [wanderer_here["name"], world["nodes"][target]["name"]])
	wanderer_here = {}


func _draw_event() -> Dictionary:
	var events: Dictionary = SimData.load_json("events")
	var keys: Array = events.keys()
	var key: String = keys[rng.range_int(0, keys.size() - 1)]
	var e: Dictionary = events[key].duplicate(true)
	e["key"] = key
	return e


## Resolves the pending event with option index. May set pending_fight.
func choose(option: int) -> Dictionary:
	if pending_event.is_empty():
		return {}
	var opt: Dictionary = pending_event["options"][option]
	var fx: Dictionary = opt["effects"]
	var n := node()
	n["cleared"] = true
	_log("%s: %s." % [pending_event["name"], opt["label"]])
	if option == 1 and fighters().size() > 0:
		_plant_fixation(fighters()[rng.range_int(0, fighters().size() - 1)], "event:%s" % pending_event["key"])
	if fx.has("days"):
		day += int(fx["days"])
	if fx.has("heal"):
		for h in fighters():
			h["hp"] = mini(h["max_hp"], h["hp"] + int(fx["heal"]))
	if fx.has("deed"):
		_deed(fx["deed"][0], int(fx["deed"][1]), {"deeds": []})
	if fx.has("report_extend"):
		writ["report_due"] = int(writ["report_due"]) + int(fx["report_extend"])
	if fx.has("reveal"):
		var count := 0
		for id in world["nodes"]:
			if not visited.has(id) and not revealed.has(id) and count < int(fx["reveal"]):
				revealed[id] = true
				count += 1
	if fx.has("tablet_carried"):
		_deed("Carried a stranger's tablet to the scribes", 1, {"deeds": []})
	if fx.has("fit_on_road"):
		for h in squad:
			if h["alive"] and h["injury"].get("severity", "") == "severe":
				var grafts: Dictionary = SimData.load_json("grafts")
				for key in grafts:
					if grafts[key]["location"] == h["injury"]["location"] and not grafts[key].get("forbids_class", []).has(h["kind"]):
						fit_graft(h, key)
						break
	if fx.has("lie"):
		tally["lies"] += int(fx["lie"])
	if fx.has("grudge_settled") and not emeriti.is_empty():
		_log("%s is heard out. The grudge is not gone, but it sleeps." % emeriti[0]["name"])
		emeriti.pop_front()
	if fx.has("fight"):
		pending_fight = fx["fight"]
	pending_event = {}
	return fx


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
	var families := [pending_fight if pending_fight != "" else "levies"]
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
		h["clay"] = u.clay
		if u.false_lines > int(h["false_lines"]):
			tally["lies"] += u.false_lines - int(h["false_lines"])
			tally["nudges"]["law"] = int(tally["nudges"].get("law", 0)) + (u.false_lines - int(h["false_lines"]))
			for i in range(u.false_lines - int(h["false_lines"])):
				_deed("%s wrote a thing true that was not" % h["name"], 1, {"deeds": []})
		h["false_lines"] = u.false_lines
		if not u.memory.is_empty():
			h["memory"] = u.memory.duplicate()
			var over: int = int(u.memory.get("used", 0)) - int(u.memory.get("base_charges", 1))
			if over >= 2:
				h["taken"] = true
				_log("%s is not %s any more. The bronze speaks with %s's voice." % [h["name"], h["name"], u.memory.get("ancestor", "the dead")])
			elif over >= 1:
				h["memory"]["possessed"] = true
				_log("%s's arm moves on its own in the fight. The old grudge is awake." % h["name"])
		h["unit_id_done"] = h["unit_id"]
		h.erase("unit_id")
	for h in fighters():
		for f in h.get("fixations", []):
			f["fights"] += 1
	for d in draws:
		var u := b.unit_by_id(d["unit"])
		var h := _hero_named(u.name)
		if h.is_empty():
			continue
		var by_family: String = SimData.units()["enemies"].get(d["by"], {}).get("family", "levies")
		_plant_fixation(h, "downed:%s" % by_family)
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
				if h.has("substitute"):
					var stand_in := _hero_named(h["substitute"])
					h.erase("substitute")
					if not stand_in.is_empty() and stand_in["alive"]:
						stand_in["alive"] = false
						h["scars"].append("substituted")
						_log("Death came for %s at %s and found %s, as the rite said." % [h["name"], node()["name"], stand_in["name"]])
						continue
				h["alive"] = false
				_log("%s died at %s." % [h["name"], node()["name"]])
	_score_pairs(b)
	_curdle_fixations()
	wanderer_ally = {}
	var named_kills := 0
	for e in b.enemies(false):
		if e.downed and e.named:
			named_kills += 1
	for e in b.enemies(false):
		if e.downed and e.named:
			_deed("Killed %s at %s" % [e.name, node()["name"]], 3, report, ["kill_named:%s" % e.family])
	if b.state == "won":
		var objective_tag := "survived:%s" % node()["name"] if b.objective["type"] == "survive" else "held:%s" % node()["name"]
		_deed("Held %s against %d" % [node()["name"], b.enemies(false).size()], 2 + named_kills, report, [objective_tag])
		if milestone:
			var ch: Dictionary = ambition["chapters"][chapter - 1]
			_deed(ch["title"], 4, report)
			match ch.get("on_complete", ""):
				"take_tablets":
					tablets = true
				"named_boards":
					var named := _hero_named(named_hero)
					if named.is_empty() or not named["alive"] or named.get("left", false):
						state = "lost"
						_log("The ship sails, and %s is not on it." % (named_hero if named_hero != "" else "the named one"))
						return report
					_deed("%s boarded at Lower Ugra" % named_hero, 5, report, ["boarded"])
				"drown_temple":
					tally["ambition_done"] = "drown_temple"
					_deed("Drowned the Temple at Ashkelu", 6, report, ["drowned_temple"])
				"found_city":
					founded_city = {"id": "pallanta_new", "name": "New Pallanta", "founder": fighters()[0]["name"] if fighters().size() > 0 else "the levy", "pos": [10, 7], "band": "upland", "walled": true}
					tally["ambition_done"] = "found_city"
					_deed("Founded %s" % founded_city["name"], 8, report, ["founded"])
			if chapter == ambition["chapters"].size():
				tally["archive_won"] += 1
				_deed("Carried the archive out", 5, report, ["archive_won"])
				_log("The tablets of Tarhuna are under seal in the squad's keeping.")
			for hh in squad:
				hh.erase("substitute")
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
			tally["archive_lost"] += 1
			_log("The tablets are lost to the water.")
			state = "lost"
	if not milestone:
		node()["cleared"] = true
		pending_fight = ""
	if fighters().is_empty():
		state = "lost"
		_log("Nobody left standing.")
	return report


## Pair scores: both survive +1, adjacent at the end +1, avenging a downed comrade +2.
func _score_pairs(b: SimBattle) -> void:
	var idx_of: Dictionary = {}
	for i in range(squad.size()):
		if squad[i].has("unit_id_done"):
			idx_of[squad[i]["unit_id_done"]] = i
	var downed_by: Dictionary = {}     # enemy id -> unit id it downed
	var killer_of: Dictionary = {}     # enemy id -> unit id that downed it
	for ev in b.events:
		if ev["type"] == "downed" and ev.get("by_id", -1) != -1:
			downed_by[ev["by_id"]] = ev["unit"]
		if ev["type"] == "downed" and ev.has("killer"):
			killer_of[ev["unit"]] = ev["killer"]
	var ids: Array = idx_of.keys()
	for x in range(ids.size()):
		for y in range(x + 1, ids.size()):
			var ua := b.unit_by_id(ids[x])
			var ub := b.unit_by_id(ids[y])
			if ua == null or ub == null:
				continue
			var score := 0
			if not ua.downed and not ub.downed:
				score += 1
				if SimGrid.distance(ua.pos, ub.pos) == 1:
					score += 1
			for enemy_id in downed_by:
				var victim: int = downed_by[enemy_id]
				var avenger: int = killer_of.get(enemy_id, -1)
				if (victim == ua.id and avenger == ub.id) or (victim == ub.id and avenger == ua.id):
					score += 2
			if score > 0:
				var ia: int = idx_of[ids[x]]
				var ib: int = idx_of[ids[y]]
				var key := "%d:%d" % [mini(ia, ib), maxi(ia, ib)]
				var current := int(pair_scores.get(key, 0))
				if (squad[ia].get("mismatched", false) or squad[ib].get("mismatched", false)) and current < 3:
					score = maxi(1, score / 2)
				pair_scores[key] = current + score
				if pair_scores[key] >= 3:
					for idx in [ia, ib]:
						if squad[idx].get("mismatched", false):
							squad[idx]["mismatched"] = false
							_log("%s is understood now." % squad[idx]["name"])


func _deed(text: String, significance: int, report: Dictionary, tags: Array = []) -> void:
	var d := {"text": text, "significance": significance, "day": day, "node": at, "recorded": false, "tags": tags}
	for tag in tags:
		_resolve_fixations(tag)
	deeds.append(d)
	report["deeds"].append(d)
	# Channel 1: the deed travels to a scribal node within reach.
	if _scribal_within(significance * TESTIMONY_RANGE_BASE + testimony_bonus):
		d["recorded"] = true
		tally["truth"] += 1


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
var elder_cities: Dictionary = {}   # cities whose Elder seat is held: gates never shut
var testimony_bonus: int = 0
var stages: Dictionary = {"law": 0, "rite": 0, "custom": 0, "tongue": 0, "sea": 0}   # track stage numbers at run start
var weather: Array = []             # the Chronicle's weather lines for this run
var tally: Dictionary = {"reports_kept": 0, "reports_defaulted": 0, "faith": 0, "sin": 0, "truth": 0, "lies": 0, "grafts_fitted": 0, "moulds_honoured": 0, "moulds_defaulted": 0, "archive_won": 0, "archive_lost": 0, "coastal_callbacks": 0, "nudges": {}}


func gates_shut() -> bool:
	return writ["outlaw"] and node()["kind"] == "city" and node()["flags"].get("walled", false) and not elder_cities.has(at)


func testify() -> int:
	if not node()["flags"].get("scribal", false) or gates_shut():
		return 0
	var n := 0
	for d in deeds:
		if not d["recorded"]:
			d["recorded"] = true
			tally["truth"] += 1
			n += 1
	if n > 0:
		_log("%d deeds testified at %s." % [n, node()["name"]])
	return n


# ---------------------------------------------------------------- fixations

func _plant_fixation(h: Dictionary, planted_by: String) -> void:
	var fx: Dictionary = SimData.load_json("fixations")
	for key in fx:
		if fx[key]["planted_by"] == planted_by:
			for existing in h.get("fixations", []):
				if existing["key"] == key:
					return
			if h.get("traits", []).has(fx[key]["trait"]) or h.get("traits", []).has(fx[key]["curdle"]):
				return
			if not h.has("fixations"):
				h["fixations"] = []
			h["fixations"].append({"key": key, "fights": 0})
			_log("%s cannot stop thinking about it: %s." % [h["name"], fx[key]["name"].to_lower()])
			return


func _resolve_fixations(tag: String) -> void:
	var fx: Dictionary = SimData.load_json("fixations")
	for h in fighters():
		var keep: Array = []
		for f in h.get("fixations", []):
			var def: Dictionary = fx[f["key"]]
			if tag.begins_with(def["resolves_on"]):
				if not h.has("traits"):
					h["traits"] = []
				h["traits"].append(def["trait"])
				h["tier_bonus"] = int(h.get("tier_bonus", 0)) + 1
				_log("%s's fixation resolves: %s." % [h["name"], def["trait"]])
			else:
				keep.append(f)
		h["fixations"] = keep


## Fixations that sat through three fights curdle.
func _curdle_fixations() -> void:
	var fx: Dictionary = SimData.load_json("fixations")
	for h in squad:
		var keep: Array = []
		for f in h.get("fixations", []):
			if f["fights"] >= 3:
				if not h.has("traits"):
					h["traits"] = []
				h["traits"].append(fx[f["key"]]["curdle"])
				_log("%s's fixation curdles: %s." % [h["name"], fx[f["key"]]["curdle"]])
			else:
				keep.append(f)
		h["fixations"] = keep


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
	if node()["flags"].get("smiths", false) == false or h["injury"].get("severity", "") != "severe" or gates_shut():
		return []
	var out: Array = []
	var grafts: Dictionary = SimData.load_json("grafts")
	for key in grafts:
		if grafts[key]["location"] == h["injury"]["location"] and not grafts[key].get("forbids_class", []).has(h["kind"]):
			out.append(key)
	return out


func fit_graft(h: Dictionary, key: String) -> void:
	tally["grafts_fitted"] += 1
	h["mould_debt"] = {"owed_at": node()["city"] if node().has("city") else at, "days": 8, "graft": key}
	h["grafts"].append(key)
	h["injury"] = {}
	h["hp"] = h["max_hp"]
	_log("%s is fitted: %s. %s" % [h["name"], SimData.load_json("grafts")[key]["name"], SimData.load_json("grafts")[key]["text"]])
	_deed("%s remade in bronze" % h["name"], 3, {"deeds": []}, ["graft"])


func refuse_graft(h: Dictionary) -> void:
	h["left"] = true
	_log("%s refuses the bronze and stays behind at %s." % [h["name"], node()["name"]])


# ---------------------------------------------------------------- rest

## The Temple heals for ink: full HP and cured Wound-like states, at a cost in lines that rises with Rite.
func temple_heal() -> bool:
	var n := node()
	if n["kind"] != "city" or not n["flags"].get("temple", false) or gates_shut():
		return false
	if stages["rite"] >= 3:
		_log("The Temple at %s has stopped healing." % n["name"])
		return false
	var cost := 1 + maxi(0, stages["rite"] - 1)
	for h in fighters():
		if h["hp"] < h["max_hp"]:
			h["hp"] = h["max_hp"]
			h["ink"] += cost
			_log("%s is healed at the Temple: %d more line%s of ink." % [h["name"], cost, "s" if cost > 1 else ""])
	tally["faith"] += 1
	day += 1
	_check_calls()
	_resolve_fixations("temple")
	return true


## Heroes at the throat are called. Answering is faith; ignoring is sin, every time.
func _check_calls() -> void:
	for h in fighters():
		if h["ink"] >= THROAT and not h["called"]:
			h["called"] = true
			_log("The ink has reached %s's throat. The Temple calls." % h["name"])


func answer_call(h: Dictionary) -> void:
	if not h["called"]:
		return
	h["left"] = true
	h["answered"] = true
	tally["faith"] += 2
	_log("%s goes to the Temple, as the ink asks." % h["name"])
	_deed("%s answered the ink" % h["name"], 2, {"deeds": []})


func ignore_call(h: Dictionary) -> void:
	if not h["called"]:
		return
	tally["sin"] += 1
	h["called"] = false
	h["ink"] += 1
	_log("%s does not answer. The lines climb." % h["name"])


## Burn the ink off at any hearth: a scar and the Temple's enmity.
func burn_ink(h: Dictionary) -> void:
	if h["ink"] <= 0:
		return
	h["ink"] = 0
	h["called"] = false
	if not h["scars"].has("burned_ink"):
		h["scars"].append("burned_ink")
	tally["sin"] += 3
	_log("%s burns the ink off. The skin will not forget, and neither will the Temple." % h["name"])
	_deed("%s burned the ink" % h["name"], 2, {"deeds": []}, ["burned_ink"])


## The tithe: Temple cities demand it from Rite Broken on. Pay a day and a line each, or refuse.
func tithe_demanded() -> bool:
	var n := node()
	return n["kind"] == "city" and n["flags"].get("temple", false) and stages["rite"] >= 2 and not n.get("tithed", false)


func pay_tithe() -> void:
	node()["tithed"] = true
	day += 1
	for h in fighters():
		h["ink"] += 1
	tally["faith"] += 1
	_log("The tithe is paid at %s: a day and a line each." % node()["name"])
	_check_calls()


func refuse_tithe() -> void:
	node()["tithed"] = true
	tally["sin"] += 1
	_log("The tithe is refused at %s." % node()["name"])


## Substitution: at a Temple, name who dies instead if the ink-bearer's downing draws death this chapter.
func substitute(h: Dictionary, stand_in: Dictionary) -> bool:
	var n := node()
	if n["kind"] != "city" or not n["flags"].get("temple", false) or h == stand_in:
		return false
	h["substitute"] = stand_in["name"]
	h["ink"] += 3
	tally["sin"] += 2
	_log("A rite at %s: if death comes for %s this chapter, it will find %s." % [n["name"], h["name"], stand_in["name"]])
	_check_calls()
	return true


## Writ forgery: at Law Lost, a sorcerer writes the report the Palace no longer takes. A false line, a lie, and the clock resets.
func forge_report(h: Dictionary) -> bool:
	if stages["law"] < 3 or int(h.get("sorcery_tier", -1)) < 1 or int(h.get("clay", 0)) < 1:
		return false
	h["clay"] -= 1
	h["false_lines"] = int(h.get("false_lines", 0)) + 1
	tally["lies"] += 1
	writ["outlaw"] = false
	writ["report_due"] = day + int(season["report_every"])
	_log("%s forges the Sun's seal on a report nobody will read. The gates open anyway." % h["name"])
	_deed("%s forged a writ" % h["name"], 2, {"deeds": []}, ["forged"])
	return true


## Scribal cities: apprentice a hero (four days, sorcery tier 0, or one tier up) and buy clay (a day, two tablets each).
func apprentice(h: Dictionary) -> bool:
	if not node()["flags"].get("scribal", false) or gates_shut() or h.get("mute", false):
		return false
	if int(h["sorcery_tier"]) >= 2:
		return false
	day += 4
	h["sorcery_tier"] = int(h["sorcery_tier"]) + 1
	var titles := ["Copyist", "Tablet-hand", "Archivist"]
	_log("%s apprentices at %s for four days and leaves a %s." % [h["name"], node()["name"], titles[h["sorcery_tier"]]])
	_deed("%s learned to write true at %s" % [h["name"], node()["name"]], 2, {"deeds": []}, ["learned"])
	return true


func buy_clay() -> bool:
	if not node()["flags"].get("scribal", false) or gates_shut():
		return false
	day += 1
	for h in fighters():
		if int(h["sorcery_tier"]) >= 0:
			h["clay"] += 2
	_log("Blank clay bought at %s." % node()["name"])
	return true


func rest() -> void:
	if node()["kind"] != "rest" and node()["kind"] != "city":
		return
	if gates_shut():
		_log("The gates of %s are shut to outlaws. A night outside heals little." % node()["name"])
		for h in fighters():
			h["hp"] = mini(h["max_hp"], h["hp"] + 2)
	elif node()["kind"] == "rest" and stages["custom"] >= 2:
		_log("No guest-right here now. A cold night.")
		for h in fighters():
			h["hp"] = mini(h["max_hp"], h["hp"] + 3)
	else:
		for h in fighters():
			h["hp"] = h["max_hp"]
	day += 1
	_log("Rested a day at %s. Day %d of %d." % [node()["name"], day, int(season["days"])])
	if day > int(season["ship_sails"]) and state == "ongoing":
		state = "lost"
		_log("The ship has sailed from Lower Ugra. The archive stays.")


# ---------------------------------------------------------------- save, load, chronicle

func to_dict() -> Dictionary:
	return {
		"seed": seed, "rng_state": rng.state(), "chapter": chapter, "day": day, "at": at, "visited": visited,
		"squad": squad, "deeds": deeds, "writ": writ, "tablets": tablets, "log": log, "state": state,
		"milestone_reached": milestone_reached, "flooded": flooded, "revealed": revealed, "pending_fight": pending_fight,
		"cleared": _cleared_ids(), "pair_scores": pair_scores, "scaling": scaling, "wanderers": wanderers, "stages": stages, "weather": weather, "tally": tally, "season": season, "emeriti": emeriti,
		"wanderer_deaths": wanderer_deaths, "favours": favours, "elder_cities": elder_cities,
	}


func _cleared_ids() -> Array:
	var out: Array = []
	for id in world["nodes"]:
		if world["nodes"][id].get("cleared", false):
			out.append(id)
	return out


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
	r.flooded = d.get("flooded", false)
	r.revealed = d.get("revealed", {})
	r.pending_fight = d.get("pending_fight", "")
	for id in d.get("cleared", []):
		r.world["nodes"][id]["cleared"] = true
	r.pair_scores = d.get("pair_scores", {})
	r.scaling = d.get("scaling", {"extra_enemies": 0, "extra_hp": 0})
	r.wanderers = d.get("wanderers", [])
	r.wanderer_deaths = d.get("wanderer_deaths", [])
	r.favours = d.get("favours", [])
	r.elder_cities = d.get("elder_cities", {})
	r.stages = d.get("stages", r.stages)
	r.emeriti = d.get("emeriti", [])
	r.weather = d.get("weather", [])
	r.tally = d.get("tally", r.tally)
	r.season = d.get("season", r.season)
	return r


var narrator: String = ""
var named_hero: String = ""         # the ships ambition names one hero who must board
var founded_city: Dictionary = {}   # set when the founding ambition completes


## The Chronicle in the Scribes' voice.
func chronicle_stub() -> String:
	return Chronicle.for_run(self, narrator)


## The old stub, kept for the tests that read it.
func chronicle_stub_plain() -> String:
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
