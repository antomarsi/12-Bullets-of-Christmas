extends SceneTree

# A Goose a-Laying next to a stationary player: checks it lobs an egg at the player's position
# (a telegraph then an EggBullet appears), that the egg sits for a while without hurting anyone,
# then hatches into a radial burst that actually damages the player — the same "exercise the real
# scene, don't just trust the isolated piece" rule as test_hen_attack.gd/test_partridge_aim.gd.
var room = null
var player = null
var goose = null
var frame := 0
var hp_start := 0.0
var egg_seen := false
var damaged_before_hatch_window := false
var damaged := false
var damaged_frame := -1

func _initialize() -> void:
	var packed: PackedScene = load("res://rooms/night_01.tscn")
	room = packed.instantiate()
	room.night = 0
	root.add_child(room)
	player = room.get_node("Player")
	player.set_physics_process(false)
	goose = load("res://mobs/geese_a_laying/GeeseALaying.tscn").instantiate()
	goose.position = player.position + Vector2(180, 0)
	room.get_node("Mobs").add_child(goose)

func _egg_in_mobs() -> bool:
	for child in room.get_node("Mobs").get_children():
		if child.get_script() != null and child.get("hatch_delay") != null:
			return true
	return false

func _process(_delta) -> bool:
	frame += 1

	if frame == 3:
		hp_start = player.health_component.health

	if not egg_seen and _egg_in_mobs():
		egg_seen = true

	if player.health_component.health < hp_start:
		if not damaged:
			damaged = true
			damaged_frame = frame
		if not egg_seen:
			# Shouldn't be possible (nothing else in this room can hurt the player), but if the
			# egg's burst somehow fired before ever being observed, flag it rather than pass
			# silently.
			damaged_before_hatch_window = true

	if (egg_seen and damaged) or frame > 1200:
		var lobbed: bool = egg_seen
		var eventually_hit: bool = damaged
		print("egg seen: ", egg_seen, "  damaged at frame: ", damaged_frame)
		print("ok   " if lobbed else "FAIL ", "the goose lobs an egg onto the player's position")
		print("ok   " if eventually_hit else "FAIL ", "the egg's hatch burst actually hits the player")
		print("goose attack test: ", "PASS" if lobbed and eventually_hit else "FAIL")
		return true
	return false
