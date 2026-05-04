extends CanvasLayer

# HUD elements
var health_bar: ProgressBar
var health_label: Label
var ammo_label: Label
var money_label: Label
var wave_label: Label
var kills_label: Label
var wave_announcement: Label
var game_over_panel: PanelContainer
var game_over_stats: Label
var crosshair: Control
var reload_indicator: Label
var damage_flash: ColorRect

# Touch controls
var touch_layer: Control
var joystick_base: Control
var joystick_knob: Control
var shoot_zone: Control
var shoot_btn: Button
var reload_btn: Button

var joystick_touch_index: int = -1
var joystick_center := Vector2.ZERO
var joystick_radius: float = 70.0
var joystick_visible_radius: float = 90.0
var look_touch_index: int = -1
var look_touch_prev := Vector2.ZERO
var auto_shoot_timer: float = 0.0

var player_ref: CharacterBody3D = null

func _ready() -> void:
	build_ui()
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

func build_ui() -> void:
	build_top_hud()
	build_crosshair()
	build_wave_announcement()
	build_touch_controls()
	build_game_over()
	build_damage_flash()

func build_top_hud() -> void:
	# Semi-transparent top panel
	var top_panel := PanelContainer.new()
	top_panel.anchor_right = 1.0
	top_panel.offset_bottom = 55
	top_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0.5)
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(1, 1, 1, 0.15)
	panel_style.content_margin_left = 15
	panel_style.content_margin_right = 15
	panel_style.content_margin_top = 5
	panel_style.content_margin_bottom = 5
	top_panel.add_theme_stylebox_override("panel", panel_style)
	add_child(top_panel)

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 15)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_panel.add_child(top_bar)

	# Health icon + bar
	var hp_box := HBoxContainer.new()
	hp_box.add_theme_constant_override("separation", 6)
	hp_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(hp_box)

	var hp_icon := Label.new()
	hp_icon.text = "+"
	hp_icon.add_theme_font_size_override("font_size", 22)
	hp_icon.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	hp_box.add_child(hp_icon)

	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(120, 22)
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.3, 0, 0, 0.8)
	bar_bg.corner_radius_top_left = 4
	bar_bg.corner_radius_top_right = 4
	bar_bg.corner_radius_bottom_left = 4
	bar_bg.corner_radius_bottom_right = 4
	health_bar.add_theme_stylebox_override("background", bar_bg)
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.9, 0.15, 0.15)
	bar_fill.corner_radius_top_left = 4
	bar_fill.corner_radius_top_right = 4
	bar_fill.corner_radius_bottom_left = 4
	bar_fill.corner_radius_bottom_right = 4
	health_bar.add_theme_stylebox_override("fill", bar_fill)
	hp_box.add_child(health_bar)

	health_label = Label.new()
	health_label.text = "100"
	health_label.add_theme_font_size_override("font_size", 16)
	health_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	hp_box.add_child(health_label)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_bar.add_child(spacer)

	# Ammo
	ammo_label = Label.new()
	ammo_label.text = "30 / 90"
	ammo_label.add_theme_font_size_override("font_size", 18)
	ammo_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0))
	top_bar.add_child(ammo_label)

	# Money
	money_label = Label.new()
	money_label.text = "$ 0"
	money_label.add_theme_font_size_override("font_size", 18)
	money_label.add_theme_color_override("font_color", Color(1, 0.85, 0))
	top_bar.add_child(money_label)

	# Wave
	wave_label = Label.new()
	wave_label.text = "Wave -"
	wave_label.add_theme_font_size_override("font_size", 18)
	wave_label.add_theme_color_override("font_color", Color(0.4, 0.85, 1))
	top_bar.add_child(wave_label)

	# Kills
	kills_label = Label.new()
	kills_label.text = "Kills: 0"
	kills_label.add_theme_font_size_override("font_size", 16)
	kills_label.add_theme_color_override("font_color", Color(1, 0.6, 0.6))
	top_bar.add_child(kills_label)

