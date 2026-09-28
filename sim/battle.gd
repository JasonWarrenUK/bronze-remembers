class_name SimBattle
extends RefCounted
## The deterministic battle state and rules. No nodes, no rendering, no global RNG.
## Every change appends an event to `events`; presentation replays them.
##
## Round: enemy cards are drawn per unit type present, then the queue is built from
## hero speed and card initiative. Units act in queue order. Heroes get one move and
## one action in either order and may delay behind a chosen unit. Enemies act their card.

const HERO_INIT_BASE := 110   # hero initiative = 110 - speed * 20 (speed 5 -> 10, speed 2 -> 70)

var grid: SimGrid
var rng: SimRng
var units: Array[SimUnit] = []
var events: Array[Dictionary] = []
var round: int = 0
var queue: Array[Dictionary] = []      # [{id, init}]
var queue_index: int = 0
var cards: Dictionary = {}             # enemy kind -> card drawn this round
var deck_state: Dictionary = {}        # enemy kind -> {draw: [], discard: []}
var state: String = "ongoing"          # ongoing | won | lost
var objective: Dictionary = {"type": "kill_all"}
var waves: Array = []                  # [{round, units: [{kind, pos}]}]
var turn: Dictionary = {}              # hero turn: {moved, acted, stride}
var hold_turns: int = 0
var _next_id: int = 1


func _init(w: int = 10, h: int = 10, seed: int = 1) -> void:
	grid = SimGrid.new(w, h)
	rng = SimRng.new(seed)


# ---------------------------------------------------------------- setup

func add_hero(kind: String, pos: Vector2i, gear: String = "") -> SimUnit:
	var u := SimUnit.hero(_next_id, kind, pos, gear)
	_next_id += 1
	units.append(u)
	return u


func add_object(kind: String, pos: Vector2i) -> SimUnit:
	var u := SimUnit.object(_next_id, kind, pos)
	_next_id += 1
	units.append(u)
	return u


func add_enemy(kind: String, pos: Vector2i) -> SimUnit:
	var u := SimUnit.enemy(_next_id, kind, pos)
	_next_id += 1
	units.append(u)
	_ensure_deck(kind, u)
	return u


func _ensure_deck(kind: String, u: SimUnit) -> void:
	var key := u.deck
	if key == "" or deck_state.has(key):
		return
	var cards_data: Array = SimData.decks()[key].duplicate(true)
	deck_state[key] = {"draw": _shuffled(cards_data), "discard": []}


func _shuffled(arr: Array) -> Array:
	var out := arr.duplicate()
	for i in range(out.size() - 1, 0, -1):
		var j := rng.range_int(0, i)
		var tmp: Variant = out[i]
		out[i] = out[j]
		out[j] = tmp
	return out


func emit(type: String, data: Dictionary = {}) -> void:
	data["type"] = type
	data["round"] = round
	events.append(data)


# ---------------------------------------------------------------- queries

func unit_by_id(id: int) -> SimUnit:
	for u in units:
		if u.id == id:
			return u
	return null


func unit_at(p: Vector2i) -> SimUnit:
	for u in units:
		if u.pos == p and not u.downed:
			return u
	return null


func heroes(alive_only: bool = true) -> Array[SimUnit]:
	var out: Array[SimUnit] = []
	for u in units:
		if u.side == "hero" and not u.inert and (not alive_only or not u.downed):
			out.append(u)
	return out


## Everything on the hero side an enemy may attack, objects included.
func targets() -> Array[SimUnit]:
	var out: Array[SimUnit] = []
	for u in units:
		if u.side == "hero" and not u.downed:
			out.append(u)
	return out


func enemies(alive_only: bool = true) -> Array[SimUnit]:
	var out: Array[SimUnit] = []
	for u in units:
		if u.side == "enemy" and (not alive_only or not u.downed):
			out.append(u)
	return out


func blocked_tiles(except: SimUnit = null) -> Dictionary:
	var out: Dictionary = {}
	for u in units:
		if not u.downed and u != except:
			out[u.pos] = true
	# Wall: enemies cannot pass a walling hero's tile or its diagonals (handled per mover in movable_tiles).
	return out


func slow_tiles() -> Dictionary:
	var out: Dictionary = {}
	for u in units:
		if u.downed:
			out[u.pos] = true
	return out


