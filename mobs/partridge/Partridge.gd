extends Mob

@export var burst_interval := 1.8
@export var keep_distance := 220.0
@export var bullet_scene: PackedScene = preload("res://bullets/pear_bullet/PearBullet.tscn")
@export var pear_pickup: PackedScene = preload("res://pickups/HealthPickup.tscn")
@export var shoot_sound: SoundSet = preload("res://data/sounds/enemy_shoot.tres")

var _max_health := 0
var _burst_timer := 1.2
var _anim_time := 0.0

func _ready() -> void:
	super._ready()
	_max_health = health

func _enraged() -> bool:
	return health <= _max_health / 2

func _physics_process(delta: float) -> void:
	if not _target:
		return

	if global_position.distance_to(_target.global_position) > keep_distance:
		follow(_target.global_position)
	else:
		follow(global_position)

	_anim_time += delta
	_sprite.frame = int(_anim_time * 4.0) % 3
	_sprite.flip_h = _target.global_position.x < global_position.x

	_burst_timer -= delta
	if _burst_timer <= 0.0:
		_fire()
		_burst_timer = burst_interval * (0.65 if _enraged() else 1.0)

func _fire() -> void:
	if not ViewUtil.on_screen(self, 24.0):
		return
	shoot_sound.play(self, global_position)
	var count := 12 if _enraged() else 8
	# One arm of the burst always points exactly at the player's current position, recomputed
	# fresh every burst, so the attack is a real threat instead of a fixed spread that can drift
	# away from the player over time and never cross them again.
	var aim_angle := global_position.angle_to_point(_target.global_position)
	BulletPattern.radial(bullet_scene, get_tree(), global_position, count, aim_angle, {"speed": 150.0, "max_range": 700.0})

func _on_DetectionArea_body_exited(_body: Player) -> void:
	pass

func _die() -> void:
	super._die()
	var pear := pear_pickup.instantiate()
	pear.position = global_position
	BulletPattern.world(get_tree()).call_deferred("add_child", pear)
