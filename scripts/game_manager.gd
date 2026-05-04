extends Node3D

var current_wave: int = 0
var enemies_alive: int = 0
var enemies_to_spawn: int = 0
var spawn_timer: float = 0.0
var spawn_interval: float = 1.5
var wave_active: bool = false
var between_waves: bool = true
var between_wave_timer: float = 4.0
var game_over: bool = false
var spawn_radius: float = 22.0
var min_spawn_distance: float = 12.0

var enemy_textures: Array[String] = [
	"res://textures/enemies/enemy_green.png",
	"res://textures/enemies/enemy_pink.png",
	"res://textures/enemies/enemy_nose.jpg",
	"res://textures/enemies/enemy_kfc.jpg",
	"res://textures/enemies/enemy_space1.jpg",
	"res://textures/enemies/enemy_space2.jpg",
	"res://textures/enemies/enemy_playground.jpg",
]

var player: CharacterBody3D
var hud: CanvasLayer
var spawn_container: Node3D

func _ready() -> void:
	build_environment()
	build_player()
	build_hud()
	spawn_container = Node3D.new()
	spawn_container.name = "SpawnContainer"
	add_child(spawn_container)

func build_environment() -> void:
	# Directional light (sun)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-50, 25, 0)
	light.shadow_enabled = true
	light.light_energy = 1.3
	light.light_color = Color(1, 0.95, 0.9)
	add_child(light)

	# Environment
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.35, 0.55, 0.8)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.4, 0.45, 0.55)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAP_ACES
	env.fog_enabled = true
	env.fog_light_color = Color(0.5, 0.6, 0.75)
	env.fog_density = 0.006
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	# ---- GROUND ----
	# Main floor
	create_static_box(Vector3(0, -0.25, 0), Vector3(70, 0.5, 70), Color(0.28, 0.32, 0.25))
	# Floor detail grid lines
	for i in range(-30, 31, 10):
		create_static_box(Vector3(float(i), 0.01, 0), Vector3(0.05, 0.02, 70), Color(0.35, 0.38, 0.3))
		create_static_box(Vector3(0, 0.01, float(i)), Vector3(70, 0.02, 0.05), Color(0.35, 0.38, 0.3))

	# ---- WALLS ----
	var wall_color := Color(0.45, 0.4, 0.35)
	var wall_top := Color(0.55, 0.5, 0.4)
	# North
	create_static_box(Vector3(0, 3, -35), Vector3(70, 6, 1.5), wall_color)
	create_static_box(Vector3(0, 6.2, -35), Vector3(70, 0.4, 2), wall_top)
	# South
	create_static_box(Vector3(0, 3, 35), Vector3(70, 6, 1.5), wall_color)
	create_static_box(Vector3(0, 6.2, 35), Vector3(70, 0.4, 2), wall_top)
	# East
	create_static_box(Vector3(35, 3, 0), Vector3(1.5, 6, 70), wall_color)
	create_static_box(Vector3(35, 6.2, 0), Vector3(2, 0.4, 70), wall_top)
	# West
	create_static_box(Vector3(-35, 3, 0), Vector3(1.5, 6, 70), wall_color)
	create_static_box(Vector3(-35, 6.2, 0), Vector3(2, 0.4, 70), wall_top)

	# ---- COVER OBJECTS ----
	var cover_color := Color(0.5, 0.48, 0.4)
	var cover_dark := Color(0.38, 0.35, 0.3)

	# Sandbag walls
	create_static_box(Vector3(8, 0.5, -10), Vector3(4, 1.0, 0.8), cover_color)
	create_static_box(Vector3(-8, 0.5, 10), Vector3(0.8, 1.0, 4), cover_color)
	create_static_box(Vector3(15, 0.5, 8), Vector3(3, 1.0, 0.8), cover_color)
	create_static_box(Vector3(-12, 0.5, -8), Vector3(0.8, 1.0, 3), cover_color)

	# Concrete barriers
	create_static_box(Vector3(0, 0.7, -18), Vector3(6, 1.4, 1.2), cover_dark)
	create_static_box(Vector3(-20, 0.7, 0), Vector3(1.2, 1.4, 5), cover_dark)
	create_static_box(Vector3(20, 0.7, -5), Vector3(1.2, 1.4, 5), cover_dark)
	create_static_box(Vector3(5, 0.7, 18), Vector3(5, 1.4, 1.2), cover_dark)

	# Pillars / columns
	var pillar_color := Color(0.55, 0.5, 0.45)
	create_static_box(Vector3(12, 2, -20), Vector3(1.5, 4, 1.5), pillar_color)
	create_static_box(Vector3(-12, 2, -20), Vector3(1.5, 4, 1.5), pillar_color)
	create_static_box(Vector3(12, 2, 20), Vector3(1.5, 4, 1.5), pillar_color)
	create_static_box(Vector3(-12, 2, 20), Vector3(1.5, 4, 1.5), pillar_color)
	create_static_box(Vector3(0, 2, 0), Vector3(2, 4, 2), pillar_color)

	# Crate stacks
	var crate_color := Color(0.55, 0.4, 0.25)
	create_static_box(Vector3(-25, 0.5, -15), Vector3(2, 1, 2), crate_color)
	create_static_box(Vector3(-25, 1.5, -15), Vector3(1.5, 1, 1.5), crate_color)
	create_static_box(Vector3(25, 0.5, 15), Vector3(2, 1, 2), crate_color)
	create_static_box(Vector3(25, 1.5, 15), Vector3(1.5, 1, 1.5), crate_color)
	create_static_box(Vector3(-18, 0.5, 22), Vector3(2, 1, 2), crate_color)
	create_static_box(Vector3(22, 0.5, -22), Vector3(2, 1, 2), crate_color)

	# Low walls / rubble
	create_static_box(Vector3(-5, 0.35, -5), Vector3(3, 0.7, 0.6), Color(0.4, 0.38, 0.35))
	create_static_box(Vector3(5, 0.35, 5), Vector3(0.6, 0.7, 3), Color(0.4, 0.38, 0.35))
	create_static_box(Vector3(-15, 0.35, 15), Vector3(2.5, 0.7, 0.6), Color(0.4, 0.38, 0.35))
	create_static_box(Vector3(18, 0.35, -12), Vector3(0.6, 0.7, 2.5), Color(0.4, 0.38, 0.35))

	# Ramps
	create_static_box(Vector3(28, 0.4, -28), Vector3(4, 0.8, 4), Color(0.4, 0.42, 0.38))
	create_static_box(Vector3(-28, 0.4, 28), Vector3(4, 0.8, 4), Color(0.4, 0.42, 0.38))