## Tiles an enemy may not enter because of a hero's Wall this round.
func wall_tiles() -> Dictionary:
	var out: Dictionary = {}
	for h in heroes():
		if h.flags.has("wall"):
			for dx in [-1, 0, 1]:
				for dy in [-1, 0, 1]:
					out[h.pos + Vector2i(dx, dy)] = true
	return out


func movable_tiles(u: SimUnit) -> Dictionary:
	if u.has("bound"):
		return {u.pos: 0}
	var blocked := blocked_tiles(u)
	if u.side == "enemy":
		blocked.merge(wall_tiles())
	var points := u.move
	if turn.get("stride", false) and u.side == "hero":
		points += 1
	if u.no_water:
		for y in grid.height:
			for x in grid.width:
				var p := Vector2i(x, y)
				if grid.is_water(p):
					blocked[p] = true
	return grid.reachable(u.pos, points, blocked, slow_tiles())


func current() -> SimUnit:
	if queue_index >= queue.size():
		return null
	return unit_by_id(queue[queue_index]["id"])


# ---------------------------------------------------------------- rounds

func start_round() -> void:
	round += 1
	cards.clear()
	for u in units:
		var keep := u.flags.has("recorded_dead")
		u.flags.clear()
		if keep:
			u.flags["recorded_dead"] = true
	# Draw one card per enemy unit type present.
	for e in enemies():
		if not cards.has(e.kind):
			cards[e.kind] = _draw(e.deck)
	# Build the queue.
	queue.clear()
	for u in units:
		if u.downed or u.inert:
			continue
		if u.free_parry:
			u.flags["parry"] = true
		if u.permanent_stand:
			u.flags["stand"] = true
		var init: int
		if u.side == "hero":
			init = HERO_INIT_BASE - u.speed * 20
		else:
			init = cards[u.kind]["init"]
		if u.has("dread"):
			init += 1000
		queue.append({"id": u.id, "init": init, "ink": u.ink})
	queue.sort_custom(func(a, b): return a["init"] < b["init"] or (a["init"] == b["init"] and a["ink"] > b["ink"]))
	queue_index = 0
	_spawn_waves()
	emit("round_start", {"cards": cards.duplicate(true), "queue": queue.duplicate(true)})
	_begin_turn()


func _draw(deck_key: String) -> Dictionary:
	var ds: Dictionary = deck_state[deck_key]
	if ds["draw"].is_empty():
		ds["draw"] = _shuffled(ds["discard"])
		ds["discard"] = []
	var card: Dictionary = ds["draw"].pop_front()
	ds["discard"].append(card)
	if card.get("shuffle", false):
		ds["draw"] = _shuffled(ds["draw"] + ds["discard"])
		ds["discard"] = []
	return card


func _spawn_waves() -> void:
	for w in waves:
		if w["round"] == round and not w.get("spawned", false):
			w["spawned"] = true
			for spec in w["units"]:
				var p := Vector2i(spec["pos"][0], spec["pos"][1])
				if unit_at(p) == null:
					var u := add_enemy(spec["kind"], p)
					if not cards.has(u.kind):
						cards[u.kind] = _draw(u.deck)
					queue.append({"id": u.id, "init": cards[u.kind]["init"], "ink": 0})
					emit("spawn", {"unit": u.id, "kind": u.kind, "pos": [p.x, p.y]})
			queue.sort_custom(func(a, b): return a["init"] < b["init"])


func _begin_turn() -> void:
	var u := current()
	if u == null:
		_end_round()
		return
	if u.downed:
		queue_index += 1
		_begin_turn()
		return
	turn = {"moved": false, "acted": false, "stride": false}
	if u.has("wound"):
		_damage(u, 1, null, "wound")
		if u.downed:
			queue_index += 1
			_begin_turn()
			return
	emit("turn_start", {"unit": u.id, "side": u.side})
	if u.side == "hero" and u.possessed:
		var nearest: SimUnit = null
		var best := 999
		for e in enemies():
			var d := SimGrid.distance(u.pos, e.pos)
			if d < best:
				best = d
				nearest = e
		if nearest != null and best <= 2:
			emit("possessed_strike", {"unit": u.id, "target": nearest.id})
			_damage(nearest, 3, u, "the ancestor")
			turn["acted"] = true
	if u.side == "enemy":
		_enemy_turn(u)
		end_turn()


