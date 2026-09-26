class_name NightData
extends RefCounted

# Gift ids in song order; the index + 1 is the night the gift appears and how many there are.
const TYPES := [
	"partridge", "dove", "hen", "calling_bird", "ring", "goose",
	"swan", "maid", "lady", "lord", "piper", "drummer",
]

const PATH := "res://data/nights/night_%02d.tres"

static var _cache := {}

static func config(night: int) -> NightConfig:
	if not _cache.has(night):
		var path := PATH % night
		_cache[night] = load(path) if ResourceLoader.exists(path) else null
	return _cache[night]

static func waves(night: int) -> Array:
	var cfg := config(night)
	return cfg.waves if cfg else []

static func total(night: int) -> int:
	var cfg := config(night)
	return cfg.total_enemies if cfg else 0

static func new_type(night: int) -> String:
	return TYPES[night - 1]
