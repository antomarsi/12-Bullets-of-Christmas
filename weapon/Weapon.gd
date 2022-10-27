class_name Weapon
extends Node2D

export var bullet_scene: PackedScene

export (float, 0.0, 360.0, 1.0) var random_angle_degrees := 10.0
# Maximum range a bullet can travel before it disappears.
export (float, 100.0, 2000.0, 1.0) var max_range := 2000.0
# The speed of the shot bullets.
export (float, 100.0, 3000.0, 1.0) var max_bullet_speed := 1500.0
# The firing rate of bullets
export var fire_rate := 3.0

onready var _audio := $AudioStreamPlayer2D
onready var _cooldown_timer := $CoolDownTimer

func _ready() -> void:
	assert(bullet_scene != null, 'Bullet Scene is not provided for "%s"' % [get_path()])
	_cooldown_timer.wait_time = 1.0 / fire_rate

func shoot() -> void:
	var bullet: Bullet = bullet_scene.instance()
	get_tree().root.add_child(bullet)
	bullet.global_transform = global_transform
	bullet.max_range = max_range
	bullet.speed = max_bullet_speed
	bullet.randomize_rotation(deg2rad(random_angle_degrees))
	_audio.play()
