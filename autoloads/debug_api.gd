extends Node
## Exposes game state for the agent loop: a JSON dump on demand, written to
## a path given on the command line or to user://debug.json.
##
## Command line (after the Godot args, separated by --):
##   --debug-dump[=path]   write the dump once the launcher has loaded its scene, then quit
##   --scene=<name>        handled by the launcher; recorded here for the dump

var user_args: Dictionary = {}
var providers: Dictionary = {}


func _ready() -> void:
	user_args = parse_user_args(OS.get_cmdline_user_args())


## Parses "--key=value" and "--flag" into a dictionary. Flags map to true.
static func parse_user_args(args: PackedStringArray) -> Dictionary:
	var parsed: Dictionary = {}
	for arg in args:
		if not arg.begins_with("--"):
			continue
		var body := arg.substr(2)
		var eq := body.find("=")
		if eq == -1:
			parsed[body] = true
		else:
			parsed[body.substr(0, eq)] = body.substr(eq + 1)
	return parsed


## Systems register a callable returning a Dictionary under a name.
func register(name: String, provider: Callable) -> void:
	providers[name] = provider


func snapshot() -> Dictionary:
	var out: Dictionary = {
		"engine": Engine.get_version_info().string,
		"frame": Engine.get_process_frames(),
		"args": user_args,
		"scene": get_tree().current_scene.scene_file_path if get_tree().current_scene else "",
	}
	for name in providers:
		out[name] = providers[name].call()
	return out


func dump(path: String = "") -> String:
	if path == "":
		path = "user://debug.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("DebugApi: cannot open %s" % path)
		return ""
	file.store_string(JSON.stringify(snapshot(), "\t"))
	file.close()
	return ProjectSettings.globalize_path(path)


## Called by the launcher once its scene is up.
func on_scene_ready() -> void:
	if user_args.has("debug-dump"):
		var target: Variant = user_args["debug-dump"]
		var written := dump(target if target is String else "")
		print("DebugApi: wrote %s" % written)
		get_tree().quit()
