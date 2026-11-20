extends AnimatableBody2D
var start_position: Vector2
var moving_to_end: bool = true
@export var end_position: Vector2
@export var move_speed: float
var can_move: bool = false

func _ready() -> void:
	start_position = global_position

func _physics_process(delta: float) -> void:
	moving_platform(delta)
	
	
func moving_platform(delta: float) -> void:
	if can_move == true:
		if global_position == start_position:
			moving_to_end = true	
		elif global_position == end_position:
			moving_to_end = false
		if moving_to_end == true:
			global_position = global_position.move_toward(end_position, move_speed*delta)
		else:
			global_position = global_position.move_toward(start_position, move_speed*delta)

	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		can_move = true 
