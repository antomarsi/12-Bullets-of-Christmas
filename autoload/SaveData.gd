extends Node

var save_path := "user://save.cfg"
var cleared := {}

func _ready() -> void:
	load_data()

func load_data() -> void:
	cleared.clear()
	var cfg := ConfigFile.new()
	if cfg.load(save_path) != OK:
		return
	for night in range(1, Game.LAST_NIGHT + 1):
		if cfg.get_value("nights", str(night), false):
			cleared[night] = true

func save_data() -> void:
	var cfg := ConfigFile.new()
	for night in cleared:
		cfg.set_value("nights", str(night), true)
	cfg.save(save_path)

func mark_cleared(night: int) -> void:
	cleared[night] = true
	save_data()

func has_progress() -> bool:
	return not cleared.is_empty()

func highest_cleared() -> int:
	var best := 0
	for night in cleared:
		best = maxi(best, night)
	return best

# While testing (debug builds) every night that already has a room is selectable.
func is_unlocked(night: int) -> bool:
	if night == 1:
		return true
	if OS.is_debug_build() and Game.room_exists(night):
		return true
	return cleared.get(night - 1, false)

func continue_night() -> int:
	var night := mini(highest_cleared() + 1, Game.LAST_NIGHT)
	while night > 1 and not Game.room_exists(night):
		night -= 1
	return night

func erase() -> void:
	cleared.clear()
	save_data()
