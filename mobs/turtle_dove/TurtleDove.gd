extends Mob

enum COLOR { RED, PURPLE, ORANGE, BLUE }
enum Phase { CHASE, WINDUP, DASH, RECOVER }

@export var selected_color: COLOR

@export_group("Dash attack")
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
@export var telegraph_color := Color(1.0, 0.2, 0.2)

@onready var _walk_anim := $WalkAnimation

var _state := Phase.CHASE
var _state_time := 0.0
var _cooldown := 1.0
var _dash_dir := Vector2.RIGHT

func _ready() -> void:
	super._ready()
	match(selected_color):
		COLOR.RED:
			_walk_anim.play("walk_red")
		COLOR.BLUE:
			_walk_anim.play("walk_blue")
		COLOR.ORANGE:
			_walk_anim.play("walk_orange")
		COLOR.PURPLE:
			_walk_anim.play("walk_blue")

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
			_sprite.position.x = randf_range(-1.0, 1.0) if _state_time > windup_time * 0.5 else 0.0
			queue_redraw()
			if _state_time >= windup_time:
				_set_state(Phase.DASH)
		Phase.DASH:
			set_velocity(_dash_dir * attack_speed)
			move_and_slide()
			_velocity = velocity
			if _state_time >= dash_time:
				_set_state(Phase.RECOVER)
		Phase.RECOVER:
			_settle()
			if _state_time >= recover_time:
				_cooldown = attack_cooldown
				_set_state(Phase.CHASE)
	_sprite.flip_h = _target.global_position.x < global_position.x

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

# Danger line along the dash path: thin while it still tracks the player, thick once locked.
func _draw() -> void:
	if _state != Phase.WINDUP:
		return
	var k := clampf(_state_time / windup_time, 0.0, 1.0)
	var locked := _state_time >= windup_time * 0.5
	var color := telegraph_color
	color.a = lerpf(0.3, 0.85, k)
	var end := _dash_dir * attack_speed * dash_time
	draw_line(Vector2.ZERO, end, color, 4.0 if locked else 1.0)
	if locked:
		var side := _dash_dir.orthogonal() * 7.0
		draw_colored_polygon(PackedVector2Array([end + _dash_dir * 12.0, end + side, end - side]), color)
		_sprite.modulate = Color(1.0, 0.55 + 0.4 * sin(_state_time * 30.0), 0.55 + 0.4 * sin(_state_time * 30.0))

func _die() -> void:
	if _state == Phase.DASH and _target:
		remove_collision_exception_with(_target)
	super._die()
