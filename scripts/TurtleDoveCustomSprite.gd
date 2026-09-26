extends AnimatedSprite2D

var colors = ["blue", "orange", "red", "purple"]

func _ready():
	randomize()
	play(colors[randi() % colors.size()])
