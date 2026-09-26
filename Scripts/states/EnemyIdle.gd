extends State

@export var pathfind : PathfindComponent

var wander_time : float
var move_position : Vector2

func randomize_wander():
	move_position = get_parent().get_parent().global_position + Vector2(randf_range(-50, 50), randf_range(-50, 50))

func enter():
	randomize_wander()

func update(delta: float):
	if pathfind.navigation_agent.is_navigation_finished():
		randomize_wander()
		pathfind.set_target_position(move_position)
