extends SceneTree

# Runs a real room, fires the player's gun to empty the magazine, and checks the ammo HUD (built
# in interface/OnScreenUI.gd) tracks ammo count and reload progress correctly.
var room = null
var player = null
var hud = null
var frame := 0
var report := []
var failed := false
var stage := 0
var stage_settle := 0

func check(ok: bool, text: String) -> void:
	report.append(("ok   " if ok else "FAIL ") + text)
	if not ok:
		failed = true

func _initialize() -> void:
	Engine.time_scale = 4.0
	var packed: PackedScene = load("res://rooms/night_01.tscn")
	room = packed.instantiate()
	room.night = 0
	root.add_child(room)
	player = room.get_node("Player")
	hud = room.get_node("UILayer/OnScreenUI")

func _lit_count() -> int:
	var n := 0
	for icon in hud._ammo_icons:
		if icon.modulate.a > 0.9:
			n += 1
	return n

func _process(_delta) -> bool:
	frame += 1
	if frame < 3:
		return false
	match stage:
		0:
			check(hud._ammo_icons.size() == player.MAX_AMMO, "HUD built %d icons for a %d-round magazine" % [hud._ammo_icons.size(), player.MAX_AMMO])
			check(_lit_count() == player.MAX_AMMO, "all %d rounds lit at full ammo" % player.MAX_AMMO)
			check(not hud._reload_label.visible, "reload label hidden while not reloading")
			player.current_ammo = 5
			stage = 1
		1:
			if _lit_count() == 5:
				check(true, "HUD shows 5 lit rounds after ammo dropped to 5")
				player.start_reload()
				stage = 2
			elif frame > 20:
				check(false, "HUD never updated to 5 lit rounds (was %d)" % _lit_count())
				stage = 2
		2:
			check(hud._reload_label.visible, "reload label shows once reloading starts")
			stage = 3
		3:
			if not player.reloading:
				# The HUD updates in its own _process(), which can lag the SceneTree script's
				# _process() by a tick on the exact frame reloading flips false — give it a couple
				# of extra ticks to catch up before asserting on its icon state.
				stage = 4
				stage_settle = 0
			else:
				var expected_min := int(player.reload_progress() * player.MAX_AMMO) - 1
				if _lit_count() < expected_min:
					check(false, "mid-reload lit count (%d) fell behind progress (expected >= %d)" % [_lit_count(), expected_min])
		4:
			stage_settle += 1
			if stage_settle >= 3:
				check(_lit_count() == player.MAX_AMMO, "all rounds relit once reload finished (%d lit)" % _lit_count())
				check(not hud._reload_label.visible, "reload label hides once reload finishes")
				for r in report:
					print(r)
				print("ammo hud test: ", "FAIL" if failed else "PASS")
				return true
	if frame > 3000:
		print("TIMEOUT at stage ", stage)
		return true
	return false
