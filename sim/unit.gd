class_name SimUnit
extends RefCounted
## One combatant. Heroes and enemies share this; `side` and `kind` tell them apart.

var id: int
var side: String            # "hero" or "enemy"
var kind: String            # key into data/units.json
var name: String
var pos: Vector2i
var facing: Vector2i = Vector2i(0, 1)
var hp: int
var max_hp: int
var speed: int = 3          # heroes: 2 to 5
var move: int = 3
var attack: int = 0         # enemies
var range: Array = [1, 1]   # enemies
var family: String = ""
var deck: String = ""
var named: bool = false
var basic: String = ""
var abilities: Array = []   # class ability keys
var gear_ability: String = ""
var cooldowns: Dictionary = {}     # ability key -> turns left
var conditions: Dictionary = {}    # "wound" | "bound" | "dread" -> turns left
var flags: Dictionary = {}         # round-scoped: brace, wall, taunt, stand, parry, unpushable, aim, shield_line, sink, swell
var downed: bool = false
var overkill: int = 0
var downed_by: String = ""
var ink: int = 0
var inert: bool = false            # objects on the field: never act, can be attacked
var scars: Array = []
var grafts: Array = []
var immune: Array = []             # condition names that cannot be applied
var longer: Dictionary = {}        # condition -> extra turns
var reach_delta: int = 0
var no_water: bool = false
var free_parry: bool = false
var face_nearest: bool = false
var shield_shoulder: bool = false
var bonus_vs: Dictionary = {}      # family -> extra damage
var permanent_stand: bool = false
var downing_severity: int = 0
var tide_immune: bool = false
var mute: bool = false
var clay: int = 0                  # tablets carried (sorcery)
var sorcery_tier: int = -1         # -1: no sorcery; 0 Copyist, 1 Tablet-hand, 2 Archivist
var false_lines: int = 0
var memory: Dictionary = {}        # bronze memory: {ancestor, ability, charges, used, full}
var possessed: bool = false
var contests: bool = false         # enemy officers, priests and scribes strike written lies


static func hero(id_: int, kind_: String, pos_: Vector2i, gear_key: String = "") -> SimUnit:
	var d: Dictionary = SimData.units()["heroes"][kind_]
	var u := SimUnit.new()
	u.id = id_
	u.side = "hero"
	u.kind = kind_
	u.name = d["name"]
	u.pos = pos_
	u.max_hp = d["hp"]
	u.hp = u.max_hp
	u.speed = d["speed"]
	u.move = d["move"]
	u.basic = d["basic"]
	u.abilities = d["abilities"].duplicate()
	u.sorcery_tier = int(d.get("sorcery_tier", -1))
	if gear_key != "":
		u.gear_ability = SimData.gear()[gear_key]["ability"]
	return u


static func object(id_: int, kind_: String, pos_: Vector2i) -> SimUnit:
	var d: Dictionary = SimData.units()["enemies"][kind_]
	var u := SimUnit.new()
	u.id = id_
	u.side = "hero"
	u.kind = kind_
	u.name = d["name"]
	u.pos = pos_
	u.max_hp = d["hp"]
	u.hp = u.max_hp
	u.family = d["family"]
	u.inert = true
	return u


## Applies a scar's modifiers from data/scars.json.
func apply_scar(key: String) -> void:
	var d: Dictionary = SimData.load_json("scars")[key]
	scars.append(key)
	speed += int(d.get("speed", 0))
	move += int(d.get("move", 0))
	max_hp += int(d.get("max_hp", 0))
	hp = mini(hp, max_hp)
	reach_delta += int(d.get("reach", 0))
	for c in d.get("immune", []):
		immune.append(c)
	for c in d.get("longer", {}):
		longer[c] = longer.get(c, 0) + int(d["longer"][c])
	free_parry = free_parry or d.get("free_parry", false)
	face_nearest = face_nearest or d.get("face_nearest", false)
	shield_shoulder = shield_shoulder or d.get("shield_shoulder", false)
	tide_immune = tide_immune or d.get("tide_immune", false)
	for f in d.get("bonus_vs", {}):
		bonus_vs[f] = bonus_vs.get(f, 0) + int(d["bonus_vs"][f])


## Applies a graft from data/grafts.json.
func apply_graft(key: String) -> void:
	var d: Dictionary = SimData.load_json("grafts")[key]
	grafts.append(key)
	speed += int(d.get("speed", 0))
	max_hp += int(d.get("max_hp", 0))
	hp = mini(hp, max_hp)
	if d.has("basic"):
		basic = d["basic"]
	if d.has("adds"):
		abilities.append(d["adds"])
	for c in d.get("immune", []):
		immune.append(c)
	no_water = no_water or d.get("no_water", false)
	permanent_stand = permanent_stand or d.get("stand", false)
	downing_severity += int(d.get("downing_severity", 0))
	mute = mute or d.get("mute", false)


static func enemy(id_: int, kind_: String, pos_: Vector2i) -> SimUnit:
	var d: Dictionary = SimData.units()["enemies"][kind_]
	var u := SimUnit.new()
	u.id = id_
	u.side = "enemy"
	u.kind = kind_
	u.name = d["name"]
	u.pos = pos_
	u.max_hp = d["hp"]
	u.hp = u.max_hp
	u.move = d["move"]
	u.attack = d["attack"]
	u.range = d["range"].duplicate()
	u.family = d["family"]
	u.deck = d["deck"]
	u.named = d.get("named", false)
	u.contests = d.get("contests", false)
	return u


func is_alive() -> bool:
	return not downed


func has(condition: String) -> bool:
	return conditions.get(condition, 0) > 0


func usable_abilities() -> Array:
	var out: Array = [basic]
	for key in abilities:
		if cooldowns.get(key, 0) == 0:
			out.append(key)
	if gear_ability != "" and cooldowns.get(gear_ability, 0) == 0:
		out.append(gear_ability)
	if sorcery_tier >= 0 and clay > 0:
		for key in SimData.abilities():
			var a: Dictionary = SimData.abilities()[key]
			if a.get("kind", "") == "sorcery" and int(a.get("tier", 0)) <= sorcery_tier and clay >= int(a.get("clay", 1)):
				out.append(key)
	if not memory.is_empty() and int(memory.get("charges", 0)) > 0:
		out.append("invoke")
	return out


func tick_cooldowns() -> void:
	for key in cooldowns.keys():
		cooldowns[key] = maxi(0, cooldowns[key] - 1)


func tick_conditions() -> void:
	for key in conditions.keys():
		conditions[key] = maxi(0, conditions[key] - 1)


func to_dict() -> Dictionary:
	return {
		"id": id, "side": side, "kind": kind, "name": name, "inert": inert, "scars": scars.duplicate(), "grafts": grafts.duplicate(),
		"pos": [pos.x, pos.y], "hp": hp, "max_hp": max_hp, "speed": speed,
		"downed": downed, "conditions": conditions.duplicate(), "cooldowns": cooldowns.duplicate(),
		"flags": flags.keys(),
	}
