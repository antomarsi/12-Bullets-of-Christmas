extends Node2D

export (bool) var MULTISHOOT = false
export (float) var SHOOT_TIMER = 1
export (PackedScene) var Bullet
export (float) var SHOOT_DISTANCE = 400
onready var has_gun = $ShootPositions.get_child_count() > 0
var guns

func _ready():
	randomize()
	if has_gun:
		get_parent().connect("shoot", global.currentScene, "_on_shoot")
		guns = $ShootPositions.get_children()
		$ShootTimer.wait_time = SHOOT_TIMER + randi() % 3
		$ShootTimer.start()

func _on_ShootTimer_timeout():
	var target = get_parent().target
	if not has_gun or not target:
		return
	if global_position.distance_to(target.get_ref().global_position) > SHOOT_DISTANCE:
		return
	if guns.size() == 1:
		var dir = (target.get_ref().global_position - guns[0].global_position).normalized()
		get_parent().emit_signal('shoot', Bullet, guns[0].global_position, dir)
	elif not MULTISHOOT:
		var shoot_position = guns[randi() % guns.size()].global_position
		var dir = (target.get_ref().global_position - shoot_position).normalized()
		get_parent().emit_signal('shoot', Bullet, shoot_position, dir)
	else:
		for shoot_position in guns:
			var dir = (target.get_ref().global_position - shoot_position.global_position).normalized()
			get_parent().emit_signal('shoot', Bullet, shoot_position.global_position, dir)