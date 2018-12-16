extends KinematicBody2D

signal shoot
signal take_hit
signal died

var velocity = Vector2()
onready var gunRoot = $Pivot/GunRoot
onready var camera = global.get_current_scene().get_node("Player/Camera2D")
onready var anim_sprite = $Pivot/Sprite


export (PackedScene) var Bullet
export (float) var SHOOT_SPEED = 0.1
export (int) var SPEED = 400
export (int) var ACCELERATION = 10
export (int) var DE_ACCELERATION = 15

var sprite_flip = false
var invicibility = false
var TYPE = global.TYPE.PLAYER
export (int) var HEALTH = 10

enum ANIM_STATE {
	IDLE,
	RUNNING
}

var anim_state = null

func _ready():
	connect("shoot", global.get_current_scene(), "_on_shoot")
	connect("take_hit", global.get_current_scene(), "_on_Player_take_hit")
	_set_state(ANIM_STATE.IDLE)
	pass

func _physics_process(delta):
	_handle_movement(delta)

func _process(delta):
	$Pivot/Sprite.flip_h = velocity.x < 0

func _set_state(new_state):
	if new_state != anim_state:
		anim_state = new_state
		if anim_state == ANIM_STATE.RUNNING:
			anim_sprite.play("Running")
		else:
			anim_sprite.play("Idle")

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
	velocity = move_and_slide(velocity)

func take_damage(damage):
	if invicibility:
		return
	invicibility = true
	$Pivot/Sprite/Invicibility.play("Invencibility")
	$Hit.play()
	HEALTH -= damage
	emit_signal("take_hit", HEALTH)
	if HEALTH <= 0:
		die()
	camera.shake(0.5, 20, 25)

func heal(amount):
	HEALTH = clamp(HEALTH+amount, 0, 10)
	emit_signal("take_hit", HEALTH)
	$Heal.play()

func die():
	emit_signal("died")
	var cam_pos = camera.global_position
	camera.get_parent().remove_child(camera)
	global.get_current_scene().add_child(camera)
	camera.global_position = cam_pos
	queue_free()

func _on_Invicibility_animation_finished(anim_name):
	invicibility = false