func build_crosshair() -> void:
	crosshair = Control.new()
	crosshair.anchors_preset = Control.PRESET_CENTER
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left = -24
	crosshair.offset_top = -24
	crosshair.offset_right = 24
	crosshair.offset_bottom = 24
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair.draw.connect(_draw_crosshair)
	add_child(crosshair)

	# Reload indicator below crosshair
	reload_indicator = Label.new()
	reload_indicator.anchors_preset = Control.PRESET_CENTER
	reload_indicator.anchor_left = 0.5
	reload_indicator.anchor_top = 0.5
	reload_indicator.anchor_right = 0.5
	reload_indicator.anchor_bottom = 0.5
	reload_indicator.offset_left = -80
	reload_indicator.offset_top = 30
	reload_indicator.offset_right = 80
	reload_indicator.offset_bottom = 60
	reload_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reload_indicator.add_theme_font_size_override("font_size", 16)
	reload_indicator.add_theme_color_override("font_color", Color(1, 1, 0.5, 0.9))
	reload_indicator.visible = false
	reload_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(reload_indicator)

func build_wave_announcement() -> void:
	wave_announcement = Label.new()
	wave_announcement.anchors_preset = Control.PRESET_CENTER_TOP
	wave_announcement.anchor_left = 0.5
	wave_announcement.anchor_right = 0.5
	wave_announcement.offset_left = -300
	wave_announcement.offset_top = 70
	wave_announcement.offset_right = 300
	wave_announcement.offset_bottom = 150
	wave_announcement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_announcement.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wave_announcement.add_theme_font_size_override("font_size", 32)
	wave_announcement.add_theme_color_override("font_color", Color(1, 0.85, 0))
	wave_announcement.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	wave_announcement.add_theme_constant_override("outline_size", 3)
	wave_announcement.visible = false
	wave_announcement.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wave_announcement)

func build_touch_controls() -> void:
	# Full-screen touch layer
	touch_layer = Control.new()
	touch_layer.anchors_preset = Control.PRESET_FULL_RECT
	touch_layer.anchor_right = 1.0
	touch_layer.anchor_bottom = 1.0
	touch_layer.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(touch_layer)

	# Joystick base (visible when touching)
	joystick_base = Control.new()
	joystick_base.custom_minimum_size = Vector2(joystick_visible_radius * 2, joystick_visible_radius * 2)
	joystick_base.visible = false
	joystick_base.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_base.draw.connect(_draw_joystick_base)
	add_child(joystick_base)

	joystick_knob = Control.new()
	joystick_knob.custom_minimum_size = Vector2(50, 50)
	joystick_knob.visible = false
	joystick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joystick_knob.draw.connect(_draw_joystick_knob)
	add_child(joystick_knob)

	# Shoot button (bottom-right, large round)
	shoot_btn = Button.new()
	shoot_btn.text = "FIRE"
	shoot_btn.anchor_left = 1.0
	shoot_btn.anchor_top = 1.0
	shoot_btn.anchor_right = 1.0
	shoot_btn.anchor_bottom = 1.0
	shoot_btn.offset_left = -160
	shoot_btn.offset_top = -160
	shoot_btn.offset_right = -15
	shoot_btn.offset_bottom = -15
	shoot_btn.add_theme_font_size_override("font_size", 22)
	var shoot_style := StyleBoxFlat.new()
	shoot_style.bg_color = Color(0.8, 0.15, 0.15, 0.7)
	shoot_style.corner_radius_top_left = 72
	shoot_style.corner_radius_top_right = 72
	shoot_style.corner_radius_bottom_left = 72
	shoot_style.corner_radius_bottom_right = 72
	shoot_style.border_width_top = 3
	shoot_style.border_width_bottom = 3
	shoot_style.border_width_left = 3
	shoot_style.border_width_right = 3
	shoot_style.border_color = Color(1, 0.3, 0.3, 0.9)
	shoot_btn.add_theme_stylebox_override("normal", shoot_style)
	var shoot_pressed := shoot_style.duplicate()
	shoot_pressed.bg_color = Color(1, 0.3, 0.3, 0.9)
	shoot_btn.add_theme_stylebox_override("pressed", shoot_pressed)
	shoot_btn.add_theme_stylebox_override("hover", shoot_style)
	shoot_btn.add_theme_color_override("font_color", Color.WHITE)
	shoot_btn.pressed.connect(_on_shoot_pressed)
	add_child(shoot_btn)

	# Reload button (above-left of shoot)
	reload_btn = Button.new()
	reload_btn.text = "R"
	reload_btn.anchor_left = 1.0
	reload_btn.anchor_top = 1.0
	reload_btn.anchor_right = 1.0
	reload_btn.anchor_bottom = 1.0
	reload_btn.offset_left = -175
	reload_btn.offset_top = -230
	reload_btn.offset_right = -110
	reload_btn.offset_bottom = -165
	reload_btn.add_theme_font_size_override("font_size", 20)
	var reload_style := StyleBoxFlat.new()
	reload_style.bg_color = Color(0.2, 0.5, 0.8, 0.6)
	reload_style.corner_radius_top_left = 32
	reload_style.corner_radius_top_right = 32
	reload_style.corner_radius_bottom_left = 32
	reload_style.corner_radius_bottom_right = 32
	reload_style.border_width_top = 2
	reload_style.border_width_bottom = 2
	reload_style.border_width_left = 2
	reload_style.border_width_right = 2
	reload_style.border_color = Color(0.4, 0.7, 1, 0.8)
	reload_btn.add_theme_stylebox_override("normal", reload_style)
	reload_btn.add_theme_stylebox_override("hover", reload_style)
	reload_btn.add_theme_color_override("font_color", Color.WHITE)
	reload_btn.pressed.connect(_on_reload_pressed)
	add_child(reload_btn)

