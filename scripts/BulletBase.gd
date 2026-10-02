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
	_on_spawn()

# Runs on every spawn, including pooled reuse (unlike _ready(), which only ever fires once per
# Node's lifetime) — anything that needs to reset per-shot belongs here, not in _ready().
func _on_spawn() -> void:
	_has_hit = false
	_travelled_distance = 0.0
	_enable()
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
	if not area is HitboxComponent:
		return
	var parent = area.get_parent()
	if parent.has_method("take_damage"):
		# The parent manages its own health/invulnerability (e.g. the player) — call it
		# directly instead of poking the HealthComponent, or the hit silently does nothing.
		parent.take_damage(int(damage.attack_damage))
	else:
		area.damage(damage)

# A rolling (or blinking) player cannot be hit, so bullets fly straight through instead of vanishing.
func _passes_through(target) -> bool:
	return target != null and target.has_method("is_invulnerable") and target.is_invulnerable()

# Returns the bullet to the pool. Subclasses with an outro (impact animation/sound) should
# disable immediately but defer calling this until the outro finishes, so it has time to play
# while the node is still in the tree (see BasicBullet.gd).
func _destroy() -> void:
	_release()

func _release() -> void:
	_disable()
	# Hits are detected from body_entered/area_entered, which fire during the physics step —
	# Godot disallows removing a CollisionObject2D from the tree right then, so defer it. Pool the
	# bullet together with (not before) the actual removal, or a shoot() call later this same
	# frame could pop it from the pool and add_child() it while it's technically still parented.
	call_deferred("_finish_release")

func _finish_release() -> void:
	if get_parent():
		get_parent().remove_child(self)
	BulletPattern.pool_release(self)

func _disable() -> void:
	set_physics_process(false)

func _enable() -> void:
	set_physics_process(true)

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
