extends Node
## The first run: Carry the archive out. --seed=N, --auto, --load to resume user://run.json


func _ready() -> void:
	var args := DebugApi.user_args
	var r: Run = null
	if has_meta("run"):
		r = get_meta("run")
	elif args.has("load"):
		r = Run.load_from(RunFlow.SAVE_PATH)
	if r == null:
		r = Run.new(int(args.get("seed", 7)))
		r.add_hero("spear", "Arnuwanda", "greaves")
		r.add_hero("sling", "Tudhal", "bracers")
		r.add_hero("shield", "Muwatti", "corselet")
	var flow := RunFlow.new()
	add_child(flow)
	if has_meta("register"):
		flow.register = get_meta("register")
		flow.roster = get_meta("roster")
		flow.spent = get_meta("spent")
	flow.start(r, args.has("auto"))
