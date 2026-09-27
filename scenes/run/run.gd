extends Node
## The first run: Carry the archive out. --seed=N, --auto, --load to resume user://run.json


func _ready() -> void:
	var args := DebugApi.user_args
	var r: Run = null
	if args.has("load"):
		r = Run.load_from(RunFlow.SAVE_PATH)
	if r == null:
		r = Run.new(int(args.get("seed", 7)))
		r.add_hero("spear", "Arnuwanda", "greaves")
		r.add_hero("sling", "Tudhal", "bracers")
		r.add_hero("shield", "Muwatti", "corselet")
	var flow := RunFlow.new()
	add_child(flow)
	flow.start(r, args.has("auto"))
