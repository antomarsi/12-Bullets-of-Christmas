extends Mob

const EggBullet := preload("res://bullets/egg_bullet/EggBullet.tscn")

# How long the egg takes to land after being lobbed — also how long the SpawnTelegraph warns at
# the landing spot, so the player always sees where it's about to come down.
@export var lob_time := 0.9

@onready var _cannon := $Cannon

func _ready() -> void:
	super._ready()

func _physics_process(_delta: float) -> void:
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

# A static nester: lobs an egg at the player's current position instead of firing a straight
# shot — the telegraph gives the player the travel time to step out from under where it'll land,
# same "stationary hazard spawned at a telegraphed point" shape as MaidAMilking's puddle and
# CallingBird's sonic ring, not a Cannon/BulletPattern projectile.
func _on_BeforeAttackTimer_timeout() -> void:
	if not _target or not ViewUtil.on_screen(self, 24.0):
		return
	var landing_pos: Vector2 = _target.global_position
	var telegraph := SpawnTelegraph.new()
	telegraph.duration = lob_time
	telegraph.position = landing_pos
	telegraph.on_done = func() -> void:
		var egg := EggBullet.instantiate()
		egg.global_position = landing_pos
		get_parent().add_child(egg)
	get_parent().add_child(telegraph)
	_cooldown_timer.start()
	_sprite.frame = 1

func _on_CoolDownTimer_timeout() -> void:
	_sprite.frame = 0
