extends Node2D

onready var parent = get_parent()

func _ready():
	_on_ShootTimer_timeout()

func _on_ShootTimer_timeout():
	parent.stop = true
	$"./../Sprite".play("default")
	$IdleTimer.start()


func _on_IdleTimer_timeout():
	parent.stop = false
	$"./../Sprite".play("leap")
	$ShootTimer.start()
