extends BulletBase

@onready var _animation_player := $AnimationPlayer as AnimationPlayer
@onready var _particles := $GPUParticles2D as GPUParticles2D
@onready var _sprite := $Sprite2D

func _ready() -> void:
	_animation_player.connect("animation_finished", Callable(self, "_on_AnimationPlayer_animation_finished"))
	super._ready()

# Reset visibility/scale directly (not just via the "RESET" animation) and immediately — an
# AnimationPlayer's play() doesn't apply a track's keyframes synchronously, only on its own next
# processing step, so a reused bullet could otherwise show a stale hidden/shrunk frame left over
# from its last "destroy" play for a tick before "spawn" catches up.
func _on_spawn() -> void:
	_sprite.visible = true
	_sprite.scale = Vector2.ONE
	_animation_player.play("spawn")
	super._on_spawn()

func _destroy():
	_disable()
	play_audio()
	_animation_player.play("destroy")


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == "destroy":
		_release()
