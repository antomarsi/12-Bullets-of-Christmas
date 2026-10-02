extends Mob

enum COLOR { RED, BLUE, ORANGE, PURPLE }
enum Phase { CHASE, WINDUP, DASH, RECOVER }

# Gameplay spawns want a random bandana color each time; tests set this false and assign
# selected_color explicitly (before add_child, so it sticks) for deterministic runs.
@export var randomize_color := true
@export var selected_color: COLOR = COLOR.RED

@export_group("Dash attack")
# Base values, tuned for RED (fast straight sai lunge). Other colors scale these in _ready().
@export var attack_speed := 650.0
# Starts a wind-up when the player is closer than this.
@export var attack_range := 280.0
# The danger line shows for this long; it follows the player for the first half, then locks.
@export var windup_time := 0.9
@export var dash_time := 0.45
# Standing still (and hittable) after the dash.
@export var recover_time := 0.9
# Pause between the end of a recovery and the next wind-up.
@export var attack_cooldown := 0.5

const COLOR_TINT := {
	COLOR.RED: Color(1.0, 0.2, 0.2),
	COLOR.BLUE: Color(0.3, 0.55, 1.0),
	COLOR.ORANGE: Color(1.0, 0.6, 0.1),
	COLOR.PURPLE: Color(0.75, 0.35, 1.0),
}
# Blue's second slash swings this far past the first (radians) to read as an X-shaped double hit.
# Kept modest so the second leg still closes in on the target instead of veering wide of it.
const BLUE_SLASH_ANGLE := 0.8
# Purple's bo-staff sweep: the telegraph draws a wide arc (reads as a big swing), but the dove's
# own path only follows a fraction of that curve, or the wind-up's wide arc would send it curving
# past the target's side instead of connecting.
const PURPLE_SWEEP_ANGLE := 0.6
const PURPLE_MOVE_SWEEP_FACTOR := 0.3

@onready var _walk_anim := $WalkAnimation
@onready var _hurtbox_shape: CollisionShape2D = $HurtBox/CollisionShape2D

var _state := Phase.CHASE
var _state_time := 0.0
var _cooldown := 1.0
var _dash_dir := Vector2.RIGHT
var _dash_dir2 := Vector2.RIGHT
var _base_hurtbox_radius := 0.0

func _ready() -> void:
	super._ready()
	if randomize_color:
		selected_color = randi() % 4
	match selected_color:
		COLOR.RED:
			_walk_anim.play("walk_red")
		COLOR.BLUE:
			_walk_anim.play("walk_blue")
		COLOR.ORANGE:
			_walk_anim.play("walk_orange")
		COLOR.PURPLE:
			_walk_anim.play("walk_purple")
	if _hurtbox_shape and _hurtbox_shape.shape is CircleShape2D:
		_base_hurtbox_radius = _hurtbox_shape.shape.radius
	# Scale the shared dash/telegraph machine per color instead of branching every timing value.
	match selected_color:
		COLOR.RED:
			pass
		COLOR.BLUE:
			windup_time *= 0.85
		COLOR.ORANGE:
			# Spin-advance: slower push toward the target, longer attack window, shorter reach.
			attack_speed *= 0.55
			dash_time *= 2.0
			attack_range *= 0.8
		COLOR.PURPLE:
			# Bo staff: slower but longer reach and a longer swing.
			attack_speed *= 0.65
			dash_time *= 1.8
			attack_range *= 1.3
			windup_time *= 1.2

func _on_DetectionArea_body_entered(body: Player) -> void:
	_target = body

func _on_DetectionArea_body_exited(_body: Player) -> void:
	pass

func _physics_process(delta: float) -> void:
	if not _target:
		return
	_state_time += delta
	match _state:
		Phase.CHASE:
			_cooldown -= delta
			var distance := global_position.distance_to(_target.global_position)
			if distance <= attack_range and _cooldown <= 0.0:
				_set_state(Phase.WINDUP)
			elif distance > attack_range * 0.7:
				follow(_target.global_position)
			else:
				orbit_target()
		Phase.WINDUP:
			_settle()
			if _state_time < windup_time * 0.5:
				_dash_dir = global_position.direction_to(_target.global_position)
				_dash_dir2 = _dash_dir.rotated(BLUE_SLASH_ANGLE)
			_sprite.position.x = randf_range(-1.0, 1.0) if _state_time > windup_time * 0.5 else 0.0
			queue_redraw()
			if _state_time >= windup_time:
				_set_state(Phase.DASH)
		Phase.DASH:
			_dash_step(delta)
			move_and_slide()
			_velocity = velocity
			if _state_time >= dash_time:
				_reset_hurtbox()
				_set_state(Phase.RECOVER)
		Phase.RECOVER:
			_settle()
			if _state_time >= recover_time:
				_cooldown = attack_cooldown
				_set_state(Phase.CHASE)
	_sprite.flip_h = _target.global_position.x < global_position.x