func end_turn() -> void:
	var u := current()
	if u != null:
		u.tick_cooldowns()
		u.tick_conditions()
		emit("turn_end", {"unit": u.id})
	queue_index += 1
	_check_state()
	if state != "ongoing":
		return
	_begin_turn()


func _end_round() -> void:
	for u in units:
		if u.flags.has("recorded_dead") and not u.downed:
			emit("written_death", {"unit": u.id})
			_damage(u, u.hp, null, "the tablet")
	if objective["type"] == "hold":
		var tile := Vector2i(objective["tile"][0], objective["tile"][1])
		var holder := unit_at(tile)
		if holder != null and holder.side == "hero":
			hold_turns += 1
			emit("hold_progress", {"turns": hold_turns, "needed": objective["turns"]})
	emit("round_end", {})
	_check_state()
	if state == "ongoing":
		start_round()


func _check_state() -> void:
	if state != "ongoing":
		return
	if heroes().is_empty():
		state = "lost"
		emit("battle_end", {"result": "lost"})
		return
	var pending_waves := false
	for w in waves:
		if not w.get("spawned", false):
			pending_waves = true
	match objective["type"]:
		"kill_all":
			if enemies().is_empty() and not pending_waves:
				state = "won"
		"hold":
			if hold_turns >= objective["turns"]:
				state = "won"
		"kill_named":
			var target := unit_by_id(objective["unit"])
			if target != null and target.downed:
				state = "won"
		"protect":
			for u in units:
				if u.inert and u.downed:
					state = "lost"
					emit("battle_end", {"result": "lost", "reason": "object_destroyed"})
					return
			if round > objective["turns"]:
				state = "won"
		"survive":
			if round > objective["turns"]:
				state = "won"
	if state == "won":
		emit("battle_end", {"result": "won"})


# ---------------------------------------------------------------- hero actions

## Hero moves along a path within reach. Returns false when illegal.
func hero_move(u: SimUnit, to: Vector2i) -> bool:
	if u != current() or u.side != "hero" or turn["moved"]:
		return false
	var reach := movable_tiles(u)
	if not reach.has(to) or to == u.pos:
		return false
	var from := u.pos
	var blocked := blocked_tiles(u)
	var route := grid.path(from, to, blocked, slow_tiles())
	_relocate(u, to, route)
	turn["moved"] = true
	if u.face_nearest:
		var nearest: SimUnit = null
		var best := 999
		for e in enemies():
			var d := SimGrid.distance(u.pos, e.pos)
			if d < best:
				best = d
				nearest = e
		if nearest != null:
			u.facing = (nearest.pos - u.pos).sign()
			if u.facing.x != 0 and u.facing.y != 0:
				u.facing = Vector2i(u.facing.x, 0)
	_check_brace_overwatch(u)
	_exposure(u)
	return true


func _relocate(u: SimUnit, to: Vector2i, route: Array[Vector2i] = []) -> void:
	var from := u.pos
	u.pos = to
	if route.size() > 0:
		var last := route[route.size() - 1]
		var before := route[route.size() - 2] if route.size() > 1 else from
		u.facing = (last - before).sign()
	emit("move", {"unit": u.id, "from": [from.x, from.y], "to": [to.x, to.y], "path": _path_list(route)})


func _path_list(route: Array[Vector2i]) -> Array:
	var out: Array = []
	for p in route:
		out.append([p.x, p.y])
	return out


