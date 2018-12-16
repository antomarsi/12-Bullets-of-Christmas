extends Navigation2D

signal path_update

onready var player_ref = global.get_player_ref()


func _on_PathUpdate_timeout():
	emit_signal("path_update", self, player_ref.get_ref().global_position)