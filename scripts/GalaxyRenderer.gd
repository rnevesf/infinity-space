# GalaxyRenderer.gd
# Renderizador 2D da galáxia.
# Recebe os dados puros (StarSystem[]) e os desenha usando Godot 2D.
# Toda a lógica visual está aqui — separada dos dados e da simulação.
#
# Técnica: formas (estrelas, planetas, conexões) desenhadas via _draw() em
# espaço de mundo. Labels de texto são Controls reais em espaço de TELA
# (via CanvasLayer), para nunca dependerem de re-escala por zoom — é isso
# que garante texto sempre nítido, em qualquer nível de zoom.
class_name GalaxyRenderer
extends Node2D

## Emitido quando o jogador clica em um sistema
signal system_clicked(system: StarSystem)

# --- Configurações visuais ---
const STAR_RADIUS_BASE: float = 7.0
const STAR_RADIUS_MAX: float = 16.0

# Conexões de hiperespaço — largura definida em PIXELS DE TELA (constante),
# convertida para unidades de mundo dividindo pelo zoom atual. Isso evita
# que as rotas fiquem gigantes e dominem a tela quando o jogador dá zoom.
const CONNECTION_COLOR_FAR: Color = Color(0.25, 0.38, 0.58, 0.30)
const CONNECTION_COLOR_NEAR: Color = Color(0.35, 0.55, 0.85, 0.45)
const CONNECTION_SCREEN_WIDTH_FAR: float = 1.0
const CONNECTION_SCREEN_WIDTH_NEAR: float = 2.0

# Seleção e hover
const HOVER_RING_COLOR: Color = Color(1.0, 1.0, 1.0, 0.55)
const HOVER_RING_WIDTH: float = 2.0
const SELECTION_RING_COLOR: Color = Color(0.4, 0.9, 1.0, 0.95)
const SELECTION_RING_WIDTH: float = 2.5

# Labels (agora via Control real em CanvasLayer — sempre nítido)
const LABEL_FONT_SIZE: int = 13
const LABEL_COLOR: Color = Color(0.85, 0.92, 1.0, 0.95)
const LABEL_OUTLINE_COLOR: Color = Color(0.02, 0.03, 0.08, 0.9)

# Órbitas e planetas
const ORBIT_COLOR: Color = Color(0.32, 0.42, 0.55, 0.4)
const ORBIT_SCREEN_WIDTH: float = 1.0
const HABITABLE_HALO_COLOR: Color = Color(0.5, 0.95, 0.7, 0.7)
const RING_PLANET_COLOR: Color = Color(0.78, 0.7, 0.55, 0.9)

# LOD thresholds de zoom
const LOD_LABELS_ZOOM: float = 0.9
const LOD_NEAR_ZOOM: float = 3.0      # A partir daqui, mostra planetas orbitando (fade começa um pouco antes)

# --- Estado ---
var _systems: Array[StarSystem] = []
var _hovered_id: int = -1
var _selected_id: int = -1
var _hovered_planet_index: int = -1
var _selected_planet_index: int = -1
var _current_zoom: float = 1.0

# Labels de tela
var _label_layer: Control = null
var _label_pool: Dictionary = {}   # system_id -> Label


func setup(systems: Array[StarSystem]) -> void:
	_systems = systems
	_clear_labels()
	queue_redraw()


## Chamado pelo Main logo após criar a cena, para que os labels de sistema
## sejam desenhados como Controls reais (espaço de tela), não texto em
## espaço de mundo — é isso que garante nitidez em qualquer zoom.
func attach_label_layer(layer: Control) -> void:
	_label_layer = layer


func update_zoom(zoom: float) -> void:
	_current_zoom = zoom
	queue_redraw()


func set_hovered(system_id: int, planet_index: int = -1) -> void:
	if _hovered_id != system_id or _hovered_planet_index != planet_index:
		_hovered_id = system_id
		_hovered_planet_index = planet_index
		queue_redraw()


func set_selected(system_id: int, planet_index: int = -1) -> void:
	if _selected_id != system_id or _selected_planet_index != planet_index:
		_selected_id = system_id
		_selected_planet_index = planet_index
		queue_redraw()


func _process(_delta: float) -> void:
	_update_labels()


# ─────────────────────────────────────────────
# DESENHO (formas — espaço de mundo)
# ─────────────────────────────────────────────

func _draw() -> void:
	if _systems.is_empty():
		return

	var show_planets: bool = _current_zoom >= (LOD_NEAR_ZOOM - 0.5)
	var visible_rect: Rect2 = _get_visible_world_rect() if show_planets else Rect2()

	for sys in _systems:
		_draw_star(sys)
		if show_planets and _in_view(sys.position, visible_rect):
			_draw_planets(sys)


# --- Estrela ---