## Hero uses an ability at a target tile. Returns false when illegal.
func hero_act(u: SimUnit, key: String, target: Vector2i) -> bool:
	if u != current() or u.side != "hero" or turn["acted"]:
		return false
	if not u.usable_abilities().has(key):
		return false
	var a := SimData.ability(key)
	var ok := false
	if a.get("kind", "") == "sorcery":
		return _write(u, key, a, target)
	if a.get("kind", "") == "memory":
		return _invoke(u, target)
	match a.get("effect", ""):
		"brace":
			u.flags["brace"] = true
			ok = true
		"wall":
			u.flags["wall"] = true
			ok = true
		"taunt":
			u.flags["taunt"] = a["radius"]
			ok = true
		"stride":
			turn["stride"] = true
			u.flags["stride"] = true
			ok = true
		"stand":
			u.flags["stand"] = true
			ok = true
		"parry":
			u.flags["parry"] = true
			ok = true
		"stamp":
			for q in grid.neighbours(u.pos):
				var t := unit_at(q)
				if t != null and t.side == "enemy":
					_apply_condition(t, "bound", 1, u)
			ok = true
		"arc":
			var hit_any := false
			for p in SimGrid.front_arc(u.pos, u.facing):
				var t := unit_at(p) if grid.in_bounds(p) else null
				if t != null and t.side == "enemy":
					_damage(t, a["damage"], u, key)
					hit_any = true
			ok = true
		_:
			ok = _hero_attack(u, a, key, target)
	if not ok:
		return false
	if a.get("kind", "") != "basic":
		u.cooldowns[key] = a["cooldown"] + 1
	if a.get("effect", "") != "stride":
		turn["acted"] = true
	emit("ability", {"unit": u.id, "ability": key, "target": [target.x, target.y]})
	return true


func _hero_attack(u: SimUnit, a: Dictionary, key: String, target: Vector2i) -> bool:
	var t := unit_at(target)
	if t == null or t.side != "enemy":
		return false
	var d := SimGrid.distance(u.pos, target)
	var r: Array = a["range"]
	var max_r: int = r[1] + (u.reach_delta if a.get("line", false) else 0)
	if d < r[0] or d > max_r:
		return false
	if a.get("line", false) and not grid.in_line(u.pos, target):
		return false
	u.facing = (target - u.pos).sign() if d == 1 or grid.in_line(u.pos, target) else u.facing
	var dmg: int = a["damage"] + int(u.bonus_vs.get(t.family, 0)) + int(u.bonus_vs.get("*", 0))
	_damage(t, dmg, u, key)
	if a.has("splash"):
		for q in grid.neighbours(target):
			var s := unit_at(q)
			if s != null and s.side == "enemy" and s != t:
				_damage(s, a["splash"], u, key)
	if a.has("push") and not t.downed:
		_push(t, (target - u.pos).sign(), a["push"], u)
	return true


## Hero delays: acts again after `after` has acted. Only before moving or acting.
func hero_delay(u: SimUnit, after: SimUnit) -> bool:
	if u != current() or turn["moved"] or turn["acted"] or u.has("dread"):
		return false
	var after_index := -1
	for i in range(queue.size()):
		if queue[i]["id"] == after.id:
			after_index = i
	if after_index <= queue_index:
		return false
	var entry: Dictionary = queue[queue_index]
	queue.remove_at(queue_index)
	queue.insert(after_index, entry)
	emit("delay", {"unit": u.id, "after": after.id})
	_begin_turn()
	return true


# ---------------------------------------------------------------- sorcery and memory

## A written lie. Contested and struck if an enemy who contests stands within 3; the clay is spent either way.
func _write(u: SimUnit, key: String, a: Dictionary, target: Vector2i) -> bool:
	var d := SimGrid.distance(u.pos, target)
	if d < a["range"][0] or d > a["range"][1]:
		return false
	u.clay -= int(a.get("clay", 1))
	u.false_lines += 1
	turn["acted"] = true
	for e in enemies():
		if e.contests and SimGrid.distance(e.pos, u.pos) <= 3:
			emit("contested", {"unit": u.id, "by": e.id, "ability": key})
			return true
	var t := unit_at(target)
	match a["effect"]:
		"count_up":
			var ally := t if t != null and t.side == "hero" else u
			ally.flags["spear_exists"] = true
			ally.bonus_vs["*"] = int(ally.bonus_vs.get("*", 0)) + 1
		"count_down":
			if t == null or t.side != "enemy":
				return false
			for f in ["shield_line", "hold_road", "swell", "unpushable", "aim"]:
				t.flags.erase(f)
			t.flags["no_shield"] = true
		"name_levy":
			if t == null or t.side != "enemy":
				return false
			t.flags["stands_down"] = true
		"name_unseen":
			u.flags["unseen"] = true
		"place":
			if unit_at(target) != null:
				return false
			var tile := grid.get_tile(target)
			grid.set_tile(target, SimGrid.Tile.FLOOR if tile != SimGrid.Tile.FLOOR else SimGrid.Tile.WALL)
			emit("tile_written", {"pos": [target.x, target.y], "tile": grid.get_tile(target)})
		"debt":
			if t == null or t.side != "enemy":
				return false
			_push(t, (u.pos - t.pos).sign(), 1, u)
		"death":
			if t == null or t.side != "enemy":
				return false
			t.flags["recorded_dead"] = true
	emit("written", {"unit": u.id, "ability": key, "target": [target.x, target.y]})
	return true


