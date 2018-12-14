extends Area2D

export (int) var SPEED = 800
export (int) var DAMAGE = 1
export (float) var LIFETIME = 1
export (bool) var SPINING = false
var TYPE = global.DO_DAMAGE_TO.ENEMY

var velocity = Vector2()

func start(_position, _direction):
	position = _position
	rotation = _direction.angle()
	$Lifetime.wait_time = LIFETIME
	$Lifetime.start()
	velocity = _direction * SPEED

func _process(delta):
	position += velocity * delta
	if SPINING:
		rotation += delta
	pass
	
func explode():
	queue_free()

func _on_Lifetime_timeout():
	explode()

func _on_Bullet_body_entered(body):
	if body.has_method('take_damage'):
		body.take_damage(DAMAGE)