func _draw_star(sys: StarSystem) -> void:
	var radius: float = _star_radius(sys.star_type)
	var color: Color = sys.star_color

	if sys.id == _selected_id:
		draw_arc(sys.position, radius + 6.0, 0.0, TAU, 48,
				SELECTION_RING_COLOR, SELECTION_RING_WIDTH, true)

	if sys.id == _hovered_id and sys.id != _selected_id:
		draw_arc(sys.position, radius + 4.5, 0.0, TAU, 36,
				HOVER_RING_COLOR, HOVER_RING_WIDTH, true)

	# Fundo translúcido (brilho difuso)
	var halo_color = color
	halo_color.a = 0.15
	_draw_aa_circle(sys.position, radius * 1.8, halo_color)

	# Corpo translúcido
	var body_color = color
	body_color.a = 0.5
	_draw_aa_circle(sys.position, radius, body_color)

	# Núcleo
	var core_color = color.lightened(0.6)
	core_color.a = 0.9
	_draw_aa_circle(sys.position, radius * 0.4, core_color)


func _draw_aa_circle(pos: Vector2, radius: float, color: Color) -> void:
	# O draw_circle nativo do Godot não aplica antialiasing corretamente 
	# em modo gl_compatibility. A solução é desenhar o círculo sólido
	# e sobrepor um "arc" (contorno) antialiased com a exata mesma cor.
	draw_circle(pos, radius, color)
	draw_arc(pos, radius, 0.0, TAU, 32, color, 1.0, true)


# --- Planetas orbitando ---

func _draw_planets(sys: StarSystem) -> void:
	if sys.planets.is_empty():
		return

	var fade_alpha: float = clamp((_current_zoom - (LOD_NEAR_ZOOM - 0.5)) / 0.5, 0.0, 1.0)
	if fade_alpha <= 0.0:
		return

	var star_radius: float = _star_radius(sys.star_type)
	var orbit_radius: float = star_radius + 12.0
	var orbit_step: float = 12.0
	var orbit_width: float = ORBIT_SCREEN_WIDTH / max(_current_zoom, 0.01)

	for i in range(sys.planets.size()):
		var planet: Dictionary = sys.planets[i]
		orbit_radius += orbit_step
		
		# Linha de órbita translúcida bem suave
		draw_arc(sys.position, orbit_radius, 0.0, TAU, 64, Color(0.32, 0.42, 0.55, fade_alpha * 0.15), orbit_width, true)

		# Ângulo determinístico para a posição do planeta
		var angle: float = fmod(float(sys.id) * 37.0 + float(i) * 61.0, 360.0) * (PI / 180.0)
		var planet_pos: Vector2 = sys.position + Vector2(cos(angle), sin(angle)) * orbit_radius

		var p_type: StarSystem.PlanetType = planet.get("type", StarSystem.PlanetType.BARREN)
		var p_radius: float = _planet_radius(p_type)
		var p_color: Color = planet.get("color", StarSystem.planet_type_color(p_type))
		
		# Seleção de planeta (Hover / Click)
		if _selected_id == sys.id and _selected_planet_index == i:
			draw_arc(planet_pos, p_radius + 3.0, 0.0, TAU, 24, SELECTION_RING_COLOR, 1.2, true)
		elif _hovered_id == sys.id and _hovered_planet_index == i:
			draw_arc(planet_pos, p_radius + 2.0, 0.0, TAU, 24, HOVER_RING_COLOR, 1.2, true)

		p_color.a = fade_alpha * 0.85
		var core: Color = p_color.lightened(0.4)
		core.a = fade_alpha
		
		# Desenha planeta
		draw_circle(planet_pos, p_radius, p_color)
		draw_circle(planet_pos, p_radius * 0.4, core)


func _planet_radius(type: StarSystem.PlanetType) -> float:
	match type:
		StarSystem.PlanetType.GAS_GIANT: return 4.5
		StarSystem.PlanetType.TERRAN:    return 3.0
		StarSystem.PlanetType.ARID:      return 2.5
		StarSystem.PlanetType.ARCTIC:    return 2.5
		StarSystem.PlanetType.TOXIC:     return 2.5
		StarSystem.PlanetType.VOLCANIC:  return 2.2
		StarSystem.PlanetType.BARREN:    return 2.0
		_: return 2.5


func _star_radius(star_type: StarSystem.StarType) -> float:
	match star_type:
		StarSystem.StarType.GIANT:  return STAR_RADIUS_MAX
		StarSystem.StarType.BLUE:   return STAR_RADIUS_BASE * 1.7
		StarSystem.StarType.YELLOW: return STAR_RADIUS_BASE * 1.15
		StarSystem.StarType.ORANGE: return STAR_RADIUS_BASE * 1.05
		StarSystem.StarType.WHITE:  return STAR_RADIUS_BASE * 0.95
		StarSystem.StarType.RED:    return STAR_RADIUS_BASE * 0.85
		_: return STAR_RADIUS_BASE


