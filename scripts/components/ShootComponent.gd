extends Node2D
class_name ShootComponent

@export var bullet_scene : PackedScene
@export var aim_component : AimComponent
@export var shoot_cooldown := 2.0
@export var attack_damage := 1
@export var random_angle_degrees : float = 10.0
# Maximum range a bullet can travel before it disappears.
@export var max_range : float = 200.0
# The speed of the shot bullets.
@export var max_bullet_speed : float = 1500.0
@onready var timer = $Cooldown

var can_shoot = true
var can_shoot_override = true

func _ready():
	timer.connect("timeout", on_timer_timeout)

func shoot():
	if can_shoot and can_shoot_override:
		spawn_bullet()
		can_shoot = false
		timer.start(shoot_cooldown)

func get_can_shoot():
	return can_shoot and can_shoot_override

func spawn_bullet() -> void:
	if not bullet_scene:
		return
	var attack = Attack.new()
	attack.attack_damage = attack_damage
	
	var bullet: BulletBase = bullet_scene.instantiate()
	get_tree().root.add_child(bullet)
	bullet.damage = attack
	bullet.global_transform = aim_component.get_shoot_position()
	bullet.max_range = max_range
	bullet.speed = max_bullet_speed
	bullet.randomize_rotation(deg_to_rad(random_angle_degrees))

func on_timer_timeout():
	can_shoot = true