func build_game_over() -> void:
	game_over_panel = PanelContainer.new()
	game_over_panel.anchors_preset = Control.PRESET_CENTER
	game_over_panel.anchor_left = 0.5
	game_over_panel.anchor_top = 0.5
	game_over_panel.anchor_right = 0.5
	game_over_panel.anchor_bottom = 0.5
	game_over_panel.offset_left = -220
	game_over_panel.offset_top = -200
	game_over_panel.offset_right = 220
	game_over_panel.offset_bottom = 200
	game_over_panel.visible = false

	var go_style := StyleBoxFlat.new()
	go_style.bg_color = Color(0.05, 0.05, 0.1, 0.92)
	go_style.border_width_top = 3
	go_style.border_width_bottom = 3
	go_style.border_width_left = 3
	go_style.border_width_right = 3
	go_style.border_color = Color(1, 0.2, 0.2, 0.8)
	go_style.corner_radius_top_left = 12
	go_style.corner_radius_top_right = 12
	go_style.corner_radius_bottom_left = 12
	go_style.corner_radius_bottom_right = 12
	go_style.content_margin_left = 25
	go_style.content_margin_right = 25
	go_style.content_margin_top = 25
	go_style.content_margin_bottom = 25
	game_over_panel.add_theme_stylebox_override("panel", go_style)
	add_child(game_over_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 18)
	game_over_panel.add_child(vbox)

	var go_title := Label.new()
	go_title.text = "GAME OVER"
	go_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_title.add_theme_font_size_override("font_size", 40)
	go_title.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	vbox.add_child(go_title)

	game_over_stats = Label.new()
	game_over_stats.text = ""
	game_over_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_stats.add_theme_font_size_override("font_size", 22)
	game_over_stats.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	vbox.add_child(game_over_stats)

	var restart_btn := Button.new()
	restart_btn.text = "RESTART"
	restart_btn.custom_minimum_size = Vector2(0, 55)
	restart_btn.add_theme_font_size_override("font_size", 24)
	restart_btn.pressed.connect(_on_restart_pressed)
	vbox.add_child(restart_btn)

	var menu_btn := Button.new()
	menu_btn.text = "MENU"
	menu_btn.custom_minimum_size = Vector2(0, 55)
	menu_btn.add_theme_font_size_override("font_size", 24)
	menu_btn.pressed.connect(_on_menu_pressed)
	vbox.add_child(menu_btn)

