extends SceneTree

# Pressing Esc on the intro must go straight to night 1's transition.
var frame := 0
var sent := false

func _initialize() -> void:
	change_scene_to_file("res://interface/Intro.tscn")

func _process(_delta) -> bool:
	frame += 1
	var scene = current_scene
	if scene == null:
		return false
	var path: String = scene.scene_file_path
	if not sent and path.ends_with("Intro.tscn") and frame > 5:
		sent = true
		var ev := InputEventKey.new()
		ev.keycode = KEY_ESCAPE
		ev.pressed = true
		Input.parse_input_event(ev)
	if sent and path.contains("transitions/"):
		print("intro skipped to: ", path.get_file(), " after ", frame, " frames")
		print("intro skip test: PASS")
		return true
	if frame > 600:
		print("intro skip test: FAIL (still at ", path, ")")
		return true
	return false
