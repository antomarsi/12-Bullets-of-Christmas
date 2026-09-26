class_name Pickup
extends Area2D

@export var pickup_sound: SoundSet = preload("res://data/sounds/pickup.tres")

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body is Player and _apply(body):
		pickup_sound.play(self, global_position)
		queue_free()

# Return true when the pickup was used up.
func _apply(_player: Player) -> bool:
	return true
