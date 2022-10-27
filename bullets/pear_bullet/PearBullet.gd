extends Bullet


onready var _animation_player := $AnimationPlayer as AnimationPlayer
onready var _particles := $Particles2D as Particles2D


func _ready() -> void:
	_animation_player.connect("animation_finished", self, "_on_AnimationPlayer_animation_finished")
	_animation_player.play("spawn")


func _destroy():
	_disable()
	_audio.play()
	_animation_player.play("destroy")


func _on_AnimationPlayer_animation_finished(anim_name: String) -> void:
	if anim_name == "destroy":
		queue_free()
