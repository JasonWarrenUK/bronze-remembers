class_name SimGrid
extends RefCounted
## Square grid of tile types with movement costs and pathfinding.
## Downed bodies and other slow tiles are passed in as a set, never stored here.

enum Tile { FLOOR, WALL, WATER, TIDE, RUBBLE }

const DIRS := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]

var width: int
var height: int
var tiles: PackedInt32Array


func _init(w: int, h: int, fill: int = Tile.FLOOR) -> void:
	width = w
	height = h
	tiles = PackedInt32Array()
	tiles.resize(w * h)
	tiles.fill(fill)


func in_bounds(p: Vector2i) -> bool:
	return p.x >= 0 and p.y >= 0 and p.x < width and p.y < height


func get_tile(p: Vector2i) -> int:
	return tiles[p.y * width + p.x]


func set_tile(p: Vector2i, t: int) -> void:
	tiles[p.y * width + p.x] = t


func is_water(p: Vector2i) -> bool:
	var t := get_tile(p)
	return t == Tile.WATER or t == Tile.TIDE


func passable(p: Vector2i) -> bool:
	return in_bounds(p) and get_tile(p) != Tile.WALL


## Cost to enter a tile. Water and rubble cost 2, tide costs 2 and exposes.
func enter_cost(p: Vector2i, slow: Dictionary = {}) -> int:
	var t := get_tile(p)
	var cost := 1
	if t == Tile.WATER or t == Tile.TIDE or t == Tile.RUBBLE:
		cost = 2
	if slow.has(p):
		cost += 1
	return cost


func neighbours(p: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for d in DIRS:
		var q: Vector2i = p + d
		if in_bounds(q):
			out.append(q)
	return out


static func distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


## Dijkstra from `from` with `points` movement. `blocked` are tiles that cannot be
## entered or crossed (units); `slow` are tiles costing one extra (downed bodies).
## Returns {Vector2i: cost}. The origin is included at cost 0.
func reachable(from: Vector2i, points: int, blocked: Dictionary = {}, slow: Dictionary = {}) -> Dictionary:
	var best: Dictionary = {from: 0}
	var frontier: Array = [[0, from]]
	while not frontier.is_empty():
		var idx := 0
		for i in range(1, frontier.size()):
			if frontier[i][0] < frontier[idx][0]:
				idx = i
		var item: Array = frontier[idx]
		frontier.remove_at(idx)
		var cost: int = item[0]
		var pos: Vector2i = item[1]
		if cost > best[pos]:
			continue
		for q in neighbours(pos):
			if not passable(q) or blocked.has(q):
				continue
			var next: int = cost + enter_cost(q, slow)
			if next > points:
				continue
			if not best.has(q) or next < best[q]:
				best[q] = next
				frontier.append([next, q])
	return best


## Shortest path (list of tiles excluding the origin) or empty if unreachable.
## `blocked` tiles cannot be crossed except the destination if `allow_dest`.
func path(from: Vector2i, to: Vector2i, blocked: Dictionary = {}, slow: Dictionary = {}, allow_dest: bool = false) -> Array[Vector2i]:
	var best: Dictionary = {from: 0}
	var prev: Dictionary = {}
	var frontier: Array = [[0, from]]
	while not frontier.is_empty():
		var idx := 0
		for i in range(1, frontier.size()):
			if frontier[i][0] < frontier[idx][0]:
				idx = i
		var item: Array = frontier[idx]
		frontier.remove_at(idx)
		var cost: int = item[0]
		var pos: Vector2i = item[1]
		if pos == to:
			break
		if cost > best[pos]:
			continue
		for q in neighbours(pos):
			if not passable(q):
				continue
			if blocked.has(q) and not (allow_dest and q == to):
				continue
			var next: int = cost + enter_cost(q, slow)
			if not best.has(q) or next < best[q]:
				best[q] = next
				prev[q] = pos
				frontier.append([next, q])
	if not best.has(to):
		return []
	var out: Array[Vector2i] = []
	var cur := to
	while cur != from:
		out.push_front(cur)
		cur = prev[cur]
	return out


## True when b lies on a straight orthogonal line from a with no wall between.
func in_line(a: Vector2i, b: Vector2i) -> bool:
	if a.x != b.x and a.y != b.y:
		return false
	var d := (b - a).sign()
	var p := a + d
	while p != b:
		if get_tile(p) == Tile.WALL:
			return false
		p += d
	return true


## Front arc of a unit facing `dir`: the tile ahead and its two diagonals.
static func front_arc(p: Vector2i, dir: Vector2i) -> Array[Vector2i]:
	var side := Vector2i(dir.y, dir.x)
	return [p + dir, p + dir + side, p + dir - side]
