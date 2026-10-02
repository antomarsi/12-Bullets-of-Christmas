extends SceneTree

# Runs real night 1 (wave mode) with the player walking toward the Partridge but never shooting,
# and checks the Partridge's aimed burst actually lands a hit within a reasonable time.
var room = null
var player = null
var partridge = null
var frame := 0
var hp0 := -1.0

func _initialize() -> void:
	var packed: PackedScene = load("res://rooms/night_01.tscn")
	room = packed.instantiate()
	room.night = 1
	root.add_child(room)
	player = room.get_node("Player")

func _process(_delta) -> bool:
	frame += 1
	if frame == 2:
		hp0 = player.health_component.health
	if partridge == null:
		for m in room.get_node("Mobs").get_children():
			if m.get("health") != null:
				partridge = m
	if partridge and is_instance_valid(partridge):
		var dir = partridge.global_position - player.global_position
		# Approach to engagement range, then hold position (a player standing their ground and
		# firing back, not endlessly chasing a retreating target).
		player.velocity_component.direction = dir.normalized() if dir.length() > 180.0 else Vector2.ZERO
		player.velocity_component.move(player)
	var hp_now: float = player.health_component.health
	if hp_now < hp0 or frame > 1800:
		print("frame ", frame, "  player hp: ", hp0, " -> ", hp_now)
		print("partridge aim test: ", "PASS" if hp_now < hp0 else "FAIL (never got hit in 30 s)")
		return true
	return false
