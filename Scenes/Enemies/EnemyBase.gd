extends KinematicBody2D

signal shoot
signal died

export (PackedScene) var Bullet
var can_shoot = false

export (int) var MAX_SPEED = 300
export (float) var MAX_FORCE = 0.02
export (Vector2) var DISTANCE = Vector2()
export (float) var SHOOT_TIMER = 2
export (int) var HEALTH = 10
export (bool) var MULTI_SHOOT = false

var velocity = Vector2()
onready var target = weakref(global.currentScene.get_node("Player"))
onready var sprite = $Sprite
var gun_point

func _ready():
	initialize()
	connect("died", global.currentScene, "_on_Enemy_died")
	connect("shoot", global.currentScene, "_on_shoot")
	$GunTimer.wait_time = SHOOT_TIMER
	$GunTimer.start()

func initialize():
	pass

func _physics_process(delta):
	if HEALTH > 0:
		_move()
	
func _move():
	if target.get_ref():
		velocity = steer(target.get_ref().global_position)
		move_and_slide(velocity)
		sprite.flip_h = ((target.get_ref().global_position - global_position).normalized()).x <= 0

func _process(delta):
	if HEALTH <= 0:
		return
	if can_shoot and Bullet and target.get_ref():
		_shoot(delta)

func steer(target):
	var desired_velocity = (target - position)
	desired_velocity = desired_velocity.normalized() * MAX_SPEED
	var steer = desired_velocity - velocity
	var target_velocity = velocity + (steer * MAX_FORCE)
	return target_velocity

func steer_keep_distance(target):
	var desired_velocity = (target - position) + DISTANCE
	desired_velocity = desired_velocity.normalized() * MAX_SPEED
	var steer = desired_velocity - velocity
	var target_velocity = velocity + (steer * MAX_FORCE)
	return target_velocity

func flee(target):
	var desired_velocity = (target - position).normalized() * MAX_SPEED
	var steer = (-1 * desired_velocity) - velocity
	var target_velocity = velocity + (steer * MAX_FORCE)
	return target_velocity
	
func _shoot(delta):
	can_shoot = false
	$GunTimer.start()
	if MULTI_SHOOT and typeof(gun_point) == TYPE_ARRAY:
		for shoot_position in gun_point:
			var dir = (target.get_ref().global_position - shoot_position.global_position).normalized()
			emit_signal('shoot', Bullet, shoot_position.global_position, dir)
	elif typeof(gun_point) == TYPE_ARRAY:
		var shoot_position = gun_point[randi() % gun_point.size()].global_position
		var dir = (target.get_ref().global_position - shoot_position).normalized()
		emit_signal('shoot', Bullet, shoot_position, dir)
	else:
		var dir = (target.get_ref().global_position - gun_point.global_position).normalized()
		emit_signal('shoot', Bullet, gun_point.global_position, dir)

func _on_GunTimer_timeout():
	can_shoot = true

func take_damage(damage):
	HEALTH -= damage
	if $Hit:
		$Hit.play()
	if HEALTH <= 0:
		$CollisionShape2D.disabled = true
		die()

func die():
	queue_free()
	emit_signal("died")