# Build a SpriteFrames .tres from an Aseprite --format json-array export.
# usage: godot --headless --path . --script build_spriteframes.gd -- hero-sheet.json hero_frames.tres
extends SceneTree

func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var json_path: String = "res://" + args[0]
	var out_path: String = "res://" + args[1]
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(json_path))
	var sheet_png: String = json_path.get_base_dir().path_join(data["meta"]["image"])
	var atlas: Texture2D = load(sheet_png)
	var frames: Array = data["frames"]
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for tag in data["meta"]["frameTags"]:
		var name: StringName = tag["name"]
		sf.add_animation(name)
		sf.set_animation_speed(name, 1000.0)          # 1 unit of "duration" == 1 ms
		sf.set_animation_loop(name, name == "idle")
		for i in range(int(tag["from"]), int(tag["to"]) + 1):
			var f: Dictionary = frames[i]
			var at := AtlasTexture.new()
			at.atlas = atlas
			at.region = Rect2(f["frame"]["x"], f["frame"]["y"], f["frame"]["w"], f["frame"]["h"])
			at.filter_clip = true
			sf.add_frame(name, at, float(f["duration"]))   # per-frame duration in ms
	var err := ResourceSaver.save(sf, out_path)
	print("saved %s err=%d anims=%s" % [out_path, err, sf.get_animation_names()])
	quit()
