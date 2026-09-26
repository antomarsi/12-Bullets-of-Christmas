class_name Player
extends CharacterBody2D

@onready var anim : AnimatedSprite2D = $Skin

@export var shoot_component : ShootComponent
@export var velocity_component : VelocityComponent
@export var aim_component : AimComponent
@onready var weapon_anim := $AimComponent/AimPivot/WeaponAnimation
@onready var _smoke_particles := $SmokeParticles

@onready var health_component : HealthComponent = $HealthComponent
@onready var _damage_audio := $DamageAudio
@onready var _death_audio := $DeathAudio

@export var MAX_AMMO := 12
@export var MAX_HEALTH := 8
var current_ammo : int
var reloading = false
var dead := false

func _ready():
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	current_ammo = MAX_AMMO
	health_component.MAX_HEALTH = MAX_HEALTH
	health_component.health_updated.connect(func(h): Events.player_health_changed.emit(int(h)))
	health_component.died.connect(_on_died)
	health_component.health = MAX_HEALTH

func _physics_process(delta):
	if dead:
		return
	_move()
	_aim_and_shoot()

func take_damage(amount) -> void:
	if dead:
		return
	health_component.health -= amount
	if not dead:
		_damage_audio.play()

func _on_died() -> void:
	dead = true
	hide()
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	_death_audio.finished.connect(func(): get_tree().change_scene_to_file("res://interface/GameOver.tscn"))
	_death_audio.play()

func _aim_and_shoot():
	aim_component.move_aim(get_global_mouse_position())
	if Input.is_action_pressed("shoot") and shoot_component.get_can_shoot():
		shoot_component.shoot()
		weapon_anim.play("shoot")
		current_ammo -= 1
		if current_ammo == 0:
			shoot_component.can_shoot_override = false
			reloading = true

func _move():
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity_component.direction = direction
	velocity_component.move(self)
	if velocity_component.is_running:
		anim.play("walk")
		_smoke_particles.emitting = true
	else:
		anim.play("idle")
		_smoke_particles.emitting = false
	if velocity_component.direction.x != 0:
		anim.flip_h = sign(velocity_component.direction.x) == -1


func _on_weapon_animation_animation_finished(anim_name):
	if anim_name == "shoot" and reloading:
		weapon_anim.play("reload")
	if anim_name == "reload":
		reloading = false
		shoot_component.can_shoot_override = true
		current_ammo = MAX_AMMO
