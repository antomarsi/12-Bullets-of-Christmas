extends Node2D

@export_file("*.tscn") var next_world: String

func _ready():
	$CanvasLayer/AnimationPlayer.play("End")

func _on_AnimationPlayer_animation_finished(anim_name):
	get_tree().change_scene_to_file(next_world)
