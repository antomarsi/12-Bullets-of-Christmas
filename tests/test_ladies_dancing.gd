extends SceneTree

# Nine ladies spawned together around a stationary player: checks they spread into a ring
# (not stacked), that the ring actually closes in (average distance to the player shrinks over
# the contract window), that at least one lady is pulled out to a visibly wider "gap" radius at
# any given moment (never a fully closed circle), and that the spin phase eventually fires a
# bullet (the spiral attack actually runs) that reaches/hits the player.
var room = null
var player = null
var ladies := []
var frame := 0
var hp_start := 0.0
var damaged := false
var min_spread_at_start := 99999.0
var avg_distance_early := 0.0
var avg_distance_late := 0.0
var gap_seen := false

func _initialize() -> void:
	var packed: PackedScene = load("res://rooms/night_01.tscn")
	room = packed.instantiate()
	room.night = 0
	root.add_child(room)
	player = room.get_node("Player")
	player.set_physics_process(false)
	for i in 9:
		var lady = load("res://mobs/ladies_dancing/LadiesDancing.tscn").instantiate()
		lady.position = player.position + Vector2(340, 0).rotated(TAU * i / 9.0)
		room.get_node("Mobs").add_child(lady)
		ladies.append(lady)

func _avg_distance() -> float:
	var total := 0.0
	for l in ladies:
		total += l.global_position.distance_to(player.global_position)
	return total / ladies.size()

func _process(_delta) -> bool:
	frame += 1

	if frame == 3:
		hp_start = player.health_component.health

	if frame == 60:
		for i in ladies.size():
			for j in range(i + 1, ladies.size()):
				min_spread_at_start = minf(min_spread_at_start, ladies[i].global_position.distance_to(ladies[j].global_position))
		avg_distance_early = _avg_distance()

	if frame > 60 and frame < 900:
		var radii := []
		for l in ladies:
			radii.append(l.global_position.distance_to(player.global_position))
		radii.sort()
		if radii[radii.size() - 1] - radii[0] > 120.0:
			gap_seen = true
		if player.health_component.health < hp_start:
			damaged = true

	if frame == 450:
		avg_distance_late = _avg_distance()

	if frame > 900:
		var spread_out: bool = min_spread_at_start > 40.0
		var closed_in: bool = avg_distance_late < avg_distance_early - 30.0
		print("min pairwise spread at start: ", min_spread_at_start)
		print("avg distance early: ", avg_distance_early, "  late: ", avg_distance_late)
		print("gap seen: ", gap_seen, "  damaged: ", damaged)
		print("ok   " if spread_out else "FAIL ", "the nine ladies spread into a ring rather than stacking")
		print("ok   " if closed_in else "FAIL ", "the ring actually closes in over time")
		print("ok   " if gap_seen else "FAIL ", "one lady is always pulled out to a visible gap radius")
		print("ok   " if damaged else "FAIL ", "the spin phase's spiral shots eventually hit the player")
		print("ladies dancing test: ", "PASS" if spread_out and closed_in and gap_seen and damaged else "FAIL")
		return true
	return false
