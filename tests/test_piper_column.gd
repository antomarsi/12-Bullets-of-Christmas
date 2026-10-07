extends SceneTree

# Four pipers spawned together near a stationary player: checks they string out into a trailing
# column (not stacked on each other), that firing actually produces real SineBullet instances
# whose own path visibly wiggles off a straight line as they fly (not just a straight shot), and
# that a sweeping note eventually reaches/hits the player.
var room = null
var player = null
var pipers := []
var frame := 0
var hp_start := 0.0
var min_pairwise_spread := 99999.0
var sine_bullet_seen := false
var wiggle_seen := false
var damaged := false
var _tracked_bullet = null
var _tracked_start_pos := Vector2.ZERO
var _tracked_forward := Vector2.RIGHT

func _initialize() -> void:
	# A clean, pillar-free room rather than night_01: pipers patrol a 300px orbit around the
	# player, and night_01's central pillar sits well inside that radius — the navmesh routes the
	# leader into a pinch point around it and the whole column gets stuck there (not a bug in the
	# formation logic itself, just a bad fit for this particular test room).
	var packed: PackedScene = load("res://rooms/BaseRoom.tscn")
	room = packed.instantiate()
	room.night = 0
	# Big enough that the formation's ~300-400px patrol/column spread stays well clear of the
	# walls — a smaller room (first tried 40x24 tiles) let bullets clip a nearby wall almost at
	# spawn, which looked identical to "notes never reach the player" until traced bullet-by-bullet.
	room.tile_map_size = Vector2i(72, 48)
	root.add_child(room)
	player = room.get_node("Player")
	player.set_physics_process(false)
	# BaseRoom places the player near the bottom of the floor by default — fine for most tests,
	# but pipers spawn in a full circle around the player here, and some ended up south of it,
	# close enough to the bottom wall that a bullet clipped it within a few px of spawning.
	# Recenter so there's clearance on every side.
	player.global_position = room.bounds.get_center()
	for i in 4:
		var piper = load("res://mobs/piper_piping/PiperPiping.tscn").instantiate()
		piper.position = player.position + Vector2(260, 0).rotated(TAU * i / 4.0)
		room.get_node("Mobs").add_child(piper)
		pipers.append(piper)

func _live_sine_bullets() -> Array:
	var world: Node = room.get_tree().current_scene if room.get_tree().current_scene else room.get_tree().root
	return world.get_children().filter(func(n): return n.get_script() != null and n.get("wave_frequency") != null)

func _process(_delta) -> bool:
	frame += 1

	if frame == 3:
		hp_start = player.health_component.health

	if frame == 180:
		for i in pipers.size():
			for j in range(i + 1, pipers.size()):
				min_pairwise_spread = minf(min_pairwise_spread, pipers[i].global_position.distance_to(pipers[j].global_position))

	if frame > 10 and frame < 900:
		if _tracked_bullet == null or not is_instance_valid(_tracked_bullet):
			var bullets := _live_sine_bullets()
			if bullets.size() > 0:
				sine_bullet_seen = true
				_tracked_bullet = bullets[0]
				_tracked_start_pos = _tracked_bullet.global_position
				_tracked_forward = Vector2.RIGHT.rotated(_tracked_bullet.rotation)
		else:
			# Perpendicular distance from the straight line the bullet started on — a pure
			# straight-line bullet would stay at ~0 forever; the sine wiggle should push it off
			# that line measurably as it travels.
			var lateral: float = (_tracked_bullet.global_position - _tracked_start_pos).dot(_tracked_forward.orthogonal())
			if absf(lateral) > 8.0:
				wiggle_seen = true

		if player.health_component.health < hp_start:
			damaged = true

	if frame > 900:
		var spread_out: bool = min_pairwise_spread > 20.0
		print("min pairwise spread: ", min_pairwise_spread)
		print("sine bullet seen: ", sine_bullet_seen, "  wiggle seen: ", wiggle_seen, "  damaged: ", damaged)
		print("ok   " if spread_out else "FAIL ", "pipers string out into a trailing column rather than stacking")
		print("ok   " if sine_bullet_seen else "FAIL ", "pipers actually fire SineBullet instances")
		print("ok   " if wiggle_seen else "FAIL ", "a sine bullet visibly wiggles off its straight-line path in flight")
		print("ok   " if damaged else "FAIL ", "a sweeping note eventually hits the player")
		print("piper column test: ", "PASS" if spread_out and sine_bullet_seen and wiggle_seen and damaged else "FAIL")
		return true
	return false
