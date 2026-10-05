extends Node2D

# Sits on the ground for hatch_delay seconds (itself harmless — this is the landing, not the
# hit), then hatches into a radial burst of shards. Not a BulletBase: like MilkPuddle/SonicRing,
# this is a stationary hazard spawned directly at a telegraphed point, not a traveling projectile.
const ShardBullet := preload("res://bullets/basic_bullet/BasicBullet.tscn")

@export var hatch_delay := 2.0
@export var burst_count := 8
@export var burst_speed := 220.0
@export var burst_damage := 1.0
@export var burst_max_range := 500.0

@onready var _sprite: Sprite2D = $Sprite2D

var _age := 0.0

func _process(delta: float) -> void:
	_age += delta
	# A faint pulse building toward hatch_delay, so the burst itself has its own telegraph.
	var k := clampf(_age / hatch_delay, 0.0, 1.0)
	_sprite.scale = Vector2.ONE * (1.0 + 0.2 * sin(k * PI * 8.0) * k)
	if _age >= hatch_delay:
		_hatch()

func _hatch() -> void:
	BulletPattern.radial(ShardBullet, get_tree(), global_position, burst_count, 0.0, {
		"speed": burst_speed,
		"max_range": burst_max_range,
		"damage": burst_damage,
	})
	queue_free()
