extends Sprite


enum CollisionMask {
	PLAYER = 1,
	MOB = 2,
	BOTH = 3
}

export var BulletScene: PackedScene

export (CollisionMask) var collision_mask := CollisionMask.PLAYER

# Maximum random angle applied to the shot bullets in degrees. Controls the
# cannon's precision.
export(float, 0.0, 30.0, 1.0) var random_angle_degrees := 10.0
# Maximum distance a bullet can travel before it disappears.
export(float, 100.0, 2000.0, 1.0) var max_range := 2000.0
# The speed of the shot bullets.
export(float, 100.0, 3000.0, 1.0) var bullet_speed := 400.0

# This is the exit where the bullets will be spit out from
onready var _position_2d := $Position2D

func shoot_at_target(target: Node2D) -> void:
	look_at(target.global_position)
	var bullet: Bullet = BulletScene.instance()
	bullet.global_transform = _position_2d.global_transform
	bullet.max_range = max_range
	bullet.speed = bullet_speed
	bullet.collision_mask = collision_mask
	
	bullet.randomize_rotation(deg2rad(random_angle_degrees))
	get_tree().root.add_child(bullet)
