extends Node

var currentScene = null

enum TYPE {
	PLAYER,
	ENEMY
}

func _ready():
	currentScene = get_tree().get_root().get_child(get_tree().get_root().get_child_count() - 1)

func get_player():
	return currentScene.get_node("Player")
	
func setScene(scene):
	currentScene.queue_free()
	var s = ResourceLoader.load(scene)
	currentScene = s.instance()
	get_tree().get_root().add_child(currentScene)