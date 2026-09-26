extends Node2D
class_name HealthComponent

@export var MAX_HEALTH := 10.0
var health : float : set = set_health
var has_died := false

signal died()
signal health_updated(health)

func _ready():
	health = MAX_HEALTH

func damage(attack: Attack):
	health -= attack.attack_damage

func set_health(new_health):
	var old_health = health
	health = clamp(new_health, 0, MAX_HEALTH)
	health_updated.emit(health)
	if health <= 0:
		has_died = true
		died.emit()
