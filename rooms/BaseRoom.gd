class_name BaseRoom
extends Node2D

@export var next_stage : PackedScene
@onready var enemies_holder = $Mobs

var enemies = []

func _ready() -> void:
	Events.last_room = get_tree().current_scene.scene_file_path
	enemies = enemies_holder.get_children()
	Events.connect("mob_died", Callable(self, "_on_mob_died"))

func _on_mob_died(mob) -> void:
	enemies.erase(mob)
	print("Now has %d enemies" % enemies.size())
	
	if enemies.size() == 0:
		if next_stage:
			get_tree().change_scene_to_packed.call_deferred(next_stage)
		else:
			get_tree().change_scene_to_file.call_deferred("res://Main.tscn")
