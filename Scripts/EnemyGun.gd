extends Node2D

export (bool) var MULTISHOOT = false
export (float) var SHOOT_TIMER = 1
export (PackedScene) var Bullet
export (float) var SHOOT_DISTANCE = 400
onready var has_gun = $ShootPositions.get_child_count() > 0
onready var target = global.get_player_ref()
var guns

func _ready():
	randomize()
	if has_gun:
		get_parent().connect("shoot", global.get_current_scene(), "_on_shoot")
		guns = $ShootPositions.get_children()
		$ShootTimer.wait_time = SHOOT_TIMER + rand_range(0, 5)
		$ShootTimer.start()

func aim(target):
	return target.get_ref().global_position

func _on_ShootTimer_timeout():
	if not has_gun or not target:
		return
	shoot()

func shoot():
	if global_position.distance_to(target.get_ref().global_position) > SHOOT_DISTANCE:
		return
	var target_position = aim(target)
	if guns.size() == 1:
		var dir = (target_position - guns[0].global_position).normalized()
		emit_shoot(dir, guns[0].global_position)
	elif not MULTISHOOT:
		var shoot_position = guns[randi() % guns.size()].global_position
		var dir = (target_position - shoot_position).normalized()
		emit_shoot(dir, shoot_position)
	else:
		for shoot_position in guns:
			var dir = (target_position - shoot_position.global_position).normalized()
			emit_shoot(dir, shoot_position.global_position)

func emit_shoot(dir, shoot_position):
	get_parent().emit_signal('shoot', Bullet, shoot_position, dir)