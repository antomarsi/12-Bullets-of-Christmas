class_name BulletBase
extends Area2D

@export var speed := 750.0
@export var max_range := 1000.0
@export var _audio : AudioStreamPlayer2D

var damage : Attack = _default_attack()

var _travelled_distance = 0.0
var _has_hit := false

static func _default_attack() -> Attack:
	var attack := Attack.new()
	attack.attack_damage = 1
	return attack

func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("area_entered", Callable(self, "_on_area_entered"))
	play_audio()

func play_audio():
	if _audio:
		if _audio is RandomAudioPlayer2D:
			_audio.play_audio()
		else:
			_audio.play()

func _physics_process(delta: float) -> void:
	_move(delta)

func randomize_rotation(max_angle: float) -> void:
	rotation += randf() * max_angle - max_angle / 2.0

func _move(delta: float) -> void:
	var distance := speed * delta
	var motion := transform.x * speed * delta

	position += motion
	_travelled_distance += distance
	if _travelled_distance > max_range:
		_destroy()

func _hit_body(body) -> void:
	if body.has_method("take_damage"):
		body.take_damage(int(damage.attack_damage))

func _hit_area(area) -> void:
	if area is HitboxComponent and not area.get_parent().has_method("take_damage"):
		area.damage(damage)

# A rolling (or blinking) player cannot be hit, so bullets fly straight through instead of vanishing.
func _passes_through(target) -> bool:
	return target != null and target.has_method("is_invulnerable") and target.is_invulnerable()

func _destroy() -> void:
	queue_free()

func _disable() -> void:
	set_physics_process(false)
	set_deferred("monitoring", false)

func _on_body_entered(body) -> void:
	if _has_hit or _passes_through(body):
		return
	_has_hit = true
	_hit_body(body)
	_destroy()

func _on_area_entered(area) -> void:
	if _has_hit or not area is HitboxComponent or _passes_through(area.get_parent()):
		return
	_has_hit = true
	_hit_area(area)
	_destroy()
