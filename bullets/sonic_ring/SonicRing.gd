extends Area2D

# An expanding ring hazard, not a travelling bullet — spawned at the Calling Bird's own position.
# The growing shape is its own telegraph: a thin ring that expands to max_radius over grow_time,
# damaging the player once if they're caught inside it during the expansion, then disappears.
@export var damage := 1
@export var grow_time := 0.7
@export var max_radius := 280.0
@export var ring_color := Color(0.6, 0.9, 1.0, 0.7)

@onready var _shape: CollisionShape2D = $CollisionShape2D

var _age := 0.0
var _has_hit := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	_shape.shape = CircleShape2D.new()
	_shape.shape.radius = 0.0

func _process(delta: float) -> void:
	_age += delta
	var k := clampf(_age / grow_time, 0.0, 1.0)
	_shape.shape.radius = max_radius * k
	queue_redraw()

	if not _has_hit:
		for body in get_overlapping_bodies():
			if body is Player:
				_has_hit = true
				body.take_damage(damage)
				break

	if _age >= grow_time:
		queue_free()

func _draw() -> void:
	var k := clampf(_age / grow_time, 0.0, 1.0)
	draw_arc(Vector2.ZERO, max_radius * k, 0.0, TAU, 32, ring_color, 3.0)
