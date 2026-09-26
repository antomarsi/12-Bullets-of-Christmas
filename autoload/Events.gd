extends Node

signal mob_died(mob)
signal player_health_changed(new_health)
signal game_over()
signal wave_started(index, total)
signal wave_cleared(index)
signal night_cleared(night)

var last_room := "res://rooms/TestRoom.tscn"
