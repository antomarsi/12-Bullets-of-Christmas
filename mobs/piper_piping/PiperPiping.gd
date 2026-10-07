extends Mob

const SineBullet := preload("res://bullets/sine_bullet/SineBullet.tscn")

@export_group("Column march")
# The leader (first in live spawn order, resolved fresh every frame — see _troupe()) patrols a
# slow orbit around the player; everyone else slots in behind the leader at column_spacing *
# their own rank, computed directly from the leader's current position/heading every frame — the
# same "anchor every follower off one shared reference" pattern Swan/Rings/Ladies all use.
# Earlier this chained each follower to whoever was directly ahead of IT instead, which reads
# right on paper ("a literal marching line") but is a classic pursuit-curve instability once the
# anchor itself keeps moving in a circle: each follower perpetually lags behind where its target
# already was, and that lag compounds down the chain, so the column just spirals further and
# further from the player instead of settling into formation. Found via test_piper_column.gd,
# which could never get a shot anywhere near the player once the whole column had drifted ~600px
# away over a few seconds.
@export var column_spacing := 44.0
@export var patrol_radius := 300.0
@export var patrol_turn_rate := 0.3

@export_group("Sweeping note lanes")
# Every piper fires a lane centered on its own current bearing to the player, oscillating side
# to side with a shared (time-based, not per-instance) sine pattern — so the lane always sweeps
# back through the player periodically (a real, dodgeable threat) rather than drifting through
# some arbitrary absolute world angle that might never cross anywhere near them. Found via
# test_piper_column.gd: an earlier version swept a single shared *absolute* angle with no
# relation to any piper's actual position, which could go an entire test run (and presumably
# real playtime) without ever lining up with the player at all. "The melody shifts pattern each
# phrase": every phrase_duration seconds the sweep switches to a different speed/arc width.
@export var phrase_duration := 6.0
@export var bullet_speed := 160.0
@export var bullet_max_range := 900.0

@onready var walk_anim := $WalkAnimation

var _patrol_angle := 0.0

func _ready() -> void:
	super._ready()
	walk_anim.play("idle")

func _troupe() -> Array:
	return get_parent().get_children().filter(func(n):
		return n.get_script() == get_script() and not n.is_queued_for_deletion() and n.get("health") != null and n.health > 0
	)

func _lane_angle() -> float:
	# Engine.get_physics_frames() (a simulation-synced tick counter), not Time.get_ticks_msec()
	# (real wall-clock time) — headless/fast-forwarded runs process physics steps far faster than
	# real time, so a wall-clock-based "t" barely advances at all across many simulated seconds,
	# freezing the sweep near its starting angle for the whole run. Found via test_piper_column.gd
	# after fixing the aim-direction bug still left every shot missing deterministically.
	var t := Engine.get_physics_frames() / 60.0
	var phrase: int = int(t / phrase_duration) % 3
	var sweep_speed := 0.6
	var sweep_arc := deg_to_rad(70.0)
	match phrase:
		1:
			sweep_speed = -0.9
			sweep_arc = deg_to_rad(50.0)
		2:
			sweep_speed = 1.3
			sweep_arc = deg_to_rad(90.0)
	var aim_angle := global_position.angle_to_point(_target.global_position)
	return aim_angle + sin(t * sweep_speed) * sweep_arc

func _physics_process(delta: float) -> void:
	if not _target:
		return

	var troupe := _troupe()
	var idx: int = maxi(troupe.find(self), 0)

	if idx == 0:
		_patrol_angle += delta * patrol_turn_rate
		var patrol_point: Vector2 = _target.global_position + Vector2.RIGHT.rotated(_patrol_angle) * patrol_radius
		follow(patrol_point)
	else:
		var leader: Node = troupe[0]
		var leader_velocity: Vector2 = leader.get("_velocity")
		var back_dir: Vector2 = -leader_velocity.normalized() if leader_velocity.length() > 1.0 else Vector2.LEFT
		var slot_point: Vector2 = leader.global_position + back_dir * column_spacing * idx
		follow(slot_point)

	_sprite.flip_h = _target.global_position.x < global_position.x
	var is_running: bool = _velocity.length() > speed * 0.3
	if is_running and walk_anim.current_animation == "idle":
		walk_anim.play("walk")
	elif not is_running and walk_anim.current_animation == "walk":
		walk_anim.play("idle")

	if is_ready_to_attack() and ViewUtil.on_screen(self, 24.0):
		_fire_note()

func _fire_note() -> void:
	var angle := _lane_angle()
	BulletPattern.shoot(SineBullet, get_tree(), global_position, angle, {
		"speed": bullet_speed,
		"max_range": bullet_max_range,
	})
	_cooldown_timer.start()
