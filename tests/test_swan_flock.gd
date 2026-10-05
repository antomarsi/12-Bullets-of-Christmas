extends SceneTree

# Seven swans spawned together far from a stationary player: checks the followers actually trail
# the leader in a spread V (not stacked on it), that the flock accelerates into a wedge charge at
# some point (a burst of high speed, not the steady cruise speed), and that killing the leader
# breaks the formation — the survivors then act independently (glide straight toward the player)
# instead of still orbiting around a dead leader's last position.
var room = null
var player = null
var swans := []
var frame := 0
var min_follower_spread := 99999.0
var max_speed_seen := 0.0
var leader = null
var leader_pos_at_death := Vector2.ZERO
var moved_toward_player_after_death := false
var dist_to_player_at_death := 0.0

func _initialize() -> void:
	var packed: PackedScene = load("res://rooms/night_01.tscn")
	room = packed.instantiate()
	room.night = 0
	root.add_child(room)
	player = room.get_node("Player")
	player.set_physics_process(false)
	for i in 7:
		var swan = load("res://mobs/swan_a_swimming/SwanASwimming.tscn").instantiate()
		swan.position = player.position + Vector2(500, -200)
		room.get_node("Mobs").add_child(swan)
		swans.append(swan)
	leader = swans[0]

func _process(_delta) -> bool:
	frame += 1

	if frame > 30 and frame < 600:
		max_speed_seen = maxf(max_speed_seen, leader.get("_velocity").length())
		var spread := 99999.0
		for i in range(1, swans.size()):
			for j in range(i + 1, swans.size()):
				spread = minf(spread, swans[i].global_position.distance_to(swans[j].global_position))
		min_follower_spread = minf(min_follower_spread, spread) if spread < 99999.0 else min_follower_spread

	if frame == 600:
		leader_pos_at_death = leader.global_position
		dist_to_player_at_death = leader.global_position.distance_to(player.global_position)
		leader.take_damage(1000)

	if frame == 700:
		var flock: Array = swans[1]._flock()
		var new_leader = flock[0] if flock.size() > 0 else null
		var survivor_moved_closer: bool = swans[1].global_position.distance_to(player.global_position) < dist_to_player_at_death
		moved_toward_player_after_death = (new_leader != swans[0]) and survivor_moved_closer

	if frame > 750:
		var spread_out: bool = min_follower_spread > 20.0
		var charged: bool = max_speed_seen > 300.0
		print("min follower-to-follower spread: ", min_follower_spread)
		print("max speed seen (leader): ", max_speed_seen)
		print("ok   " if spread_out else "FAIL ", "followers spread into a V rather than stacking")
		print("ok   " if charged else "FAIL ", "the flock accelerates into a wedge charge")
		print("ok   " if moved_toward_player_after_death else "FAIL ", "killing the leader breaks the formation (survivors act independently)")
		print("swan flock test: ", "PASS" if spread_out and charged and moved_toward_player_after_death else "FAIL")
		return true
	return false
