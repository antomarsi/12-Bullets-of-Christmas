extends Mob

const SonicRing := preload("res://bullets/sonic_ring/SonicRing.tscn")

enum Phase { APPROACH, WINDUP, AIRBORNE, RECOVER }

@export_group("Leap")
@export var windup_time := 0.5
@export var leap_duration := 0.5
@export var leap_arc_height := 50.0
@export var recover_time := 0.4
# How often the "whose turn is it" wave slot rotates — ten lords leap one at a time, like
# leapfrog, instead of all fighting over the same cooldown independently. Must be at least
# windup_time + leap_duration or two neighboring slots' turns overlap mid-leap (found via
# test_lord_leap.gd: with the default windup+leap totaling 1.0s, a 0.6s interval let a second
# lord start its own windup before the first had even landed).
@export var leap_wave_interval := 1.0
@export var landing_damage := 1

@onready var _hurtbox := $HurtBox
@onready var _line_of_sight := $RayCast2D

var _phase := Phase.APPROACH
var _phase_time := 0.0
var _leap_start := Vector2.ZERO
var _leap_target := Vector2.ZERO
var _invulnerable := false

func _ready() -> void:
	super._ready()
	_hurtbox.connect("body_entered", Callable(self, "_on_HurtBox_body_entered"))

func _on_DetectionArea_body_entered(body: Player) -> void:
	_target = body
	_line_of_sight.enabled = true

func _on_DetectionArea_body_exited(_body: Player) -> void:
	if always_aware:
		return
	_target = null
	_line_of_sight.enabled = false

# Living lords, self included, in spawn order — resolved fresh every frame (never cached at
# _ready()) per the lesson from the Swan/Ladies formation bugs: several lords spawned in the
# same frame can all have _ready() deferred until after the whole batch's add_child() calls,
# so a count-my-siblings-now snapshot would see the same number for everyone.
func _troupe() -> Array:
	return get_parent().get_children().filter(func(n):
		return n.get_script() == get_script() and not n.is_queued_for_deletion() and n.get("health") != null and n.health > 0
	)

# Exactly one lord is "it" at any moment, rotating through the troupe on a shared clock that
# every lord reads identically (the engine's own elapsed time) rather than anything
# per-instance — sidesteps the same spawn-order trap without needing any cross-instance signal.
func _is_my_turn_to_leap(troupe: Array) -> bool:
	var idx: int = maxi(troupe.find(self), 0)
	var count: int = maxi(troupe.size(), 1)
	var slot := int(Time.get_ticks_msec() / 1000.0 / leap_wave_interval) % count
	return slot == idx

func _physics_process(delta: float) -> void:
	if not _target:
		return

	match _phase:
		Phase.APPROACH:
			follow(_target.global_position)
			_line_of_sight.target_position = _target.global_position - global_position
			if is_ready_to_attack() and _is_my_turn_to_leap(_troupe()) and ViewUtil.on_screen(self, 24.0):
				_start_windup()
		Phase.WINDUP:
			_phase_time += delta
			if _phase_time >= windup_time:
				_start_airborne()
		Phase.AIRBORNE:
			_phase_time += delta
			var t: float = clampf(_phase_time / leap_duration, 0.0, 1.0)
			global_position = _leap_start.lerp(_leap_target, t)
			_sprite.position.y = -sin(t * PI) * leap_arc_height
			if t >= 1.0:
				_land()
		Phase.RECOVER:
			_phase_time += delta
			if _phase_time >= recover_time:
				_phase = Phase.APPROACH
				_cooldown_timer.start()

	_sprite.flip_h = sign(_target.global_position.direction_to(global_position).x) == 1

func _start_windup() -> void:
	_phase = Phase.WINDUP
	_phase_time = 0.0
	_leap_start = global_position
	_leap_target = _target.global_position
	var telegraph := SpawnTelegraph.new()
	telegraph.duration = windup_time
	telegraph.position = _leap_target
	get_parent().add_child(telegraph)

func _start_airborne() -> void:
	_phase = Phase.AIRBORNE
	_phase_time = 0.0
	_invulnerable = true

func _land() -> void:
	_phase = Phase.RECOVER
	_phase_time = 0.0
	_sprite.position.y = 0.0
	_invulnerable = false
	var ring := SonicRing.instantiate()
	ring.damage = landing_damage
	ring.global_position = global_position
	get_parent().add_child(ring)

func take_damage(amount: int) -> void:
	if _invulnerable:
		return
	super.take_damage(amount)

func _on_HurtBox_body_entered(body: Node) -> void:
	if body is Player:
		body.take_damage(damage)
