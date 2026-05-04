extends Control

var money_label: Label
var wave_label: Label

func _ready() -> void:
	build_menu()

func build_menu() -> void:
	# Background gradient
	var bg := ColorRect.new()
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.05, 0.05, 0.12)
	add_child(bg)

	# Accent line top
	var accent := ColorRect.new()
	accent.anchor_right = 1.0
	accent.offset_bottom = 4
	accent.color = Color(0.9, 0.15, 0.15)
	add_child(accent)

	# Center container
	var center := VBoxContainer.new()
	center.anchors_preset = Control.PRESET_CENTER
	center.anchor_left = 0.5
	center.anchor_top = 0.5
	center.anchor_right = 0.5
	center.anchor_bottom = 0.5
	center.offset_left = -220
	center.offset_top = -260
	center.offset_right = 220
	center.offset_bottom = 260
	center.add_theme_constant_override("separation", 16)
	add_child(center)

	# Title
	var title := Label.new()
	title.text = "OKSISHUTER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 48)
	title.add_theme_color_override("font_color", Color(1, 0.25, 0.25))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	title.add_theme_constant_override("outline_size", 4)
	center.add_child(title)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "WAVE SURVIVAL FPS"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	center.add_child(subtitle)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 15)
	center.add_child(spacer)

	# Stats panel
	var stats_panel := PanelContainer.new()
	var stats_style := StyleBoxFlat.new()
	stats_style.bg_color = Color(0.12, 0.12, 0.2, 0.8)
	stats_style.border_width_top = 2
	stats_style.border_width_bottom = 2
	stats_style.border_width_left = 2
	stats_style.border_width_right = 2
	stats_style.border_color = Color(1, 0.85, 0, 0.3)
	stats_style.corner_radius_top_left = 10
	stats_style.corner_radius_top_right = 10
	stats_style.corner_radius_bottom_left = 10
	stats_style.corner_radius_bottom_right = 10
	stats_style.content_margin_left = 20
	stats_style.content_margin_right = 20
	stats_style.content_margin_top = 15
	stats_style.content_margin_bottom = 15
	stats_panel.add_theme_stylebox_override("panel", stats_style)
	center.add_child(stats_panel)

	var stats_vbox := VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 10)
	stats_panel.add_child(stats_vbox)

	# Money
	var money_hbox := HBoxContainer.new()
	money_hbox.add_theme_constant_override("separation", 10)
	money_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	stats_vbox.add_child(money_hbox)

	var coin_icon := Label.new()
	coin_icon.text = "$"
	coin_icon.add_theme_font_size_override("font_size", 28)
	coin_icon.add_theme_color_override("font_color", Color(1, 0.85, 0))
	money_hbox.add_child(coin_icon)

	money_label = Label.new()
	money_label.text = str(GameData.money)
	money_label.add_theme_font_size_override("font_size", 28)
	money_label.add_theme_color_override("font_color", Color(1, 1, 1))
	money_hbox.add_child(money_label)

	# Best wave
	wave_label = Label.new()
	if GameData.highest_wave > 0:
		wave_label.text = "Best wave: " + str(GameData.highest_wave)
	else:
		wave_label.text = "No games played yet"
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.add_theme_font_size_override("font_size", 18)
	wave_label.add_theme_color_override("font_color", Color(0.5, 0.8, 1))
	stats_vbox.add_child(wave_label)

	# Total kills
	var kills_label := Label.new()
	kills_label.text = "Total kills: " + str(GameData.total_kills)
	kills_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	kills_label.add_theme_font_size_override("font_size", 16)
	kills_label.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	stats_vbox.add_child(kills_label)

	# Spacer 2
	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 10)
	center.add_child(spacer2)

	# Play button
	var play_btn := Button.new()
	play_btn.text = "PLAY"
	play_btn.custom_minimum_size = Vector2(300, 65)
	play_btn.add_theme_font_size_override("font_size", 30)
	var play_style := StyleBoxFlat.new()
	play_style.bg_color = Color(0.8, 0.15, 0.15, 0.85)
	play_style.corner_radius_top_left = 10
	play_style.corner_radius_top_right = 10
	play_style.corner_radius_bottom_left = 10
	play_style.corner_radius_bottom_right = 10
	play_style.border_width_top = 2
	play_style.border_width_bottom = 2
	play_style.border_width_left = 2
	play_style.border_width_right = 2
	play_style.border_color = Color(1, 0.3, 0.3, 0.9)
	play_btn.add_theme_stylebox_override("normal", play_style)
	var play_hover := play_style.duplicate()
	play_hover.bg_color = Color(1, 0.25, 0.25, 0.9)
	play_btn.add_theme_stylebox_override("hover", play_hover)
	play_btn.add_theme_stylebox_override("pressed", play_hover)
	play_btn.add_theme_color_override("font_color", Color.WHITE)
	play_btn.pressed.connect(_on_play_pressed)
	center.add_child(play_btn)

	# Quit button
	var quit_btn := Button.new()
	quit_btn.text = "QUIT"
	quit_btn.custom_minimum_size = Vector2(300, 55)
	quit_btn.add_theme_font_size_override("font_size", 22)
	var quit_style := StyleBoxFlat.new()
	quit_style.bg_color = Color(0.2, 0.2, 0.3, 0.6)
	quit_style.corner_radius_top_left = 8
	quit_style.corner_radius_top_right = 8
	quit_style.corner_radius_bottom_left = 8
	quit_style.corner_radius_bottom_right = 8
	quit_style.border_width_top = 1
	quit_style.border_width_bottom = 1
	quit_style.border_width_left = 1
	quit_style.border_width_right = 1
	quit_style.border_color = Color(0.5, 0.5, 0.6, 0.5)
	quit_btn.add_theme_stylebox_override("normal", quit_style)
	quit_btn.add_theme_color_override("font_color", Color(0.7, 0.7, 0.8))
	quit_btn.pressed.connect(_on_quit_pressed)
	center.add_child(quit_btn)

	# Version label
	var version := Label.new()
	version.text = "v1.1"
	version.anchor_left = 1.0
	version.anchor_top = 1.0
	version.anchor_right = 1.0
	version.anchor_bottom = 1.0
	version.offset_left = -60
	version.offset_top = -30
	version.add_theme_font_size_override("font_size", 14)
	version.add_theme_color_override("font_color", Color(0.4, 0.4, 0.5))
	add_child(version)

func _on_play_pressed() -> void:
	GameData.reset_for_new_game()
	get_tree().change_scene_to_file("res://scenes/game_world.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
