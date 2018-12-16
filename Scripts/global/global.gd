extends Node

var currentScene = null
var player_ref

enum ENTITY_TYPE {
	PLAYER,
	ENEMY,
	ENEMY_NO_KNOCKBACK,
	PICKUP
}
const ENTITY = ENTITY_TYPE

func _ready():
	currentScene = get_tree().get_root().get_child(get_tree().get_root().get_child_count() - 1)
	player_ref = weakref(currentScene.get_node("Player"))
	
func get_player_ref():
	return weakref(get_current_scene().get_node("Player"))
	
func get_current_scene():
	return get_tree().get_root().get_child(get_tree().get_root().get_child_count() - 1)

func setScene(scene):
	get_tree().change_scene(scene)
	currentScene = get_tree().get_root().get_child(get_tree().get_root().get_child_count() - 1)
	player_ref = weakref(currentScene.get_node("Player"))
	get_tree().get_root().add_child(currentScene)