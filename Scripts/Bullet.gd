extends Area2D

export (int) var SPEED = 800
export (int) var DAMAGE = 1
export (float) var LIFETIME = 1

var velocity = Vector2()

func start(_position, _direction):
	position = _position
	rotation = _direction.angle()
	$Lifetime.wait_time = LIFETIME
	velocity = _direction * SPEED

func _process(delta):
	position += velocity * delta
	pass
	
func explode():
	queue_free()

func _on_Lifetime_timeout():
	explode()

func _on_Bullet_body_entered(body):
	explode()
	if body.has_method('take_damage'):
		body.take_damage(DAMAGE)

func _on_Bullet_area_shape_entered(area_id, area, area_shape, self_shape):
	print("enter")
	pass # Replace with function body.
