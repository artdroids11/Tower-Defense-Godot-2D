extends Node2D

@export var enemy_color: Color = Color.REBECCA_PURPLE
@export var radius: float = 20.0
@export var speed: float = 200.0

@export var money_reward: int = 5

var path_points: PackedVector2Array
var current_point_index: int = 0

var health: float = 3.0
var is_dead: bool = false

func _draw():
	draw_circle(Vector2.ZERO, radius, enemy_color)
	
func _process(delta: float) -> void:
	if current_point_index >= path_points.size():
		print("Inimigo chegou ao final da rota.")
		
		get_parent().damage_base(1)
		get_parent().enemies_alive -= 1
		
		queue_free()
		return
	
	var target_position: Vector2 = path_points[current_point_index]
	
	global_position = global_position.move_toward(
		target_position,
		speed * delta
	)
	
	if global_position.distance_to(target_position) < 2.0:
		current_point_index += 1
		
func take_damage(amount: float) -> void:
	if is_dead:
		return
	
	health -= amount
	print("Vida do inimigo: ", health)
	
	if health <= 0.0:
		is_dead = true
		
		remove_from_group("enemies")
		get_parent().enemies_alive -= 1
		get_parent().add_money(money_reward)
		queue_free()
	
