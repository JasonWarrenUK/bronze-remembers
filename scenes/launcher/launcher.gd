extends Node
## Boots into a named scene from the command line, so the agent can jump
## straight to a situation: godot --path . -- --scene=battle_smoke
##
## Scenes are looked up in res://scenes/<name>/<name>.tscn. With no --scene
## the launcher shows a placeholder so the project runs from the editor too.

const SCENES_ROOT := "res://scenes"


func _ready() -> void:
	var args := DebugApi.user_args
	var name: String = str(args.get("scene", ""))
	if name == "":
		_show_placeholder()
	else:
		var path := "%s/%s/%s.tscn" % [SCENES_ROOT, name, name]
		if not ResourceLoader.exists(path):
			push_error("Launcher: no scene at %s" % path)
			get_tree().quit(2)
			return
		var packed: PackedScene = load(path)
		var instance := packed.instantiate()
		add_child(instance)
	await get_tree().process_frame
	DebugApi.on_scene_ready()


func _show_placeholder() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	var col := VBoxContainer.new()
	col.position = Vector2(220, 100)
	col.add_theme_constant_override("separation", 8)
	layer.add_child(col)
	var title := Label.new()
	title.text = "BRONZE REMEMBERS"
	col.add_child(title)
	for item in [["The Register", "res://scenes/register/register.tscn"], ["Continue the run", ""], ["The slice fight", "res://scenes/battle_smoke/battle_smoke.tscn"]]:
		var b := Button.new()
		b.text = item[0]
		if item[1] == "":
			b.pressed.connect(func():
				DebugApi.user_args["load"] = true
				get_tree().change_scene_to_file("res://scenes/run/run.tscn"))
		else:
			b.pressed.connect(func(): get_tree().change_scene_to_file(item[1]))
		col.add_child(b)
