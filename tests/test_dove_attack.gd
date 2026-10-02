extends SceneTree

# Turtle dove: visible wind-up, direction lock, dash passes through the player, recovery pause.
var room = null
var player = null
var dove = null
var frame := 0
var t := 0.0
var report := []
var failed := false
var saw_windup := false
var windup_start := -1.0
var windup_len := 0.0
var saw_dash := false
var dash_start_side := 0.0
var passed_through := false
var hp_start := 0.0
var damaged := false
var dash_len := 0.0
var dash_t0 := -1.0

func check(ok: bool, text: String) -> void:
	report.append(("ok   " if ok else "FAIL ") + text)
	if not ok:
		failed = true

func _initialize() -> void:
	var packed: PackedScene = load("res://rooms/night_01.tscn")
	room = packed.instantiate()
	room.night = 0
	root.add_child(room)
	player = room.get_node("Player")
	player.set_physics_process(false)

func _process(delta) -> bool:
	frame += 1
	t += delta
	if frame == 3:
		dove = load("res://mobs/turtle_dove/TurtleDove.tscn").instantiate()
		dove.position = player.position + Vector2(200, 0)
		var args := OS.get_cmdline_user_args()
		if args.size() > 0:
			dove.randomize_color = false
			dove.selected_color = int(args[0])
		room.get_node("Mobs").add_child(dove)
		hp_start = player.health_component.health
	if dove == null:
		return false
	var rel: float = dove.global_position.x - player.global_position.x
	if dove.is_winding_up():
		if windup_start < 0.0:
			windup_start = t
		saw_windup = true
	elif windup_start >= 0.0 and windup_len == 0.0:
		windup_len = t - windup_start
	if dove.is_dashing():
		if not saw_dash:
			saw_dash = true
			dash_start_side = signf(rel)
			dash_t0 = t
		elif signf(rel) != dash_start_side and abs(rel) > 2.0:
			passed_through = true
	elif saw_dash and dash_len == 0.0:
		dash_len = t - dash_t0
	if player.health_component.health < hp_start:
		damaged = true
	if (saw_dash and dash_len > 0.0 and t > dash_t0 + 2.5) or frame > 3000:
		check(saw_windup, "dove shows a wind-up before attacking")
		check(abs(windup_len - dove.windup_time) < 0.15, "wind-up lasted %.2f s (windup_time %.2f)" % [windup_len, dove.windup_time])
		check(saw_dash and abs(dash_len - dove.dash_time) < 0.15, "dash lasted %.2f s (dash_time %.2f)" % [dash_len, dove.dash_time])
		check(passed_through, "dove passed through the player instead of stopping at them")
		check(damaged, "the dash hurt the player")
		for r in report:
			print(r)
		print("dove attack test: ", "FAIL" if failed else "PASS")
		return true
	return false