# ─────────────────────────────────────────────
# LABELS — espaço de TELA (Controls reais, nunca borram)
# ─────────────────────────────────────────────

func _clear_labels() -> void:
	for lbl in _label_pool.values():
		if is_instance_valid(lbl):
			lbl.queue_free()
	_label_pool.clear()


func _create_label(sys: StarSystem) -> Label:
	var lbl: Label = Label.new()
	lbl.text = sys.name
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.add_theme_font_size_override("font_size", LABEL_FONT_SIZE)
	lbl.add_theme_color_override("font_color", LABEL_COLOR)
	lbl.add_theme_color_override("font_outline_color", LABEL_OUTLINE_COLOR)
	lbl.add_theme_constant_override("outline_size", 3)
	_label_layer.add_child(lbl)
	return lbl


func _update_labels() -> void:
	if _label_layer == null or _systems.is_empty():
		return

	var show: bool = _current_zoom >= LOD_LABELS_ZOOM
	if not show:
		for lbl in _label_pool.values():
			lbl.visible = false
		return

	var vp: Viewport = get_viewport()
	if vp == null:
		return
	var xform: Transform2D = vp.get_canvas_transform()
	var visible_rect: Rect2 = _get_visible_world_rect()

	for sys in _systems:
		var on_screen: bool = _in_view(sys.position, visible_rect)
		var lbl: Label = _label_pool.get(sys.id)

		if not on_screen:
			if lbl:
				lbl.visible = false
			continue

		if lbl == null:
			lbl = _create_label(sys)
			_label_pool[sys.id] = lbl

		var radius: float = _star_radius(sys.star_type)
		var world_pos: Vector2 = sys.position + Vector2(0.0, radius + 20.0)
		var screen_pos: Vector2 = xform * world_pos

		lbl.visible = true
		lbl.position = screen_pos - Vector2(lbl.size.x * 0.5, 0.0)


# --- Culling por área visível (performance com 200-500 sistemas) ---

func _get_visible_world_rect() -> Rect2:
	var vp: Viewport = get_viewport()
	if vp == null:
		return Rect2()
	var cam: Camera2D = vp.get_camera_2d()
	if cam == null:
		return Rect2()
	var screen_size: Vector2 = Vector2(vp.get_visible_rect().size)
	var half_world: Vector2 = (screen_size * 0.5) / cam.zoom
	var center: Vector2 = cam.get_screen_center_position()
	return Rect2(center - half_world, half_world * 2.0)


func _in_view(pos: Vector2, rect: Rect2) -> bool:
	if rect.size == Vector2.ZERO:
		return true
	return rect.grow(250.0).has_point(pos)


# ─────────────────────────────────────────────
# INPUT — hover e clique via sinal da câmera
# ─────────────────────────────────────────────

func on_camera_left_click(screen_pos: Vector2) -> void:
	var world_pos: Vector2 = get_global_mouse_position()
	var obj: Dictionary = _find_object_at(world_pos)
	if obj.sys_id >= 0:
		set_selected(obj.sys_id, obj.planet_index)
		system_clicked.emit(_systems[obj.sys_id])


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var world_pos: Vector2 = get_global_mouse_position()
		var obj: Dictionary = _find_object_at(world_pos)
		set_hovered(obj.sys_id, obj.planet_index)


func _find_object_at(world_pos: Vector2) -> Dictionary:
	var best_id: int = -1
	var best_dist: float = INF
	var best_planet: int = -1
	
	var sys_threshold: float = clamp(35.0 / _current_zoom, 12.0, 200.0)
	var show_planets: bool = _current_zoom >= (LOD_NEAR_ZOOM - 0.5)

	for sys in _systems:
		var d: float = world_pos.distance_to(sys.position)
		if d < sys_threshold and d < best_dist:
			best_dist = d
			best_id = sys.id
			best_planet = -1
			
		# Verifica clique nos planetas orbitando
		if show_planets and d < 300.0: # Apenas se o mouse estiver na vizinhança do sistema
			var star_radius: float = _star_radius(sys.star_type)
			var orbit_radius: float = star_radius + 22.0
			var orbit_step: float = 16.0
			for i in range(sys.planets.size()):
				orbit_radius += orbit_step
				var angle: float = fmod(float(sys.id) * 37.0 + float(i) * 61.0, 360.0) * (PI / 180.0)
				var planet_pos: Vector2 = sys.position + Vector2(cos(angle), sin(angle)) * orbit_radius
				var p_dist: float = world_pos.distance_to(planet_pos)
				# 8.0 = hit radius de cada planeta
				if p_dist < 8.0 and p_dist < best_dist:
					best_dist = p_dist
					best_id = sys.id
					best_planet = i

	return {"sys_id": best_id, "planet_index": best_planet}
