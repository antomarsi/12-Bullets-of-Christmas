class_name BaseRoom
extends Node2D

@export var next_stage : PackedScene
@onready var enemies_holder = $Mobs

var enemies = []

func _ready() -> void:
	enemies = enemies_holder.get_children()
	Events.connect("mob_died", Callable(self, "_on_mob_died"))

func _on_mob_died(mob) -> void:
	enemies.erase(mob)
	print("Now has %d enemies" % enemies.size())
	
	if enemies.size() == 0:
		get_tree().change_scene_to_packed(next_stage)
