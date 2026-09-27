class_name WorldGen
extends RefCounted
## Builds the run's region from data/world.json: cities as persistent nodes,
## roads with fixed landmarks and generated fill, day costs, one drowned town.
##
## Node: {id, kind, name, pos, road, city, days_from_a, flags}
## Kinds: city, landmark, rest, event, battle, market, drowned_town
## Edges: {a, b, days} between consecutive nodes on a road.


static func generate(seed: int, stage: String = "Whole") -> Dictionary:
	var rng := SimRng.new(seed)
	var data: Dictionary = SimData.load_json("world")
	var nodes: Dictionary = {}
	var edges: Array = []
	for cid in data["cities"]:
		var c: Dictionary = data["cities"][cid]
		nodes[cid] = {"id": cid, "kind": "city", "name": c["name"], "pos": c["pos"], "city": cid, "flags": c.duplicate()}
	var weights: Dictionary = data["fill_weights"][stage]
	var drowned: Dictionary = data.get("drowned_town", {})
	for road in data["roads"]:
		var a: String = road["a"]
		var b: String = road["b"]
		var days: int = road["days"]
		var chain: Array = [a]
		var pa: Array = nodes[a]["pos"]
		var pb: Array = nodes[b]["pos"]
		for step in range(1, days):
			var t := float(step) / float(days)
			var pos := [roundi(lerpf(pa[0], pb[0], t)), roundi(lerpf(pa[1], pb[1], t))]
			var id := "%s-%s-%d" % [a, b, step]
			var landmark: Dictionary = {}
			for lm in road["landmarks"]:
				if lm["at"] == step:
					landmark = lm
			var node: Dictionary
			if not landmark.is_empty():
				node = {"id": id, "kind": "landmark", "name": landmark["name"], "landmark": landmark["kind"], "pos": pos, "road": [a, b], "flags": {}}
			elif not drowned.is_empty() and drowned["road"][0] == a and drowned["road"][1] == b and drowned["at"] == step:
				node = {"id": id, "kind": "drowned_town", "name": drowned["name"], "pos": pos, "road": [a, b], "flags": {}}
			else:
				var kind: String = rng.weighted(weights)
				node = {"id": id, "kind": kind, "name": _fill_name(kind, rng), "pos": pos, "road": [a, b], "flags": {}}
			nodes[id] = node
			chain.append(id)
		chain.append(b)
		for i in range(chain.size() - 1):
			edges.append({"a": chain[i], "b": chain[i + 1], "days": 1})
	return {"region": data["region"], "seed": seed, "nodes": nodes, "edges": edges}


static func _fill_name(kind: String, rng: SimRng) -> String:
	var names := {
		"rest": ["A shepherd's fold", "The old waystation", "A hearth that still answers", "Cistern of the road"],
		"event": ["A stopped cart", "Smoke on the ridge", "A tablet nailed to a post", "Two men arguing over a goat"],
		"battle": ["Outlaws at the culvert", "A toll that is not the king's", "The burned hamlet", "Spears in the barley"],
		"market": ["A Tin Road camp", "Traders under a plane tree"],
	}
	var list: Array = names.get(kind, ["The road"])
	return list[rng.range_int(0, list.size() - 1)]


static func neighbours(world: Dictionary, node_id: String) -> Array:
	var out: Array = []
	for e in world["edges"]:
		if e["a"] == node_id:
			out.append({"id": e["b"], "days": e["days"]})
		elif e["b"] == node_id:
			out.append({"id": e["a"], "days": e["days"]})
	return out


## Shortest path in days between two nodes (Dijkstra over the node graph).
static func route(world: Dictionary, from: String, to: String) -> Array:
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
		if item[1] == to:
			break
		for n in neighbours(world, item[1]):
			var cost: int = item[0] + n["days"]
			if not best.has(n["id"]) or cost < best[n["id"]]:
				best[n["id"]] = cost
				prev[n["id"]] = item[1]
				frontier.append([cost, n["id"]])
	if not best.has(to):
		return []
	var path: Array = []
	var cur: String = to
	while cur != from:
		path.push_front(cur)
		cur = prev[cur]
	return path


static func find_node(world: Dictionary, spec: String) -> String:
	if spec.begins_with("landmark:"):
		var name := spec.substr(9)
		for id in world["nodes"]:
			if world["nodes"][id].get("name", "") == name:
				return id
		return ""
	return spec if world["nodes"].has(spec) else ""
