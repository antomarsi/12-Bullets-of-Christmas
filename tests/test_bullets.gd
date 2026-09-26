extends SceneTree

# Runs night 1 (the Partridge) and checks that enemy bullets are spawned and visible in flight.
var room = null
var frame := 0
var max_bullets := 0
var min_scale := 999.0
var hidden_seen := 0
var player_damage := 0

func _initialize() -> void:
	Engine.time_scale = 5.0
	var packed: PackedScene = load("res://rooms/night_01.tscn")
	room = packed.instantiate()
	root.add_child(room)

func _process(_delta) -> bool:
	frame += 1
	var player = room.get_node_or_null("Player")
	if player and frame == 1:
		player.health_component.MAX_HEALTH = 1000000
		player.health_component.health = 1000000
	var bullets := []
	for c in root.get_children():
		if c.has_method("randomize_rotation"):
			bullets.append(c)
	max_bullets = maxi(max_bullets, bullets.size())
	for b in bullets:
		var sprite: Sprite2D = b.get_node("Sprite2D")
		min_scale = minf(min_scale, sprite.scale.x)
		if not sprite.visible or sprite.scale.x < 0.5:
			if not b._has_hit and b._travelled_distance > 20.0 and b._travelled_distance < 600.0:
				hidden_seen += 1
	if frame > 900:
		print("max enemy bullets alive at once: ", max_bullets)
		print("bullet sprite scale seen (min): ", min_scale, "  hidden/too-small samples in flight: ", hidden_seen)
		print("bullet test: ", "PASS" if max_bullets >= 8 and hidden_seen == 0 else "FAIL")
		return true
	return false
