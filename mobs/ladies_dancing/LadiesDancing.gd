extends Mob

const PearBullet := preload("res://bullets/pear_bullet/PearBullet.tscn")

@export_group("Rotating ring")
@export var max_ring_radius := 320.0
@export var min_ring_radius := 140.0
@export var contract_time := 8.0
@export var ring_turn_rate := 0.4
@export var spin_turn_rate := 1.8
# The ring always leaves one slot pulled wide — a gap to slip through — and that slot rotates
# around the troupe over time instead of staying in one place.
@export var gap_radius_bonus := 220.0
@export var gap_rotation_time := 2.5

@export_group("Spiral shots")
@export var spin_shoot_duration := 3.0
@export var bullet_speed := 200.0
@export var bullet_max_range := 700.0

@onready var _hurtbox := $HurtBox

var _ring_angle := 0.0
var _phase_time := 0.0
var _pending_aim_angle := 0.0

func _ready() -> void:
	super._ready()
	_hurtbox.connect("body_entered", Callable(self, "_on_HurtBox_body_entered"))

# Living troupe members, self included, in spawn order — every lady computes the same list
# independently each frame (no shared/synchronized state needed) so her own slot index and the
# current gap slot always agree with everyone else's.
func _troupe() -> Array:
	return get_parent().get_children().filter(func(n):
		return n.get_script() == get_script() and not n.is_queued_for_deletion() and n.get("health") != null and n.health > 0
	)

func _physics_process(delta: float) -> void:
	if not _target:
		return

	var troupe := _troupe()
	var count: int = maxi(troupe.size(), 1)
	var slot: int = maxi(troupe.find(self), 0)

	# The whole troupe shares one close-in/spin-and-shoot cycle, derived purely from elapsed
	# time rather than any cross-instance signal — the same "pure function of time" trick
	# CallingBird's attack-phase stagger uses, just extended into a two-state cycle.
	_phase_time += delta
	var cycle := contract_time + spin_shoot_duration
	var t := fmod(_phase_time, cycle)
	var spinning: bool = t >= contract_time

	var turn_rate := spin_turn_rate if spinning else ring_turn_rate
	_ring_angle += delta * turn_rate

	var radius: float = min_ring_radius if spinning else lerpf(max_ring_radius, min_ring_radius, clampf(t / contract_time, 0.0, 1.0))
	var gap_slot: int = int(_phase_time / gap_rotation_time) % count
	var in_gap: bool = slot == gap_slot
	if in_gap:
		radius += gap_radius_bonus

	var my_angle := _ring_angle + TAU * slot / count
	var slot_point: Vector2 = _target.global_position + Vector2.RIGHT.rotated(my_angle) * radius
	follow(slot_point)

	_sprite.flip_h = _target.global_position.x < global_position.x

	if spinning and not in_gap:
		_pending_aim_angle = my_angle
		_try_attack()

func _try_attack() -> void:
	if not is_ready_to_attack() or not ViewUtil.on_screen(self, 24.0):
		return
	_before_attack_timer.start()

func _on_BeforeAttackTimer_timeout() -> void:
	if not _target:
		return
	# Fired outward along this lady's own current ring angle (not aimed at the player) — since
	# the ring keeps rotating while every lady fires repeatedly during the spin phase, the trail
	# of shots from each moving emitter traces a spiral, the same "rotating radial burst reads as
	# a spiral" trick Partridge's own attack already uses, just spread across nine emitters.
	BulletPattern.shoot(PearBullet, get_tree(), global_position, _pending_aim_angle, {
		"speed": bullet_speed,
		"max_range": bullet_max_range,
	})
	_cooldown_timer.start()

func _on_HurtBox_body_entered(body: Node) -> void:
	if body is Player:
		body.take_damage(damage)
