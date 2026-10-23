extends Node2D

const ENEMY_SCENE = preload("res://scenes/enemy.tscn")

# No sistema 2D da Godot, a origem local (0, 0) fica 
# no canto superior esquerdo do espaço de referência; 
# X cresce para a direita e Y cresce para baixo.
#
# Imagine que a janela do nosso jogo tenha 960 pixels de largura e 540 pixels de altura.
#  - Vector2(0, 0) representa o canto superior esquerdo.
#  - Vector2(960, 0) representa o canto superior direito.
#  - Vector2(960, 540) representa o canto inferior direito.
#  - Vector2(0, 540) representa o canto inferior esquerdo.

@onready var ground: Polygon2D = $Ground
@onready var path: Line2D = $Path
@onready var health_label: Label = $CanvasLayer/HealthLabel
@onready var waves_label: Label = $CanvasLayer/Waves
@onready var defeat_screen: Control = $CanvasLayer/DefeatScreen

@onready var restart_button: Button = $CanvasLayer/DefeatScreen/Content/RestartButton

@onready var tower_info_panel: PanelContainer = $CanvasLayer/TowerInfoPanel
@onready var tower_name_label: Label = $CanvasLayer/TowerInfoPanel/InfoContent/TowerNameLabel
@onready var damage_label: Label = $CanvasLayer/TowerInfoPanel/InfoContent/DamageLabel
@onready var range_label: Label = $CanvasLayer/TowerInfoPanel/InfoContent/RangeLabel
@onready var interval_label: Label = $CanvasLayer/TowerInfoPanel/InfoContent/IntervalLabel

@onready var upgrade_button: Button = $CanvasLayer/TowerInfoPanel/InfoContent/UpgradeButton

@onready var money_label: Label = $CanvasLayer/MoneyLabel

var base_health: int = 100

const UPGRADE_COST: int = 25
var money: int = 100

var current_wave: int = 0
var enemies_per_wave: int = 5
var spawn_interval: float = .7
var wave_interval: float = 2.0
var game_over: bool = false
var enemies_alive: int = 0
var total_waves: int = 5

var selected_tower: Node2D = null

func _ready():
	ground.polygon = PackedVector2Array([
		Vector2(0,0),
		Vector2(960,0),
		Vector2(960,540),
		Vector2(0,540)
	])
	
	ground.color = Color("558d50ff")
	
	path.points = PackedVector2Array([
		Vector2(-20, 100),
		Vector2(180, 100),
		Vector2(180, 260),
		Vector2(390, 260),
		Vector2(390, 130),
		Vector2(650, 130),
		Vector2(650, 410),
		Vector2(820, 410),
		Vector2(980, 410)
	])

	path.width = 54.0
	path.default_color = Color("806d44ff")
	
	defeat_screen.hide()
	tower_info_panel.hide()
	upgrade_button.hide()
	restart_button.pressed.connect(_on_restart_button_pressed)
	upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	
	start_wave()
	update_money_label()
	
func damage_base(amount: int) -> void:
	if base_health <= 0:
		return

	base_health = max(base_health - amount, 0)
	health_label.text = "Vida da base: " + str(base_health)

	print("Vida da base: ", base_health)

	if base_health <= 0:
		print("DERROTA! A base foi destruída.")
		game_over = true
		await get_tree().create_timer(0.8).timeout
		defeat_screen.show()
		
func _on_restart_button_pressed() -> void:
	print("BOTÃO CLICADO!")
	get_tree().reload_current_scene()
	
func spawn_enemy() -> void:
	var enemy = ENEMY_SCENE.instantiate()
	
	add_child(enemy)
	
	enemy.path_points = path.points
	enemy.current_point_index = 0
	enemy.global_position = path.points[0]
	
	enemies_alive += 1
	
func start_wave() -> void:
	if game_over:
		return
	
	if current_wave >= total_waves:
		print("Todas as ondas foram concluídas!")
		return
		
	current_wave += 1
	print("Iniciando onda: ", current_wave)
	waves_label.text = str(current_wave) + "/" + str(total_waves)
	
	for i in range(enemies_per_wave):
		if game_over:
			return
		
		spawn_enemy()
		await get_tree().create_timer(spawn_interval).timeout
		
	print("Todos os inimigos da onda ", current_wave, " foram enviados.")
	wait_and_start_next_wave()	
	
func wait_and_start_next_wave() -> void:
	while enemies_alive > 0:
		if game_over:
			return
		await get_tree().create_timer(.5).timeout
		
	if game_over:
		return
		
	await get_tree().create_timer(wave_interval).timeout
	
	if game_over:
		return
	
	if current_wave >= total_waves:
		print("Todas as ondas foram concluídas!")
		return
	
	start_wave()
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var clicked_position: Vector2 = get_global_mouse_position()
			var towers = get_tree().get_nodes_in_group("towers")
			
			for tower in towers:
				var tower_position: Vector2 = tower.global_position
				var tower_rect := Rect2(
					tower_position - Vector2(18, 18),
					 Vector2(36, 36)
					)
					
				if tower_rect.has_point(clicked_position):
					select_tower(tower)
					return
					
			if selected_tower != null:
				selected_tower.set_selected(false)
				selected_tower = null
				tower_info_panel.hide()
				upgrade_button.hide()
			
