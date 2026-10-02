class_name BulletPattern
extends RefCounted

const PLAYER_MASK := 1

# Free instances by scene path, kept out of the tree between shots instead of being freed —
# avoids an instantiate()+queue_free() churn on every bullet (bullet-hell fires a lot of these).
static var _pool: Dictionary = {}

static func world(tree: SceneTree) -> Node:
	return tree.current_scene if tree.current_scene else tree.root

# Called by BulletBase._release() when a bullet is done (hit something or ran out of range).
static func pool_release(bullet: BulletBase) -> void:
	var path := bullet.scene_file_path
	var bucket: Array = _pool.get(path, [])
	bucket.append(bullet)
	_pool[path] = bucket

# opts: speed, max_range, damage, mask
static func shoot(scene: PackedScene, tree: SceneTree, pos: Vector2, angle: float, opts := {}) -> BulletBase:
	var path := scene.resource_path
	var bucket: Array = _pool.get(path, [])
	var bullet: BulletBase
	var reused := false
	if bucket.size() > 0:
		bullet = bucket.pop_back()
		reused = true
	else:
		bullet = scene.instantiate()
	var attack := Attack.new()
	attack.attack_damage = opts.get("damage", 1.0)
	bullet.damage = attack
	if opts.has("speed"):
		bullet.speed = opts.speed
	bullet.max_range = opts.get("max_range", 800.0)
	bullet.collision_mask = opts.get("mask", PLAYER_MASK)
	bullet.rotation = angle
	bullet.position = pos
	world(tree).add_child(bullet)
	if reused:
		# _ready() (which calls _on_spawn() for a fresh instance) only ever fires once per Node's
		# lifetime — a reused instance needs its per-shot state reset explicitly.
		bullet._on_spawn()
	return bullet

static func aimed(scene: PackedScene, tree: SceneTree, pos: Vector2, target: Vector2, opts := {}) -> BulletBase:
	return shoot(scene, tree, pos, pos.angle_to_point(target) + PI, opts)

static func fan(scene: PackedScene, tree: SceneTree, pos: Vector2, aim_angle: float, count: int, spread_deg: float, opts := {}) -> Array:
	var bullets := []
	var spread := deg_to_rad(spread_deg)
	for i in count:
		var t := 0.0 if count == 1 else float(i) / (count - 1) - 0.5
		bullets.append(shoot(scene, tree, pos, aim_angle + t * spread, opts))
	return bullets

static func radial(scene: PackedScene, tree: SceneTree, pos: Vector2, count: int, angle_offset: float, opts := {}) -> Array:
	var bullets := []
	for i in count:
		bullets.append(shoot(scene, tree, pos, angle_offset + TAU * i / count, opts))
	return bullets
