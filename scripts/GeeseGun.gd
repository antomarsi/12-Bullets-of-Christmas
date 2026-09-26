extends "res://scripts/EnemyGun.gd"

func _ready():
	pass

func _on_ShootTimer_timeout():
	if not has_gun or not target:
		return
	shoot()
	$"../Sprite2D".play("Shoot")
	$AnimChanger.start()

func _on_AnimChanger_timeout():
	$"../Sprite2D".play("Idle")