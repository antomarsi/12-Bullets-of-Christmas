extends SceneTree

# Usage: godot --headless --path . --script res://tests/test_wave_flow.gd -- <night> [room_night] [lifetime_frames]
# Runs the waves of <night> inside the room scene of [room_night] (default: same night). Mobs live
# for [lifetime_frames] (default 0 = killed on spawn) so their AI and attacks run; the player can't die.
var night := 2
var room_night := 0
var lifetime := 0
var frame := 0
var started := []
var cleared := []
var night_done := false
var max_alive := 0
var room = null
var born := {}
var spawn_checked := 0
var spawn_in_wall := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		night = int(args[0])
	room_night = int(args[1]) if args.size() > 1 else night
	lifetime = int(args[2]) if args.size() > 2 else 0
	Engine.time_scale = 10.0
	var ev = root.get_node("Events")
	ev.wave_started.connect(func(i, total): started.append([i, total]))
	ev.wave_cleared.connect(func(i): cleared.append(i))
	ev.night_cleared.connect(func(n): night_done = true)
	var packed: PackedScene = load("res://rooms/night_%02d.tscn" % room_night)
	room = packed.instantiate()
	room.night = night
	root.add_child(room)

func _process(_delta) -> bool:
	frame += 1
	var player = room.get_node_or_null("Player")
	if player:
		player.health_component.MAX_HEALTH = 1000000
		player.health_component.health = 1000000
	var director = room.get("director")
	if director:
		max_alive = maxi(max_alive, director.alive_count())
	for mob in room.get_node("Mobs").get_children():
		if mob.has_method("take_damage") and not mob.is_queued_for_deletion() and mob.get("health") != null and mob.health > 0:
			var id: int = mob.get_instance_id()
			if not born.has(id):
				born[id] = frame
				if room.has_method("has_tiles") and room.has_tiles():
					spawn_checked += 1
					if not room.is_walkable(mob.global_position, 1):
						spawn_in_wall += 1
			if frame - born[id] >= lifetime:
				mob.take_damage(100000)
	if night_done:
		return _finish()
	if frame > 40000:
		print("TIMEOUT")
		return _finish()
	return false

func _finish() -> bool:
	var spawned := -1
	if room.get("director") != null:
		spawned = room.director.spawned_total
	var expected_waves := NightData.waves(night).size()
	var ok := night_done and started.size() == expected_waves and cleared.size() == expected_waves
	print("night ", night, " in room ", room_night, ": waves ", started.size(), "/", expected_waves,
		" cleared ", cleared.size(), " night_cleared ", night_done,
		" spawned ", spawned, " (table total ", NightData.total(night), ")", " max alive ", max_alive)
	print("spawns checked against the tile map: ", spawn_checked, "  in a wall: ", spawn_in_wall)
	print("wave flow test: ", "PASS" if ok and spawn_in_wall == 0 else "FAIL")
	return true
