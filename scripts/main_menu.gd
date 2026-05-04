extends Control

var money_label: Label
var wave_label: Label

func _ready() -> void:
	build_menu()

func build_menu() -> void:
	# Background
	var bg := ColorRect.new()
	bg.anchors_preset = Control.PRESET_FULL_RECT
	bg.anchor_right = 1.0
	bg.anchor_bottom = 1.0
	bg.color = Color(0.06, 0.06, 0.12)
	add_child(bg)

	# Center container
	var center := VBoxContainer.new()
	center.anchors_preset = Control.PRESET_CENTER
	center.anchor_left = 0.5
	center.anchor_top = 0.5
	center.anchor_right = 0.5
	center.anchor_bottom = 0.5
	center.offset_left = -200
	center.offset_top = -220
	center.offset_right = 200
	center.offset_bottom = 220
	center.add_theme_constant_override("separation", 20)
	add_child(center)

	# Title
	var title := Label.new()
	title.text = "OKSISHUTER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 52)
	title.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	center.add_child(title)

	# Subtitle
	var subtitle := Label.new()
	subtitle.text = "Wave Survival FPS"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 20)
	subtitle.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	center.add_child(subtitle)

	# Spacer
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 10)
	center.add_child(spacer)

	# Money display
	var money_panel := PanelContainer.new()
	center.add_child(money_panel)

	var money_hbox := HBoxContainer.new()
	money_hbox.add_theme_constant_override("separation", 10)
	money_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	money_panel.add_child(money_hbox)

	var coin_label := Label.new()
	coin_label.text = "Coins:"
	coin_label.add_theme_font_size_override("font_size", 26)
	coin_label.add_theme_color_override("font_color", Color(1, 0.85, 0))
	money_hbox.add_child(coin_label)

	money_label = Label.new()
	money_label.text = str(GameData.money)
	money_label.add_theme_font_size_override("font_size", 26)
	money_label.add_theme_color_override("font_color", Color.WHITE)
	money_hbox.add_child(money_label)

	# Best wave
	wave_label = Label.new()
	wave_label.text = "Best wave: " + str(GameData.highest_wave)
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_label.add_theme_font_size_override("font_size", 20)
	wave_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	center.add_child(wave_label)

	# Spacer 2
	var spacer2 := Control.new()
	spacer2.custom_minimum_size = Vector2(0, 15)
	center.add_child(spacer2)

	# Play button
	var play_btn := Button.new()
	play_btn.text = "PLAY"
	play_btn.custom_minimum_size = Vector2(300, 60)
	play_btn.add_theme_font_size_override("font_size", 28)
	play_btn.pressed.connect(_on_play_pressed)
	center.add_child(play_btn)

	# Quit button
	var quit_btn := Button.new()
	quit_btn.text = "QUIT"
	quit_btn.custom_minimum_size = Vector2(300, 60)
	quit_btn.add_theme_font_size_override("font_size", 28)
	quit_btn.pressed.connect(_on_quit_pressed)
	center.add_child(quit_btn)

func _on_play_pressed() -> void:
	GameData.reset_for_new_game()
	get_tree().change_scene_to_file("res://scenes/game_world.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
