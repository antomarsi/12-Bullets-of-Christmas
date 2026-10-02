extends SceneTree

# Stress test for the bullet-pooling work: ~20 mobs alive plus enough fire to reach ~300
# concurrent bullets, checking (1) frame time stays reasonable and (2) the pool is actually being
# reused rather than growing unbounded (peak distinct instances stays well below total shots).
const MOB_COUNT := 20
const TARGET_BULLETS := 300
const BULLET_SCENE := preload("res://bullets/basic_bullet/BasicBullet.tscn")

var room = null
var player = null
var frame := 0
var shots_fired := 0
var seen_ids := {}
var max_concurrent := 0
var frame_times := []
var last_ticks := 0

func _initialize() -> void:
	Engine.time_scale = 1.0
	last_ticks = Time.get_ticks_usec()
	var packed: PackedScene = load("res://rooms/night_01.tscn")
	room = packed.instantiate()
	room.night = 0
	root.add_child(room)
	player = room.get_node("Player")
	var mobs: Node = room.get_node("Mobs")
	var scenes := [
		load("res://mobs/turtle_dove/TurtleDove.tscn"),
		load("res://mobs/french_hen/FrenchHen.tscn"),
		load("res://mobs/partridge/Partridge.tscn"),
	]
	for i in MOB_COUNT:
		var mob = scenes[i % scenes.size()].instantiate()
		mob.position = player.position + Vector2.RIGHT.rotated(TAU * i / MOB_COUNT) * 250.0
		mobs.add_child(mob)

func _process(_delta) -> bool:
	var now := Time.get_ticks_usec()
	frame_times.append(now - last_ticks)
	last_ticks = now
	frame += 1
	if frame == 1:
		player.health_component.MAX_HEALTH = 1000000
		player.health_component.health = 1000000

	# Keep firing until we're holding ~TARGET_BULLETS concurrently, then let them fly/expire.
	var bullets := []
	for c in root.get_children():
		if c.has_method("randomize_rotation"):
			bullets.append(c)
	max_concurrent = maxi(max_concurrent, bullets.size())
	for b in bullets:
		seen_ids[b.get_instance_id()] = true

	# Fire a steady stream for the whole run (not just until TARGET_BULLETS is first reached) —
	# bullets also expire and get pooled continuously, so sustained fire is what actually exercises
	# reuse. Rate chosen so concurrent count * lifetime settles in the ~300 range.
	if frame < 580:
		for i in 3:
			var angle := randf() * TAU
			BulletPattern.shoot(BULLET_SCENE, self, player.position, angle, {"speed": 500.0, "max_range": 1200.0})
			shots_fired += 1

	if frame > 600:
		var avg_us := 0.0
		for t in frame_times:
			avg_us += t
		avg_us /= frame_times.size()
		var avg_ms := avg_us / 1000.0
		var reused_ratio := 1.0 - float(seen_ids.size()) / maxf(shots_fired, 1.0)
		print("mobs alive: ", MOB_COUNT, "  shots fired: ", shots_fired, "  max concurrent bullets: ", max_concurrent)
		print("distinct bullet instances ever seen: ", seen_ids.size(), "  pool reuse ratio: %.2f" % reused_ratio)
		print("average frame time: %.2f ms" % avg_ms)
		var ok_perf: bool = avg_ms < 33.0
		var ok_pool: bool = seen_ids.size() < shots_fired * 0.5
		var ok_scale: bool = max_concurrent >= 100
		print("ok   " if ok_perf else "FAIL ", "average frame time under 33ms")
		print("ok   " if ok_pool else "FAIL ", "bullet pool is reused (instances seen well below shots fired)")
		print("ok   " if ok_scale else "FAIL ", "reached a meaningful concurrent bullet count (>=100)")
		print("perf stress test: ", "PASS" if ok_perf and ok_pool and ok_scale else "FAIL")
		return true
	return false
