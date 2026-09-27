extends GutTest


func test_reachable_respects_walls_and_costs() -> void:
	var g := SimGrid.new(5, 5)
	g.set_tile(Vector2i(1, 0), SimGrid.Tile.WALL)
	g.set_tile(Vector2i(0, 1), SimGrid.Tile.RUBBLE)
	var r := g.reachable(Vector2i(0, 0), 2)
	assert_false(r.has(Vector2i(1, 0)), "wall unreachable")
	assert_eq(r[Vector2i(0, 1)], 2, "rubble costs 2")
	assert_false(r.has(Vector2i(0, 2)), "beyond points")


func test_path_goes_around_units() -> void:
	var g := SimGrid.new(5, 1)
	var p := g.path(Vector2i(0, 0), Vector2i(4, 0), {Vector2i(2, 0): true})
	assert_eq(p.size(), 0, "corridor blocked by a unit")
	var g2 := SimGrid.new(5, 2)
	var p2 := g2.path(Vector2i(0, 0), Vector2i(4, 0), {Vector2i(2, 0): true})
	assert_eq(p2.size(), 6, "detours through the second row")


func test_downed_bodies_slow() -> void:
	var g := SimGrid.new(4, 1)
	var r := g.reachable(Vector2i(0, 0), 3, {}, {Vector2i(1, 0): true})
	assert_eq(r[Vector2i(1, 0)], 2)
	assert_eq(r[Vector2i(2, 0)], 3)
	assert_false(r.has(Vector2i(3, 0)))


func test_in_line_blocked_by_wall() -> void:
	var g := SimGrid.new(5, 5)
	assert_true(g.in_line(Vector2i(0, 2), Vector2i(4, 2)))
	g.set_tile(Vector2i(2, 2), SimGrid.Tile.WALL)
	assert_false(g.in_line(Vector2i(0, 2), Vector2i(4, 2)))
	assert_false(g.in_line(Vector2i(0, 0), Vector2i(1, 1)), "diagonals are not lines")
