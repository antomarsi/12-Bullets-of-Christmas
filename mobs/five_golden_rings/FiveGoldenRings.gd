extends Mob

@export var attack_speed := 1200.0

@export_group("Pentagon formation")
# All five rings close in from this distance; it contracts toward min_formation_radius as they
# orbit, so the ring reads as "closing in" rather than holding a fixed circle.
@export var max_formation_radius := 260.0
# Must stay below close_attack_range, or the formation settles into a stable orbit that never
# actually gets close enough to trigger a charge.
@export var min_formation_radius := 80.0
@export var contract_time := 6.0
# How close counts as "close enough to charge" — checked directly against distance rather than
# the inherited _target_within_range flag, because the base Mob.tscn's AttackArea radius (~350px)
# is sized for ranged attackers and would otherwise trip the moment DetectionArea does, skipping
# the formation/contraction phase almost entirely (the same reason CallingBird ignores that flag
# and computes its own kiting distance instead).
@export var close_attack_range := 110.0
# Each death speeds up everyone left (fewer rings = the remaining ones get bolder), up to this cap.
@export var speed_up_per_death := 0.12

@onready var _hurtbox := $HurtBox
@onready var _collision_shape := $CollisionShape2D
@onready var _line_of_sight := $RayCast2D

var _is_in_attack_state := false
var _charge_direction := Vector2()
var _spawn_order := 0
var _time_alive := 0.0

func _ready() -> void:
	super._ready()
	_hurtbox.connect("body_entered", Callable(self, "_on_HurtBox_body_entered"))
	var siblings := get_parent().get_children().filter(func(n): return n != self and n.get_script() == get_script())
	_spawn_order = siblings.size()
	# Stagger each ring's first windup by its spawn order (thumb to pinky), so they don't all
	# charge at once — the same cooldown-prestart trick CallingBird uses for its attack phases.
	_cooldown_timer.start(_cooldown_timer.wait_time * _spawn_order / 5.0)

func _on_DetectionArea_body_entered(body: Player) -> void:
	_target = body
	_line_of_sight.enabled = true

func _on_DetectionArea_body_exited(_body: Player) -> void:
	# Mob.gd's base handler already ignores this for an always_aware mob (which every ring is) —
	# this override only needs to add the line-of-sight toggle on top.
	if always_aware:
		return
	_target = null
	_line_of_sight.enabled = false

func _rotate_towards(pos: Vector2, factor := 0.5) -> void:
	var rot: float = lerp(rotation, pos.angle_to_point(global_position), factor)
	_sprite.rotation = rot
	_collision_shape.rotation = rot
	_hurtbox.rotation = rot

func does_see_target() -> bool:
	return _line_of_sight.is_colliding() and _line_of_sight.get_collider() == _target

# Living rings only, in stable spawn order, so the pentagon smoothly becomes a square then a
# triangle as rings die instead of leaving a gap where a dead one used to be.
func _living_rings() -> Array:
	var siblings := get_parent().get_children().filter(func(n):
		return n.get_script() == get_script() and not n.is_queued_for_deletion() and n.get("health") != null and n.health > 0
	)
	siblings.sort_custom(func(a, b): return a._spawn_order < b._spawn_order)
	return siblings

func _speed_multiplier(living_count: int) -> float:
	return 1.0 + speed_up_per_death * (5 - living_count)

func _physics_process(delta: float) -> void:
	if not _target:
		return

	_time_alive += delta
	_rotate_towards(_target.global_position, 1)
	_line_of_sight.target_position = _target.global_position - global_position
	var mult := _speed_multiplier(_living_rings().size())
	speed = 250.0 * mult

	if _is_in_attack_state:
		_velocity = attack_speed * mult * _charge_direction
		set_velocity(_velocity)
		move_and_slide()
		_velocity = velocity
		# Bounce off walls instead of sticking to them, so a charge that clips a pillar keeps
		# threatening rather than just stalling dead against it.
		if get_slide_collision_count() > 0:
			var normal := get_slide_collision(0).get_normal()
			_charge_direction = _charge_direction.bounce(normal)
	elif global_position.distance_to(_target.global_position) <= close_attack_range:
		orbit_target()
		_prepare_to_attack()
	else:
		_orbit_formation()

	_sprite.modulate = Color.WHITE if _before_attack_timer.is_stopped() else Color(1.0, 0.95, 0.4)

# Chasing position: a point on a shrinking ring around the player, offset by this ring's current
# slot in the live formation (recomputed every frame so the shape contracts as siblings die).
func _orbit_formation() -> void:
	var living := _living_rings()
	var living_count: int = maxi(living.size(), 1)
	var slot: int = living.find(self)
	if slot < 0:
		slot = 0
	var angle := TAU * slot / living_count
	var radius: float = lerpf(max_formation_radius, min_formation_radius, clampf(_time_alive / contract_time, 0.0, 1.0))
	var slot_point := _target.global_position + Vector2.RIGHT.rotated(angle) * radius
	follow(slot_point)

func _prepare_to_attack() -> void:
	if not is_ready_to_attack():
		return
	_before_attack_timer.start()
	_enter_attack_state()

func _on_BeforeAttackTimer_timeout() -> void:
	# The target might have exited the range while the timeout was running,
	# so we check again
	if not _target:
		_exit_attack_state()
		return
	_charge_direction = global_position.direction_to(_target.global_position)
	_cooldown_timer.start()

func _on_CoolDownTimer_timeout() -> void:
	_exit_attack_state()

func _enter_attack_state() -> void:
	_is_in_attack_state = true

func _exit_attack_state() -> void:
	_charge_direction = Vector2()
	_is_in_attack_state = false

func _on_HurtBox_body_entered(body: Node) -> void:
	if body is Player:
		body.take_damage(damage)
		_exit_attack_state()