## Bronze memory: the ancestor's ability, full for the line or a bond, an echo otherwise.
func _invoke(u: SimUnit, target: Vector2i) -> bool:
	var m := u.memory
	var ability: Dictionary = SimData.ability(m.get("ability", "thrust"))
	var t := unit_at(target)
	if t == null or t.side != "enemy":
		return false
	var dmg: int = int(ability.get("damage", 3))
	if not m.get("full", false):
		dmg = int(ceil(dmg / 2.0))
	m["charges"] = int(m.get("charges", 0)) - 1
	m["used"] = int(m.get("used", 0)) + 1
	m["wear"] = int(m.get("wear", 0)) + 1
	emit("invoke", {"unit": u.id, "ancestor": m.get("ancestor", ""), "target": t.id})
	_damage(t, dmg, u, "the bronze")
	turn["acted"] = true
	return true


# ---------------------------------------------------------------- damage and forces

func _damage(t: SimUnit, amount: int, source: SimUnit, cause: String) -> void:
	if t.downed:
		return
	var dealt := amount
	if t.flags.has("shield_line") or t.flags.has("swell") or t.flags.has("hold_road"):
		dealt = maxi(0, dealt - 1)
	if source != null and t.side == "hero":
		var from_dir := (source.pos - t.pos).sign()
		for ally in heroes():
			if ally != t and ally.shield_shoulder and SimGrid.distance(ally.pos, t.pos) == 1 and from_dir != -t.facing:
				dealt = maxi(0, dealt - 1)
				break
		if t.shield_shoulder and from_dir == -t.facing:
			dealt += 1
	if t.flags.has("parry") and source != null and SimGrid.distance(source.pos, t.pos) == 1:
		dealt = int(ceil(dealt / 2.0))
		t.flags.erase("parry")
	t.hp -= dealt
	emit("hit", {"unit": t.id, "by": source.id if source != null else -1, "cause": cause, "damage": dealt, "hp": t.hp})
	if t.hp <= 0:
		t.overkill = -t.hp
		t.hp = 0
		t.downed = true
		t.downed_by = source.kind if source != null else cause
		emit("downed", {"unit": t.id, "by": t.downed_by, "by_id": source.id if source != null else -1, "killer": source.id if source != null else -1, "overkill": t.overkill})


func _apply_condition(t: SimUnit, cond: String, turns: int, source: SimUnit) -> void:
	if t.downed or t.inert:
		return
	if t.immune.has(cond):
		emit("condition_resisted", {"unit": t.id, "condition": cond})
		return
	turns += int(t.longer.get(cond, 0))
	t.conditions[cond] = maxi(t.conditions.get(cond, 0), turns)
	emit("condition", {"unit": t.id, "condition": cond, "turns": turns, "by": source.id if source != null else -1})


## Push `t` `steps` tiles along `dir`. Wall behind: Wound. Water: Dread. Unit: both Bound.
func _push(t: SimUnit, dir: Vector2i, steps: int, source: SimUnit) -> void:
	if t.flags.has("stand") or t.flags.has("unpushable") or t.flags.has("hold_road"):
		emit("push_resisted", {"unit": t.id})
		return
	for i in steps:
		var next := t.pos + dir
		if not grid.in_bounds(next) or grid.get_tile(next) == SimGrid.Tile.WALL:
			_apply_condition(t, "wound", 2, source)
			return
		var other := unit_at(next)
		if other != null:
			_apply_condition(t, "bound", 1, source)
			_apply_condition(other, "bound", 1, source)
			return
		var from := t.pos
		t.pos = next
		emit("forced_move", {"unit": t.id, "from": [from.x, from.y], "to": [next.x, next.y], "kind": "push"})
		if grid.is_water(next):
			_apply_condition(t, "dread", 1, source)
			_exposure(t)
			return


