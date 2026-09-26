extends Node2D
class_name PathfindComponent

@onready var navigation_agent : NavigationAgent2D = $NavigationAgent2D
@onready var intervalTimer : Timer = $Timer

@export var velocity_component : VelocityComponent
@export var debug_draw_enabled : bool = false
var target : Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	navigation_agent.connect("velocity_computed", _on_navigation_velocity_computed)
	set_process(OS.is_debug_build() && debug_draw_enabled)

func _process(delta):
	queue_redraw()

func _draw():
	if not (OS.is_debug_build() && debug_draw_enabled):
		return
	for i in len(navigation_agent.get_current_navigation_path()):
		var point = navigation_agent.get_current_navigation_path()[i]
		draw_circle(to_local(point), 3.0, Color.ORANGE)
		if i > 0:
			var previous_point = navigation_agent.get_current_navigation_path()[i - 1]
			draw_line(to_local(previous_point), to_local(point), Color.ORANGE, 2.0)

func set_target_position(target_position: Vector2):
	if not intervalTimer.is_stopped():
		return
	intervalTimer.start()
	navigation_agent.target_position = target_position

func force_set_target_position(target_position: Vector2):
	navigation_agent.target_position = target_position
	intervalTimer.start()

func followPath():
	if (navigation_agent.is_navigation_finished()):
		velocity_component.decelerate()
		return
	
	var direction = (navigation_agent.get_next_path_position() - global_position).normalized()
	velocity_component.accelerate_in_direction(direction)
	navigation_agent.velocity = velocity_component.velocity

func _on_navigation_velocity_computed(safe_velocity: Vector2):
	var newDirection = safe_velocity.normalized()
	var currentDirection = velocity_component.velocity.normalized()
	var halfway = newDirection.lerp(currentDirection, 0.1)
	velocity_component.velocity = halfway * velocity_component.velocity.length()
