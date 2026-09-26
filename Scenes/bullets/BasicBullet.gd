extends BulletBase

@onready var _animation_player := $AnimationPlayer as AnimationPlayer
@onready var _particles := $GPUParticles2D as GPUParticles2D
@onready var _sprite := $Sprite2D

func _ready() -> void:
	_animation_player.connect("animation_finished", Callable(self, "_on_AnimationPlayer_animation_finished"))
	_animation_player.play("spawn")
	super._ready()

func _destroy():
	_disable()
	play_audio()
	_animation_player.play("destroy")


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == "destroy":
		queue_free()