## Drag `t` one tile toward the nearest water.
func _drag_toward_water(t: SimUnit, source: SimUnit) -> void:
	if t.flags.has("stand"):
		emit("push_resisted", {"unit": t.id})
		return
	var target := _nearest_water(t.pos)
	if target == Vector2i(-1, -1):
		return
	var dir := (target - t.pos).sign()
	var next := t.pos + Vector2i(dir.x, 0) if dir.x != 0 else t.pos + Vector2i(0, dir.y)
	if not grid.passable(next) or unit_at(next) != null:
		return
	var from := t.pos
	t.pos = next
	emit("forced_move", {"unit": t.id, "from": [from.x, from.y], "to": [next.x, next.y], "kind": "drag"})
	if grid.is_water(next):
		_apply_condition(t, "dread", 1, source)
	_exposure(t)


func _nearest_water(from: Vector2i) -> Vector2i:
	var best := Vector2i(-1, -1)
	var best_d := 999
	for y in grid.height:
		for x in grid.width:
			var p := Vector2i(x, y)
			if grid.is_water(p):
				var d := SimGrid.distance(from, p)
				if d < best_d:
					best_d = d
					best = p
	return best


func _exposure(u: SimUnit) -> void:
	if u.side == "hero" and not u.tide_immune and grid.get_tile(u.pos) == SimGrid.Tile.TIDE:
		u.flags["exposed"] = true
		emit("exposure", {"unit": u.id, "tile": "tide"})


## A braced hero hits the first enemy that ends a move adjacent to them.
func _check_brace_overwatch(mover: SimUnit) -> void:
	if mover.side != "enemy":
		return
	for h in heroes():
		if h.flags.has("brace") and SimGrid.distance(h.pos, mover.pos) <= 2 and grid.in_line(h.pos, mover.pos):
			h.flags.erase("brace")
			emit("overwatch", {"unit": h.id, "target": mover.id})
			_damage(mover, SimData.ability(h.basic)["damage"], h, "brace")
			return


# ---------------------------------------------------------------- enemy AI

func _profile_focus(e: SimUnit, card: Dictionary) -> SimUnit:
	var candidates := targets()
	if candidates.is_empty():
		return null
	# Taunt overrides the profile within radius.
	for h in candidates:
		if h.flags.has("taunt") and SimGrid.distance(h.pos, e.pos) <= int(h.flags["taunt"]):
			return h
	var profile: String = SimData.units()["families"][e.family]["focus"]
	if e.kind == "outlaw_slinger" or e.kind == "officer":
		profile = "closest"
	var best: SimUnit = null
	var best_key := 1e9
	for h in candidates:
		if h.flags.has("unseen"):
			continue
		var key: float
		match profile:
			"nearest_water":
				var w := _nearest_water(h.pos)
				key = (SimGrid.distance(h.pos, w) if w != Vector2i(-1, -1) else 50) * 100 + _path_len(e, h.pos)
			_:
				key = _path_len(e, h.pos) * 100
		key -= h.ink   # ties: most ink first
		if key < best_key:
			best_key = key
			best = h
	return best


func _path_len(e: SimUnit, to: Vector2i) -> int:
	var blocked := blocked_tiles(e)
	blocked.merge(wall_tiles())
	var route := grid.path(e.pos, to, blocked, slow_tiles(), true)
	return route.size() if route.size() > 0 else 99


