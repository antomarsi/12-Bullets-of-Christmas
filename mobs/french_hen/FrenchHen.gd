extends Mob

const CroissantBullet := preload("res://bullets/croissant_bullet/CroissantBullet.tscn")

@export_group("Croissant fan attack")
@export var fan_count := 3
@export var fan_spread_degrees := 36.0
@export var bullet_speed := 220.0
@export var bullet_max_range := 900.0

@export_group("Triangle formation")
# How far out the three hens spread from the player while chasing, before one gets close enough
# to attack. Set once in _ready() from how many sibling hens already exist, so three hens spawned
# together settle into roughly the three points of a triangle around the player instead of
# stacking on the same approach line.
@export var formation_radius := 140.0

@onready var _cannon := $Cannon
@onready var _muzzle := $Cannon/Marker2D
@onready var _walk_anim := $WalkAnimation

var _formation_angle := 0.0

func _ready() -> void:
	super._ready()
	_walk_anim.play("idle")
	var siblings := get_parent().get_children().filter(func(n): return n != self and n.get_script() == get_script())
	_formation_angle = TAU * (siblings.size() % 3) / 3.0

func _physics_process(delta: float) -> void:
	if not _target:
		return

	_cannon.look_at(_target.global_position)

	if _target_within_range:
		prepare_to_attack()
	else:
		var slot := _target.global_position + Vector2.RIGHT.rotated(_formation_angle) * formation_radius
		follow(slot)

	_sprite.flip_h = sign(_target.global_position.direction_to(global_position).x) == 1

	var is_running = _velocity.length() > speed / 2.0
	if is_running and _walk_anim.current_animation == "idle":
		_walk_anim.play("walk")
	elif not is_running and _walk_anim.current_animation == "walk":
		_walk_anim.play("idle")

func prepare_to_attack() -> void:
	if not is_ready_to_attack():
		return
	_before_attack_timer.start()

func _on_BeforeAttackTimer_timeout() -> void:
	if not _target or not ViewUtil.on_screen(self, 24.0):
		return
	var pos: Vector2 = _muzzle.global_position
	var aim_angle := pos.angle_to_point(_target.global_position) + PI
	BulletPattern.fan(CroissantBullet, get_tree(), pos, aim_angle, fan_count, fan_spread_degrees, {
		"speed": bullet_speed,
		"max_range": bullet_max_range,
	})
	_cooldown_timer.start()
