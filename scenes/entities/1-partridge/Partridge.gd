extends CharacterBody2D

@export var pathfindComponent : PathfindComponent
@export var velocityComponent : VelocityComponent
@export var player : Node2D
@onready var sprite := $Sprite

@onready var health_component : HealthComponent = $HealthComponent

func _ready():
	health_component.died.connect(_on_died)

func take_damage(amount) -> void:
	health_component.health -= amount

func _on_died() -> void:
	set_process(false)
	set_physics_process(false)
	Events.mob_died.emit(self)
	queue_free()

func _process(delta):
	#var target = global_position
	#if player:
		#target = player.global_position
	#pathfindComponent.set_target_position(target)
	pathfindComponent.followPath()
	velocityComponent.move(self)
	pass

func _physics_process(delta):
	if velocityComponent.velocity.length():
		sprite.play("walk")
	else:
		sprite.play("idle")
	if velocityComponent.velocity.x != 0:
		sprite.flip_h = sign(velocityComponent.velocity.x) == -1
	pass
