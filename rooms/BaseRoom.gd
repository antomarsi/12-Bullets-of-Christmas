class_name BaseRoom
extends Node2D

const TILE := 16
const FLOOR_TILES := [Vector2i(5, 0), Vector2i(5, 0), Vector2i(5, 0), Vector2i(5, 0), Vector2i(5, 0), Vector2i(5, 0), Vector2i(5, 0), Vector2i(5, 1), Vector2i(0, 1)]
const WALL_TOPS := [Vector2i(2, 0), Vector2i(3, 0)]
const WALL_FACES := [Vector2i(2, 1), Vector2i(3, 1)]

# night > 0: waves come from NightData via a WaveDirector. night == 0: legacy test rooms
# with mobs placed by hand under Mobs.
@export var night := 0
@export var next_stage : PackedScene

@export_group("Tile map")
# Floor area in tiles (16 px each). Walls are added around it. (0, 0) = no tiles (placeholder floor).
@export var tile_map_size := Vector2i.ZERO
@export var wall_thickness := 2
# Extra wall blocks inside the arena, in floor-area tile coordinates.
@export var pillars: Array[Rect2i] = []
@export var tile_set: TileSet = preload("res://tileset/room_tiles.tres")

@export_group("Placeholder (no tile map)")
@export var bounds := Rect2(0, 0, 1280, 720)
@export var floor_color := Color(0.82, 0.88, 0.95)

@onready var enemies_holder = $Mobs

var enemies = []
var director: WaveDirector
var camera: GameCamera
var _floor_cells := {}
var _wall_cells := {}

func _ready() -> void:
	Events.last_room = scene_file_path
	if tile_map_size != Vector2i.ZERO:
		_build_tiles()
	queue_redraw()
	if night > 0:
		if tile_map_size == Vector2i.ZERO:
			_build_bounds()
		_setup_camera()
		Events.night_cleared.connect(_on_night_cleared, CONNECT_ONE_SHOT)
		director = WaveDirector.new()
		director.night = night
		add_child(director)
		director.start(enemies_holder, _spawn_points())
	else:
		enemies = enemies_holder.get_children()
		Events.connect("mob_died", Callable(self, "_on_mob_died"))

func _draw() -> void:
	if tile_map_size == Vector2i.ZERO:
		draw_rect(bounds, floor_color)

# --- tiles -------------------------------------------------------------------------------

func _build_tiles() -> void:
	var t := wall_thickness
	var total := tile_map_size + Vector2i(t * 2, t * 2)
	bounds = Rect2(0, 0, total.x * TILE, total.y * TILE)

	var old_map := get_node_or_null("TileMap")
	if old_map:
		old_map.queue_free()

	var blocked := {}
	for r in pillars:
		for x in range(r.position.x, r.end.x):
			for y in range(r.position.y, r.end.y):
				blocked[Vector2i(x + t, y + t)] = true

	for x in total.x:
		for y in total.y:
			var cell := Vector2i(x, y)
			var border := x < t or y < t or x >= total.x - t or y >= total.y - t
			if border or blocked.has(cell):
				_wall_cells[cell] = true
			else:
				_floor_cells[cell] = true

	var floor_layer := TileMapLayer.new()
	floor_layer.name = "Floor"
	floor_layer.tile_set = tile_set
	floor_layer.z_index = -20
	add_child(floor_layer)
	var wall_layer := TileMapLayer.new()
	wall_layer.name = "Walls"
	wall_layer.tile_set = tile_set
	wall_layer.z_index = -10
	add_child(wall_layer)

	for cell in _floor_cells:
		var pick: Vector2i = FLOOR_TILES[(cell.x * 7 + cell.y * 13) % FLOOR_TILES.size()]
		floor_layer.set_cell(cell, 0, pick)
	for cell in _wall_cells:
		var below: Vector2i = cell + Vector2i(0, 1)
		var variants: Array = WALL_FACES if _floor_cells.has(below) else WALL_TOPS
		# Walls also need floor under their face tiles so nothing shows through.
		floor_layer.set_cell(cell, 0, FLOOR_TILES[0])
		wall_layer.set_cell(cell, 0, variants[(cell.x * 3 + cell.y * 5) % variants.size()])

	var player := get_node_or_null("Player") as Node2D
	if player:
		player.position = Vector2(total.x * TILE / 2.0, (total.y - t - 5) * TILE)

func has_tiles() -> bool:
	return not _floor_cells.is_empty()

# True when every tile within `margin_tiles` of the position is floor (not wall, not outside).
func is_walkable(pos: Vector2, margin_tiles := 1) -> bool:
	if not has_tiles():
		return bounds.grow(-margin_tiles * TILE).has_point(pos)
	var c := Vector2i(floori(pos.x / TILE), floori(pos.y / TILE))
	for dx in range(-margin_tiles, margin_tiles + 1):
		for dy in range(-margin_tiles, margin_tiles + 1):
			if not _floor_cells.has(c + Vector2i(dx, dy)):
				return false
	return true

# --- spawns and camera -------------------------------------------------------------------

func _spawn_points() -> Array:
	var points := []
	if has_tiles():
		for cell in _floor_cells:
			if cell.x % 3 == 0 and cell.y % 3 == 0:
				var pos: Vector2 = (Vector2(cell) + Vector2(0.5, 0.5)) * TILE
				if is_walkable(pos, 3):
					points.append(pos)
		return points
	var holder := get_node_or_null("SpawnPoints")
	if holder:
		for marker in holder.get_children():
			points.append((marker as Node2D).global_position)
	if points.is_empty():
		var m := 80.0
		points = [
			bounds.position + Vector2(m, m),
			bounds.position + Vector2(bounds.size.x - m, m),
			bounds.position + Vector2(m, bounds.size.y - m),
			bounds.position + Vector2(bounds.size.x - m, bounds.size.y - m),
		]
	return points

func _setup_camera() -> void:
	var player := get_node_or_null("Player") as Node2D
	if player == null:
		return
	camera = GameCamera.new()
	camera.target = player
	add_child(camera)
	camera.set_limits(bounds)
	camera.global_position = player.global_position.round()

func _build_bounds() -> void:
	var t := 64.0
	var rects := [
		Rect2(bounds.position.x - t, bounds.position.y - t, bounds.size.x + 2 * t, t),
		Rect2(bounds.position.x - t, bounds.end.y, bounds.size.x + 2 * t, t),
		Rect2(bounds.position.x - t, bounds.position.y, t, bounds.size.y),
		Rect2(bounds.end.x, bounds.position.y, t, bounds.size.y),
	]
	for r in rects:
		var body := StaticBody2D.new()
		body.collision_layer = 17
		body.collision_mask = 0
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = r.size
		shape.shape = rect
		body.position = r.get_center()
		body.add_child(shape)
		add_child(body)

func _on_night_cleared(cleared_night: int) -> void:
	SaveData.mark_cleared(cleared_night)
	await get_tree().create_timer(2.0).timeout
	Game.advance_after_clear(cleared_night)

func _on_mob_died(mob) -> void:
	enemies.erase(mob)
	print("Now has %d enemies" % enemies.size())

	if enemies.size() == 0:
		if next_stage:
			get_tree().change_scene_to_packed.call_deferred(next_stage)
		else:
			get_tree().change_scene_to_file.call_deferred("res://Main.tscn")
