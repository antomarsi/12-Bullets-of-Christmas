extends Mob

export var attack_speed := 1200.0

onready var _walk_anim := $WalkAnimation
onready var _hurtbox := $HurtBox
onready var _collision_shape := $CollisionShape2D
onready var _line_of_sight := $RayCast2D

var _is_in_attack_state := false
var _charge_direction := Vector2()

func _ready() -> void:
	._ready()
	_hurtbox.connect("body_entered", self, "_on_HurtBox_body_entered")

func _on_DetectionArea_body_entered(body: Player) -> void:
	_target = body
	_line_of_sight.enabled = true

func _on_DetectionArea_body_exited(_body: Player) -> void:
	_target = null
	_line_of_sight.enabled = false

func _rotate_towards(pos: Vector2, factor := 0.5) -> void:
	var rot: float = lerp(rotation, pos.angle_to_point(global_position), factor)
	_sprite.rotation = rot
	_collision_shape.rotation = rot
	_hurtbox.rotation = rot

func does_see_target() -> bool:
	return _line_of_sight.is_colliding() and _line_of_sight.get_collider() == _target

func _physics_process(delta: float) -> void:
	if not _target:
		return
	
	_rotate_towards(_target.global_position, 1)
	_line_of_sight.cast_to = _target.global_position - global_position
	
	if _target_within_range:
		if _is_in_attack_state:
			_velocity = attack_speed * _charge_direction
			_velocity = move_and_slide(_velocity)
		else:
			orbit_target()
			_prepare_to_attack()
	else:
		follow(_target.global_position)

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
