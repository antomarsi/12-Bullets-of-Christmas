extends Area2D

# A ground hazard left by the Maid a-Milking's splash attack: grows in, sits as a damaging puddle
# for a while, then shrinks away. Damage repeats every frame the player overlaps it, same as the
# contact-damage HurtBox pattern in Mob.gd — the player's own post-hit invulnerability blink is
# what rate-limits it, not a cooldown here.
@export var damage := 1
@export var grow_time := 0.3
@export var lifetime := 3.0
@export var shrink_time := 0.4
@export var max_radius := 36.0

@onready var _shape: CollisionShape2D = $CollisionShape2D
@onready var _sprite: Sprite2D = $Sprite2D

var _age := 0.0

func _ready() -> void:
	_update_scale(0.0)

func _process(delta: float) -> void:
	_age += delta
	var total := grow_time + lifetime + shrink_time
	var k := 1.0
	if _age < grow_time:
		k = _age / grow_time
	elif _age > grow_time + lifetime:
		k = 1.0 - (_age - grow_time - lifetime) / shrink_time
	_update_scale(clampf(k, 0.0, 1.0))

	for body in get_overlapping_bodies():
		if body is Player:
			body.take_damage(damage)

	if _age >= total:
		queue_free()

func _update_scale(k: float) -> void:
	_shape.shape.radius = max_radius * k
	_sprite.scale = Vector2.ONE * k
