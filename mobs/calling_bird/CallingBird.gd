extends Mob

const SonicRing := preload("res://bullets/sonic_ring/SonicRing.tscn")

# Keeps its distance (kite) instead of closing in, and calls an expanding sonic ring instead of
# firing a bullet.
@export var kite_min_range := 140.0
@export var kite_max_range := 220.0
@export_range(0.0, 1.0, 0.01) var attack_phase_stagger := 0.5

@onready var walk_anim := $WalkAnimation

# Four calling birds spawned together take the four compass points around the player (the same
# sibling-counting pattern FrenchHen._ready() uses for its triangle formation, just quantized to
# 4 points instead of 3) and split into two attack phases — opposite compass points (N/S, E/W)
# share a phase, so rings land in an alternating cross pattern rather than all four at once.
var _formation_angle := 0.0
var _attack_phase := 0

func _ready() -> void:
	super._ready()
	walk_anim.play("idle")
	var siblings := get_parent().get_children().filter(func(n): return n != self and n.get_script() == get_script())
	var slot := siblings.size() % 4
	_formation_angle = TAU * slot / 4.0
	_attack_phase = slot % 2
	if _attack_phase == 1:
		_cooldown_timer.start(attack_cooldown_stagger_seconds())

func attack_cooldown_stagger_seconds() -> float:
	return _cooldown_timer.wait_time * attack_phase_stagger

func _physics_process(_delta: float) -> void:
	if not _target:
		return

	var distance := global_position.distance_to(_target.global_position)
	if distance < kite_min_range:
		var away := global_position + global_position.direction_to(_target.global_position) * -1.0 * 50.0
		follow(away)
	elif distance > kite_max_range:
		var slot_point := _target.global_position + Vector2.RIGHT.rotated(_formation_angle) * ((kite_min_range + kite_max_range) * 0.5)
		follow(slot_point)
	else:
		orbit_target()

	_sprite.flip_h = _target.global_position.x < global_position.x

	var is_running: bool = _velocity.length() > speed / 2.0
	if is_running and walk_anim.current_animation == "idle":
		walk_anim.play("walk")
	elif not is_running and walk_anim.current_animation == "walk":
		walk_anim.play("idle")

	# Must stay within SonicRing's max_radius (280, well past this 264) — the ring spawns at the
	# bird's own position, not the player's, so attacking from further out than the ring's reach
	# would just never actually hit anyone.
	if distance <= kite_max_range * 1.2:
		prepare_to_attack()

func prepare_to_attack() -> void:
	if not is_ready_to_attack():
		return
	_before_attack_timer.start()

func _on_BeforeAttackTimer_timeout() -> void:
	if not _target or not ViewUtil.on_screen(self, 24.0):
		return
	var ring := SonicRing.instantiate()
	ring.global_position = global_position
	get_parent().add_child(ring)
	_cooldown_timer.start()
