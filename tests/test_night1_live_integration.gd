extends SceneTree

# Runs the REAL night 1 (wave mode, not a synthetic mob) with no scripted damage or kills, to check
# two reports: (a) the player never takes damage from real enemy fire, (b) the room clears itself
# without the player ever shooting.
var room = null
var player = null
var frame := 0
var hp_history := []
var mob_hp_start := -1.0
var night_cleared_seen := false
var partridge = null

func _initialize() -> void:
	var ev = root.get_node("Events")
	ev.night_cleared.connect(func(n): night_cleared_seen = true)
	var packed: PackedScene = load("res://rooms/night_01.tscn")
	room = packed.instantiate()
	room.night = 1
	root.add_child(room)
	player = room.get_node("Player")

func _process(_delta) -> bool:
	frame += 1
	if partridge == null:
		for m in room.get_node("Mobs").get_children():
			if m.name.begins_with("Partridge") or m.get("health") != null:
				partridge = m
				mob_hp_start = m.health
	if partridge and is_instance_valid(partridge):
		# Walk the player toward the partridge so its radial bullets have a real chance to hit,
		# same as a player standing near it, but never press the shoot input.
		var dir = (partridge.global_position - player.global_position)
		if dir.length() > 60.0:
			player.velocity_component.direction = dir.normalized()
		else:
			player.velocity_component.direction = Vector2.ZERO
		player.velocity_component.move(player)
	hp_history.append(player.health_component.health)
	if frame == 900 or night_cleared_seen:
		var hp_now: float = player.health_component.health
		var mob_hp_now: float = partridge.health if partridge and is_instance_valid(partridge) else -1.0
		print("frame ", frame, "  player hp: ", hp_history[0], " -> ", hp_now, "  mob hp: ", mob_hp_start, " -> ", mob_hp_now, "  night_cleared fired: ", night_cleared_seen)
		print("player ever took damage: ", hp_now < hp_history[0])
		print("mob died without being shot: ", night_cleared_seen and mob_hp_start > 0)
		print("live integration test: ", "INFO (see numbers above, not a pass/fail)")
		return true
	return false
