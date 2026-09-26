extends Control

@export var next_world # (String, FILE, "*.tscn")

func _on_Start_pressed():
	global.setScene(next_world)


func _on_Exit_pressed():
	get_tree().quit()
