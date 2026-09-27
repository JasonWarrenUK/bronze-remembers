class_name UnitView
extends Node2D
## One unit on the field. Plays sim events with tweens; never decides rules.

const CELL := 32
const SHEETS := {
	"spear": "res://art/sheets/spear-mapped.png", "sling": "res://art/sheets/sling-mapped.png", "shield": "res://art/sheets/shield-mapped.png",
	"outlaw_spear": "res://art/sheets/outlaw-spear-mapped.png", "outlaw_slinger": "res://art/sheets/outlaw-slinger-mapped.png", "officer": "res://art/sheets/officer-mapped.png",
	"jointed": "res://art/sheets/jointed-mapped.png", "drowned": "res://art/sheets/drowned-mapped.png", "tidecaller": "res://art/sheets/tidecaller-mapped.png",
}

var unit_id: int
var side: String
var facing: String = "down"
var sprite: AnimatedSprite2D
var hp_bar: ColorRect
var hp_fill: ColorRect
var max_hp: int = 1
var ring: Polygon2D
var weapon: Sprite2D
var weapon_class: String = ""
const OVERLAY_CLASSES := ["spear", "sling", "shield"]


func setup(u: SimUnit, palette: Dictionary) -> void:
	unit_id = u.id
	side = u.side
	max_hp = u.max_hp
	position = cell_to_world(u.pos)
	ring = Polygon2D.new()
	ring.polygon = PackedVector2Array([Vector2(-14, 10), Vector2(14, 10), Vector2(14, 14), Vector2(-14, 14)])
	ring.color = palette["hero_ring"] if side == "hero" else palette["enemy_ring"]
	ring.visible = false
	add_child(ring)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = SpriteSheets.build(SHEETS[u.kind])
	sprite.centered = true
	sprite.position = Vector2(0, -4)
	sprite.play("idle_down")
	add_child(sprite)
	if OVERLAY_CLASSES.has(u.kind):
		weapon_class = u.kind
		weapon = Sprite2D.new()
		weapon.centered = true
		weapon.position = Vector2(0, -4)
		add_child(weapon)
		_update_weapon()
	hp_bar = ColorRect.new()
	hp_bar.size = Vector2(24, 3)
	hp_bar.position = Vector2(-12, 12)
	hp_bar.color = palette["bar_back"]
	add_child(hp_bar)
	hp_fill = ColorRect.new()
	hp_fill.size = Vector2(24, 3)
	hp_fill.position = Vector2(-12, 12)
	hp_fill.color = palette["hero_hp"] if side == "hero" else palette["enemy_hp"]
	add_child(hp_fill)
	set_hp(u.hp)


static func cell_to_world(p: Vector2i) -> Vector2:
	return Vector2(p.x * CELL + CELL / 2.0, p.y * CELL + CELL / 2.0)


func set_hp(hp: int) -> void:
	hp_fill.size.x = 24.0 * clampf(float(hp) / float(max_hp), 0.0, 1.0)


func set_active(on: bool) -> void:
	ring.visible = on


func face(dir: Vector2i) -> void:
	facing = SpriteSheets.facing_name(dir)
	sprite.play("idle_" + facing)
	_update_weapon()


func _update_weapon() -> void:
	if weapon == null:
		return
	weapon.texture = load("res://art/overlays/%s-%s.png" % [weapon_class, facing])
	# Behind the body when facing up, in front otherwise.
	weapon.z_index = -1 if facing == "up" else 1
	weapon.position = sprite.position


## Walks a path of cells; awaits completion.
func play_move(path: Array, step_time: float, sfx: Callable) -> void:
	var from := position
	for cell in path:
		var to := cell_to_world(Vector2i(cell[0], cell[1]))
		var d := Vector2i(signi(int(to.x - from.x)), signi(int(to.y - from.y)))
		facing = SpriteSheets.facing_name(d)
		sprite.play("walk_" + facing)
		var tw := create_tween()
		tw.tween_property(self, "position", to, step_time)
		sfx.call("step")
		await tw.finished
		from = to
	sprite.play("idle_" + facing)


func play_forced_move(to_cell: Array, time: float) -> void:
	var to := cell_to_world(Vector2i(to_cell[0], to_cell[1]))
	var tw := create_tween()
	tw.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "position", to, time)
	await tw.finished


func play_attack(dir: Vector2i, lunge_time: float) -> void:
	facing = SpriteSheets.facing_name(dir)
	sprite.play("attack_" + facing)
	var lunge := Vector2(dir.x, dir.y) * 8.0
	var tw := create_tween()
	tw.tween_property(sprite, "position", Vector2(0, -4) + lunge, lunge_time * 0.4).set_ease(Tween.EASE_OUT)
	tw.tween_property(sprite, "position", Vector2(0, -4), lunge_time * 0.6).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	sprite.play("idle_" + facing)


## The hit: flash, knockback and recoil, squash. Camera shake and hit-stop are the field's job.
func play_hit(from_dir: Vector2i, damage: int, hp: int, flash_colour: Color) -> void:
	set_hp(hp)
	var recoil := Vector2(from_dir.x, from_dir.y) * (3.0 + 1.5 * damage)
	sprite.modulate = flash_colour
	sprite.scale = Vector2(1.15, 0.85)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(sprite, "position", Vector2(0, -4) + recoil, 0.05)
	tw.tween_property(sprite, "modulate", Color.WHITE, 0.18)
	tw.tween_property(sprite, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_property(sprite, "position", Vector2(0, -4), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished


func _process(_delta: float) -> void:
	if weapon != null:
		weapon.position = sprite.position
		weapon.scale = sprite.scale
		weapon.modulate = sprite.modulate
		if weapon.texture == null or not weapon.texture.resource_path.ends_with("%s-%s.png" % [weapon_class, facing]):
			_update_weapon()


func play_downed() -> void:
	sprite.play("downed")
	if weapon != null:
		weapon.visible = false
	hp_bar.visible = false
	hp_fill.visible = false
	ring.visible = false
	z_index = -1
	var tw := create_tween()
	tw.tween_property(sprite, "modulate", Color(0.7, 0.7, 0.7, 1.0), 0.3)
	await tw.finished
