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

func setScene(scene):
	currentScene.queue_free()
	var s = ResourceLoader.load(scene)
	currentScene = s.instance()
	player_ref = weakref(currentScene.get_node("Player"))
	get_tree().get_root().add_child(currentScene)