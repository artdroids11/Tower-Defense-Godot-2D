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
@onready var defeat_screen: Control = $CanvasLayer/DefeatScreen
@onready var restart_button: Button = $CanvasLayer/DefeatScreen/Content/RestartButton

var base_health: int = 10

var current_wave: int = 0
var enemies_per_wave: int = 5
var spwan_interval: float = .7
var wave_interval: float = 2.0
var game_over: bool = false

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

	$Enemy.path_points = path.points
	$Enemy.current_point_index = 0
	
	defeat_screen.hide()
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
	
func start_wave() -> void:
	if game_over:
		return
		
	current_wave += 1
	print("Iniciando onda: ", current_wave)
	
	for i in range(enemies_per_wave):
		if game_over:
			return
		
		spawn_enemy()
		await get_tree().create_timer(wave_interval).timeout
		
	print("Todos os inimigos da onda ", current_wave, " foram enviados.")
	wait_and_start_next_wave()	
	
func wait_and_start_next_wave() -> void:
	await get_tree().create_timer(wave_interval).timeout
	
	if not game_over:
		start_wave()
		

	
	
	
