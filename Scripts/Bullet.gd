extends Area2D

export (int) var SPEED = 800
export (int) var DAMAGE = 1
export (float) var LIFETIME = 1
export (float) var SPIN = 0

enum BULLET_TYPE {
	ENEMY,
	PLAYER
}
onready var TYPE = global.ENTITY.PLAYER
export (BULLET_TYPE) var bullet_type

var velocity = Vector2()
func _ready():
	if bullet_type == BULLET_TYPE.ENEMY:
		TYPE = global.ENTITY.ENEMY_NO_KNOCKBACK

func start(_position, _direction):
	position = _position
	rotation = _direction.angle()
	$Lifetime.wait_time = LIFETIME
	$Lifetime.start()
	velocity = _direction * SPEED

func _process(delta):
	position += velocity * delta
	if SPIN > 0:
		rotation += delta * SPIN
	pass
	
func explode():
	queue_free()

func _on_Lifetime_timeout():
	explode()
