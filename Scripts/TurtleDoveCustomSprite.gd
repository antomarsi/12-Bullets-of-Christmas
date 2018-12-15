extends AnimatedSprite

var colors = ["blue", "orange", "red", "purple"]

func _ready():
	randomize()
	play(colors[randi() % colors.size()])
