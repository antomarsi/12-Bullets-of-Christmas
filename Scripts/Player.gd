extends KinematicBody2D

signal shoot

var anim
var velocity = Vector2()
onready var gunRoot = $Pivot/GunRoot
var can_shoot = false

export (PackedScene) var Bullet
export (float) var SHOOT_SPEED = 0.1
export (int) var SPEED = 400
export (int) var ACCELERATION = 10
export (int) var DE_ACCELERATION = 15
var flip = false

func _ready():
	anim = $AnimatedSprite
	$GunTimer.wait_time = SHOOT_SPEED
	pass
	
func _process(delta):
	_aim_gun()
	_handle_movement(delta)
	_shoot(delta)
	
func _aim_gun():
	var mouse_pos = get_global_mouse_position()
	gunRoot.look_at(mouse_pos)

	if mouse_pos.x > global_position.x:
		$Pivot/GunRoot/GunSprite.flip_v = false
		flip = false
	elif mouse_pos.x < global_position.x:
		$Pivot/GunRoot/GunSprite.flip_v = true
		flip = true

func _shoot(delta):
	if Input.is_action_pressed("click") and can_shoot:
		can_shoot = false
		$GunTimer.start()
		var dir = ($Pivot/GunRoot/GunSprite/ShootPoint.global_transform.origin - global_transform.origin).normalized()
		emit_signal('shoot', Bullet, $Pivot/GunRoot/GunSprite/ShootPoint.global_position, dir)

func _handle_movement(delta):
	var dir = Vector2()
	if Input.is_action_pressed("move_right"):
		dir.x += 1
	if Input.is_action_pressed("move_left"):
		dir.x -= 1
	if Input.is_action_pressed("move_down"):
		dir.y += 1
	if Input.is_action_pressed("move_up"):
		dir.y -= 1
	dir = dir.normalized()
	
	var new_pos = dir * SPEED
	var hv = velocity
	var accel  = DE_ACCELERATION
	
	if (dir.dot(hv) > 0):
		accel = ACCELERATION
	velocity = hv.linear_interpolate(new_pos, accel * delta)
	
	velocity = move_and_slide(velocity);
	

func _on_GunTimer_timeout():
	can_shoot = true
