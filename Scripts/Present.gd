extends Area2D
export (int) var HEALTH_AMOUNT = 1
onready var TYPE = global.ENTITY.PICKUP

func _on_Present_area_entered(body):
	if body.get_parent().has_method("heal"):
		body.get_parent().heal(HEALTH_AMOUNT)
		queue_free()