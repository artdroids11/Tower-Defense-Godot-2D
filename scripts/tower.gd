extends Node2D

@export var range: float = 250.0
@export var tower_radius: float = 18.0

var main:Node2D
var enemies_in_range: Array[Node2D] = []
var target: Node2D = null

var attack_damage: int = 1
var attack_interval: float = 1.0
var attack_timer: float = 1.0

func _draw() -> void:
	draw_circle(Vector2.ZERO, range, Color(0.2, 0.6, 1.0, 0.2))
	draw_circle(Vector2.ZERO, tower_radius, Color(0.706, 0.0, 0.0, 1.0))

func _ready() -> void:
	position = Vector2(285, 190)
	main = get_parent()
	
func _process(delta: float) -> void:
	find_enemies_in_range()
	select_target()
	attack(delta)

func find_enemies_in_range() -> void:
	var current_enemies: Array[Node2D] = []
	
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		
		var distance: float = global_position.distance_to(enemy.global_position)
		
		if distance <= range:
			current_enemies.append(enemy)
			
			if not enemies_in_range.has(enemy):
				print("Inimigo entrou no alcance!")
		elif enemies_in_range.has(enemy):
			print("Inimigo saiu do alcance!")
	
	enemies_in_range = current_enemies
	
func select_target() -> void:
	var closest_enemy: Node2D = null
	var closest_distance: float = range
	
	for enemy in enemies_in_range:
		if not is_instance_valid(enemy):
			continue
			
		var distance: float = global_position.distance_to(enemy.global_position)
		
		if closest_distance == null or distance < closest_distance:
			closest_distance = distance
			closest_enemy = enemy
			
	if target != closest_enemy:
		target = closest_enemy
		
		if target != null:
			print("Alvo selecionado: ", target.name)
		else:
			print("Nenhum alvo no alcance")

func attack(delta:float) -> void:
	attack_timer += delta
	
	if attack_timer >= attack_interval:
		if is_instance_valid(target):
			print("Atacando o alvo: ", target.name)
			target.take_damage(attack_damage)
		else:
			("Nenhum alvo no alcance")
		
		attack_timer -= attack_interval
	
