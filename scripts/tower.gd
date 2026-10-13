extends Node2D

const PROJECTILE_SCENE = preload("res://scenes/projectiles.tscn")

@export var attack_range: float = 230.0
@export var tower_radius: float = 18.0

var main:Node2D
var enemies_in_range: Array[Node2D] = []
var target: Node2D = null

@export var attack_damage: int = 2
@export var attack_interval: float = 1.0
var attack_timer: float = 0.0

var is_selected: bool = false

func _draw() -> void:
	if is_selected:
		draw_circle(Vector2.ZERO, attack_range, Color(0.441, 0.27, 0.12, 0.137))

func _ready() -> void:
	main = get_parent()
	set_selected(false)
	
func set_selected(value: bool) -> void:
	is_selected = value
	queue_redraw()
	
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
		
		if distance <= attack_range:
			current_enemies.append(enemy)
			
			if not enemies_in_range.has(enemy):
				print("Inimigo entrou no alcance!")
		elif enemies_in_range.has(enemy):
			print("Inimigo saiu do alcance!")
	
	enemies_in_range = current_enemies
	
func select_target() -> void:
	var closest_enemy: Node2D = null
	var closest_distance: float = attack_range
	
	for enemy in enemies_in_range:
		if not is_instance_valid(enemy):
			continue
			
		var distance: float = global_position.distance_to(enemy.global_position)
		
		if closest_enemy == null or distance < closest_distance:
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
			var projectile = PROJECTILE_SCENE.instantiate()
			get_parent().add_child(projectile)
			
			projectile.global_position = global_position
			projectile.target = target
			
			projectile.damage = attack_damage
			
			projectile.direction = (target.global_position 
			- projectile.global_position).normalized()
			
			projectile.rotation = projectile.direction.angle()
	
		
		attack_timer -= attack_interval
		
