extends SceneTree

# Three lords spawned together near a stationary player: checks the leapfrog turn-taking never
# lets more than one lord be airborne at once, that an airborne lord is actually invulnerable to
# damage (take_damage() is a no-op mid-leap), and that landing still deals real damage via the
# shockwave ring — the same "exercise the real scene" rule as test_calling_bird_attack.gd.
var room = null
var player = null
var lords := []
var frame := 0
var hp_start := 0.0
var max_simultaneous_airborne := 0
var saw_airborne := false
var ignored_damage_while_airborne := false
var damaged := false

func _initialize() -> void:
	var packed: PackedScene = load("res://rooms/night_01.tscn")
	room = packed.instantiate()
	room.night = 0
	root.add_child(room)
	player = room.get_node("Player")
	player.set_physics_process(false)
	for i in 3:
		var lord = load("res://mobs/lords_a_leaping/LordsALeaping.tscn").instantiate()
		lord.position = player.position + Vector2(220, 0).rotated(TAU * i / 3.0)
		room.get_node("Mobs").add_child(lord)
		lords.append(lord)

func _process(_delta) -> bool:
	frame += 1

	if frame == 3:
		hp_start = player.health_component.health

	if frame > 5 and frame < 600:
		var airborne := 0
		for l in lords:
			if is_instance_valid(l) and l.get("_phase") == 2:  # Phase.AIRBORNE
				airborne += 1
				saw_airborne = true
				var health_before: int = l.health
				l.take_damage(1000)
				if l.health == health_before:
					ignored_damage_while_airborne = true
		max_simultaneous_airborne = maxi(max_simultaneous_airborne, airborne)
		if player.health_component.health < hp_start:
			damaged = true

	if frame > 600:
		var staggered: bool = max_simultaneous_airborne <= 1
		print("max lords airborne at once: ", max_simultaneous_airborne, "  saw airborne: ", saw_airborne)
		print("ok   " if staggered else "FAIL ", "leapfrog turn-taking keeps at most one lord airborne at a time")
		print("ok   " if ignored_damage_while_airborne else "FAIL ", "an airborne lord is invulnerable to damage")
		print("ok   " if damaged else "FAIL ", "a landing shockwave actually hits the player")
		print("lord leap test: ", "PASS" if staggered and ignored_damage_while_airborne and damaged else "FAIL")
		return true
	return false
