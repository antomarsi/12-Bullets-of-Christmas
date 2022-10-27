class_name Player
extends KinematicBody2D

export var max_health := 5

export var speed := 650.0

export (float, 0.01, 1.0) var drag_factor := 0.12

var health := max_health setget set_health
var velocity := Vector2.ZERO

onready var _camera := $ShakingCamera2D
onready var _damage_audio = $DamageAudio
onready var _death_audio = $DeathAudio
onready var _smoke_particles := $SmokeParticles
onready var _skin := $Skin
onready var _gun_holder := $GunHolder

func _ready() -> void:
	# ON DEATH
	_death_audio.connect("finished", get_tree(), "change_scene", ["res://interface/GameOver.tscn"])


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var desired_velocity := speed * direction
	var steering := desired_velocity - velocity
	velocity += steering * drag_factor
	velocity = move_and_slide(velocity, Vector2.ZERO)
	
	var is_running = velocity.length() > speed / 2.0
	
	_smoke_particles.emitting = is_running
	if _skin.animation == "idle" and is_running:
		_skin.play("running")
	elif _skin.animation == "running" and not is_running:
		_skin.play("idle")
	_skin.flip_h = sign(direction.x) == -1
	
	
func set_health(new_health: int) -> void:
	health = clamp(new_health, 0, max_health)
	Events.emit_signal("player_health_changed", health)

func take_damage(amount: int) -> void:
	if health <= 0:
		return
	set_health(health - amount)
	
	if health <= 0:
		_disable()
		_gun_holder.hide()
		_death_audio.play()
	else:
		_damage_audio.play()
		_camera.shake_intensity += 0.6

func _disable() -> void:
	set_process(false)
	set_physics_process(false)
	collision_mask = 0
	collision_layer = 0
