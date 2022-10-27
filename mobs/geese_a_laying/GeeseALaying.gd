extends Mob

onready var _cannon := $Cannon

func _ready() -> void:
	._ready()

func _physics_process(delta: float) -> void:
	if not _target:
		return
		
	_cannon.look_at(_target.global_position)
	
	if _target_within_range:
		prepare_to_attack()

	var direction = _target.global_position.direction_to(global_position)
	_sprite.flip_h = sign(direction.x) == 1

func prepare_to_attack() -> void:
	if not is_ready_to_attack():
		return
	_before_attack_timer.start()

func _on_BeforeAttackTimer_timeout() -> void:
	if not _target:
		return
	_cannon.shoot_at_target(_target)
	_cooldown_timer.start()
	_sprite.frame = 1
	
func _on_CoolDownTimer_timeout() -> void:
	_sprite.frame = 0
