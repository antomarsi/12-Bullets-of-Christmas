extends Control

const FONT := preload("res://fonts/pixelart.ttf")

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.color = Color(0.05, 0.06, 0.1)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var box := VBoxContainer.new()
	box.set_anchors_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 24)
	add_child(box)

	var title := Label.new()
	title.text = "SELECT A NIGHT"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_override("font", FONT)
	title.add_theme_font_size_override("font_size", 40)
	box.add_child(title)

	var center := CenterContainer.new()
	box.add_child(center)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 16)
	center.add_child(grid)

	var first_enabled: Button = null
	for night in range(1, Game.LAST_NIGHT + 1):
		var button := _make_button(night)
		grid.add_child(button)
		if first_enabled == null and not button.disabled:
			first_enabled = button

	var back := Button.new()
	back.text = "BACK"
	back.custom_minimum_size = Vector2(200, 44)
	back.add_theme_font_override("font", FONT)
	back.add_theme_font_size_override("font_size", 20)
	back.pressed.connect(func(): get_tree().change_scene_to_file("res://Main.tscn"))
	var back_row := CenterContainer.new()
	back_row.add_child(back)
	box.add_child(back_row)

	if first_enabled:
		first_enabled.grab_focus()

func _make_button(night: int) -> Button:
	var config := NightData.config(night)
	var gift := config.gift_name if config else "?"
	var button := Button.new()
	button.custom_minimum_size = Vector2(230, 96)
	button.add_theme_font_override("font", FONT)
	button.add_theme_font_size_override("font_size", 16)
	var built := Game.room_exists(night)
	var unlocked := SaveData.is_unlocked(night)
	var mark := "  [CLEARED]" if SaveData.cleared.get(night, false) else ""
	button.text = "NIGHT %d%s\n%s" % [night, mark, gift]
	if not built:
		button.text = "NIGHT %d\n(coming soon)" % night
	button.disabled = not (built and unlocked)
	button.pressed.connect(func(): Game.start_night(night))
	return button
