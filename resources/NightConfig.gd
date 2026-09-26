@tool
class_name NightConfig
extends Resource

enum Tier { SMALL, MEDIUM, LARGE }

@export_range(1, 12) var night := 1
@export var gift_name := ""
@export var tier: Tier = Tier.MEDIUM
@export var waves: Array[WaveData] = []

# Read-only in the inspector: total enemies over all waves (song rule: night N has N(N+1)/2).
@export var total_enemies: int:
	get:
		var total := 0
		for wave in waves:
			if wave:
				total += wave.enemy_count
		return total
	set(_value):
		pass

func expected_total() -> int:
	return night * (night + 1) / 2

func count_of(mob_id: String) -> int:
	var total := 0
	for wave in waves:
		for entry in wave.entries:
			if entry.mob_id == mob_id:
				total += entry.count
	return total
