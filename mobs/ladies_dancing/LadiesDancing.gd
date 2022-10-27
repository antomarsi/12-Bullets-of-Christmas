extends Mob

export var attack_speed := 1200.0

onready var _walk_anim := $WalkAnimation
onready var _hurtbox := $HurtBox
onready var _collision_shape := $CollisionShape2D

var _is_in_attack_state := false
var _charge_direction := Vector2()

func _ready() -> void:
	._ready()
	_hurtbox.connect("body_entered", self, "_on_HurtBox_body_entered")

func _on_DetectionArea_body_entered(body: Player) -> void:
	_target = body

func _on_DetectionArea_body_exited(_body: Player) -> void:
	_target = null

func _physics_process(delta: float) -> void:
	if not _target:
		return
	
	orbit_target()
	follow(_target.global_position)

func _on_HurtBox_body_entered(body: Node) -> void:
	if body is Player:
		body.take_damage(damage)