func build_damage_flash() -> void:
	damage_flash = ColorRect.new()
	damage_flash.anchors_preset = Control.PRESET_FULL_RECT
	damage_flash.anchor_right = 1.0
	damage_flash.anchor_bottom = 1.0
	damage_flash.color = Color(1, 0, 0, 0)
	damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(damage_flash)

# ---- Drawing ----

func _draw_crosshair() -> void:
	var center := crosshair.size / 2
	var gap := 5.0
	var length := 14.0
	var thickness := 2.5
	var color := Color(0.2, 1, 0.2, 0.85)
	var shadow := Color(0, 0, 0, 0.4)
	# Shadow
	crosshair.draw_rect(Rect2(center.x - thickness / 2 + 1, center.y - gap - length + 1, thickness, length), shadow)
	crosshair.draw_rect(Rect2(center.x - thickness / 2 + 1, center.y + gap + 1, thickness, length), shadow)
	crosshair.draw_rect(Rect2(center.x - gap - length + 1, center.y - thickness / 2 + 1, length, thickness), shadow)
	crosshair.draw_rect(Rect2(center.x + gap + 1, center.y - thickness / 2 + 1, length, thickness), shadow)
	# Main
	crosshair.draw_rect(Rect2(center.x - thickness / 2, center.y - gap - length, thickness, length), color)
	crosshair.draw_rect(Rect2(center.x - thickness / 2, center.y + gap, thickness, length), color)
	crosshair.draw_rect(Rect2(center.x - gap - length, center.y - thickness / 2, length, thickness), color)
	crosshair.draw_rect(Rect2(center.x + gap, center.y - thickness / 2, length, thickness), color)
	# Center dot
	crosshair.draw_circle(center, 2.0, color)

func _draw_joystick_base() -> void:
	var center := joystick_base.size / 2
	joystick_base.draw_circle(center, joystick_visible_radius, Color(1, 1, 1, 0.08))
	joystick_base.draw_arc(center, joystick_visible_radius, 0, TAU, 64, Color(1, 1, 1, 0.25), 2.0)

func _draw_joystick_knob() -> void:
	var center := joystick_knob.size / 2
	joystick_knob.draw_circle(center, 22, Color(1, 1, 1, 0.35))
	joystick_knob.draw_arc(center, 22, 0, TAU, 32, Color(1, 1, 1, 0.6), 2.0)

# ---- Touch Input ----

func _input(event: InputEvent) -> void:
	if game_over_panel and game_over_panel.visible:
		return

	if event is InputEventScreenTouch:
		_handle_touch(event)
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		_handle_drag(event)
		get_viewport().set_input_as_handled()

func _handle_touch(event: InputEventScreenTouch) -> void:
	var vp_size := get_viewport().get_visible_rect().size
	var screen_half := vp_size.x * 0.45

	# Ignore top bar area
	if event.position.y < 60:
		return

	# Check if touch is on shoot/reload buttons
	if shoot_btn:
		var btn_rect := Rect2(
			vp_size.x + shoot_btn.offset_left,
			vp_size.y + shoot_btn.offset_top,
			shoot_btn.offset_right - shoot_btn.offset_left,
			shoot_btn.offset_bottom - shoot_btn.offset_top
		)
		if btn_rect.has_point(event.position):
			if event.pressed:
				_on_shoot_pressed()
			return

	if reload_btn:
		var btn_rect := Rect2(
			vp_size.x + reload_btn.offset_left,
			vp_size.y + reload_btn.offset_top,
			reload_btn.offset_right - reload_btn.offset_left,
			reload_btn.offset_bottom - reload_btn.offset_top
		)
		if btn_rect.has_point(event.position):
			if event.pressed:
				_on_reload_pressed()
			return

	if event.pressed:
		if event.position.x < screen_half:
			# Left side: joystick
			if joystick_touch_index == -1:
				joystick_touch_index = event.index
				joystick_center = event.position
				_show_joystick(event.position)
		else:
			# Right side: look + tap to shoot
			if look_touch_index == -1:
				look_touch_index = event.index
				look_touch_prev = event.position
				# Tap on right side = shoot
				_on_shoot_pressed()
	else:
		if event.index == joystick_touch_index:
			joystick_touch_index = -1
			_hide_joystick()
			if player_ref and player_ref.has_method("set_joystick_input"):
				player_ref.set_joystick_input(Vector2.ZERO)
		elif event.index == look_touch_index:
			look_touch_index = -1

