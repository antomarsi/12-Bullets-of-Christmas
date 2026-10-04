extends Control

const BULLET_ICON := preload("res://bullets/basic_bullet/bullet.png")
const FONT := preload("res://fonts/pixelart.ttf")

# Must match GameCamera's fixed 2x zoom and 640x360 world view (see CLAUDE.md's Display-and-camera
# note) — the UI is laid out for a fixed 1280x720 regardless of real window size (canvas_items
# stretch handles that uniformly for both UI and world), so these can be hardcoded rather than
# read from the camera, and the arithmetic stays correct at any actual display resolution.
const VIEW_ZOOM := 2.0
const VIEW_CENTER := Vector2(640.0, 360.0)
const ARROW_MARGIN := 40.0
const ARROW_SIZE := 12.0
const ARROW_COLOR := Color(1.0, 0.3, 0.3, 0.85)

@onready var _health_bar := $container/HealthBar

var _player = null
var _max_ammo := 12
var _ammo_icons: Array[TextureRect] = []
var _reload_label: Label

func _ready() -> void:
	Events.connect("player_health_changed", Callable(self, "_on_player_health_changed"))
	_build_ammo_hud()

func _on_player_health_changed(health: int) -> void:
	_health_bar.health = health

# Bottom-right row of bullet icons for the 12-round magazine (the title mechanic): full brightness
# for rounds still in the mag, dimmed for spent ones. While reloading, rounds light back up
# left-to-right in sync with the player's actual reload progress instead of popping in all at
# once, and a "RELOADING" label shows above the row.
func _build_ammo_hud() -> void:
	_player = get_tree().get_first_node_in_group("player")
	if _player and _player.get("MAX_AMMO") != null:
		_max_ammo = _player.MAX_AMMO

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	vbox.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	vbox.grow_vertical = Control.GROW_DIRECTION_BEGIN
	vbox.position = Vector2(-30, -30)
	vbox.add_theme_constant_override("separation", 4)
	vbox.alignment = BoxContainer.ALIGNMENT_END
	add_child(vbox)

	_reload_label = Label.new()
	_reload_label.text = "RELOADING"
	_reload_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_reload_label.add_theme_font_override("font", FONT)
	_reload_label.add_theme_font_size_override("font_size", 16)
	_reload_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3))
	_reload_label.add_theme_color_override("font_outline_color", Color.BLACK)
	_reload_label.add_theme_constant_override("outline_size", 4)
	_reload_label.visible = false
	vbox.add_child(_reload_label)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 3)
	hbox.alignment = BoxContainer.ALIGNMENT_END
	vbox.add_child(hbox)

	for i in _max_ammo:
		var icon := TextureRect.new()
		icon.texture = BULLET_ICON
		icon.custom_minimum_size = Vector2(16, 10)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(icon)
		_ammo_icons.append(icon)

func _process(_delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	var filled: int = int(_player.reload_progress() * _max_ammo) if _player.reloading else _player.current_ammo
	for i in _ammo_icons.size():
		_ammo_icons[i].modulate = Color(1, 1, 1, 1) if i < filled else Color(1, 1, 1, 0.25)
	_reload_label.visible = _player.reloading
	queue_redraw()

# Points a small arrow at the screen edge toward every off-screen enemy, for Large-tier rooms
# where enemies can be out of view (the follow camera clamps to the room bounds, so enemies stay
# in-world but not necessarily on-screen). Drawn in this Control's own local space, which the root
# node's anchors (fills its parent edge-to-edge, no offset) make equivalent to the fixed 1280x720
# UI layout — mapping a world position into that space has to go through the ACTIVE GAME CAMERA,
# not this Control's own canvas transform (the UI layer intentionally ignores the game camera's
# zoom entirely, per the Display-and-camera note in CLAUDE.md, so they're different spaces).
func _draw() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return
	for mob in get_tree().get_nodes_in_group("mobs"):
		if not is_instance_valid(mob) or not (mob is Node2D):
			continue
		if ViewUtil.on_screen(mob, 0.0):
			continue
		var rel: Vector2 = mob.global_position - camera.global_position
		if rel == Vector2.ZERO:
			continue
		var dir := rel.normalized()
		var ui_pos: Vector2 = rel * VIEW_ZOOM + VIEW_CENTER
		var edge := Vector2(
			clampf(ui_pos.x, ARROW_MARGIN, 1280.0 - ARROW_MARGIN),
			clampf(ui_pos.y, ARROW_MARGIN, 720.0 - ARROW_MARGIN)
		)
		var tip := edge + dir * ARROW_SIZE
		var side := dir.orthogonal() * ARROW_SIZE * 0.6
		var back := edge - dir * ARROW_SIZE * 0.4
		draw_colored_polygon(PackedVector2Array([tip, back + side, back - side]), ARROW_COLOR)
