extends SceneTree

# French Hen: fires a fan of boomerang croissants (curving bullets, not straight lines) and at
# least one of them actually hits the player. Real-scene test rather than a synthetic one, per the
# project's usual rule for "does the attack actually connect" bugs.
var room = null
var player = null
var hen = null
var frame := 0
var report := []
var failed := false
var hp_start := 0.0
var damaged := false
var bullets_seen := {}
var rotations := {}

func check(ok: bool, text: String) -> void:
	report.append(("ok   " if ok else "FAIL ") + text)
	if not ok:
		failed = true

func _initialize() -> void:
	var packed: PackedScene = load("res://rooms/night_01.tscn")
	room = packed.instantiate()
	room.night = 0
	root.add_child(room)
	player = room.get_node("Player")
	player.set_physics_process(false)

func _process(_delta) -> bool:
	frame += 1
	if frame == 3:
		hen = load("res://mobs/french_hen/FrenchHen.tscn").instantiate()
		hen.position = player.position + Vector2(40, 0)
		room.get_node("Mobs").add_child(hen)
		hp_start = player.health_component.health
	if hen == null:
		return false

	for child in root.get_children():
		var script = child.get_script()
		if script != null and script.resource_path.ends_with("CroissantBullet.gd"):
			var id := child.get_instance_id()
			if not rotations.has(id):
				rotations[id] = []
			bullets_seen[id] = true
			rotations[id].append(child.rotation)

	if player.health_component.health < hp_start:
		damaged = true

	if frame > 600:
		# The cooldown is short enough that a second volley can fire before this check, so allow
		# any whole number of fan-sized volleys rather than requiring exactly one.
		var fan_count: int = hen.fan_count
		var fired_in_full_volleys: bool = bullets_seen.size() > 0 and bullets_seen.size() % fan_count == 0
		check(fired_in_full_volleys, "hen fired whole volleys of %d croissants (saw %d)" % [fan_count, bullets_seen.size()])
		var curved := false
		for id in rotations:
			var samples: Array = rotations[id]
			if samples.size() > 5 and absf(samples[-1] - samples[0]) > 0.2:
				curved = true
		check(curved, "croissant bullets curve over time (boomerang), not a straight line")
		check(damaged, "a croissant hit the player")
		for r in report:
			print(r)
		print("hen attack test: ", "FAIL" if failed else "PASS")
		return true
	return false
