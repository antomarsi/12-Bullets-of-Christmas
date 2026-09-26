extends Pickup

@export var heal_amount := 2

func _apply(player: Player) -> bool:
	if player.health_component.health >= player.health_component.MAX_HEALTH:
		return false
	player.heal(heal_amount)
	return true
