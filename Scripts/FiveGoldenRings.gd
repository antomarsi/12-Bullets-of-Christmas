extends "res://Scripts/Enemy.gd"
onready var target = global.player_ref

func spritedir_loop():
	if target:
		$Sprite.look_at(target.get_ref().global_position)
		$Gun.look_at(target.get_ref().global_position)
