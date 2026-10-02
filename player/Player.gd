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
@export var hit_sound: SoundSet = preload("res://data/sounds/player_hit.tres")
@export var hit_flash_color := Color(1.0, 0.25, 0.25)
# Total i-frames after a hit (flash + blink). Bullet-hell nights fire in bursts, so this stays
# short enough that a second bullet from the same burst can still land.
@export var hit_invulnerable_time := 0.45

@export_group("Roll")
@export var roll_speed := 330.0
@export var roll_duration := 0.32
@export var roll_cooldown := 0.5
# Speed multiplier at the start (>1 = a punchy burst) and end (<1 = coasting to a stop) of the
# roll; it eases from one to the other (fast initial drop-off, gentle finish), not a straight line.
@export var roll_start_speed_mult := 1.3
@export var roll_end_speed_mult := 0.4
# Optional horizontal strip of square frames (dive -> tucked roll -> recovery). Drop the PNG here
# (or save it as res://player/roll_sheet.png); frame count is read from its width/height. Empty =
# the normal sprite just spins during the roll.
@export var roll_texture: Texture2D
var _roll_frame_count := 1

@export_group("Reload")
@export var reload_time := 1.6

var _invulnerable := false
var _rolling := false
var _roll_dir := Vector2.DOWN
var _roll_left := 0.0
var _roll_cd := 0.0
var _roll_sprite: Sprite2D
var _reload_elapsed := 0.0
var _reload_bar: ReloadBar
var current_ammo : int
var reloading = false
var dead := false

func heal(amount) -> void:
	if dead:
		return
	health_component.health += amount

func _ready():
	add_to_group("player")
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	current_ammo = MAX_AMMO
	health_component.MAX_HEALTH = MAX_HEALTH
	health_component.health_updated.connect(func(h): Events.player_health_changed.emit(int(h)))
	health_component.died.connect(_on_died)
	health_component.health = MAX_HEALTH
	if roll_texture == null and ResourceLoader.exists("res://player/roll_sheet.png"):
		roll_texture = load("res://player/roll_sheet.png")
	if roll_texture:
		_roll_frame_count = maxi(roll_texture.get_width() / roll_texture.get_height(), 1)
		_roll_sprite = Sprite2D.new()
		_roll_sprite.texture = roll_texture
		_roll_sprite.hframes = _roll_frame_count
		_roll_sprite.position = anim.position
		_roll_sprite.visible = false
		add_child(_roll_sprite)
	_reload_bar = ReloadBar.new()
	_reload_bar.position = Vector2(0, -34)
	add_child(_reload_bar)

func _physics_process(delta):
	if dead:
		return
	_roll_cd = maxf(_roll_cd - delta, 0.0)
	_update_reload(delta)
	if _rolling:
		_roll_step(delta)
		return
	if Input.is_action_just_pressed("roll") and roll():
		_roll_step(delta)
		return
	if Input.is_action_just_pressed("reload"):
		start_reload()
	_move()
	_aim_and_shoot()

# --- damage ------------------------------------------------------------------------------

# True while rolling or blinking after a hit; bullets pass through and nothing hurts.
func is_invulnerable() -> bool:
	return _invulnerable or _rolling

func take_damage(amount) -> void:
	if dead or is_invulnerable():
		return
	health_component.health -= amount
	if dead:
		return
	hit_sound.play(self, global_position)
	get_tree().call_group("camera", "add_shake", 4.0)
	_hit_feedback()

# Red flash, then a short blink during which the player can't be hurt again. Total length is
# hit_invulnerable_time regardless of how many blink cycles that fits.
func _hit_feedback() -> void:
	_invulnerable = true
	anim.modulate = hit_flash_color
	var tween := create_tween()
	var flash_time := minf(0.1, hit_invulnerable_time * 0.3)
	tween.tween_property(anim, "modulate", Color.WHITE, flash_time)
	var blink_time := hit_invulnerable_time - flash_time
	var cycles := maxi(roundi(blink_time / 0.1), 1)
	var cycle_time := blink_time / cycles
	for i in cycles:
		tween.tween_property(anim, "modulate:a", 0.25, cycle_time * 0.5)
		tween.tween_property(anim, "modulate:a", 1.0, cycle_time * 0.5)
	tween.finished.connect(func():
		_invulnerable = false
		anim.modulate = Color.WHITE)

