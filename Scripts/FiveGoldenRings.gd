extends "res://Scripts/Enemy.gd"
onready var target = global.player_ref

func spritedir_loop():
	if target:
		$Sprite.look_at(target.get_ref().global_position)
		$Gun.look_at(target.get_ref().global_position)

func _initialize():
	randomize()
	._initialize()

func update_path(nav, player_position):
	var position = player_position
	player_position.x = rand_range(-10, 10)
	player_position.y = rand_range(-10, 10)
	path = nav.get_simple_path(global_position, player_position)
	set_physics_process (true)