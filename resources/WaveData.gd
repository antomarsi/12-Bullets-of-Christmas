@tool
class_name WaveData
extends Resource

@export var entries: Array[WaveEntry] = []

# Read-only in the inspector: how many enemies this wave spawns.
@export var enemy_count: int:
	get:
		var total := 0
		for entry in entries:
			if entry:
				total += entry.count
		return total
	set(_value):
		pass
