# PauseMenu.gd
class_name PauseMenu
extends Control

var _panel: PanelContainer
var _main_vbox: VBoxContainer
var _settings_vbox: VBoxContainer

var _resolutions: Array = [
	{"name": "1280x720 (16:9)", "size": Vector2i(1280, 720)},
	{"name": "1920x1080 (16:9)", "size": Vector2i(1920, 1080)},
	{"name": "2560x1080 (21:9 Ultrawide)", "size": Vector2i(2560, 1080)},
	{"name": "2560x1440 (16:9 QHD)", "size": Vector2i(2560, 1440)},
	{"name": "3440x1440 (21:9 Ultrawide)", "size": Vector2i(3440, 1440)},
	{"name": "3840x2160 (16:9 4K)", "size": Vector2i(3840, 2160)}
]

var _window_modes: Array = [
	{"name": "Janela", "mode": DisplayServer.WINDOW_MODE_WINDOWED},
	{"name": "Tela Cheia sem Bordas", "mode": DisplayServer.WINDOW_MODE_FULLSCREEN},
	{"name": "Tela Cheia Exclusiva", "mode": DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN}
]

var _res_opt: OptionButton
var _mode_opt: OptionButton
var _aa_opt: OptionButton

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS # Continua rodando quando pausado
	set_anchors_preset(Control.PRESET_FULL_RECT)
	
	# Fundo translúcido escuro
	var bg: ColorRect = ColorRect.new()
	bg.color = Color(0.0, 0.0, 0.0, 0.7)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	
	# Painel central
	_panel = PanelContainer.new()
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.10, 0.16, 0.95)
	style.border_color = Color(0.4, 0.9, 1.0, 0.6)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.content_margin_left = 32
	style.content_margin_right = 32
	style.content_margin_top = 24
	style.content_margin_bottom = 32
	_panel.add_theme_stylebox_override("panel", style)
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	add_child(_panel)
	
	_build_main_menu()
	_build_settings_menu()
	
	_show_main()
	hide()

func _build_main_menu() -> void:
	_main_vbox = VBoxContainer.new()
	_main_vbox.add_theme_constant_override("separation", 16)
	_panel.add_child(_main_vbox)
	
	var title: Label = Label.new()
	title.text = "MENU PAUSADO"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	title.add_theme_font_size_override("font_size", 24)
	_main_vbox.add_child(title)
	
	_main_vbox.add_child(HSeparator.new())
	
	var btn_resume: Button = _make_button("Continuar")
	btn_resume.pressed.connect(func(): set_paused(false))
	_main_vbox.add_child(btn_resume)
	
	var btn_config: Button = _make_button("Configurações")
	btn_config.pressed.connect(_show_settings)
	_main_vbox.add_child(btn_config)
	
	var btn_quit: Button = _make_button("Sair do Jogo")
	btn_quit.pressed.connect(func(): get_tree().quit())
	_main_vbox.add_child(btn_quit)

