extends KinematicBody2D

signal shoot
signal take_hit
signal died

export (int) var SPEED = 70
export (int) var ACCELERATION = 10
export (int) var DE_ACCELERATION = 15
export (int) var HEALTH = 10

onready var TYPE = global.ENTITY.ENEMY
var HitStun = null

var movedir = Vector2(0, 0)
var knockdir = Vector2(0, 0)
var velocity = Vector2(0, 0)
var sprite
var flip = false

func _ready():
	_initialize()
	pass

func _initialize():
	sprite = $Sprite
	
func _physics_process(delta):
	if HitStun != null and HitStun.time_left > 0:
		move_and_slide(knockdir.normalized() * SPEED * 1.5)
	else:
		movement_loop(delta)

func _process(delta):
	spritedir_loop()

func movement_loop(delta):
	var dir = movedir.normalized()
	
	dir = dir.normalized()
	
	var new_pos = dir * SPEED
	var hv = velocity
	var accel  = DE_ACCELERATION
	
	if (dir.dot(hv) > 0):
		accel = ACCELERATION

	velocity = hv.linear_interpolate(new_pos, accel * delta)
	velocity = move_and_slide(velocity)

func spritedir_loop():
	if flip and movedir.x > 0:
		flip = false
		$Sprite.flip_h = flip
	elif not flip and movedir.x < 0:
		flip = true
		$Sprite.flip_h = flip

func take_damage(damage):
	HEALTH -= damage
	if $Hit:
		$Hit.play()
	if HEALTH <= 0:
		die()
		
func die():
	queue_free()
	emit_signal("died")

func _on_hitbox_area_entered(area):
	var body
	if area.get("DAMAGE") != null:
		body = area
	else:
		body = area.get_parent()
	if body.get("DAMAGE") != null and body.get("TYPE") != TYPE:
		if (TYPE == global.ENTITY.ENEMY and body.get("TYPE") == global.ENTITY.ENEMY_NO_KNOCKBACK):
			return
		if body.has_method("explode"):
			body.explode()
		take_damage(body.get("DAMAGE"))
		if body.get("TYPE") in [global.ENTITY.ENEMY, global.ENTITY.PLAYER] and HitStun != null and HitStun.time_left == 0:
			knockdir = transform.origin - body.transform.origin
			HitStun.start()