func _handle_drag(event: InputEventScreenDrag) -> void:
	if event.index == joystick_touch_index:
		var diff := event.position - joystick_center
		if diff.length() > joystick_radius:
			diff = diff.normalized() * joystick_radius
		var normalized := diff / joystick_radius
		if player_ref and player_ref.has_method("set_joystick_input"):
			player_ref.set_joystick_input(normalized)
		_update_joystick_knob(joystick_center + diff)
	elif event.index == look_touch_index:
		var relative := event.position - look_touch_prev
		look_touch_prev = event.position
		if player_ref and player_ref.has_method("apply_touch_look"):
			player_ref.apply_touch_look(relative)

func _show_joystick(center: Vector2) -> void:
	if joystick_base:
		joystick_base.position = center - joystick_base.size / 2
		joystick_base.visible = true
	if joystick_knob:
		joystick_knob.position = center - joystick_knob.size / 2
		joystick_knob.visible = true

func _hide_joystick() -> void:
	if joystick_base:
		joystick_base.visible = false
	if joystick_knob:
		joystick_knob.visible = false

func _update_joystick_knob(pos: Vector2) -> void:
	if joystick_knob:
		joystick_knob.position = pos - joystick_knob.size / 2

# ---- HUD Updates ----

func update_health(value: int) -> void:
	if health_bar:
		health_bar.value = value
	if health_label:
		health_label.text = str(value)
	flash_damage()

func update_ammo(current: int, reserve: int) -> void:
	if ammo_label:
		ammo_label.text = str(current) + " / " + str(reserve)

func update_money(value: int) -> void:
	if money_label:
		money_label.text = "$ " + str(value)

func update_wave(wave_number: int) -> void:
	if wave_label:
		wave_label.text = "Wave " + str(wave_number)
	show_announcement("WAVE " + str(wave_number))

func update_kills(kills: int) -> void:
	if kills_label:
		kills_label.text = "Kills: " + str(kills)

func update_wave_countdown(seconds: float) -> void:
	if wave_announcement:
		wave_announcement.visible = true
		wave_announcement.text = "Next wave in " + str(int(seconds)) + "..."
		wave_announcement.modulate.a = 1.0

func show_wave_complete(wave_number: int, bonus: int) -> void:
	show_announcement("WAVE " + str(wave_number) + " COMPLETE!\n+" + str(bonus) + " $")

func show_announcement(text: String) -> void:
	if wave_announcement:
		wave_announcement.visible = true
		wave_announcement.text = text
		wave_announcement.modulate.a = 1.0
		var tween := create_tween()
		tween.tween_interval(2.5)
		tween.tween_property(wave_announcement, "modulate:a", 0.0, 1.0)
		tween.tween_callback(func(): wave_announcement.visible = false)

func show_reloading(visible: bool) -> void:
	if reload_indicator:
		reload_indicator.visible = visible
		reload_indicator.text = "RELOADING..."

func flash_damage() -> void:
	if damage_flash:
		damage_flash.color = Color(1, 0, 0, 0.25)
		var tween := create_tween()
		tween.tween_property(damage_flash, "color:a", 0.0, 0.3)

func show_game_over(waves: int, kills: int, money: int) -> void:
	if game_over_panel:
		game_over_panel.visible = true
	if game_over_stats:
		game_over_stats.text = "Waves: " + str(waves) + "\nKills: " + str(kills) + "\nMoney: $ " + str(money)

func _on_restart_pressed() -> void:
	GameData.reset_for_new_game()
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_shoot_pressed() -> void:
	if player_ref and player_ref.has_method("try_shoot"):
		player_ref.try_shoot()

func _on_reload_pressed() -> void:
	if player_ref and player_ref.has_method("start_reload"):
		player_ref.start_reload()
