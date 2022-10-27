extends Control

export var max_health := 8 setget set_max_health
export var health := 8 setget set_health

onready var array_health = [
	$"1",
	$"2",
	$"3",
	$"4",
	$"5",
	$"6",
	$"7",
	$"8"
]

func _ready() -> void:
	_redraw_health_bar()
	
func set_max_health(new_max_health: int) -> void:
	max_health = new_max_health
	_redraw_health_bar()

func set_health(new_health: int) -> void:
	# The clamp() function prevents the new_health from going over max_health or
	# below 0.
	health = clamp(new_health, 0, max_health)
	_redraw_health_bar()


func _redraw_health_bar() -> void:
	# Because we use individual TextureRect nodes to draw health points, to
	# redraw the bar, we delete all the existing nodes and create new ones with
	# the appropriate texture.
	for child in array_health:
		child.hide()

	# We need as many nodes as there is max_health: one texture per health
	# point.
	for index in array_health.size():
		if index < health:
			array_health[index].show()
		# When index is higher than health, draw an empty heart.
		else:
			array_health[index].hide()
