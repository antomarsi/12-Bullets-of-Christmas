extends "res://Scripts/Entity.gd"

enum FOLLOW_TYPE {\
	FOLLOW,
	STATIC
}
var path = []
var stop = false

export (FOLLOW_TYPE) var TRACK = FOLLOW_TYPE.FOLLOW

const DAMAGE = 1

func _initialize():
	._initialize()
	if TRACK == FOLLOW_TYPE.FOLLOW:
		global.currentScene.get_node("nav").connect("path_update", self, "update_path")
	connect("died", global.currentScene, "_on_Enemy_died")

func _physics_process(delta):
	if TRACK == FOLLOW_TYPE.STATIC:
		return
	go_to_path(delta)

func player_died():
	stop = true

func update_path(nav, player_position):
	path = nav.get_simple_path(global_position, player_position)
	set_physics_process (true)

func go_to_path(delta):
	if (path.size() >= 1):
		var to_walk = delta * SPEED
		var d = global_position.distance_to(path[0])
		if d > 2:
			global_position = global_position.linear_interpolate(path[0], (SPEED * delta)/d)
		else:
			path.remove(0)
	else:
		set_physics_process (false)

func spritedir_loop():
	if path.size() == 0:
		return
	if flip and (path[0] - global_position).x > 0:
		flip = false
		$Sprite.flip_h = !$Sprite.flip_h
	elif not flip and (path[0] - global_position).x < 0:
		flip = true
		$Sprite.flip_h = !$Sprite.flip_h