func _build_settings_menu() -> void:
	_settings_vbox = VBoxContainer.new()
	_settings_vbox.add_theme_constant_override("separation", 16)
	_panel.add_child(_settings_vbox)
	
	var title: Label = Label.new()
	title.text = "CONFIGURAÇÕES"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0))
	title.add_theme_font_size_override("font_size", 24)
	_settings_vbox.add_child(title)
	
	_settings_vbox.add_child(HSeparator.new())
	
	# Modo de Tela HBox
	var mode_hbox: HBoxContainer = HBoxContainer.new()
	var mode_label: Label = Label.new()
	mode_label.text = "Modo de Janela:"
	mode_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	mode_hbox.add_child(mode_label)
	
	_mode_opt = OptionButton.new()
	_mode_opt.custom_minimum_size = Vector2(260, 0)
	for i in range(_window_modes.size()):
		_mode_opt.add_item(_window_modes[i].name, i)
	
	_mode_opt.item_selected.connect(_on_mode_selected)
	mode_hbox.add_child(_mode_opt)
	_settings_vbox.add_child(mode_hbox)
	
	# Resolução HBox
	var res_hbox: HBoxContainer = HBoxContainer.new()
	var res_label: Label = Label.new()
	res_label.text = "Resolução (Janela):"
	res_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	res_hbox.add_child(res_label)
	
	_res_opt = OptionButton.new()
	_res_opt.custom_minimum_size = Vector2(260, 0)
	for i in range(_resolutions.size()):
		_res_opt.add_item(_resolutions[i].name, i)
	
	_res_opt.item_selected.connect(_on_resolution_selected)
	res_hbox.add_child(_res_opt)
	_settings_vbox.add_child(res_hbox)
	
	# Anti-aliasing (MSAA) HBox
	var aa_hbox: HBoxContainer = HBoxContainer.new()
	var aa_label: Label = Label.new()
	aa_label.text = "Anti-aliasing (Serrilhado):"
	aa_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	aa_hbox.add_child(aa_label)
	
	_aa_opt = OptionButton.new()
	_aa_opt.custom_minimum_size = Vector2(260, 0)
	_aa_opt.add_item("Desativado", 0)
	_aa_opt.add_item("MSAA 2x", 1)
	_aa_opt.add_item("MSAA 4x", 2)
	_aa_opt.add_item("MSAA 8x", 3)
	
	_aa_opt.item_selected.connect(_on_aa_selected)
	aa_hbox.add_child(_aa_opt)
	_settings_vbox.add_child(aa_hbox)
	
	_sync_ui_with_display()
	
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 16)
	_settings_vbox.add_child(spacer)
	
	var btn_back: Button = _make_button("Voltar")
	btn_back.pressed.connect(_show_main)
	_settings_vbox.add_child(btn_back)

func _sync_ui_with_display() -> void:
	var current_mode = DisplayServer.window_get_mode()
	var mode_idx = 0
	
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		mode_idx = 1
	elif current_mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		mode_idx = 2
	
	_mode_opt.selected = mode_idx
	_res_opt.disabled = (mode_idx != 0) # Só ativa resolução se for janela
	
	var current_size = DisplayServer.window_get_size()
	for i in range(_resolutions.size()):
		if _resolutions[i].size == current_size:
			_res_opt.selected = i
			break
			
	_aa_opt.selected = get_viewport().msaa_2d

func _show_main() -> void:
	if _settings_vbox: _settings_vbox.visible = false
	if _main_vbox: _main_vbox.visible = true

func _show_settings() -> void:
	if _main_vbox: _main_vbox.visible = false
	if _settings_vbox: 
		_settings_vbox.visible = true
		_sync_ui_with_display()

func _make_button(text: String) -> Button:
	var btn: Button = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(300, 40)
	return btn

func _on_mode_selected(index: int) -> void:
	var mode = _window_modes[index].mode
	DisplayServer.window_set_mode(mode)
	
	# Desabilita o menu de resolução se não for modo janela
	_res_opt.disabled = (index != 0)
	
	if index == 0:
		# Se voltou para o modo janela, reaplica a resolução selecionada
		_on_resolution_selected(_res_opt.selected)

func _on_resolution_selected(index: int) -> void:
	var res = _resolutions[index]
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_size(res.size)
		# Centraliza a janela ao mudar de tamanho
		var screen = DisplayServer.window_get_current_screen()
		var screen_size = DisplayServer.screen_get_size(screen)
		var win_size = DisplayServer.window_get_size()
		DisplayServer.window_set_position((screen_size - win_size) / 2)

func _on_aa_selected(index: int) -> void:
	get_viewport().msaa_2d = index as Viewport.MSAA

func set_paused(paused: bool) -> void:
	get_tree().paused = paused
	visible = paused
	if paused:
		_show_main() # Sempre que abrir o menu, mostra a tela inicial

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.pressed and event.keycode == KEY_ESCAPE:
			# Se o menu de configuração estiver aberto, ESC apenas volta para o menu principal
			if visible and _settings_vbox.visible:
				_show_main()
			else:
				set_paused(!get_tree().paused)
			get_viewport().set_input_as_handled()
