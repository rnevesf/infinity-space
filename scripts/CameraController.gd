# CameraController.gd
# Câmera 2D com:
#   - Zoom suave centrado no mouse (scroll)
#   - Pan por botão ESQUERDO ou DIREITO/MÉDIO
#   - Deadzone de 6px para distinguir click de arrasto com botão esquerdo
class_name CameraController
extends Camera2D

## Emitido quando o zoom muda (para o GalaxyRenderer ajustar LOD)
signal zoom_changed(new_zoom: float)

## Emitido quando o botão esquerdo foi solto SEM arrastar (= clique real)
signal left_clicked(screen_pos: Vector2)

# --- Configurações ---
const ZOOM_MIN: float = 0.04     # Galáxia inteira visível
const ZOOM_MAX: float = 8.0      # Zoom máximo — estrelas bem grandes
const ZOOM_SPEED: float = 0.12   # Fator de zoom por scroll
const ZOOM_LERP: float = 10.0    # Suavidade da interpolação
const DRAG_DEADZONE: float = 6.0 # Pixels mínimos para considerar "arrastando"

# --- Estado ---
var _target_zoom: float = 1.0
var _last_zoom_emitted: float = 0.0

# Pan state — compartilhado entre botões
var _is_panning: bool = false
var _pan_button: int = -1
var _pan_start_mouse: Vector2 = Vector2.ZERO
var _pan_start_camera: Vector2 = Vector2.ZERO
var _pan_dragged: bool = false   # True se moveu além da deadzone


func _ready() -> void:
	_target_zoom = 0.12
	zoom = Vector2(_target_zoom, _target_zoom)
	_last_zoom_emitted = _target_zoom


func _process(delta: float) -> void:
	# Interpola zoom suavemente
	var current_zoom: float = zoom.x
	var new_zoom: float = lerp(current_zoom, _target_zoom, ZOOM_LERP * delta)
	zoom = Vector2(new_zoom, new_zoom)

	# Emite sinal quando zoom muda significativamente
	if abs(new_zoom - _last_zoom_emitted) > 0.005:
		_last_zoom_emitted = new_zoom
		zoom_changed.emit(new_zoom)


func _unhandled_input(event: InputEvent) -> void:
	# --- Scroll = zoom ---
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton

		if mb.pressed:
			match mb.button_index:
				MOUSE_BUTTON_WHEEL_UP:
					_zoom_at_mouse(1.0 + ZOOM_SPEED)
					get_viewport().set_input_as_handled()
					return
				MOUSE_BUTTON_WHEEL_DOWN:
					_zoom_at_mouse(1.0 - ZOOM_SPEED)
					get_viewport().set_input_as_handled()
					return

		# Início do pan: botão esquerdo, direito ou médio pressionados
		if mb.pressed and mb.button_index in [
				MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_is_panning = true
			_pan_button = mb.button_index
			_pan_start_mouse = mb.position
			_pan_start_camera = position
			_pan_dragged = false
			return

		# Soltura do botão
		if not mb.pressed and mb.button_index == _pan_button:
			if _pan_button == MOUSE_BUTTON_LEFT and not _pan_dragged:
				# Click limpo (sem arrastar) — delega ao GalaxyRenderer via sinal
				left_clicked.emit(mb.position)
			_is_panning = false
			_pan_button = -1
			get_viewport().set_input_as_handled()
			return

	# --- Movimento do mouse = pan ---
	if event is InputEventMouseMotion and _is_panning:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		var delta_mouse: Vector2 = mm.position - _pan_start_mouse

		# Verifica deadzone (só para botão esquerdo — direito/médio pan imediato)
		if _pan_button == MOUSE_BUTTON_LEFT and not _pan_dragged:
			if delta_mouse.length() < DRAG_DEADZONE:
				return  # Ainda dentro da deadzone, não move
			_pan_dragged = true

		position = _pan_start_camera - delta_mouse / zoom.x
		get_viewport().set_input_as_handled()


func _zoom_at_mouse(factor: float) -> void:
	## Aplica zoom centrado na posição do mouse.
	var old_zoom: float = _target_zoom
	_target_zoom = clamp(_target_zoom * factor, ZOOM_MIN, ZOOM_MAX)

	if abs(_target_zoom - old_zoom) < 0.0001:
		return

	# Mantém o ponto do mouse fixo no mundo durante o zoom
	var viewport: Viewport = get_viewport()
	if not viewport:
		return
	var mouse_screen: Vector2 = viewport.get_mouse_position()
	var viewport_size: Vector2 = Vector2(viewport.get_visible_rect().size)
	var mouse_offset: Vector2 = mouse_screen - viewport_size * 0.5

	var mouse_world_before: Vector2 = position + mouse_offset / old_zoom
	var mouse_world_after: Vector2 = position + mouse_offset / _target_zoom
	position += mouse_world_before - mouse_world_after


func focus_on(world_position: Vector2, target_zoom: float = 1.5) -> void:
	## Move suavemente a câmera para um ponto específico.
	position = world_position
	_target_zoom = clamp(target_zoom, ZOOM_MIN, ZOOM_MAX)
