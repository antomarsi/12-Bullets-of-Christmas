extends Node2D

export(String, FILE, "*.tscn") var next_world


func _on_AnimationPlayer_animation_finished(anim_name):
	global.setScene(next_world)
