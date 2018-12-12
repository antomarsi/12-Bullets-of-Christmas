extends KinematicBody2D

signal died

var can_hurt = true

export (int) var MAX_SPEED = 300
export (float) var MAX_FORCE = 0.02
export (Vector2) var DISTANCE = Vector2()
export (int) var HEALTH = 10

var velocity = Vector2()
var collision = null

onready var target = weakref(global.currentScene.get_node("Player"))
var knockback_angle


func _ready():
	connect("died", global.currentScene, "_on_Enemy_died")
	connect("shoot", global.currentScene, "_on_shoot")
	pass

func _physics_process(delta):
	if HEALTH > 0:
		_move()

func _move():
	if can_hurt and target.get_ref():
		velocity = steer(target.get_ref().global_position)
		collision = move_and_collide(velocity)
	elif knockback_angle and not can_hurt:
		move_and_slide(knockback_angle)

func _process(delta):
	if collision and can_hurt and collision.collider.name == "Player":
		_on_hit(collision.collider)
		knockback_angle = collision.normal * 300
		collision = null

func _draw():
	if collision:
		print(collision.position)
		draw_line(to_local(collision.position), to_local(collision.position + (collision.normal * 100)), Color(1.0, 0.0, 0.0))
		
func steer(target):
	var desired_velocity = (target - position)
	desired_velocity = desired_velocity.normalized() * MAX_SPEED
	var steer = desired_velocity - velocity
	var target_velocity = velocity + (steer * MAX_FORCE)
	return target_velocity

func _on_Timer_timeout():
	can_hurt = true

func _on_hit(body):
	if body.has_method("take_damage"):
		body.take_damage(1)
	can_hurt = false
	$Timer.start(1)
	pass # Replace with function body.
	
func take_damage(damage):
	HEALTH -= damage
	$Hit.play()
	if HEALTH <= 0:
		$CollisionShape2D.disabled = true
		die()

func die():
	queue_free()
	emit_signal("died")