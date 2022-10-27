class_name GunHolder
extends Area2D


export var weapon_scene: PackedScene setget set_weapon_scene

var weapon: Weapon

onready var _bullet_spawning_point := $BulletSpawningPoint

func _physics_process(delta: float) -> void:
	look_at(get_global_mouse_position())

func set_weapon_scene(scene: PackedScene) -> void:
	weapon_scene = scene
	if weapon:
		weapon.queue_free()

	# If the node hasn't been added to the scene tree yet, pause the function until it emits its "ready" signal.
	# This is necessary if you assign a spell scene in the Inspector, as Godot will try to run this function right after creating this node in memory, before adding it to the scene tree.
	if not is_inside_tree():
		yield(self, "ready")

	if weapon_scene:
		var new_bullet = scene.instance()
		assert(new_bullet is Weapon, "You passed a scene that is not a Weapon to the SpellHolder.")

		weapon = new_bullet
		_bullet_spawning_point.add_child(weapon)


func _disable() -> void:
	set_weapon_scene(null)
