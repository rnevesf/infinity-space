# StarfieldBackground.gd
# Fundo estrelado com parallax leve para dar profundidade.
# Desenha estrelas de fundo em múltiplas camadas com velocidades diferentes.
# Muito mais leve que ParallaxBackground do Godot para grandes universos.
class_name StarfieldBackground
extends Node2D

const LAYER_COUNT: int = 3
const STARS_PER_LAYER: int = 150
const FIELD_SIZE: float = 12000.0  # Cobre a galáxia + borda generosa

# Cada layer: {stars: Vector2[], brightness: float, parallax_factor: float, size: float}
var _layers: Array[Dictionary] = []
var _rng: RandomNumberGenerator


func _ready() -> void:
	z_index = -10  # Sempre atrás de tudo
	_rng = RandomNumberGenerator.new()
	_rng.seed = 42  # Seed fixo: o fundo não precisa ser reproduzível por seed do jogo
	_generate_layers()


func _generate_layers() -> void:
	_layers.clear()
	var configs: Array[Dictionary] = [
		{"parallax": 0.02, "brightness": 0.25, "size": 0.8},  # Mais distante
		{"parallax": 0.05, "brightness": 0.4,  "size": 1.2},  # Média distância
		{"parallax": 0.10, "brightness": 0.55, "size": 1.8},  # Mais próxima
	]

	for cfg in configs:
		var stars: Array[Vector2] = []
		for i in range(STARS_PER_LAYER):
			stars.append(Vector2(
				_rng.randf_range(-FIELD_SIZE * 0.5, FIELD_SIZE * 0.5),
				_rng.randf_range(-FIELD_SIZE * 0.5, FIELD_SIZE * 0.5)
			))
		cfg["stars"] = stars
		_layers.append(cfg)


func _draw() -> void:
	# Preenche o fundo com a cor do espaço
	var cam: Camera2D = get_viewport().get_camera_2d()
	if not cam:
		return

	# Fundo sólido — cobre toda a viewport com uma margem generosa
	var vp_size: Vector2 = get_viewport_rect().size
	var half: Vector2 = vp_size * 0.5 / cam.zoom
	draw_rect(
		Rect2(cam.position - half * 2.0, half * 4.0),
		Color(0.03, 0.04, 0.08)  # Quase preto / azul-marinho muito escuro
	)

	# Estrelas de fundo com parallax
	for layer in _layers:
		var parallax: float = layer.get("parallax", 0.05)
		var brightness: float = layer.get("brightness", 0.4)
		var size: float = layer.get("size", 1.0)
		var stars: Array = layer.get("stars", [])

		var offset: Vector2 = cam.position * parallax
		var color: Color = Color(brightness, brightness, brightness + 0.05)

		for star_pos in stars:
			draw_circle(star_pos + offset, size / cam.zoom.x, color)


func _process(_delta: float) -> void:
	queue_redraw()
