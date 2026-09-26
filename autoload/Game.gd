extends Node

const LAST_NIGHT := 12

var current_night := 1

func room_path(night: int) -> String:
	return "res://rooms/night_%02d.tscn" % night

func transition_path(night: int) -> String:
	return "res://transitions/%dNight.tscn" % night

func room_exists(night: int) -> bool:
	return ResourceLoader.exists(room_path(night))

# Plays the night's hand-made verse transition (scenes/transitions/), which then loads the room.
func start_night(night: int) -> void:
	current_night = night
	if ResourceLoader.exists(transition_path(night)):
		get_tree().change_scene_to_file(transition_path(night))
	else:
		load_room(night)

func load_room(night: int) -> void:
	current_night = night
	if room_exists(night):
		get_tree().change_scene_to_file(room_path(night))
	else:
		get_tree().change_scene_to_file("res://interface/NightSelect.tscn")

func advance_after_clear(night: int) -> void:
	if night < LAST_NIGHT and room_exists(night + 1):
		start_night(night + 1)
	else:
		get_tree().change_scene_to_file("res://interface/NightSelect.tscn")
