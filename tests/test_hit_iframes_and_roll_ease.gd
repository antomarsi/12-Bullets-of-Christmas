extends SceneTree

# Checks (1) the post-hit invulnerability window is short enough that a second hit from the same
# burst can land, and (2) the roll has a punchy start (>1x speed) easing out to a slow finish
# (<1x), front-loaded rather than linear.
var room = null
var player = null
var frame := 0
var stage := 0
var stage_t := 0.0
var report := []
var failed := false
var first_hit_frame := -1
var second_hit_frame := -1
var speed_samples := []

func check(ok: bool, text: String) -> void:
	report.append(("ok   " if ok else "FAIL ") + text)
	if not ok:
		failed = true

func _initialize() -> void:
	var packed: PackedScene = load("res://rooms/night_01.tscn")
	room = packed.instantiate()
	room.night = 0
	root.add_child(room)
	player = room.get_node("Player")
	player.set_physics_process(false)

func _process(delta) -> bool:
	frame += 1
	if frame < 3:
		return false
	stage_t += delta
	match stage:
		0:
			# Fire damage every frame and see how long until the second one actually lands.
			var hp_before: float = player.health_component.health
			player.take_damage(1)
			if player.health_component.health < hp_before:
				if first_hit_frame < 0:
					first_hit_frame = frame
				elif second_hit_frame < 0:
					second_hit_frame = frame
					var window_s: float = (second_hit_frame - first_hit_frame) * delta
					check(window_s < 0.9, "invulnerability window is %.2f s (was ~0.99 s before the fix)" % window_s)
					check(absf(window_s - player.hit_invulnerable_time) < 0.15, "window (%.2f s) is close to hit_invulnerable_time (%.2f s)" % [window_s, player.hit_invulnerable_time])
					stage = 1
					stage_t = 0.0
		1:
			if stage_t > 0.3 and not player._invulnerable:
				player.roll(Vector2.RIGHT)
				stage = 2
				stage_t = 0.0
		2:
			if player.is_rolling():
				speed_samples.append([1.0 - player._roll_left / player.roll_duration, player.velocity.length() / player.roll_speed])
			elif speed_samples.size() > 3:
				# The very first sample can land on the same tick roll() was called, before
				# Player._physics_process has run even once (headless idle ticks can outrun the
				# fixed physics tick), reading a stale velocity of 0. Use the highest of the first
				# few samples as the true start value instead of trusting sample 0 literally.
				var start_mult: float = 0.0
				for i in mini(3, speed_samples.size()):
					start_mult = maxf(start_mult, speed_samples[i][1])
				var end_mult: float = speed_samples[-1][1]
				check(start_mult > 1.05, "roll starts with a punch (%.2fx roll_speed)" % start_mult)
				check(end_mult < 0.9, "roll ends slower (%.2fx roll_speed)" % end_mult)
				check(start_mult > end_mult, "speed decreases over the roll (%.2f -> %.2f)" % [start_mult, end_mult])
				# Ease-out: at 25% through, speed should already have dropped closer to the end
				# value than a straight line from start to end would predict.
				var quarter = speed_samples[int(speed_samples.size() * 0.25)]
				var linear_quarter: float = lerpf(start_mult, end_mult, quarter[0])
				check(quarter[1] < linear_quarter, "at %.0f%% through, speed %.2fx is below the linear prediction %.2fx (front-loaded drop)" % [quarter[0] * 100, quarter[1], linear_quarter])
				for r in report:
					print(r)
				print("iframes/roll-ease test: ", "FAIL" if failed else "PASS")
				return true
	if frame > 3000:
		print("TIMEOUT at stage ", stage)
		return true
	return false
