extends KinematicBody2D

signal shoot
signal take_hit
signal died

var velocity = Vector2()
onready var gunRoot = $Pivot/GunRoot
onready var camera = global.currentScene.get_node("Player/Camera2D")
onready var anim_sprite = $Pivot/Sprite
var can_shoot = false

export (PackedScene) var Bullet
export (float) var SHOOT_SPEED = 0.1
export (int) var SPEED = 400
export (int) var ACCELERATION = 10
export (int) var DE_ACCELERATION = 15

var flip = false
var sprite_flip = false
export (int) var HEALTH = 10

enum ANIM_STATE {
	IDLE,
	RUNNING
}

var anim_state = null

func _ready():
	connect("shoot", global.currentScene, "_on_shoot")
	connect("take_hit", global.currentScene, "_on_Player_take_hit")
	$GunTimer.wait_time = SHOOT_SPEED
	_set_state(ANIM_STATE.IDLE)
	pass

func _physics_process(delta):
	_handle_movement(delta)

func _process(delta):
	_aim_gun()
	_shoot(delta)
	$Pivot/Sprite.flip_h = velocity.x < 0
		

func _aim_gun():
	var mouse_pos = get_global_mouse_position()
	gunRoot.look_at(mouse_pos)

	if mouse_pos.x > global_position.x:
		$Pivot/GunRoot/GunSprite.flip_v = false
		flip = false
	elif mouse_pos.x < global_position.x:
		$Pivot/GunRoot/GunSprite.flip_v = true
		flip = true

func _set_state(new_state):
	if new_state != anim_state:
		anim_state = new_state
		if anim_state == ANIM_STATE.RUNNING:
			anim_sprite.play("Running")
		else:
			anim_sprite.play("Idle")
			

func _shoot(delta):
	if Input.is_action_pressed("click") and can_shoot:
		can_shoot = false
		$GunTimer.start()
		var dir = ($Pivot/GunRoot/ShootPoint.global_transform.origin - global_transform.origin).normalized()
		emit_signal('shoot', Bullet, $Pivot/GunRoot/ShootPoint.global_position, dir)

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
	if Input.is_key_pressed(KEY_F):
		camera.shake(0.5, 20, 25)

	if dir.x != 0 or dir.y != 0:
		_set_state(ANIM_STATE.RUNNING)
	else:
		_set_state(ANIM_STATE.IDLE)

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

func take_damage(damage):
	HEALTH -= damage
	emit_signal("take_hit", HEALTH)
	if HEALTH <= 0:
		die()
	camera.shake(0.5, 20, 25)

func heal(amount):
	HEALTH = clamp(HEALTH+amount, 0, 10)
	emit_signal("take_hit", HEALTH)

func die():
	emit_signal("died")
	var cam_pos = camera.global_position
	camera.get_parent().remove_child(camera)
	global.currentScene.add_child(camera)
	camera.global_position = cam_pos