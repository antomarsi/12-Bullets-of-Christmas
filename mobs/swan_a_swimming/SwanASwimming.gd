extends Mob

@onready var _cannon := $Cannon
@onready var walk_anim := $WalkAnimation

@export_group("V formation")
# The leader is whichever living swan comes first in the flock's own child order; followers
# trail it in a V, alternating left/right by rank. This is resolved fresh every frame from
# get_children() rather than cached once at _ready() — several swans spawned in the same frame
# (the usual wave-spawn case) can all run _ready() only after every add_child() in that batch has
# already happened, so a count-my-existing-siblings-at-ready trick (FrenchHen/CallingBird's
# formation-angle idiom) would have every swan see the same final sibling count and nobody ever
# landing on "I was first" — found via test_swan_flock.gd, where it silently made every swan fall
# back to acting leaderless. get_children() order is still the real spawn order regardless.
@export var formation_spacing := 50.0

@export_group("Gliding movement")
# Swans build speed up and shed it gradually instead of Mob.follow()'s snappier steering — reads
# as gliding on ice, per the plan's "no water tiles, so swans glide with momentum" note. This
# bypasses Mob.follow()/navmesh routing entirely, which is fine since night 7's map is mostly
# open (per the plan's sketch, just four corner rocks); reuses the inherited `_velocity` the same
# way FiveGoldenRings drives its own charge state directly instead of through follow().
@export var cruise_speed := 140.0
@export var cruise_accel := 220.0
@export var cruise_turn_rate := 0.5
@export var charge_speed := 480.0
@export var charge_accel := 700.0

@export_group("Wedge charge")
@export var charge_cooldown := 5.0
@export var charge_duration := 1.6
@export var regroup_radius := 260.0

var _charging := false
var _charge_timer := 0.0
var _charge_cooldown_timer := 0.0
var _charge_direction := Vector2.RIGHT
var _cruise_angle := 0.0

func _ready() -> void:
	super._ready()
	walk_anim.play("idle")

# Living flock members in spawn order, self included — flock[0] is the leader.
func _flock() -> Array:
	return get_parent().get_children().filter(func(n):
		return n.get_script() == get_script() and not n.is_queued_for_deletion() and n.get("health") != null and n.health > 0
	)

func _physics_process(delta: float) -> void:
	if not _target:
		return

	var flock := _flock()
	var leader = flock[0] if flock.size() > 0 else self
	if leader == self:
		_update_leader(delta)
	else:
		_update_follower(leader, flock.find(self), delta)

	_cannon.look_at(_target.global_position)
	if _target_within_range:
		prepare_to_attack()

	_sprite.flip_h = sign(_target.global_position.direction_to(global_position).x) == 1
	var is_running: bool = _velocity.length() > cruise_speed * 0.3
	if is_running and walk_anim.current_animation == "idle":
		walk_anim.play("walk")
	elif not is_running and walk_anim.current_animation == "walk":
		walk_anim.play("idle")

func _update_leader(delta: float) -> void:
	if _charging:
		_charge_timer -= delta
		_glide_towards(global_position + _charge_direction * 999.0, charge_accel, charge_speed, delta)
		if _charge_timer <= 0.0:
			_charging = false
			_charge_cooldown_timer = charge_cooldown
	else:
		_charge_cooldown_timer -= delta
		# A loose orbit around the player so the flock reads as patrolling rather than stuck in
		# place between charges.
		_cruise_angle += delta * cruise_turn_rate
		var cruise_target: Vector2 = _target.global_position + Vector2.RIGHT.rotated(_cruise_angle) * regroup_radius
		_glide_towards(cruise_target, cruise_accel, cruise_speed, delta)
		if _charge_cooldown_timer <= 0.0:
			_charging = true
			_charge_timer = charge_duration
			_charge_direction = global_position.direction_to(_target.global_position)

func _update_follower(leader: Node, flock_index: int, delta: float) -> void:
	# flock_index 0 is the leader, so a follower's own rank among followers starts at 0.
	var follower_rank_index: int = maxi(flock_index - 1, 0)
	var rank: int = follower_rank_index / 2 + 1
	var side := -1.0 if follower_rank_index % 2 == 0 else 1.0
	var leader_velocity: Vector2 = leader.get("_velocity")
	var lead_dir: Vector2 = leader_velocity.normalized() if leader_velocity.length() > 1.0 else Vector2.RIGHT
	var behind := -lead_dir * formation_spacing * rank
	var out := lead_dir.orthogonal() * side * formation_spacing * rank * 0.6
	var slot_point: Vector2 = leader.global_position + behind + out
	var charging: bool = leader.get("_charging")
	var accel: float = charge_accel if charging else cruise_accel
	var top_speed: float = charge_speed if charging else cruise_speed
	_glide_towards(slot_point, accel, top_speed, delta)

func _glide_towards(target_pos: Vector2, accel: float, max_speed: float, delta: float) -> void:
	var desired := global_position.direction_to(target_pos) * max_speed
	var diff := desired - _velocity
	var max_delta := accel * delta
	if diff.length() > max_delta:
		diff = diff.normalized() * max_delta
	_velocity += diff
	set_velocity(_velocity)
	move_and_slide()
	_velocity = velocity

func prepare_to_attack() -> void:
	if not is_ready_to_attack():
		return
	_before_attack_timer.start()

func _on_BeforeAttackTimer_timeout() -> void:
	if not _target or not ViewUtil.on_screen(self, 24.0):
		return
	_cannon.shoot_at_target(_target)
	_cooldown_timer.start()
