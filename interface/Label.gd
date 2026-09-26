extends Label

@export_file("*.tscn") var next_world: String
@export var duration := 0.05

@onready var _anim_player := $AnimationPlayer

var lapsed = 0
var letters = 0
var oldVisible = 0

func _ready():
	lapsed = 0
	letters = text.length()
	visible_characters = 0

func _process(delta):
	lapsed = lapsed + delta
	visible_characters = int(lapsed / duration)
	if visible_characters >= letters:
		$"../Timer".start()
		set_process(false)

func _on_Timer_timeout():
	_anim_player.play("fade")

func _on_AnimationPlayer_animation_finished(anim_name):
	get_tree().change_scene_to_file(next_world)
