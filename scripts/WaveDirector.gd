class_name WaveDirector
extends Node

@export var night := 1
@export var stagger_time := 4.0
@export var wave_time_cap := 45.0
@export var breather_time := 3.0
@export var telegraph_time := 0.7
@export var min_spawn_distance := 260.0

var _mobs_parent: Node
var _spawn_points: Array = []
var _alive := {}
var _banner := WaveBanner.new()
var spawned_total := 0

func start(mobs_parent: Node, spawn_points: Array) -> void:
	_mobs_parent = mobs_parent
	_spawn_points = spawn_points
	add_child(_banner)
	Events.mob_died.connect(_on_mob_died)
	_run()

func alive_count() -> int:
	return _alive.size()

func _run() -> void:
	var waves: Array = NightData.waves(night)
	for i in waves.size():
		Events.wave_started.emit(i + 1, waves.size())
		_banner.show_text("NIGHT %d  -  WAVE %d/%d" % [night, i + 1, waves.size()])
		await get_tree().create_timer(1.0).timeout
		await _spawn_wave(waves[i])
		await _wait_until_clear()
		Events.wave_cleared.emit(i + 1)
		if i < waves.size() - 1:
			await get_tree().create_timer(breather_time).timeout
	Events.night_cleared.emit(night)

func _spawn_wave(wave: WaveData) -> void:
	var queue := []
	for entry in wave.entries:
		for n in entry.count:
			queue.append(entry)
	queue.shuffle()
	var delay := stagger_time / maxf(queue.size(), 1.0)
	for entry in queue:
		_telegraph_and_spawn(entry)
		await get_tree().create_timer(delay).timeout
	await get_tree().create_timer(telegraph_time).timeout

func _telegraph_and_spawn(entry: WaveEntry) -> void:
	var scene := entry.scene
	if scene == null:
		push_warning("WaveDirector: no scene for '%s' (not built yet), skipping" % entry.mob_id)
		return
	var pos := _pick_spawn_point()
	var telegraph := SpawnTelegraph.new()
	telegraph.duration = telegraph_time
	telegraph.position = pos
	telegraph.on_done = func() -> void:
		var mob: Node2D = scene.instantiate()
		mob.position = pos
		_mobs_parent.add_child(mob)
		_alive[mob.get_instance_id()] = mob
		spawned_total += 1
		mob.tree_exited.connect(func() -> void: _alive.erase(mob.get_instance_id()))
	_mobs_parent.add_child(telegraph)

func _pick_spawn_point() -> Vector2:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	var candidates := []
	var farthest := Vector2.ZERO
	var farthest_d := -1.0
	for p in _spawn_points:
		var d: float = player.global_position.distance_to(p) if player else 9999.0
		if d >= min_spawn_distance:
			candidates.append(p)
		if d > farthest_d:
			farthest_d = d
			farthest = p
	var pick: Vector2 = candidates.pick_random() if candidates.size() > 0 else farthest
	return pick + Vector2(randf_range(-24, 24), randf_range(-24, 24))

func _wait_until_clear() -> void:
	var elapsed := 0.0
	while elapsed < wave_time_cap:
		await get_tree().process_frame
		elapsed += get_process_delta_time()
		if _alive.is_empty() and _telegraphs_done():
			return

func _telegraphs_done() -> bool:
	for child in _mobs_parent.get_children():
		if child is SpawnTelegraph:
			return false
	return true

func _on_mob_died(mob) -> void:
	_alive.erase(mob.get_instance_id())
