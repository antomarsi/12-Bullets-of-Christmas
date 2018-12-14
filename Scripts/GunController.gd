extends Position2D
onready var player = get_parent().get_parent()
var can_shoot = false
var flip = false

func _ready():
	$GunTimer.wait_time = player.SHOOT_SPEED
	$GunTimer.start()
	pass

func _process(delta):
	_aim_gun()
	_shoot(delta)
	
func _shoot(delta):
	if Input.is_action_pressed("click") and can_shoot:
		can_shoot = false
		$GunTimer.start()
		$Shoot.play()
		var dir = ($Pivot/GunRoot/ShootPoint.global_transform.origin - global_transform.origin).normalized()
		player.emit_signal('shoot', player.Bullet, $ShootPoint.global_position, dir)

func _aim_gun():
	var mouse_pos = get_global_mouse_position()
	look_at(mouse_pos)

	if mouse_pos.x > global_position.x:
		$GunSprite.flip_v = false
		flip = false
	elif mouse_pos.x < global_position.x:
		$GunSprite.flip_v = true
		flip = true

func _on_GunTimer_timeout():
	can_shoot = true