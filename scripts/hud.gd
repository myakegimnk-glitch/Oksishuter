extends CanvasLayer

var health_bar: ProgressBar
var health_label: Label
var ammo_label: Label
var money_label: Label
var wave_label: Label
var kills_label: Label
var wave_announcement: Label
var game_over_panel: PanelContainer
var game_over_stats: Label
var shoot_btn: Button
var reload_btn: Button
var crosshair: Control

var joystick_touch_index: int = -1
var joystick_center := Vector2.ZERO
var joystick_radius: float = 80.0
var joystick_visual: Control
var joystick_knob: Control
var look_touch_index: int = -1
var look_touch_prev := Vector2.ZERO

var player_ref: CharacterBody3D = null

func _ready() -> void:
	build_ui()
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player_ref = players[0]

func build_ui() -> void:
	# Top bar
	var top_margin := MarginContainer.new()
	top_margin.anchors_preset = Control.PRESET_TOP_WIDE
	top_margin.anchor_right = 1.0
	top_margin.offset_bottom = 50
	top_margin.add_theme_constant_override("margin_left", 20)
	top_margin.add_theme_constant_override("margin_top", 10)
	top_margin.add_theme_constant_override("margin_right", 20)
	top_margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(top_margin)

	var top_bar := HBoxContainer.new()
	top_bar.add_theme_constant_override("separation", 20)
	top_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_margin.add_child(top_bar)

	# Health bar
	health_bar = ProgressBar.new()
	health_bar.custom_minimum_size = Vector2(180, 28)
	health_bar.max_value = 100
	health_bar.value = 100
	health_bar.show_percentage = false
	top_bar.add_child(health_bar)

	health_label = Label.new()
	health_label.text = "HP: 100"
	health_label.add_theme_font_size_override("font_size", 18)
	health_label.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	top_bar.add_child(health_label)

	# Ammo
	ammo_label = Label.new()
	ammo_label.text = "30 / 90"
	ammo_label.add_theme_font_size_override("font_size", 18)
	ammo_label.add_theme_color_override("font_color", Color.WHITE)
	top_bar.add_child(ammo_label)

	# Money
	money_label = Label.new()
	money_label.text = "Coins: 0"
	money_label.add_theme_font_size_override("font_size", 18)
	money_label.add_theme_color_override("font_color", Color(1, 0.85, 0))
	top_bar.add_child(money_label)

	# Wave
	wave_label = Label.new()
	wave_label.text = "Wave 0"
	wave_label.add_theme_font_size_override("font_size", 18)
	wave_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
	top_bar.add_child(wave_label)

	# Kills
	kills_label = Label.new()
	kills_label.text = "Kills: 0"
	kills_label.add_theme_font_size_override("font_size", 18)
	kills_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	top_bar.add_child(kills_label)

	# Crosshair
	crosshair = Control.new()
	crosshair.anchors_preset = Control.PRESET_CENTER
	crosshair.anchor_left = 0.5
	crosshair.anchor_top = 0.5
	crosshair.anchor_right = 0.5
	crosshair.anchor_bottom = 0.5
	crosshair.offset_left = -20
	crosshair.offset_top = -20
	crosshair.offset_right = 20
	crosshair.offset_bottom = 20
	crosshair.mouse_filter = Control.MOUSE_FILTER_IGNORE
	crosshair.draw.connect(_draw_crosshair)
	add_child(crosshair)

	# Wave announcement
	wave_announcement = Label.new()
	wave_announcement.anchors_preset = Control.PRESET_CENTER_TOP
	wave_announcement.anchor_left = 0.5
	wave_announcement.anchor_right = 0.5
	wave_announcement.offset_left = -250
	wave_announcement.offset_top = 120
	wave_announcement.offset_right = 250
	wave_announcement.offset_bottom = 200
	wave_announcement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_announcement.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	wave_announcement.add_theme_font_size_override("font_size", 36)
	wave_announcement.add_theme_color_override("font_color", Color(1, 0.8, 0))
	wave_announcement.visible = false
	wave_announcement.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(wave_announcement)

	# Shoot button (bottom-right)
	shoot_btn = Button.new()
	shoot_btn.text = "FIRE"
	shoot_btn.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	shoot_btn.anchor_left = 1.0
	shoot_btn.anchor_top = 1.0
	shoot_btn.anchor_right = 1.0
	shoot_btn.anchor_bottom = 1.0
	shoot_btn.offset_left = -150
	shoot_btn.offset_top = -150
	shoot_btn.offset_right = -20
	shoot_btn.offset_bottom = -20
	shoot_btn.add_theme_font_size_override("font_size", 24)
	shoot_btn.pressed.connect(_on_shoot_pressed)
	add_child(shoot_btn)

	# Reload button (above shoot button)
	reload_btn = Button.new()
	reload_btn.text = "RELOAD"
	reload_btn.anchors_preset = Control.PRESET_BOTTOM_RIGHT
	reload_btn.anchor_left = 1.0
	reload_btn.anchor_top = 1.0
	reload_btn.anchor_right = 1.0
	reload_btn.anchor_bottom = 1.0
	reload_btn.offset_left = -150
	reload_btn.offset_top = -220
	reload_btn.offset_right = -20
	reload_btn.offset_bottom = -160
	reload_btn.add_theme_font_size_override("font_size", 18)
	reload_btn.pressed.connect(_on_reload_pressed)
	add_child(reload_btn)

	# Game Over Panel (hidden by default)
	game_over_panel = PanelContainer.new()
	game_over_panel.anchors_preset = Control.PRESET_CENTER
	game_over_panel.anchor_left = 0.5
	game_over_panel.anchor_top = 0.5
	game_over_panel.anchor_right = 0.5
	game_over_panel.anchor_bottom = 0.5
	game_over_panel.offset_left = -200
	game_over_panel.offset_top = -180
	game_over_panel.offset_right = 200
	game_over_panel.offset_bottom = 180
	game_over_panel.visible = false
	add_child(game_over_panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	game_over_panel.add_child(vbox)

	var go_title := Label.new()
	go_title.text = "GAME OVER"
	go_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	go_title.add_theme_font_size_override("font_size", 36)
	go_title.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
	vbox.add_child(go_title)

	game_over_stats = Label.new()
	game_over_stats.text = ""
	game_over_stats.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	game_over_stats.add_theme_font_size_override("font_size", 20)
	vbox.add_child(game_over_stats)

	var restart_btn := Button.new()
	restart_btn.text = "RESTART"
	restart_btn.custom_minimum_size = Vector2(0, 50)
	restart_btn.add_theme_font_size_override("font_size", 22)
	restart_btn.pressed.connect(_on_restart_pressed)
	vbox.add_child(restart_btn)

	var menu_btn := Button.new()
	menu_btn.text = "MENU"
	menu_btn.custom_minimum_size = Vector2(0, 50)
	menu_btn.add_theme_font_size_override("font_size", 22)
	menu_btn.pressed.connect(_on_menu_pressed)
	vbox.add_child(menu_btn)

func _draw_crosshair() -> void:
	var center := crosshair.size / 2
	var color := Color(1, 1, 1, 0.8)
	var gap := 4.0
	var length := 12.0
	var thickness := 2.0
	crosshair.draw_rect(Rect2(center.x - thickness / 2, center.y - gap - length, thickness, length), color)
	crosshair.draw_rect(Rect2(center.x - thickness / 2, center.y + gap, thickness, length), color)
	crosshair.draw_rect(Rect2(center.x - gap - length, center.y - thickness / 2, length, thickness), color)
	crosshair.draw_rect(Rect2(center.x + gap, center.y - thickness / 2, length, thickness), color)

func _input(event: InputEvent) -> void:
	if game_over_panel and game_over_panel.visible:
		return
	if event is InputEventScreenTouch:
		_handle_touch(event)
	elif event is InputEventScreenDrag:
		_handle_drag(event)

func _handle_touch(event: InputEventScreenTouch) -> void:
	var vp_size := get_viewport().get_visible_rect().size
	var screen_half := vp_size.x / 2.0
	var top_zone := vp_size.y * 0.15

	if event.position.y < top_zone:
		return

	# Check if touch is on buttons
	if shoot_btn and shoot_btn.get_global_rect().has_point(event.position):
		return
	if reload_btn and reload_btn.get_global_rect().has_point(event.position):
		return

	if event.pressed:
		if event.position.x < screen_half:
			if joystick_touch_index == -1:
				joystick_touch_index = event.index
				joystick_center = event.position
		else:
			if look_touch_index == -1:
				look_touch_index = event.index
				look_touch_prev = event.position
	else:
		if event.index == joystick_touch_index:
			joystick_touch_index = -1
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
	elif event.index == look_touch_index:
		var relative := event.position - look_touch_prev
		look_touch_prev = event.position
		if player_ref and player_ref.has_method("apply_touch_look"):
			player_ref.apply_touch_look(relative)

func update_health(value: int) -> void:
	if health_bar:
		health_bar.value = value
	if health_label:
		health_label.text = "HP: " + str(value)

func update_ammo(current: int, reserve: int) -> void:
	if ammo_label:
		ammo_label.text = str(current) + " / " + str(reserve)

func update_money(value: int) -> void:
	if money_label:
		money_label.text = "Coins: " + str(value)

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

func show_wave_complete(wave_number: int, bonus: int) -> void:
	show_announcement("WAVE " + str(wave_number) + " COMPLETE!\n+" + str(bonus) + " coins")

func show_announcement(text: String) -> void:
	if wave_announcement:
		wave_announcement.visible = true
		wave_announcement.text = text
		wave_announcement.modulate.a = 1.0
		var tween := create_tween()
		tween.tween_interval(2.0)
		tween.tween_property(wave_announcement, "modulate:a", 0.0, 1.0)
		tween.tween_callback(func(): wave_announcement.visible = false)

func show_game_over(waves: int, kills: int, money: int) -> void:
	if game_over_panel:
		game_over_panel.visible = true
	if game_over_stats:
		game_over_stats.text = "Waves survived: " + str(waves) + "\nTotal kills: " + str(kills) + "\nMoney earned: " + str(money)

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
