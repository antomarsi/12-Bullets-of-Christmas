class_name BaseRoom
extends Node2D

export (PackedScene) var next_stage
onready var enemies_holder = $Mobs

var enemies = []

func _ready() -> void:
	enemies = enemies_holder.get_children()
	Events.connect("mob_died", self, "_on_mob_died")

func _on_mob_died(mob) -> void:
	enemies.erase(mob)
	print("Now has %d enemies" % enemies.size())
	
	if enemies.size() == 0:
		get_tree().change_scene_to(next_stage)
