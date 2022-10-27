extends Mob

onready var _cannon := $Cannon
onready var _anim := $WalkAnimation

func _ready() -> void:
	._ready()
	_anim.play("idle")
	_anim.connect("animation_finished", self, "_on_WalkAnimation_finished")

func _physics_process(delta: float) -> void:
	if not _target:
		return
		
	_cannon.look_at(_target.global_position)
	
	if _target_within_range:
		prepare_to_attack()

func prepare_to_attack() -> void:
	if not is_ready_to_attack():
		return
	_before_attack_timer.start()

func _on_BeforeAttackTimer_timeout() -> void:
	if not _target:
		return
	_anim.play("attack")
	_cannon.shoot_at_target(_target)
	_cooldown_timer.start()

func _on_WalkAnimation_finished(anim_name) -> void:
	if anim_name == "attack":
		_anim.play("idle")
	
