class_name Bullet
extends Area2D

export var speed := 750.0
export var damage := 1
export var max_range := 1000.0

var _travelled_distance = 0.0

onready var _audio := $AudioStreamPlayer2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	assert(_audio, "The scene %s does not contain a node called AudioStreamPlayer2D" % [filename])
	assert(
		_audio is AudioStreamPlayer2D,
		"The scene %s's audio node is not an AudioStreamPlayer2D" % [filename]
	)
	connect("body_entered", self, "_on_body_entered")


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

func _hit_body(body: Node) -> void:
	if not body.has_method("take_damage"):
		return
	body.take_damage(damage)

func _destroy() -> void:
	queue_free()
	
func _disable() -> void:
	set_physics_process(false)
	set_deferred("monitoring", false)

func _on_body_entered(body: Node) -> void:
	_hit_body(body)
	_destroy()
