extends Mob

onready var _cannon := $Cannon
onready var walk_anim := $WalkAnimation

func _ready() -> void:
	._ready()
	walk_anim.play("idle")

func _physics_process(delta: float) -> void:
	if not _target:
		return
		
	_cannon.look_at(_target.global_position)
	
	if _target_within_range:
		orbit_target()
		prepare_to_attack()
	else:
		follow(_target.global_position)
	var direction = _target.global_position.direction_to(global_position)
	_sprite.flip_h = sign(direction.x) == 1
	
	var is_running = _velocity.length() > speed / 2.0

	if is_running and walk_anim.current_animation == "idle":
		walk_anim.play("walk")
	elif not is_running and walk_anim.current_animation == "walk":
		walk_anim.play("idle")

func prepare_to_attack() -> void:
	if not is_ready_to_attack():
		return
	_before_attack_timer.start()

func _on_BeforeAttackTimer_timeout() -> void:
	if not _target:
		return
	_cannon.shoot_at_target(_target)
	_cooldown_timer.start()
	
