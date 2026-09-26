class_name RandomAudioPlayer2D
extends AudioStreamPlayer2D

@export var sounds = [] # (Array, AudioStream)
@export var randomize_pitch := true

func play_audio(from_position = 0.0) -> void:
	if sounds:
		stream = sounds[randi() % sounds.size()]
	if randomize_pitch:
		pitch_scale = randf_range(0.9, 1.6)
	play(from_position)
