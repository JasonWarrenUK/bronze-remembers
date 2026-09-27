extends Node
## Saves the viewport to PNG. Needs a real window (not --headless).
##
## Command line: --shot=<path> [--shot-frame=N]
##   saves after N frames (default 3), then quits.

var _pending_path: String = ""
var _frames_left: int = 3


func _ready() -> void:
	var args := DebugApi.parse_user_args(OS.get_cmdline_user_args())
	if args.has("shot"):
		_pending_path = str(args["shot"])
		_frames_left = int(args.get("shot-frame", 3))


func _process(_delta: float) -> void:
	if _pending_path == "":
		return
	_frames_left -= 1
	if _frames_left > 0:
		return
	var written := save(_pending_path)
	print("Screenshot: wrote %s" % written)
	_pending_path = ""
	get_tree().quit()


func save(path: String) -> String:
	var image := get_viewport().get_texture().get_image()
	var absolute := ProjectSettings.globalize_path(path)
	var err := image.save_png(absolute)
	if err != OK:
		push_error("Screenshot: save failed (%d) for %s" % [err, absolute])
		return ""
	return absolute