func select_tower(tower: Node2D) -> void:
	if selected_tower == tower:
		selected_tower.set_selected(false)
		selected_tower = null
		tower_info_panel.hide()
		upgrade_button.hide()
		return
		
	if selected_tower != null:
		selected_tower.set_selected(false)
		
	selected_tower = tower
	selected_tower.set_selected(true)
	update_tower_info(selected_tower)

func update_tower_info(tower: Node2D) -> void:
	tower_name_label.text = tower.name
	damage_label.text = "Dano: " + str(tower.attack_damage)
	range_label.text = "Alcance: " + str(tower.attack_range)
	interval_label.text = "Intervalo: " + str(tower.attack_interval) + "s"
	
	tower_info_panel.show()
	upgrade_button.show()
	tower_info_panel.reset_size()
	update_upgrade_button(tower)
	position_tower_info(tower)
	
func position_tower_info(tower: Node2D) -> void:
	var tower_position: Vector2 = tower.get_global_transform_with_canvas().origin
	var viewport_size: Vector2 = get_viewport_rect().size
	var panel_size: Vector2 = tower_info_panel.size
	var tower_rect: Rect2 = Rect2(
		tower_position - Vector2(18, 18),
		Vector2(36, 36)
	)
	var margin: float = 30.0
	
	var candidates: Array[Vector2] = [
		tower_position + Vector2(margin, -panel_size.y / 2.0),
		tower_position + Vector2(-panel_size.x - margin, -panel_size.y / 2.0),
		tower_position + Vector2(-panel_size.x / 2.0, -panel_size.y - margin),
		tower_position + Vector2(-panel_size.x / 2.0, margin),
		tower_position + Vector2(margin, -panel_size.y - margin),
		tower_position + Vector2(-panel_size.x - margin, -panel_size.y - margin),
		tower_position + Vector2(margin, margin),
		tower_position + Vector2(-panel_size.x - margin, margin)
	]
	
	var best_position: Vector2 = Vector2.ZERO
	var fewest_conflicts: int = 2147483647
	
	for candidate in candidates:
		var candidate_position: Vector2 = Vector2(
			clampf(candidate.x, 0.0, maxf(0.0, viewport_size.x - panel_size.x)),
			clampf(candidate.y, 0.0, maxf(0.0, viewport_size.y - panel_size.y))
		)
		
		var panel_rect: Rect2 = Rect2(candidate_position, panel_size)
		var conflicts: int = count_path_conflicts(panel_rect)
		
		if panel_rect.intersects(tower_rect):
			conflicts += 1000000
		
		if conflicts == 0:
			best_position = candidate_position
			fewest_conflicts = 0
			break
			
		if conflicts < fewest_conflicts:
			fewest_conflicts = conflicts
			best_position = candidate_position
			
	tower_info_panel.position = best_position
	
func count_path_conflicts(panel_rect: Rect2) -> int:
	var conflicts: int = 0
	var points: PackedVector2Array = path.points
	var path_transform: Transform2D = path.get_global_transform_with_canvas()
	var safe_rect: Rect2 = panel_rect.grow(path.width / 2.0)
	
	for i in range(points.size() - 1):
		var start: Vector2 = path_transform * points[i]
		var finish: Vector2 = path_transform * points[i + 1]
		var distance: float = start.distance_to(finish)
		var steps: int = maxi(1, int(ceil(distance / 8.0)))
		
		for step in range(steps + 1):
			var point: Vector2 = start.lerp(finish, float(step) / steps)
			
			if safe_rect.has_point(point):
				conflicts += 1
				
	return conflicts
		 
func _on_upgrade_button_pressed() -> void:
	if selected_tower == null:
		return
		
	if selected_tower.upgrade_level >= 2:
		return
	
	if money < UPGRADE_COST:
		print("Saldo insuficiente!")
		return
		
	money -= UPGRADE_COST
	
	selected_tower.upgrade_tower()
	
	update_money_label()
	update_tower_info(selected_tower)
	
func update_upgrade_button(tower: Node2D) -> void:
	if tower.upgrade_level >= 2:
		upgrade_button.disabled = true
		upgrade_button.text = "Nível máximo"
	else:
		upgrade_button.disabled = false
		upgrade_button.text = "Melhorar torre"
		
func update_money_label() -> void:
	money_label.text = "Dinheiro: " + str(money)
	
func add_money(amount: int) -> void:
	money += amount
	update_money_label()
	
	print("Dinheiro recebido: ", amount)
	print("Saldo atual: ", money)
