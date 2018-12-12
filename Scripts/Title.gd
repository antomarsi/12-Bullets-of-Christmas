extends Control

export(String, FILE, "*.tscn") var next_world

func _on_Start_pressed():
	global.setScene(next_world)


func _on_Exit_pressed():
	get_tree().quit()
