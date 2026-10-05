extends SceneTree

# Five rings spawned together around a stationary player: checks they spread into distinct
# pentagon formation slots instead of stacking on the player's position, that they dash one at a
# time (thumb to pinky) rather than all charging simultaneously, and that killing some speeds the
# survivors up (the formation contracting into a square/triangle as rings die).
var room = null
var player = null
var rings := []
var frame := 0
var min_pairwise_distance := 99999.0
var max_simultaneous_attackers := 0
var speed_before_deaths := 0.0
var speed_after_deaths := 0.0

func _initialize() -> void:
	var packed: PackedScene = load("res://rooms/night_01.tscn")
	room = packed.instantiate()
	room.night = 0
	root.add_child(room)
	player = room.get_node("Player")
	player.set_physics_process(false)
	for i in 5:
		var ring = load("res://mobs/five_golden_rings/FiveGoldenRings.tscn").instantiate()
		# Outside close_attack_range so all five have to hold the pentagon formation first.
		ring.position = player.position + Vector2(220, 0).rotated(TAU * i / 5.0)
		room.get_node("Mobs").add_child(ring)
		rings.append(ring)

func _process(_delta) -> bool:
	frame += 1

	if frame == 60:
		for i in rings.size():
			for j in range(i + 1, rings.size()):
				var d: float = rings[i].global_position.distance_to(rings[j].global_position)
				min_pairwise_distance = minf(min_pairwise_distance, d)
		speed_before_deaths = rings[0].speed

	if frame > 60 and frame < 400:
		var attacking := 0
		for r in rings:
			if is_instance_valid(r) and r.get("_is_in_attack_state") == true:
				attacking += 1
		max_simultaneous_attackers = maxi(max_simultaneous_attackers, attacking)

	if frame == 400:
		rings[3].take_damage(1000)
		rings[4].take_damage(1000)

	if frame == 440:
		speed_after_deaths = rings[0].speed

	if frame > 460:
		var spread_out: bool = min_pairwise_distance > 60.0
		var staggered: bool = max_simultaneous_attackers < 5
		var sped_up: bool = speed_after_deaths > speed_before_deaths
		print("min pairwise distance at frame 60: ", min_pairwise_distance)
		print("max rings charging at once: ", max_simultaneous_attackers)
		print("speed before deaths: ", speed_before_deaths, "  after 2 deaths: ", speed_after_deaths)
		print("ok   " if spread_out else "FAIL ", "the five rings spread into distinct formation slots")
		print("ok   " if staggered else "FAIL ", "rings dash one at a time (thumb to pinky), not all at once")
		print("ok   " if sped_up else "FAIL ", "killing rings speeds the survivors up")
		print("five golden rings test: ", "PASS" if spread_out and staggered and sped_up else "FAIL")
		return true
	return false
