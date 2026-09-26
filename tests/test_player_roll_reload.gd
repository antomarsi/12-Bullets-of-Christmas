extends SceneTree

# Roll: moves, invulnerable, cooldown, bullets pass through. Reload: takes reload_time, bar shows, refills.
var room = null
var player = null
var frame := 0
var t := 0.0
var report := []
var failed := false
var stage := 0
var stage_t := 0.0
var start_pos := Vector2.ZERO
var bullet = null
var hp_before := 0.0

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

func _process(delta) -> bool:
	frame += 1
	if frame < 3:
		return false
	stage_t += delta
	match stage:
		0:
			start_pos = player.global_position
			hp_before = player.health_component.health
			check(player.roll(Vector2.RIGHT), "roll starts")
			check(not player.roll(Vector2.RIGHT), "second roll refused while rolling")
			check(player.is_invulnerable() and player.is_rolling(), "player is invulnerable while rolling")
			player.take_damage(3)
			check(player.health_component.health == hp_before, "no damage taken while rolling")
			# an enemy bullet flying at the rolling player must go through
			var scene: PackedScene = load("res://bullets/pear_bullet/PearBullet.tscn")
			bullet = BulletPattern.shoot(scene, self, start_pos + Vector2(60, 0), PI, {"speed": 100.0, "max_range": 500.0})
			stage = 1; stage_t = 0.0
		1:
			if not player.is_rolling():
				var moved: float = player.global_position.x - start_pos.x
				check(moved > 60.0 and moved < 140.0, "roll moved %.0f px in %.2f s" % [moved, stage_t])
				check(abs(stage_t - player.roll_duration) < 0.1, "roll lasted about roll_duration")
				check(is_instance_valid(bullet) and not bullet._has_hit, "enemy bullet passed through the rolling player")
				check(not player.roll(Vector2.LEFT), "roll is on cooldown right after rolling")
				stage = 2; stage_t = 0.0
		2:
			if stage_t > 1.0:
				check(player.roll(Vector2.LEFT), "roll available again after the cooldown")
				stage = 3; stage_t = 0.0
		3:
			if not player.is_rolling() and stage_t > player.roll_duration + 1.2 and not player._invulnerable:
				hp_before = player.health_component.health
				player.take_damage(1)
				check(player.health_component.health == hp_before - 1, "damage works again after the roll")
				stage = 4; stage_t = 0.0
		4:
			if stage_t > 1.3:
				player.current_ammo = 0
				player.start_reload()
				check(player.reloading and player._reload_bar.visible, "reload starts and the bar is visible")
				stage = 5; stage_t = 0.0
		5:
			if stage_t > player.reload_time * 0.5 and player.reloading:
				check(player.reload_progress() > 0.3 and player.reload_progress() < 0.8, "reload bar is around half way (%.2f)" % player.reload_progress())
				check(player.current_ammo == 0, "no ammo until the reload finishes")
				stage = 6
			elif not player.reloading:
				stage = 6
		6:
			if not player.reloading:
				check(abs(stage_t - player.reload_time) < 0.15, "reload took %.2f s (reload_time %.2f)" % [stage_t, player.reload_time])
				check(player.current_ammo == player.MAX_AMMO and not player._reload_bar.visible, "ammo refilled and bar hidden")
				for r in report:
					print(r)
				print("roll/reload test: ", "FAIL" if failed else "PASS")
				return true
	if frame > 3000:
		print("TIMEOUT at stage ", stage)
		return true
	return false