func create_static_box(pos: Vector3, size: Vector3, color: Color) -> void:
	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.position = pos
	add_child(body)

	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_inst.material_override = mat
	body.add_child(mesh_inst)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	body.add_child(col)

func build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.collision_layer = 2
	player.collision_mask = 1
	player.position = Vector3(0, 1, 0)
	player.add_to_group("player")

	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.7
	col.shape = shape
	player.add_child(col)

	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.65, 0)
	player.add_child(head)

	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 70.0
	camera.current = true
	head.add_child(camera)

	var raycast := RayCast3D.new()
	raycast.name = "RayCast3D"
	raycast.target_position = Vector3(0, 0, -100)
	raycast.collision_mask = 5
	raycast.enabled = true
	camera.add_child(raycast)

	var muzzle := OmniLight3D.new()
	muzzle.name = "MuzzleFlash"
	muzzle.visible = false
	muzzle.light_color = Color(1, 0.8, 0.3)
	muzzle.light_energy = 4.0
	muzzle.omni_range = 6.0
	muzzle.position = Vector3(0.25, -0.15, -0.7)
	camera.add_child(muzzle)

	# Weapon visual — gun shape
	var gun_body := MeshInstance3D.new()
	gun_body.name = "WeaponMesh"
	var gun_mesh := BoxMesh.new()
	gun_mesh.size = Vector3(0.06, 0.08, 0.45)
	gun_body.mesh = gun_mesh
	gun_body.position = Vector3(0.28, -0.22, -0.55)
	var gun_mat := StandardMaterial3D.new()
	gun_mat.albedo_color = Color(0.15, 0.15, 0.18)
	gun_mat.metallic = 0.6
	gun_body.material_override = gun_mat
	camera.add_child(gun_body)

	# Gun grip
	var grip := MeshInstance3D.new()
	var grip_mesh := BoxMesh.new()
	grip_mesh.size = Vector3(0.05, 0.1, 0.04)
	grip.mesh = grip_mesh
	grip.position = Vector3(0.28, -0.3, -0.42)
	grip.material_override = gun_mat
	camera.add_child(grip)

	# Gun barrel tip
	var barrel := MeshInstance3D.new()
	var barrel_mesh := BoxMesh.new()
	barrel_mesh.size = Vector3(0.035, 0.035, 0.08)
	barrel.mesh = barrel_mesh
	barrel.position = Vector3(0.28, -0.2, -0.82)
	var barrel_mat := StandardMaterial3D.new()
	barrel_mat.albedo_color = Color(0.1, 0.1, 0.12)
	barrel_mat.metallic = 0.8
	barrel.material_override = barrel_mat
	camera.add_child(barrel)

	var script := load("res://scripts/player.gd")
	player.set_script(script)

	add_child(player)

	player.health_changed.connect(_on_player_health_changed)
	player.ammo_changed.connect(_on_player_ammo_changed)
	player.player_died.connect(_on_player_died)
	player.reload_started.connect(_on_player_reload_started)
	player.reload_finished.connect(_on_player_reload_finished)

