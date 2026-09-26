extends SceneTree

func _initialize() -> void:
	var failures := 0
	for night in range(1, 13):
		var cfg := NightData.config(night)
		if cfg == null:
			failures += 1
			print("FAIL night %d: resource missing or not loadable" % night)
			continue
		if cfg.night != night:
			failures += 1
			print("FAIL night %d: resource says night %d" % [night, cfg.night])
		if cfg.total_enemies != cfg.expected_total():
			failures += 1
			print("FAIL night %d: total %d, expected %d" % [night, cfg.total_enemies, cfg.expected_total()])
		for k in range(1, night + 1):
			var type: String = NightData.TYPES[k - 1]
			if cfg.count_of(type) != k:
				failures += 1
				print("FAIL night %d: %s x%d, expected %d" % [night, type, cfg.count_of(type), k])
		var types_seen := {}
		for wave in cfg.waves:
			for entry in wave.entries:
				types_seen[entry.mob_id] = true
		if types_seen.size() != night:
			failures += 1
			print("FAIL night %d: %d types, expected %d" % [night, types_seen.size(), night])
		var last: WaveData = cfg.waves.back()
		if last.entries.size() != 1 or last.entries[0].mob_id != NightData.new_type(night):
			failures += 1
			print("FAIL night %d: last wave is not the headliner alone" % night)
		if cfg.gift_name == "":
			failures += 1
			print("FAIL night %d: no gift name" % night)
	print("night data test: ", "PASS" if failures == 0 else "%d FAILURES" % failures)
	quit(1 if failures > 0 else 0)
