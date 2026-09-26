extends Node2D

var _done := false

func _ready() -> void:
	$CanvasLayer/AnimationPlayer.play("End")

func _on_AnimationPlayer_animation_finished(_anim_name) -> void:
	skip()

func skip() -> void:
	if _done:
		return
	_done = true
	Game.load_room(Game.current_night)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed or event is InputEventMouseButton and event.pressed:
		skip()
