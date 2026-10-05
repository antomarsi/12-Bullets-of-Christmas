class_name Mob
extends CharacterBody2D


# The damage this mob inflicts when it hits the player.
@export var damage := 1
# How much damage the mob can take before dying.
@export var health := 2
# How far from the player this mob will orbit. The export hint in parentheses limits
# The minimum and maximum orbit distance you can choose.
@export_range(50.0, 400.0, 1.0) var orbit_distance := 200.0
# Movement speed in pixels per second.
@export var speed := 250.0

# This will be set if the robot is in view
var _target: Player = null
# if the robot can be attacked
var _target_within_range := false

# The velocity of the enemy
var _velocity := Vector2.ZERO
# How fast the enemy can react
var _drag_factor := 6.0
# Detects when player is close


@onready var _nav_agent: NavigationAgent2D = $NavigationAgent2D
@onready var _detection_area := $DetectionArea
# Detects when player is within attack range; smaller than detection area.
@onready var _attack_area := $AttackArea
# Plays a sound when the mob dies.
@onready var _die_sound := $DieSound
# Wind-up time just before attacking.
@onready var _before_attack_timer := $BeforeAttackTimer
# Waiting time before attacking again.
@onready var _cooldown_timer := $CoolDownTimer
# The enemy sprite itself. Unused in the base mob, but can be useful in
# inherited mobs.
@onready var _sprite := $Sprite2D
# Another sprite that is visible when the enemy is alerted. Can be a different
# color, a "!" sign, anything.
@onready var _sprite_alert := $Sprite2D/Alert
# The animation player.
@onready var _animation_player := $AnimationPlayer

var _hurtbox_area: Area2D = null


@export var always_aware := true

func _ready() -> void:
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	if always_aware:
		_target = get_tree().get_first_node_in_group("player")
	_ensure_hurtbox_reach()
	# This area detects when the player gets in range of the mob. Use it to play
	# "wake-up" style animations, or get the mob to track the player.
	_detection_area.connect("body_entered", Callable(self, "_on_DetectionArea_body_entered"))
	_detection_area.connect("body_exited", Callable(self, "_on_DetectionArea_body_exited"))
	# This is another area that detects when the player gets within attack range.
	_attack_area.connect("body_entered", Callable(self, "_on_AttackArea_body_entered"))
	_attack_area.connect("body_exited", Callable(self, "_on_AttackArea_body_exited"))
	# We connect the die sound to call queue_free after it
	_die_sound.connect("finished", Callable(self, "_on_DieSound_finished"))
	# There's a little wind up before attacking, and we attack once it times out.
	_before_attack_timer.connect("timeout", Callable(self, "_on_BeforeAttackTimer_timeout"))
	_cooldown_timer.connect("timeout", Callable(self, "_on_CoolDownTimer_timeout"))
	# _sprite_alert is when the player is in view. We start out with it invisible.
	_sprite_alert.visible = false
	
# Contact-damage mobs have a HurtBox; it must reach past the body, otherwise the body collides with
# the player first and the hurtbox never overlaps it (the doves and rings could not hurt anyone).
func _ensure_hurtbox_reach() -> void:
	var hurt := get_node_or_null("HurtBox")
	_hurtbox_area = hurt as Area2D
	var body_shape := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if hurt == null or body_shape == null or body_shape.shape == null:
		return
	var body_rect := body_shape.shape.get_rect()
	var reach := maxf(body_rect.size.x, body_rect.size.y) * 0.5 + 12.0
	for child in hurt.get_children():
		if child is CollisionShape2D and child.shape != null:
			var rect: Rect2 = child.shape.get_rect()
			if maxf(rect.size.x, rect.size.y) * 0.5 < reach:
				var circle := CircleShape2D.new()
				circle.radius = reach
				child.shape = circle
				child.position = body_shape.position

# Contact damage keeps applying while the player stays inside the HurtBox (the player's
# blinking invincibility after a hit stops it from draining health every frame).
func _process(_delta: float) -> void:
	if _hurtbox_area == null or health <= 0:
		return
	for body in _hurtbox_area.get_overlapping_bodies():
		if body is Player:
			body.take_damage(damage)

func is_ready_to_attack() -> bool:
	return (
		_target
		and _cooldown_timer.is_stopped()
		and _before_attack_timer.is_stopped()
	)

func follow(target_global_position: Vector2) -> void:
	var steer_target := target_global_position
	# Route around obstacles when a room has baked a navmesh (tile rooms only — see BaseRoom.gd);
	# legacy night==0 test rooms with no tile map never get a NavRegion, so this stays false there
	# and behavior is unchanged. A brand-new region can take a physics tick to register with the
	# server, so "no path yet" is treated the same as "no navigation at all" — falls back to a
	# direct line for that one tick instead of stalling, and self-corrects next frame.
	if _navigation_available():
		_nav_agent.target_position = target_global_position
		if not _nav_agent.is_navigation_finished():
			steer_target = _nav_agent.get_next_path_position()
	var desired_velocity := global_position.direction_to(steer_target) * speed
	var steering := desired_velocity - _velocity
	_velocity += steering / _drag_factor
	set_velocity(_velocity)
	move_and_slide()
	_velocity = velocity

func _navigation_available() -> bool:
	var map := get_world_2d().navigation_map
	return NavigationServer2D.map_get_regions(map).size() > 0

func orbit_target() -> void:
	if not _target:
		return
	var direction := _target.global_position.direction_to(global_position)
	var offset_from_target := direction.rotated(PI / 6.0) * orbit_distance
	follow(_target.global_position + offset_from_target)

func take_damage(amount: int) -> void:
	health -= amount
	if health <= 0:
		_die()
	else:
		_animation_player.stop()
		_animation_player.play("hit")
	
func _die() -> void:
	_disable()
	Events.emit_signal("mob_died", self)
	_animation_player.play("die")
	_die_sound.play()

func _disable() -> void:
	collision_mask = 0
	collision_layer = 0
	_detection_area.set_deferred("monitoring", false)
	_detection_area.set_deferred("monitorable", false)
	_detection_area.collision_layer = 0
	_detection_area.collision_mask = 0
	
	_attack_area.set_deferred("monitoring", false)
	_attack_area.set_deferred("monitorable", false)
	_attack_area.collision_layer = 0
	_attack_area.collision_mask = 0
	
	set_physics_process(false)
	
func _on_DieSound_finished() -> void:
	queue_free()
	
func _on_DetectionArea_body_entered(body: Player) -> void:
	_target = body
	_sprite_alert.visible = true

func _on_DetectionArea_body_exited(_body: Player) -> void:
	# An always_aware mob should never lose its target through this signal — DetectionArea can
	# report a spurious exit (even for a single newly-added mob, not just several added in the
	# same frame) while the physics server's overlap state first settles, which would otherwise
	# null _target forever (nothing else ever re-targets the player for an always-aware mob) and
	# silently freeze whatever _physics_process does with it. Found via test_five_golden_rings.gd
	# and test_goose_attack.gd hitting the same failure independently.
	if always_aware:
		return
	_target = null
	_sprite_alert.visible = false
	
	# Called when the player is within attack range.
func _on_AttackArea_body_entered(body: Player) -> void:
	_target_within_range = true

func _on_AttackArea_body_exited(_body: Player) -> void:
	_target_within_range = false
	
	# Called when the wind-up before attacking has ran out. The mob should now
# attack.
func _on_BeforeAttackTimer_timeout() -> void:
	pass

# Called when the attack was launched and recovered from. The mob is ready to
# attack again now.
func _on_CoolDownTimer_timeout() -> void:
	pass