func _enemy_turn(e: SimUnit) -> void:
	if e.flags.has("stands_down"):
		emit("stands_down", {"unit": e.id})
		return
	var card: Dictionary = cards[e.kind]
	emit("enemy_card", {"unit": e.id, "card": card["name"]})
	var special: String = card.get("special", "")
	# Self and ally specials that need no focus.
	match special:
		"unpushable": e.flags["unpushable"] = true
		"shield_line":
			for a in enemies():
				if a.kind == e.kind and a != e and SimGrid.distance(a.pos, e.pos) == 1:
					a.flags["shield_line"] = true
			e.flags["shield_line"] = true
		"hold_road":
			e.flags["hold_road"] = true
			for a in enemies():
				if a.family == e.family and SimGrid.distance(a.pos, e.pos) == 1:
					a.flags["shield_line"] = true
		"aim": e.flags["aim"] = true
		"swell": e.flags["swell"] = true
		"sink":
			for a in enemies():
				if a.family == "sea" and grid.is_water(a.pos):
					a.flags["sink"] = true
		"sink_self":
			if grid.is_water(e.pos):
				e.flags["sink"] = true
		"rally":
			for a in enemies():
				if a.family == e.family and a != e and SimGrid.distance(a.pos, e.pos) <= 3:
					a.flags["rally"] = true
		"press":
			for a in enemies():
				if a.family == e.family and SimGrid.distance(a.pos, e.pos) <= 3:
					a.flags["press"] = true
		"rise":
			for a in enemies():
				if a.kind == "jointed" and SimGrid.distance(a.pos, e.pos) <= 3:
					a.flags["rise"] = true
		"wake":
			for a in enemies():
				if a.family == "sea" and SimGrid.distance(a.pos, e.pos) == 1:
					a.flags["wake"] = true
		"order_brace":
			for a in enemies():
				if a.family == e.family and a != e and SimGrid.distance(a.pos, e.pos) == 1:
					a.flags["brace"] = true
		"rising_tide", "call_tide":
			var count: int = 1 if special == "rising_tide" else 2
			_raise_tide(count)
		"recede":
			_move_toward(e, _nearest_water(e.pos), 2)
			return
		"surface":
			_surface(e)
			return
		"flee":
			var f := _profile_focus(e, card)
			if f != null:
				_move_away(e, f.pos, mini(3, e.move + int(card.get("move", 0))))
			return
	var focus := _profile_focus(e, card)
	if focus == null:
		return
	var move_points: int = e.move + int(card.get("move", 0)) + (1 if e.flags.has("rally") else 0) + (2 if e.flags.has("rise") else 0)
	if card.get("no_move", false):
		move_points = 0
	var can_attack: bool = not bool(card.get("no_attack", false))
	# Move toward focus until in range.
	if move_points > 0 and not e.has("bound"):
		if not _in_range(e, focus.pos):
			_approach(e, focus, move_points)
	if not can_attack:
		return
	if not _in_range(e, focus.pos):
		return
	if card.get("only_range", 0) > 0 and SimGrid.distance(e.pos, focus.pos) != card["only_range"]:
		return
	if card.get("only_bound", false) and not focus.has("bound"):
		return
	if card.get("only_in_water", false) and not grid.is_water(focus.pos):
		return
	var dmg: int = e.attack + int(card.get("attack", 0)) + (1 if e.flags.has("aim") else 0) + (1 if e.flags.has("press") else 0) + (1 if e.flags.has("wake") else 0)
	e.flags.erase("aim")
	e.facing = (focus.pos - e.pos).sign()
	match special:
		"arc":
			for p in SimGrid.front_arc(e.pos, e.facing):
				var t := unit_at(p) if grid.in_bounds(p) else null
				if t != null and t.side == "hero":
					_damage(t, dmg, e, card["name"])
		"splash":
			_damage(focus, dmg, e, card["name"])
			for q in grid.neighbours(focus.pos):
				var s := unit_at(q)
				if s != null and s.side == "hero":
					_damage(s, 1, e, card["name"])
		"push":
			_damage(focus, dmg, e, card["name"])
			if not focus.downed:
				_push(focus, (focus.pos - e.pos).sign(), 1, e)
		"drag":
			_damage(focus, dmg, e, card["name"])
			if not focus.downed:
				_drag_toward_water(focus, e)
		"bound":
			_damage(focus, dmg, e, card["name"])
			_apply_condition(focus, "bound", 1, e)
		"wound":
			_damage(focus, dmg, e, card["name"])
			_apply_condition(focus, "wound", 2, e)
		"dread":
			for h in heroes():
				if SimGrid.distance(h.pos, e.pos) <= card.get("radius", 2):
					_apply_condition(h, "dread", 1, e)
		"attack_then_retreat":
			_damage(focus, dmg, e, card["name"])
			_move_away(e, focus.pos, 2)
		_:
			_damage(focus, dmg, e, card["name"])


func _in_range(e: SimUnit, target: Vector2i) -> bool:
	var d := SimGrid.distance(e.pos, target)
	return d >= e.range[0] and d <= e.range[1]


