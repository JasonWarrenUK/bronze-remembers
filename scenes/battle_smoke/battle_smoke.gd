extends Node
## The vertical slice fight: three levy heroes hold a ford against outlaws,
## and the tide brings sea-things on round 3.


func _ready() -> void:
	var seed: int = int(DebugApi.user_args.get("seed", 7))
	var b := SimBattle.new(10, 10, seed)
	for x in 10:
		b.grid.set_tile(Vector2i(x, 9), SimGrid.Tile.WATER)
	for x in [3, 4, 6]:
		b.grid.set_tile(Vector2i(x, 8), SimGrid.Tile.TIDE)
	for p in [Vector2i(4, 3), Vector2i(4, 4), Vector2i(7, 6), Vector2i(2, 6)]:
		b.grid.set_tile(p, SimGrid.Tile.WALL)
	for p in [Vector2i(5, 5), Vector2i(6, 2), Vector2i(1, 7)]:
		b.grid.set_tile(p, SimGrid.Tile.RUBBLE)
	b.add_hero("spear", Vector2i(1, 4), "greaves")
	b.add_hero("sling", Vector2i(0, 3), "bracers")
	b.add_hero("shield", Vector2i(1, 3), "corselet")
	b.add_enemy("outlaw_spear", Vector2i(7, 3))
	b.add_enemy("outlaw_spear", Vector2i(8, 2))
	b.add_enemy("outlaw_slinger", Vector2i(9, 4))
	b.waves = [{"round": 3, "units": [{"kind": "jointed", "pos": [4, 8]}, {"kind": "drowned", "pos": [7, 8]}]}]
	var view := BattleView.new()
	view.auto = DebugApi.user_args.has("auto")
	add_child(view)
	await view.present(b)
