extends CharacterBody2D

@onready var anim : AnimatedSprite2D = $Skin

@export var shoot_component : ShootComponent
@export var velocity_component : VelocityComponent
@export var aim_component : AimComponent
@onready var weapon_anim := $AimComponent/AimPivot/WeaponAnimation
@onready var _smoke_particles := $SmokeParticles

@export var MAX_AMMO := 12
var current_ammo : int
var reloading = false

func _ready():
	current_ammo = MAX_AMMO

func _physics_process(delta):
	_move()
	_aim_and_shoot()

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
