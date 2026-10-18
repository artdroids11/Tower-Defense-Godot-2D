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

var base_health: int = 100

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
	restart_button.pressed.connect(_on_restart_button_pressed)
	
	start_wave()
	
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
func _input(event: InputEvent) -> void:
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
			
func select_tower(tower: Node2D) -> void:
	if selected_tower == tower:
		selected_tower.set_selected(false)
		selected_tower = null
		tower_info_panel.hide()
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
	interval_label.text = "Intervalo: " + str(tower.attack_interval) + " s"
	
	tower_info_panel.show()
	tower_info_panel.reset_size()
	position_tower_info(tower)
	
func position_tower_info(tower: Node2D) -> void:
	var tower_position: Vector2 = tower.get_global_transform_with_canvas().origin
	var viewport_size: Vector2 = get_viewport_rect().size
	
	var panel_position: Vector2 = tower_position + Vector2(30, -tower_info_panel.size.y - 20)
	
	if panel_position.x + tower_position.x > viewport_size.x:
		panel_position.x = tower_position.x - tower_info_panel.size.x - 30
		
	if panel_position.y < 0:
		panel_position.y = tower_position.y + 30
		
	panel_position.x = clampf(panel_position.x, 0, viewport_size.x - tower_info_panel.size.x)
	panel_position.y = clampf(panel_position.y, 0, viewport_size.y - tower_info_panel.size.y)
	
	tower_info_panel.position = panel_position	
	