func build_hud() -> void:
	var hud_scene := load("res://scenes/hud.tscn")
	if hud_scene:
		hud = hud_scene.instantiate()
		add_child(hud)
	else:
		hud = CanvasLayer.new()
		hud.name = "HUD"
		var script := load("res://scripts/hud.gd")
		hud.set_script(script)
		add_child(hud)

func _process(delta: float) -> void:
	if game_over:
		return

	if between_waves:
		between_wave_timer -= delta
		if between_wave_timer <= 0:
			start_next_wave()
		else:
			if hud and hud.has_method("update_wave_countdown"):
				hud.update_wave_countdown(ceil(between_wave_timer))
		return

	if wave_active:
		if enemies_to_spawn > 0:
			spawn_timer -= delta
			if spawn_timer <= 0:
				spawn_enemy()
				enemies_to_spawn -= 1
				spawn_timer = spawn_interval

		if enemies_to_spawn <= 0 and enemies_alive <= 0:
			complete_wave()

func start_next_wave() -> void:
	current_wave += 1
	between_waves = false
	wave_active = true

	var enemy_count := 3 + current_wave * 2
	enemies_to_spawn = enemy_count
	enemies_alive = 0
	spawn_timer = 0.3
	spawn_interval = max(0.4, 1.5 - current_wave * 0.1)

	if hud and hud.has_method("update_wave"):
		hud.update_wave(current_wave)

func complete_wave() -> void:
	wave_active = false
	between_waves = true
	between_wave_timer = 5.0

	var wave_bonus := current_wave * 50
	GameData.add_money(wave_bonus)
	if GameData.highest_wave < current_wave:
		GameData.highest_wave = current_wave

	# Give ammo bonus each wave
	if player and player.has_method("set_joystick_input"):
		player.reserve_ammo += 30

	if hud and hud.has_method("show_wave_complete"):
		hud.show_wave_complete(current_wave, wave_bonus)
	if hud and hud.has_method("update_money"):
		hud.update_money(GameData.money)

func spawn_enemy() -> void:
	if not player:
		return

	var enemy_node := CharacterBody3D.new()
	enemy_node.name = "Enemy"
	enemy_node.collision_layer = 4
	enemy_node.collision_mask = 1

	var collision := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.35
	shape.height = 1.4
	collision.shape = shape
	collision.position.y = 0.7
	enemy_node.add_child(collision)

	var sprite := Sprite3D.new()
	sprite.name = "Sprite3D"
	sprite.pixel_size = 0.0015
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var tex_path: String = enemy_textures[randi() % enemy_textures.size()]
	var tex := load(tex_path)
	if tex:
		sprite.texture = tex
	sprite.position.y = 0.8
	enemy_node.add_child(sprite)

	var script := load("res://scripts/enemy.gd")
	enemy_node.set_script(script)

	var health_mult := 1.0 + (current_wave - 1) * 0.25
	enemy_node.max_health = int(80 * health_mult)
	enemy_node.speed = 2.0 + current_wave * 0.25
	enemy_node.money_reward = 10 + current_wave * 3
	enemy_node.attack_damage = 8 + current_wave * 2
	enemy_node.attack_range = 2.5

	var angle := randf() * TAU
	var dist := randf_range(min_spawn_distance, spawn_radius)
	var spawn_pos := player.global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
	spawn_pos.x = clamp(spawn_pos.x, -32, 32)
	spawn_pos.z = clamp(spawn_pos.z, -32, 32)
	spawn_pos.y = 0.0

	spawn_container.add_child(enemy_node)
	enemy_node.global_position = spawn_pos

	enemy_node.enemy_died.connect(_on_enemy_died)
	enemies_alive += 1

func _on_enemy_died(reward: int) -> void:
	enemies_alive -= 1
	GameData.add_money(reward)
	GameData.total_kills += 1
	if hud and hud.has_method("update_money"):
		hud.update_money(GameData.money)
	if hud and hud.has_method("update_kills"):
		hud.update_kills(GameData.total_kills)

func _on_player_health_changed(new_health: int) -> void:
	if hud and hud.has_method("update_health"):
		hud.update_health(new_health)

func _on_player_ammo_changed(current: int, reserve: int) -> void:
	if hud and hud.has_method("update_ammo"):
		hud.update_ammo(current, reserve)

func _on_player_died() -> void:
	game_over = true
	if GameData.highest_wave < current_wave:
		GameData.highest_wave = current_wave
	if hud and hud.has_method("show_game_over"):
		hud.show_game_over(current_wave, GameData.total_kills, GameData.money)

func _on_player_reload_started() -> void:
	if hud and hud.has_method("show_reloading"):
		hud.show_reloading(true)

func _on_player_reload_finished() -> void:
	if hud and hud.has_method("show_reloading"):
		hud.show_reloading(false)