func _on_died() -> void:
	dead = true
	hide()
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	_death_audio.finished.connect(func(): get_tree().change_scene_to_file("res://interface/GameOver.tscn"))
	_death_audio.play()

# --- roll --------------------------------------------------------------------------------

func is_rolling() -> bool:
	return _rolling

# Dodge roll: fast dash with no damage taken and bullets passing through. Direction defaults
# to the movement keys, then to the aim direction. Returns false while on cooldown.
func roll(direction := Vector2.ZERO) -> bool:
	if dead or _rolling or _roll_cd > 0.0:
		return false
	var dir := direction
	if dir == Vector2.ZERO:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir == Vector2.ZERO:
		dir = (get_global_mouse_position() - global_position).normalized()
	if dir == Vector2.ZERO:
		dir = Vector2.DOWN
	_roll_dir = dir.normalized()
	_rolling = true
	_roll_left = roll_duration
	_roll_cd = roll_cooldown + roll_duration
	aim_component.visible = false
	_smoke_particles.emitting = true
	if _roll_sprite:
		anim.visible = false
		_roll_sprite.visible = true
		_roll_sprite.flip_h = _roll_dir.x < 0.0
	else:
		anim.flip_h = _roll_dir.x < 0.0
		var spin := create_tween()
		spin.tween_property(anim, "rotation", TAU * (-1.0 if _roll_dir.x < 0.0 else 1.0), roll_duration)
	return true

func _roll_step(delta: float) -> void:
	var progress := 1.0 - _roll_left / roll_duration
	if _roll_sprite:
		_roll_sprite.frame = clampi(int(progress * _roll_frame_count), 0, _roll_frame_count - 1)
	# Ease-out: (1 - progress)^2 drops fast right after the punch, then flattens into the finish.
	var ease_out := (1.0 - progress) * (1.0 - progress)
	var speed_mult := lerpf(roll_end_speed_mult, roll_start_speed_mult, ease_out)
	set_velocity(_roll_dir * roll_speed * speed_mult)
	move_and_slide()
	_roll_left -= delta
	if _roll_left <= 0.0:
		_end_roll()

func _end_roll() -> void:
	_rolling = false
	anim.rotation = 0.0
	anim.visible = true
	if _roll_sprite:
		_roll_sprite.visible = false
	aim_component.visible = true
	velocity_component.velocity = _roll_dir * velocity_component.MAX_SPEED * 0.5

# --- reload ------------------------------------------------------------------------------

# Timed reload with a bar above the player; can be started manually with R.
func start_reload() -> void:
	if reloading or dead or current_ammo >= MAX_AMMO:
		return
	reloading = true
	shoot_component.can_shoot_override = false
	_reload_elapsed = 0.0
	weapon_anim.play("reload")
	_reload_bar.begin()

func reload_progress() -> float:
	return clampf(_reload_elapsed / reload_time, 0.0, 1.0) if reloading else 0.0

func _update_reload(delta: float) -> void:
	if not reloading:
		return
	_reload_elapsed += delta
	_reload_bar.progress = _reload_elapsed / reload_time
	if _reload_elapsed >= reload_time:
		reloading = false
		current_ammo = MAX_AMMO
		shoot_component.can_shoot_override = true
		_reload_bar.finish()

# --- shooting and moving -----------------------------------------------------------------

func _aim_and_shoot():
	aim_component.move_aim(get_global_mouse_position())
	if Input.is_action_pressed("shoot") and shoot_component.get_can_shoot():
		shoot_component.shoot()
		weapon_anim.play("shoot")
		current_ammo -= 1
		if current_ammo == 0:
			start_reload()

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
	pass
