extends SceneTree

# A Calling Bird next to a stationary player: checks it backs away rather than closing to melee
# (kiting), and that its sonic ring attack actually damages the player (mirrors
# tests/test_hen_attack.gd's "exercise the real scene" approach).
var room = null
var player = null
var bird = null
var frame := 0
var hp_start := 0.0
var damaged := false
var min_distance_after_settle := 99999.0
var max_distance_seen := 0.0

func _initialize() -> void:
	var packed: PackedScene = load("res://rooms/night_01.tscn")
	room = packed.instantiate()
	room.night = 0
	root.add_child(room)
	player = room.get_node("Player")
	player.set_physics_process(false)

func _process(_delta) -> bool:
	frame += 1
	if frame == 3:
		bird = load("res://mobs/calling_bird/CallingBird.tscn").instantiate()
		# Spawn well inside kite_min_range so it has to actually retreat, not just hold position.
		bird.position = player.position + Vector2(60, 0)
		room.get_node("Mobs").add_child(bird)
		hp_start = player.health_component.health
	if bird == null:
		return false

	var distance: float = bird.global_position.distance_to(player.global_position)
	max_distance_seen = maxf(max_distance_seen, distance)
	if frame > 120:
		min_distance_after_settle = minf(min_distance_after_settle, distance)
	if player.health_component.health < hp_start:
		damaged = true

	if (damaged and frame > 400) or frame > 1800:
		var retreated: bool = max_distance_seen > 100.0
		var kept_distance: bool = min_distance_after_settle > bird.kite_min_range * 0.7
		print("max distance reached: ", max_distance_seen, "  distance once settled: ", min_distance_after_settle)
		print("ok   " if retreated else "FAIL ", "bird backed away from point-blank range")
		print("ok   " if kept_distance else "FAIL ", "bird keeps its distance rather than closing to melee")
		print("ok   " if damaged else "FAIL ", "the sonic ring hit the player")
		print("calling bird attack test: ", "PASS" if retreated and kept_distance and damaged else "FAIL")
		return true
	return false
