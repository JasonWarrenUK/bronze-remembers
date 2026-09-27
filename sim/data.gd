class_name SimData
extends RefCounted
## Loads the slice's data files once. Pure data: no nodes, works headless.

static var _cache: Dictionary = {}


static func load_json(name: String) -> Dictionary:
	if _cache.has(name):
		return _cache[name]
	var path := "res://data/%s.json" % name
	var text := FileAccess.get_file_as_string(path)
	if text == "":
		push_error("SimData: cannot read %s" % path)
		return {}
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_error("SimData: bad JSON in %s" % path)
		return {}
	_cache[name] = parsed
	return parsed


static func units() -> Dictionary:
	return load_json("units")


static func abilities() -> Dictionary:
	return load_json("abilities")


static func gear() -> Dictionary:
	return load_json("gear")


static func decks() -> Dictionary:
	return load_json("decks")


static func ability(key: String) -> Dictionary:
	return abilities().get(key, {})
