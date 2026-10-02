extends Mob

const MilkPuddle := preload("res://props/milk_puddle/MilkPuddle.tscn")

# Not a stand-and-shoot turret anymore: she tries to keep her distance (survive) while marking the
# player's position and splashing a damaging puddle there, instead of firing a straight bullet.
@export var keep_distance := 180.0
@export var retreat_speed_mult := 0.8
@export var puddle_telegraph_time := 0.6

@onready var _anim := $WalkAnimation

func _ready() -> void:
	super._ready()
	_anim.play("idle")
	_anim.connect("animation_finished", Callable(self, "_on_WalkAnimation_finished"))

func _physics_process(_delta: float) -> void:
	if not _target:
		return

	var distance := global_position.distance_to(_target.global_position)
	if distance > keep_distance:
		follow(_target.global_position)
	else:
		# Too close for comfort — back away instead of standing still and taking a hit.
		var away := global_position + global_position.direction_to(_target.global_position) * -1.0 * speed * retreat_speed_mult
		follow(away)

	_sprite.flip_h = _target.global_position.x < global_position.x

	if distance <= keep_distance * 1.3:
		prepare_to_attack()

func prepare_to_attack() -> void:
	if not is_ready_to_attack():
		return
	_before_attack_timer.start()

func _on_BeforeAttackTimer_timeout() -> void:
	if not _target or not ViewUtil.on_screen(self, 24.0):
		return
	_anim.play("attack")
	var target_pos: Vector2 = _target.global_position
	var telegraph := SpawnTelegraph.new()
	telegraph.duration = puddle_telegraph_time
	telegraph.position = target_pos
	telegraph.on_done = func() -> void:
		var puddle := MilkPuddle.instantiate()
		puddle.global_position = target_pos
		get_parent().add_child(puddle)
	get_parent().add_child(telegraph)
	_cooldown_timer.start()

func _on_WalkAnimation_finished(anim_name) -> void:
	if anim_name == "attack":
		_anim.play("idle")
