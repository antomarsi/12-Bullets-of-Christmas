extends "res://Scripts/Entity.gd"

onready var target = global.player_ref
enum FOLLOW_TYPE {
	STEER,
	FLEE
}

export (FOLLOW_TYPE) var TRACK = FOLLOW_TYPE.STEER

const DAMAGE = 1

func _initialize():
	._initialize()
	connect("died", global.currentScene, "_on_Enemy_died")

func _physics_process(delta):
	if target:
		match(TRACK):
			FOLLOW_TYPE.STEER:
				steer(target)
			FOLLOW_TYPE.FLEE:
				flee(target)
		._physics_process(delta)

func steer(target):
	var desired_velocity = (target.get_ref().global_position - position)
	desired_velocity = desired_velocity.normalized() * SPEED
	var steer = desired_velocity - velocity
	movedir = velocity + (steer * ACCELERATION)

func flee(target):
	var desired_velocity = (target.get_ref().global_position - global_position).normalized() * SPEED
	var steer = (-1 * desired_velocity) - velocity
	movedir = velocity + (steer * ACCELERATION)

func spritedir_loop():
	if not target:
		return
	if flip and ((target.get_ref().global_position - global_position).normalized()).x > 0:
		flip = false
		$Sprite.flip_h = !$Sprite.flip_h
	elif not flip and ((target.get_ref().global_position - global_position).normalized()).x < 0:
		flip = true
		$Sprite.flip_h = !$Sprite.flip_h