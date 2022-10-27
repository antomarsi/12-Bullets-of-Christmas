extends Control

onready var _health_bar := $container/HealthBar

func _ready() -> void:
	Events.connect("player_health_changed", self, "_on_player_health_changed")
	
func _on_player_health_changed(health: int) -> void:
	_health_bar.health = health


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta: float) -> void:
#	pass
