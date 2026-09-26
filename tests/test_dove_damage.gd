extends SceneTree

# Usage: ... --script res://tests/test_dove_damage.gd -- [mob scene path]
# Spawns a contact-damage mob near a stationary player: does it hurt the player, with flash + sound?
var room = null
var player = null
var dove = null
var frame := 0
var last_hp := -1.0
var hits := []
var audio_playing_on_hit := 0
var flash_seen := false
var sound_seen := 0
var mob_path := "res://mobs/turtle_dove/TurtleDove.tscn"

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() > 0:
		mob_path = args[0]
	Engine.time_scale = 4.0
	var packed: PackedScene = load("res://rooms/night_01.tscn")
	room = packed.instantiate()
	room.night = 0
	root.add_child(room)
	player = room.get_node("Player")
	player.set_physics_process(false)

func _process(_delta) -> bool:
	frame += 1
	if frame == 3:
		dove = load(mob_path).instantiate()
		dove.position = player.position + Vector2(150, 0)
		room.get_node("Mobs").add_child(dove)
	if dove == null:
		return false
	var hp: float = player.health_component.health
	if last_hp < 0.0:
		last_hp = hp
	if hp < last_hp:
		hits.append(frame)
		for c in root.get_children():
			if c is AudioStreamPlayer and c.playing:
				sound_seen += 1
				break
		last_hp = hp
	var skin = player.get_node("Skin")
	if skin.modulate != Color(1, 1, 1, 1):
		flash_seen = true
	if frame > 1500:
		print("hits on player: ", hits.size(), " at frames ", hits.slice(0, 6))
		print("player final hp: ", last_hp, " / ", player.health_component.MAX_HEALTH)
		print("hit sound played on ", sound_seen, " of ", hits.size(), " hits")
		print("player sprite flash seen: ", flash_seen)
		print(mob_path.get_file(), " test: ", "PASS" if hits.size() > 0 and flash_seen and sound_seen > 0 else "FAIL")
		return true
	return false
