class_name BulletPattern
extends RefCounted

const PLAYER_MASK := 1

static func world(tree: SceneTree) -> Node:
	return tree.current_scene if tree.current_scene else tree.root

# opts: speed, max_range, damage, mask
static func shoot(scene: PackedScene, tree: SceneTree, pos: Vector2, angle: float, opts := {}) -> BulletBase:
	var bullet: BulletBase = scene.instantiate()
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
