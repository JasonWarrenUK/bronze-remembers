class_name SpriteSheets
extends RefCounted
## Builds SpriteFrames from a 128x128 mapped sheet: a 4x4 grid of 32px cells.
## Row order from the LoRA: down, left, right, up. Columns 0 to 2 walk; column 3 is
## arms raised (down), jump left, jump right and lying on the floor (up).

const CELL := 32
const ROWS := {"down": 0, "left": 1, "right": 2, "up": 3}


static func build(sheet_path: String) -> SpriteFrames:
	var tex: Texture2D = load(sheet_path)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for dir in ROWS:
		var row: int = ROWS[dir]
		_add(frames, "idle_" + dir, tex, [[1, row]], 1.0, true)
		_add(frames, "walk_" + dir, tex, [[0, row], [1, row], [2, row], [1, row]], 8.0, true)
	_add(frames, "attack_down", tex, [[3, 0]], 1.0, false)
	_add(frames, "attack_left", tex, [[3, 1]], 1.0, false)
	_add(frames, "attack_right", tex, [[3, 2]], 1.0, false)
	_add(frames, "attack_up", tex, [[1, 3]], 1.0, false)
	_add(frames, "downed", tex, [[3, 3]], 1.0, false)
	return frames


static func _add(frames: SpriteFrames, name: String, tex: Texture2D, cells: Array, fps: float, loop: bool) -> void:
	frames.add_animation(name)
	frames.set_animation_speed(name, fps)
	frames.set_animation_loop(name, loop)
	for c in cells:
		var atlas := AtlasTexture.new()
		atlas.atlas = tex
		atlas.region = Rect2(c[0] * CELL, c[1] * CELL, CELL, CELL)
		atlas.filter_clip = true
		frames.add_frame(name, atlas)


## A single 16x16 texture shown at 2x for objects on the field.
static func build_static(path: String) -> SpriteFrames:
	var tex: Texture2D = load(path)
	var frames := SpriteFrames.new()
	frames.remove_animation("default")
	for name in ["idle_down", "idle_left", "idle_right", "idle_up", "walk_down", "walk_left", "walk_right", "walk_up", "attack_down", "attack_left", "attack_right", "attack_up", "downed"]:
		frames.add_animation(name)
		frames.add_frame(name, tex)
	return frames


static func facing_name(dir: Vector2i) -> String:
	if dir == Vector2i(0, -1):
		return "up"
	if dir == Vector2i(-1, 0):
		return "left"
	if dir == Vector2i(1, 0):
		return "right"
	return "down"
