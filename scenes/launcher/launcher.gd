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
	var label := Label.new()
	label.text = "Bronze Remembers\nlauncher: pass -- --scene=<name>"
	label.position = Vector2(16, 16)
	add_child(label)
