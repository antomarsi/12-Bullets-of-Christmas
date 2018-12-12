extends Area2D
export (int) var HEALTH_AMOUNT = 1

func _on_Present_body_entered(body):
	if body.has_method("heal"):
		body.heal(HEALTH_AMOUNT)
		queue_free()
