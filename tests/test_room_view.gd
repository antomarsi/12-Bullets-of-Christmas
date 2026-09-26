extends SceneTree

# Night 1 test ground: camera zoom/limits/follow, wall collision, spawn candidates on floor, stretch settings.
var room = null
var player = null
var frame := 0
var report := []
var failed := false

func check(ok: bool, text: String) -> void:
	report.append(("ok   " if ok else "FAIL ") + text)
	if not ok:
		failed = true

func _initialize() -> void:
	check(ProjectSettings.get_setting("display/window/stretch/mode") == "canvas_items", "stretch mode is canvas_items")
	check(ProjectSettings.get_setting("display/window/stretch/aspect") == "keep", "stretch aspect is keep")
	var packed: PackedScene = load("res://rooms/night_01.tscn")
	room = packed.instantiate()
	room.night = 0  # no waves: this test only checks the map and camera
	root.add_child(room)
	player = room.get_node("Player")
	player.set_physics_process(false)

func _process(_delta) -> bool:
	frame += 1
	if frame == 2:
		check(room.has_tiles(), "night 1 has a tile map")
		check(room.get_node_or_null("Walls") != null and room.get_node_or_null("Floor") != null, "Floor and Walls layers exist")
		check(not room.is_walkable(Vector2(8, 8), 0), "a border tile is not walkable")
		check(room.is_walkable(Vector2(room.bounds.size.x / 2.0, room.bounds.size.y / 2.0 + 60), 1), "the arena centre area is walkable")
		check(not room.is_walkable(Vector2((10 + 2) * 16 + 8, (8 + 2) * 16 + 8), 0), "a pillar tile is not walkable")
		var pts: Array = room._spawn_points()
		var bad := 0
		for p in pts:
			if not room.is_walkable(p, 3):
				bad += 1
		check(pts.size() > 50 and bad == 0, "%d spawn candidates, %d not on floor (margin 3)" % [pts.size(), bad])
		# Camera created by night rooms only; build one the same way here.
		room._setup_camera()
		check(room.camera != null and room.camera.zoom == Vector2(2, 2), "camera exists with 2x zoom")
		check(int(room.camera.limit_right) == int(room.bounds.end.x), "camera limits follow the map bounds")
		player.global_position = Vector2(room.bounds.size.x - 120, room.bounds.size.y - 100)
	if frame == 90:
		var d: float = room.camera.global_position.distance_to(player.global_position)
		check(d < 200.0, "camera follows the player (distance %.0f px)" % d)
		# Walk the player left into the wall and see it stop at the inner edge (2 tiles = 32 px).
		player.global_position = Vector2(200, 200)
	if frame > 90 and frame <= 300:
		player.velocity_component.direction = Vector2.LEFT
		player.velocity_component.move(player)
	if frame == 301:
		check(player.global_position.x > 30.0, "player is stopped by the wall (x = %.1f, inner edge 32)" % player.global_position.x)
		for r in report:
			print(r)
		print("room view test: ", "FAIL" if failed else "PASS")
		return true
	return false
