extends Area2D
class_name HitboxComponent

@export_category("Components")
@export var health_component : HealthComponent


func damage(attack: Attack):
	if health_component:
		health_component.damage(attack)
