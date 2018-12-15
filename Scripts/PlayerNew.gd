extends "res://Scripts/Entity.gd"

onready var camera = global.currentScene.get_node("Player/Camera2D")
export (float) var SHOOT_SPEED = 0.1

var anim_state = null
var invicibility = false

enum ANIM_STATE {
	IDLE,
	RUNNING
}

func _initialize():
	._initialize()
	TYPE = global.ENTITY.PLAYER
	HitStun = $HitStun
	_set_state(ANIM_STATE.IDLE)

func _physics_process(delta):
	controls_loop()
	._physics_process(delta)
	
func controls_loop():
	var RIGHT = Input.is_action_pressed("move_right")
	var LEFT = Input.is_action_pressed("move_left")
	var UP = Input.is_action_pressed("move_up")
	var DOWN = Input.is_action_pressed("move_down")
	movedir.x = -int(LEFT) + int(RIGHT)
	movedir.y = -int(UP) + int(DOWN)
	
func _set_state(new_state):
	if new_state != anim_state:
		anim_state = new_state
		if anim_state == ANIM_STATE.RUNNING:
			$Sprite.play("Running")
		else:
			$Sprite.play("Idle")
	
func spritedir_loop():
	.spritedir_loop()
	if movedir.x != 0 or movedir.y != 0:
		_set_state(ANIM_STATE.RUNNING)
	else:
		_set_state(ANIM_STATE.IDLE)

func take_damage(damage):
	if invicibility:
		return
	invicibility = true
	$Sprite/Anim.play("Invencibility")
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
	global.currentScene.add_child(camera)
	camera.global_position = cam_pos
	queue_free()

func _on_hitbox_area_entered(area):
	if not invicibility:
		._on_hitbox_area_entered(area)


func _on_Anim_animation_finished(anim_name):
	if anim_name == "Invencibility":
		invicibility = false
