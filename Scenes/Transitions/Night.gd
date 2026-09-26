extends Node2D

@export var next_world # (String, FILE, "*.tscn")

func _ready():
	$CanvasLayer/AnimationPlayer.play("End")

func _on_AnimationPlayer_animation_finished(anim_name):
	global.setScene(next_world)