# Per-color movement during the DASH phase. All colors keep net progress toward the target so the
# dove always actually reaches (and passes through) whoever it's attacking.
func _dash_step(_delta: float) -> void:
	var k := clampf(_state_time / dash_time, 0.0, 1.0)
	match selected_color:
		COLOR.RED:
			# Fast straight lunge.
			set_velocity(_dash_dir * attack_speed)
		COLOR.BLUE:
			# Two quick hits at an angle from each other, like a double katana slash.
			var dir := _dash_dir if _state_time < dash_time * 0.5 else _dash_dir2
			set_velocity(dir * attack_speed)
		COLOR.ORANGE:
			# Nunchaku spin: wobbles in a tight corkscrew while still closing distance, and the
			# hurtbox pulses outward through the middle of the attack.
			var wobble := _dash_dir.rotated(sin(_state_time * 24.0) * 0.5)
			set_velocity(wobble * attack_speed)
			if _hurtbox_shape and _hurtbox_shape.shape is CircleShape2D:
				_hurtbox_shape.shape.radius = _base_hurtbox_radius * (1.0 + 0.9 * sin(k * PI))
		COLOR.PURPLE:
			# Bo staff sweep: the swing curves from one side of the target to the other.
			var angle := lerpf(-PURPLE_SWEEP_ANGLE, PURPLE_SWEEP_ANGLE, k) * PURPLE_MOVE_SWEEP_FACTOR
			var swept := _dash_dir.rotated(angle)
			set_velocity(swept * attack_speed)

func _reset_hurtbox() -> void:
	if _hurtbox_shape and _hurtbox_shape.shape is CircleShape2D:
		_hurtbox_shape.shape.radius = _base_hurtbox_radius

func _set_state(new_state: Phase) -> void:
	if _state == Phase.DASH and _target:
		remove_collision_exception_with(_target)
	_state = new_state
	_state_time = 0.0
	_sprite.position.x = 0.0
	_sprite.modulate = Color.WHITE
	queue_redraw()
	if new_state == Phase.DASH and _target:
		# Slip through the player instead of being blocked by them.
		add_collision_exception_with(_target)

func _settle() -> void:
	_velocity = _velocity.lerp(Vector2.ZERO, 0.25)
	set_velocity(_velocity)
	move_and_slide()

func is_winding_up() -> bool:
	return _state == Phase.WINDUP

func is_dashing() -> bool:
	return _state == Phase.DASH

# Telegraph shape is unique per color, so a busy screen with mixed doves stays readable.
func _draw() -> void:
	if _state != Phase.WINDUP:
		return
	var k := clampf(_state_time / windup_time, 0.0, 1.0)
	var locked := _state_time >= windup_time * 0.5
	var color: Color = COLOR_TINT[selected_color]
	color.a = lerpf(0.3, 0.85, k)
	match selected_color:
		COLOR.RED:
			_draw_line_telegraph(_dash_dir, attack_speed * dash_time, color, locked)
		COLOR.BLUE:
			_draw_line_telegraph(_dash_dir, attack_speed * dash_time * 0.5, color, locked)
			_draw_line_telegraph(_dash_dir2, attack_speed * dash_time * 0.5, color, locked)
		COLOR.ORANGE:
			var radius: float = _base_hurtbox_radius * 1.9
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, color, 3.0 if locked else 1.0)
		COLOR.PURPLE:
			var reach: float = attack_speed * dash_time
			var a0: float = _dash_dir.rotated(-PURPLE_SWEEP_ANGLE).angle()
			var a1: float = _dash_dir.rotated(PURPLE_SWEEP_ANGLE).angle()
			draw_arc(Vector2.ZERO, reach, a0, a1, 16, color, 5.0 if locked else 1.5)
	if locked:
		_sprite.modulate = Color(1.0, 0.55 + 0.4 * sin(_state_time * 30.0), 0.55 + 0.4 * sin(_state_time * 30.0))

func _draw_line_telegraph(dir: Vector2, length: float, color: Color, locked: bool) -> void:
	var end := dir * length
	draw_line(Vector2.ZERO, end, color, 4.0 if locked else 1.0)
	if locked:
		var side := dir.orthogonal() * 7.0
		draw_colored_polygon(PackedVector2Array([end + dir * 12.0, end + side, end - side]), color)

func _die() -> void:
	if _state == Phase.DASH and _target:
		remove_collision_exception_with(_target)
	super._die()
