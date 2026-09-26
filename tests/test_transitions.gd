extends SceneTree

# Plays each night's transition scene (scenes/transitions/NNight.tscn) to the end of its "End" animation.
var night := 1
var frame := 0
var scene = null
var results := []
var finished := false
var anim_len := 0.0

func _initialize() -> void:
	Engine.time_scale = 20.0
	_start_night()

func _start_night() -> void:
	var packed: PackedScene = load("res://scenes/transitions/%dNight.tscn" % night)
	scene = packed.instantiate()
	scene._done = true  # don't leave the scene when the animation ends
	root.get_node("Game").current_night = night
	root.add_child(scene)
	var player: AnimationPlayer = scene.get_node("CanvasLayer/AnimationPlayer")
	anim_len = player.get_animation("End").length
	finished = false
	player.animation_finished.connect(func(_n): finished = true)
	frame = 0

func _process(_delta) -> bool:
	frame += 1
	if finished or frame > 6000:
		results.append("night %d: %s (End = %.1f s, %d frames)" % [night, "ok" if finished else "DID NOT FINISH", anim_len, frame])
		scene.queue_free()
		night += 1
		if night > 12:
			for r in results:
				print(r)
			var bad := results.filter(func(r): return "DID NOT" in r)
			print("transition test: ", "PASS" if bad.is_empty() else "FAIL")
			return true
		_start_night()
	return false
