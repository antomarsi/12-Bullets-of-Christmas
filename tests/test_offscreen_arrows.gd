extends SceneTree

# A mob placed far outside the camera's view should get an off-screen arrow drawn for it; once it
# (or the camera) brings it back on-screen, the arrow should stop being drawn. OnScreenUI._draw()
# isn't itself easy to assert on directly, so this drives the same ViewUtil.on_screen() check the
# drawing logic branches on, and separately confirms a mob far outside the room's Large-tier bounds
# still has a position OnScreenUI can compute an arrow for without erroring (get_viewport_rect()/
# get_camera_2d() aren't null in a real running room).
var room = null
var player = null
var hud = null
var mob = null
var frame := 0
var checked := false
var result_passed := false

func _initialize() -> void:
	var packed: PackedScene = load("res://rooms/night_04.tscn")
	room = packed.instantiate()
	room.night = 0
	root.add_child(room)
	player = room.get_node("Player")
	hud = room.get_node("UILayer/OnScreenUI")
	# night == 0 (legacy mode) skips camera setup entirely — this test needs a real active camera,
	# so call the same setup the wave-mode path (night > 0) would have, now that the tile room's
	# _build_tiles() has already set `bounds` (that part runs regardless of night).
	room._setup_camera()

	mob = load("res://mobs/Mob.tscn").instantiate()
	# Far from the player/camera, well outside the ~640x360 world view.
	mob.position = player.position + Vector2(2000, 0)
	mob.always_aware = false
	room.get_node("Mobs").add_child(mob)

func _process(_delta) -> bool:
	frame += 1
	if frame < 3:
		return false

	var camera := root.get_viewport().get_camera_2d()
	if camera == null:
		print("FAIL no active camera")
		print("offscreen arrows test: FAIL")
		return true

	if not checked:
		checked = true
		var far_offscreen: bool = not ViewUtil.on_screen(mob, 0.0)
		# Camera look-ahead can drift it a fair way from the player's exact position in a bare
		# test context with no real aim input — that's GameCamera's own behavior, not this
		# feature, so position the mob relative to wherever the camera actually is right now
		# rather than assuming "near the player" means "on-screen".
		mob.global_position = camera.global_position + Vector2(20, 0)
		var now_onscreen: bool = ViewUtil.on_screen(mob, 0.0)
		hud.queue_redraw()
		print("ok   " if far_offscreen else "FAIL ", "a mob far outside the view is detected as off-screen")
		print("ok   " if now_onscreen else "FAIL ", "the same mob next to the player is detected as on-screen")
		result_passed = far_offscreen and now_onscreen
		return false

	# A couple more frames for the queued redraw to actually invoke OnScreenUI._draw() for real
	# (with the mob now on-screen, so the off-screen branch is skipped; the far-off-screen branch
	# already ran once naturally during earlier frames with the mob at its original position) —
	# any error inside the drawing code would print here rather than silently not happen.
	if frame > 10:
		print("offscreen arrows test: ", "PASS" if result_passed else "FAIL")
		return true
	return false
