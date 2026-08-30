# SystemInfoPanel.gd
# Painel de informações que aparece ao clicar num sistema estelar.
# UI em CanvasLayer — sempre visível independente do zoom/pan da câmera.
class_name SystemInfoPanel
extends Control

# Referências a nós filhos (configuradas no _ready via código)
var _panel: PanelContainer
var _title_label: Label
var _star_type_label: Label
var _planets_label: Label
var _resources_label: Label
var _connections_label: Label
var _close_btn: Button

# Cores de painel (estilo flat escuro)
const PANEL_BG: Color = Color(0.08, 0.10, 0.16, 0.92)
const TITLE_COLOR: Color = Color(0.4, 0.9, 1.0)        # Ciano vibrante
const SUBTITLE_COLOR: Color = Color(0.7, 0.8, 1.0)     # Azul-lavanda
const TEXT_COLOR: Color = Color(0.82, 0.87, 0.95)
const ACCENT_COLOR: Color = Color(0.3, 0.7, 1.0, 0.4)


func _ready() -> void:
	_build_ui()
	hide()


func _build_ui() -> void:
	# Ancora no canto inferior direito
	set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	set_offset(SIDE_RIGHT, -16)
	set_offset(SIDE_BOTTOM, -16)
	custom_minimum_size = Vector2(280, 0)

	# PanelContainer com StyleBox customizado
	_panel = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = ACCENT_COLOR
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 12
	style.content_margin_bottom = 14
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	# VBox dentro do painel
	var vbox: VBoxContainer = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	_panel.add_child(vbox)

	# Linha de título + botão fechar
	var title_row: HBoxContainer = HBoxContainer.new()
	vbox.add_child(title_row)

	_title_label = _make_label("SISTEMA", TITLE_COLOR, 16, true)
	title_row.add_child(_title_label)

	title_row.add_child(_spacer())

	_close_btn = Button.new()
	_close_btn.text = "×"
	_close_btn.flat = true
	_close_btn.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	_close_btn.add_theme_color_override("font_hover_color", Color(1.0, 0.4, 0.4))
	_close_btn.pressed.connect(hide)
	title_row.add_child(_close_btn)

	# Separador
	vbox.add_child(_separator())

	# Tipo de estrela
	_star_type_label = _make_label("", SUBTITLE_COLOR, 12)
	vbox.add_child(_star_type_label)

	# Planetas
	vbox.add_child(_make_label("PLANETAS", Color(0.5, 0.7, 1.0, 0.8), 10))
	_planets_label = _make_label("", TEXT_COLOR, 11)
	_planets_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_planets_label)

	# Recursos
	vbox.add_child(_separator())
	vbox.add_child(_make_label("RECURSOS", Color(0.5, 0.7, 1.0, 0.8), 10))
	_resources_label = _make_label("", TEXT_COLOR, 11)
	vbox.add_child(_resources_label)

	# Conexões
	vbox.add_child(_separator())
	_connections_label = _make_label("", Color(0.6, 0.8, 0.6), 10)
	vbox.add_child(_connections_label)


func show_system(system: StarSystem) -> void:
	_title_label.text = system.name.to_upper()
	_title_label.add_theme_color_override("font_color", system.star_color)

	_star_type_label.text = "★ %s" % StarSystem.star_type_name(system.star_type)

	# Planetas
	if system.planets.is_empty():
		_planets_label.text = "Nenhum planeta detectado"
	else:
		var planet_lines: PackedStringArray = []
		for p in system.planets:
			var type_name: String = _planet_type_name(p.get("type", 0))
			planet_lines.append("• %s — %s" % [p.get("name", "?"), type_name])
		_planets_label.text = "\n".join(planet_lines)

	# Recursos
	var res: Dictionary = system.resources
	var res_text: String = ""
	if res.get("minerals", 0) > 0:
		res_text += "⬡ Minerais: %d   " % res.get("minerals", 0)
	if res.get("energy", 0) > 0:
		res_text += "⚡ Energia: %d   " % res.get("energy", 0)
	if res.get("influence", 0) > 0:
		res_text += "◈ Influência: %d" % res.get("influence", 0)
	if res.get("rare", 0) > 0:
		res_text += "\n✦ Recurso Raro detectado!"
	_resources_label.text = res_text if not res_text.is_empty() else "Sem recursos conhecidos"

	# Conexões
	_connections_label.text = "⬡ %d rota(s) de hiperespaço" % system.connections.size()

	show()


func _planet_type_name(type: int) -> String:
	match type:
		StarSystem.PlanetType.TERRAN:    return "Terrestre"
		StarSystem.PlanetType.ARID:      return "Árido"
		StarSystem.PlanetType.ARCTIC:    return "Gelado"
		StarSystem.PlanetType.VOLCANIC:  return "Vulcânico"
		StarSystem.PlanetType.GAS_GIANT: return "Gigante Gasoso"
		StarSystem.PlanetType.BARREN:    return "Estéril"
		StarSystem.PlanetType.TOXIC:     return "Tóxico"
		_: return "Desconhecido"


# --- Helpers de construção de UI ---

func _make_label(text: String, color: Color, size: int, bold: bool = false) -> Label:
	var lbl: Label = Label.new()
	lbl.text = text
	lbl.add_theme_color_override("font_color", color)
	lbl.add_theme_font_size_override("font_size", size)
	if bold:
		lbl.add_theme_font_size_override("font_size", size)
	return lbl


func _separator() -> HSeparator:
	var sep: HSeparator = HSeparator.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.3, 0.4, 0.6, 0.3)
	style.content_margin_top = 2
	style.content_margin_bottom = 2
	sep.add_theme_stylebox_override("separator", style)
	return sep


func _spacer() -> Control:
	var spacer: Control = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return spacer
