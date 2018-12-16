extends Label

export (String, FILE, "*.tscn") var next_world
export (float) var duration = 0.05

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
	$"../AnimationPlayer".play("fade")
	pass # Replace with function body.


func _on_AnimationPlayer_animation_finished(anim_name):
	global.setScene(next_world)
