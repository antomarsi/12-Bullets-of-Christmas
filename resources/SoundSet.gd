@tool
class_name SoundSet
extends Resource

# A sound effect you can edit in the Inspector: drag audio files into `streams` (one is picked at
# random each time), and tune volume, pitch variation and how often it may retrigger.
@export var streams: Array[AudioStream] = []
@export_range(-60.0, 12.0, 0.5) var volume_db := 0.0
@export_range(0.0, 0.5, 0.01) var pitch_variation := 0.05
@export_range(0, 500, 10) var min_interval_ms := 60
@export var positional := true

var _last_ms := -100000

func play(node: Node, position := Vector2.ZERO) -> void:
	if streams.is_empty() or node == null or not node.is_inside_tree():
		return
	var now := Time.get_ticks_msec()
	if now - _last_ms < min_interval_ms:
		return
	_last_ms = now
	var stream: AudioStream = streams.pick_random()
	if stream == null:
		return
	var player: Node
	if positional:
		var p2 := AudioStreamPlayer2D.new()
		p2.global_position = position
		p2.max_distance = 2000.0
		player = p2
	else:
		player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_variation, pitch_variation)
	player.finished.connect(player.queue_free)
	var parent := node.get_tree().current_scene if node.get_tree().current_scene else node.get_tree().root
	parent.add_child(player)
	if positional:
		(player as Node2D).global_position = position
	player.play()
