extends Node2D

@export var speed: float = 850.0
var target: Node2D
var direction: Vector2 = Vector2.ZERO
var previous_position: Vector2 = Vector2.ZERO

func _draw() -> void:
	draw_line(Vector2(-12, 0),Vector2(12, 0),Color(1.0, 0.008, 0.016, 1.0),5.0)

func _process(delta: float) -> void:
	if not is_instance_valid(target):
		queue_free()
		return
		
	previous_position = global_position
	global_position += direction * speed * delta
	
	var closest_point: Vector2 = Geometry2D.get_closest_point_to_segment(
		target.global_position,
		previous_position,
		global_position
	)
		
	if global_position.distance_to(target.global_position) < 25.0:
		target.take_damage(3)
		queue_free()
