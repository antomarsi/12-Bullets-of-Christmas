extends Node2D

var health_ui = "GUI/TopView/Health/"

export(String, FILE, "*.tscn") var next_world

func _ready():
	$GUI/Transition/AnimationPlayer.play("Fade_in")
	pass

func _on_shoot(bullet, _position, _direction):
	var b = bullet.instance()
	add_child(b)
	b.start(_position, _direction)

func _on_Player_take_hit(health):
	for i in range(10):
		get_node(health_ui+str(i+1)).set_visible((i+1) <= health)

func _go_next_scene():
	$GUI/Transition/AnimationPlayer.play("Fade_out")
	yield($GUI/Transition/AnimationPlayer, "animation_finished")
	global.setScene(next_world)

func _on_Enemy_died():
	$EnemyKillTimer.start(1)

func _on_EnemyKillTimer_timeout():
	print($Enemies.get_child_count())
	if $Enemies.get_child_count() == 0:
		_go_next_scene()


func _on_Turtle_dove_died():
	pass # Replace with function body.
