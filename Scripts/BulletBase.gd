class_name BulletBase
extends Area2D

@export var speed := 750.0
@export var max_range := 1000.0
@export var _audio : AudioStreamPlayer2D

var damage : Attack

var _travelled_distance = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	connect("body_entered", Callable(self, "_on_body_entered"))
	play_audio()

func play_audio():
	if _audio:
		if _audio is RandomAudioPlayer2D:
			_audio.play_audio()
		else:
			_audio.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
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
	print(body)
	if body is HitboxComponent:
		body.damage(damage)

func _destroy() -> void:
	queue_free()
	
func _disable() -> void:
	set_physics_process(false)
	set_deferred("monitoring", false)

func _on_body_entered(body) -> void:
	_hit_body(body)
	_destroy()