func _approach(e: SimUnit, focus: SimUnit, points: int) -> void:
	var reach := movable_tiles(e)
	var reach_pts := grid.reachable(e.pos, points, _enemy_blocked(e), slow_tiles())
	var best := e.pos
	var best_key := 1e9
	for p in reach_pts:
		var d := SimGrid.distance(p, focus.pos)
		var key: float = (0 if (d >= e.range[0] and d <= e.range[1]) else 1000 + d * 10) + reach_pts[p]
		if key < best_key:
			best_key = key
			best = p
	if best != e.pos:
		var route := grid.path(e.pos, best, _enemy_blocked(e), slow_tiles())
		_relocate(e, best, route)
		_check_brace_overwatch(e)


func _enemy_blocked(e: SimUnit) -> Dictionary:
	var b := blocked_tiles(e)
	b.merge(wall_tiles())
	return b


func _move_toward(e: SimUnit, target: Vector2i, points: int) -> void:
	if target == Vector2i(-1, -1):
		return
	var reach := grid.reachable(e.pos, points, _enemy_blocked(e), slow_tiles())
	var best := e.pos
	var best_d := SimGrid.distance(e.pos, target)
	for p in reach:
		var d := SimGrid.distance(p, target)
		if d < best_d:
			best_d = d
			best = p
	if best != e.pos:
		_relocate(e, best, grid.path(e.pos, best, _enemy_blocked(e), slow_tiles()))


func _move_away(e: SimUnit, from: Vector2i, points: int) -> void:
	var reach := grid.reachable(e.pos, points, _enemy_blocked(e), slow_tiles())
	var best := e.pos
	var best_d := SimGrid.distance(e.pos, from)
	for p in reach:
		var d := SimGrid.distance(p, from)
		if d > best_d:
			best_d = d
			best = p
	if best != e.pos:
		_relocate(e, best, grid.path(e.pos, best, _enemy_blocked(e), slow_tiles()))


func _surface(e: SimUnit) -> void:
	var reach := grid.reachable(e.pos, 2, _enemy_blocked(e), slow_tiles())
	for p in reach:
		if not grid.is_water(p):
			_relocate(e, p, grid.path(e.pos, p, _enemy_blocked(e), slow_tiles()))
			return


## Turn `count` floor tiles adjacent to water into tide.
func _raise_tide(count: int) -> void:
	var candidates: Array[Vector2i] = []
	for y in grid.height:
		for x in grid.width:
			var p := Vector2i(x, y)
			if grid.get_tile(p) == SimGrid.Tile.FLOOR:
				for q in grid.neighbours(p):
					if grid.is_water(q):
						candidates.append(p)
						break
	for i in count:
		if candidates.is_empty():
			return
		var idx := rng.range_int(0, candidates.size() - 1)
		var p: Vector2i = candidates[idx]
		candidates.remove_at(idx)
		grid.set_tile(p, SimGrid.Tile.TIDE)
		emit("tide", {"pos": [p.x, p.y]})
		var u := unit_at(p)
		if u != null:
			_exposure(u)


# ---------------------------------------------------------------- result

## Weighted draw per downed hero: scar, severe or dead, by overkill and enemy strength.
func resolve_downings() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for h in heroes(false):
		if not h.downed:
			continue
		var strength := 1
		var enemy_data: Dictionary = SimData.units()["enemies"].get(h.downed_by, {})
		if not enemy_data.is_empty():
			strength = enemy_data["attack"] + (2 if enemy_data.get("named", false) else 0)
		var severity: int = h.overkill + strength + h.downing_severity
		var weights := {"scar": maxf(1.0, 8.0 - severity), "severe": float(severity), "dead": maxf(0.0, severity - 4.0)}
		var outcome: String = rng.weighted(weights)
		out.append({"unit": h.id, "outcome": outcome, "overkill": h.overkill, "by": h.downed_by})
		emit("downing_result", {"unit": h.id, "outcome": outcome})
	return out


func snapshot() -> Dictionary:
	var us: Array = []
	for u in units:
		us.append(u.to_dict())
	return {"round": round, "state": state, "queue": queue.duplicate(true), "cards": cards.duplicate(true), "units": us, "events": events.size()}
