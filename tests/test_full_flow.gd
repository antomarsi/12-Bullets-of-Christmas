extends SceneTree

# Menu -> Intro -> verse screen -> night 1 -> verse screen -> night 2 -> verse screen -> night 3
# -> ... -> verse screen -> night 7 -> night select, with a temp save file.
var frame := 0
var sequence := []
var last_path := ""
var stage := 0
var save
var select_checked := false
var select_report := ""

func _initialize() -> void:
	Engine.time_scale = 10.0
	save = root.get_node("SaveData")
	save.save_path = "user://test_save.cfg"
	save.erase()
	change_scene_to_file("res://Main.tscn")

func _process(_delta) -> bool:
	frame += 1
	var scene = current_scene
	if scene == null:
		return false
	var path: String = scene.scene_file_path
	if path != last_path:
		sequence.append(path.get_file())
		last_path = path
		if path.ends_with("Main.tscn") and stage == 0:
			pass
	if path.ends_with("Main.tscn") and stage == 0 and frame > 5:
		var cont = scene.get_node("Buttons/Continue")
		var sel = scene.get_node("Buttons/NightSelect")
		print("menu: Continue visible=", cont.visible, " NightSelect visible=", sel.visible)
		scene.get_node("Buttons/Start").pressed.emit()
		stage = 1
	if path.contains("transitions/") and frame % 20 == 0:
		scene.skip()
	if scene.get("director") != null:
		var player = scene.get_node_or_null("Player")
		if player:
			player.health_component.MAX_HEALTH = 1000000
			player.health_component.health = 1000000
		for mob in scene.get_node("Mobs").get_children():
			if mob.has_method("take_damage") and not mob.is_queued_for_deletion() and mob.get("health") != null and mob.health > 0:
				mob.take_damage(100000)
	if path.ends_with("NightSelect.tscn") and not select_checked:
		select_checked = true
		var enabled := []
		var disabled := 0
		for b in scene.find_children("*", "Button", true, false):
			if b.text.begins_with("NIGHT"):
				if b.disabled:
					disabled += 1
				else:
					enabled.append(b.text.get_slice("\n", 0))
		select_report = "night select: enabled=%s disabled=%d" % [enabled, disabled]
		return _finish()
	if frame > 60000:
		print("TIMEOUT at ", path)
		return _finish()
	return false

func _finish() -> bool:
	print("sequence: ", sequence)
	print(select_report)
	print("cleared in temp save: ", save.cleared.keys())
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_save.cfg"))
	var expected := ["Main.tscn", "Intro.tscn", "1Night.tscn", "night_01.tscn", "2Night.tscn", "night_02.tscn", "3Night.tscn", "night_03.tscn", "4Night.tscn", "night_04.tscn", "5Night.tscn", "night_05.tscn", "6Night.tscn", "night_06.tscn", "7Night.tscn", "night_07.tscn", "NightSelect.tscn"]
	var cleared_all: bool = save.cleared.has(1) and save.cleared.has(2) and save.cleared.has(3) and save.cleared.has(4) and save.cleared.has(5) and save.cleared.has(6) and save.cleared.has(7)
	print("full flow test: ", "PASS" if sequence == expected and cleared_all else "FAIL")
	return true
