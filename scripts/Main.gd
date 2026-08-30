# Main.gd
# Nó raiz da cena principal.
# Orquestra a geração da galáxia e conecta os sistemas:
#   GalaxyGenerator → dados → GalaxyRenderer (visual)
#                           → SystemInfoPanel (UI ao clicar)
#   CameraController → zoom → GalaxyRenderer (LOD)
#                           → StarfieldBackground (parallax)
class_name Main
extends Node2D

# --- Configuração ---
## Seed do universo. Mude para gerar galáxias completamente diferentes.
@export var universe_seed: int = 12345

# --- Referências a nós filhos (criados programaticamente no _ready) ---
var _camera: CameraController
var _starfield: StarfieldBackground
var _galaxy_renderer: GalaxyRenderer
var _info_panel: SystemInfoPanel
var _pause_menu: PauseMenu
var _hud_layer: CanvasLayer

# --- Dados ---
var _galaxy_systems: Array[StarSystem] = []
var _home_system: StarSystem = null


func _ready() -> void:
	_build_scene_tree()
	_generate_galaxy()
	_connect_signals()
	_focus_home_system()
	_update_hud_seed_display()


# --- Construção da cena por código ---
# (Sem arquivo .tscn para manter tudo em GDScript e facilitar iteração)

func _build_scene_tree() -> void:
	# 1. Câmera (filho do Main para usar coordenadas de mundo)
	_camera = CameraController.new()
	_camera.name = "Camera"
	add_child(_camera)
	_camera.make_current()

	# 2. Fundo estrelado (filho do Main, Z negativo)
	_starfield = StarfieldBackground.new()
	_starfield.name = "Starfield"
	add_child(_starfield)

	# 3. Renderizador da galáxia (filho do Main, no mundo 2D)
	_galaxy_renderer = GalaxyRenderer.new()
	_galaxy_renderer.name = "GalaxyRenderer"
	add_child(_galaxy_renderer)

	# 4. CanvasLayer para UI (sempre na frente, não afetada por câmera)
	_hud_layer = CanvasLayer.new()
	_hud_layer.name = "HUD"
	_hud_layer.layer = 10
	add_child(_hud_layer)

	# 4b. Container de labels de sistema — Controls reais em espaço de TELA.
	# Fica sob o painel de info na ordem de desenho (adicionado antes dele).
	var world_labels: Control = Control.new()
	world_labels.name = "WorldLabels"
	world_labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_labels.set_anchors_preset(Control.PRESET_FULL_RECT)
	_hud_layer.add_child(world_labels)
	_galaxy_renderer.attach_label_layer(world_labels)

	# 5. Painel de info do sistema (dentro do HUD)
	_info_panel = SystemInfoPanel.new()
	_info_panel.name = "SystemInfoPanel"
	_hud_layer.add_child(_info_panel)

	# 6. Label de seed (canto superior esquerdo)
	_add_seed_label()

	# 7. Label de instruções (canto inferior esquerdo)
	_add_instructions_label()

	# 8. Pause Menu (sempre no topo do HUD)
	_pause_menu = PauseMenu.new()
	_pause_menu.name = "PauseMenu"
	_hud_layer.add_child(_pause_menu)


func _add_seed_label() -> void:
	var lbl: Label = Label.new()
	lbl.name = "SeedLabel"
	lbl.set_anchors_preset(Control.PRESET_TOP_LEFT)
	lbl.position = Vector2(16, 16)
	lbl.add_theme_color_override("font_color", Color(0.4, 0.6, 0.9, 0.6))
	lbl.add_theme_font_size_override("font_size", 11)
	_hud_layer.add_child(lbl)


func _add_instructions_label() -> void:
	var lbl: Label = Label.new()
	lbl.name = "InstructionsLabel"
	lbl.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	lbl.set_offset(SIDE_LEFT, 16)
	lbl.set_offset(SIDE_BOTTOM, -16)
	lbl.text = "🖱 Scroll: Zoom   |   Arrastar (qualquer botão): Mover mapa   |   Click esquerdo: Selecionar sistema"
	lbl.add_theme_color_override("font_color", Color(0.5, 0.6, 0.8, 0.5))
	lbl.add_theme_font_size_override("font_size", 10)
	_hud_layer.add_child(lbl)


func _update_hud_seed_display() -> void:
	var lbl: Label = _hud_layer.get_node_or_null("SeedLabel")
	if lbl:
		lbl.text = "ESPAÇO INFINITO  |  Seed: %d  |  %d sistemas" % [
			universe_seed,
			_galaxy_systems.size()
		]


# --- Geração ---

func _generate_galaxy() -> void:
	print("\n=== ESPAÇO INFINITO ===")
	print("Seed: %d" % universe_seed)

	var generator: GalaxyGenerator = GalaxyGenerator.new(universe_seed)
	_galaxy_systems = generator.generate()

	# Passa os dados para o renderizador
	_galaxy_renderer.setup(_galaxy_systems)

	# Define o sistema natal como o mais próximo do centro
	_home_system = _find_home_system()
	print("Sistema natal: '%s' (ID %d)" % [_home_system.name, _home_system.id])


func _find_home_system() -> StarSystem:
	## Escolhe o sistema natal: estrela amarela ou laranja mais próxima do centro,
	## com pelo menos 1 planeta habitável (Terran ou Arid).
	var best: StarSystem = null
	var best_score: float = INF

	for sys in _galaxy_systems:
		# Prefere estrelas amarelas/laranja (mais "confortáveis")
		var type_bonus: float = 0.0
		if sys.star_type in [StarSystem.StarType.YELLOW, StarSystem.StarType.ORANGE]:
			type_bonus = -200.0  # Bônus negativo = prefere este

		# Verifica habitabilidade
		var has_habitable: bool = false
		for planet in sys.planets:
			if planet.get("habitability", 0.0) > 0.3:
				has_habitable = true
				break

		if not has_habitable:
			continue

		var score: float = sys.position.length() + type_bonus
		if score < best_score:
			best_score = score
			best = sys

	# Fallback: qualquer sistema com planetas
	if not best:
		for sys in _galaxy_systems:
			if not sys.planets.is_empty():
				return sys
		return _galaxy_systems[0]

	return best


# --- Sinais ---

func _connect_signals() -> void:
	_camera.zoom_changed.connect(_on_zoom_changed)
	# left_clicked só dispara quando o botão esquerdo solta SEM ter arrastado
	_camera.left_clicked.connect(_galaxy_renderer.on_camera_left_click)
	_galaxy_renderer.system_clicked.connect(_on_system_clicked)


func _on_zoom_changed(new_zoom: float) -> void:
	_galaxy_renderer.update_zoom(new_zoom)


func _on_system_clicked(system: StarSystem) -> void:
	print("Sistema selecionado: %s | Planetas: %d | Conexões: %d" % [
		system.name,
		system.planets.size(),
		system.connections.size()
	])
	_info_panel.show_system(system)


# --- Foco inicial ---

func _focus_home_system() -> void:
	if not _home_system:
		return
	# Posiciona câmera no sistema natal com zoom de sistema (nível médio)
	_camera.focus_on(_home_system.position, 1.8)
	# Seleciona-o visualmente
	_info_panel.show_system(_home_system)


# --- Input (Atalhos Globais) ---

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			if not get_tree().paused:
				_pause_menu.set_paused(true)
				get_viewport().set_input_as_handled()

