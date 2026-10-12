extends Node2D

@export var speed: float = 1000.0
var target: Node2D
var direction: Vector2 = Vector2.ZERO
var previous_position: Vector2 = Vector2.ZERO

var damage: int = 1

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
		
	if closest_point.distance_to(target.global_position) < 20.0:
		target.take_damage(damage)
		queue_free()
