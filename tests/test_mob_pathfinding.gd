extends SceneTree

# A pillar sits directly between a mob and the player. Drives Mob.follow() manually every frame
# (bypassing any specific enemy's attack state machine, e.g. Turtle Dove's dash phase doesn't call
# follow() at all) to test the pathfinding primitive itself in isolation: does the navmesh baked by
# BaseRoom._build_navigation() actually route the mob around the pillar instead of letting it get
# stuck on the pillar's edge the way plain seek-steering (pre-pathfinding follow()) used to?
var room = null
var player = null
var mob = null
var frame := 0
var start_distance := 0.0

func _initialize() -> void:
	var packed: PackedScene = load("res://rooms/BaseRoom.tscn")
	room = packed.instantiate()
	room.night = 0
	room.tile_map_size = Vector2i(20, 12)
	# A pillar directly between the spawn points below, with 3 tiles (48px) of clearance above and
	# below it — comfortably more than the mob's own ~43px collision diameter (radius 21.468 per
	# Mob.tscn), or the navmesh would correctly route it toward a gap it physically can't fit
	# through, which is a test-geometry bug, not a pathfinding one (this is exactly what happened
	# with an 8-tile pillar leaving only 2-tile/32px gaps: the agent found and followed a path
	# toward the gap, then got physically stuck at the wall it couldn't fit past).
	var wall_pillars: Array[Rect2i] = [Rect2i(8, 3, 4, 6)]
	room.pillars = wall_pillars
	root.add_child(room)

	player = room.get_node("Player")
	player.position = Vector2(5 * 16, 7 * 16)
	player.set_physics_process(false)

	mob = load("res://mobs/Mob.tscn").instantiate()
	mob.position = Vector2(19 * 16, 7 * 16)
	mob.always_aware = false
	room.get_node("Mobs").add_child(mob)
	start_distance = mob.global_position.distance_to(player.global_position)

func _process(_delta) -> bool:
	frame += 1
	if frame > 5:
		mob.follow(player.global_position)
	var distance: float = mob.global_position.distance_to(player.global_position)
	# Two solid CharacterBody2Ds physically can't get closer than roughly their combined radii
	# (mob ~21.5px + player's own) — "reached" just needs to be well inside the pillar's own extent
	# (67px), proving it actually routed there rather than merely drifting a little from its start.
	if distance < 50.0 or frame > 1200:
		var reached: bool = distance < 50.0
		print("start distance: ", start_distance, "  final distance: ", distance, "  frame: ", frame)
		print("mob pathfinding test: ", "PASS" if reached else "FAIL (never routed around the pillar)")
		return true
	return false
