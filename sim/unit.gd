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
	if gear_key != "":
		u.gear_ability = SimData.gear()[gear_key]["ability"]
	return u


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
	return out


func tick_cooldowns() -> void:
	for key in cooldowns.keys():
		cooldowns[key] = maxi(0, cooldowns[key] - 1)


func tick_conditions() -> void:
	for key in conditions.keys():
		conditions[key] = maxi(0, conditions[key] - 1)


func to_dict() -> Dictionary:
	return {
		"id": id, "side": side, "kind": kind, "name": name,
		"pos": [pos.x, pos.y], "hp": hp, "max_hp": max_hp, "speed": speed,
		"downed": downed, "conditions": conditions.duplicate(), "cooldowns": cooldowns.duplicate(),
		"flags": flags.keys(),
	}
