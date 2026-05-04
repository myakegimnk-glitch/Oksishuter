extends Node3D

var current_wave: int = 0
var enemies_alive: int = 0
var enemies_to_spawn: int = 0
var spawn_timer: float = 0.0
var spawn_interval: float = 1.5
var wave_active: bool = false
var between_waves: bool = true
var between_wave_timer: float = 3.0
var game_over: bool = false
var spawn_radius: float = 20.0
var min_spawn_distance: float = 10.0

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
	# Directional light
	var light := DirectionalLight3D.new()
	light.transform = Transform3D.IDENTITY
	light.rotation_degrees = Vector3(-45, 30, 0)
	light.shadow_enabled = true
	light.light_energy = 1.2
	add_child(light)

	# Ambient light
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.4, 0.6, 0.8)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.3, 0.3, 0.4)
	env.ambient_light_energy = 0.5
	env.fog_enabled = true
	env.fog_light_color = Color(0.5, 0.6, 0.7)
	env.fog_density = 0.01
	var world_env := WorldEnvironment.new()
	world_env.environment = env
	add_child(world_env)

	# Floor
	var floor_body := StaticBody3D.new()
	floor_body.collision_layer = 1
	add_child(floor_body)

	var floor_mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(60, 1, 60)
	floor_mesh.mesh = box_mesh
	floor_mesh.position = Vector3(0, -0.5, 0)
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.35, 0.35, 0.3)
	floor_mesh.material_override = floor_mat
	floor_body.add_child(floor_mesh)

	var floor_col := CollisionShape3D.new()
	var floor_shape := BoxShape3D.new()
	floor_shape.size = Vector3(60, 1, 60)
	floor_col.shape = floor_shape
	floor_col.position = Vector3(0, -0.5, 0)
	floor_body.add_child(floor_col)

	# Walls
	var wall_color := Color(0.5, 0.45, 0.4)
	create_wall(Vector3(0, 2.5, -30), Vector3(60, 5, 1), wall_color)
	create_wall(Vector3(0, 2.5, 30), Vector3(60, 5, 1), wall_color)
	create_wall(Vector3(-30, 2.5, 0), Vector3(1, 5, 60), wall_color)
	create_wall(Vector3(30, 2.5, 0), Vector3(1, 5, 60), wall_color)

	# Some cover objects
	create_cover(Vector3(5, 0.75, -8), Vector3(3, 1.5, 1))
	create_cover(Vector3(-7, 0.75, 5), Vector3(1, 1.5, 4))
	create_cover(Vector3(10, 0.75, 10), Vector3(2, 1.5, 2))
	create_cover(Vector3(-12, 0.75, -6), Vector3(4, 1.5, 1))

func create_wall(pos: Vector3, size: Vector3, color: Color) -> void:
	var wall := StaticBody3D.new()
	wall.collision_layer = 1
	wall.position = pos
	add_child(wall)

	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mesh_inst.material_override = mat
	wall.add_child(mesh_inst)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	wall.add_child(col)

func create_cover(pos: Vector3, size: Vector3) -> void:
	var cover := StaticBody3D.new()
	cover.collision_layer = 1
	cover.position = pos
	add_child(cover)

	var mesh_inst := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_inst.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.6, 0.55, 0.45)
	mesh_inst.material_override = mat
	cover.add_child(mesh_inst)

	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	col.shape = shape
	cover.add_child(col)

func build_player() -> void:
	player = CharacterBody3D.new()
	player.name = "Player"
	player.collision_layer = 2
	player.collision_mask = 1
	player.position = Vector3(0, 1, 0)
	player.add_to_group("player")

	var col := CollisionShape3D.new()
	var shape := CapsuleShape3D.new()
	shape.radius = 0.4
	shape.height = 1.8
	col.shape = shape
	player.add_child(col)

	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.7, 0)
	player.add_child(head)

	var camera := Camera3D.new()
	camera.name = "Camera3D"
	camera.fov = 75.0
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
	muzzle.light_energy = 3.0
	muzzle.omni_range = 5.0
	muzzle.position = Vector3(0.3, -0.2, -0.8)
	camera.add_child(muzzle)

	# Weapon visual (simple box for gun)
	var weapon := MeshInstance3D.new()
	weapon.name = "WeaponMesh"
	var weapon_mesh := BoxMesh.new()
	weapon_mesh.size = Vector3(0.08, 0.08, 0.5)
	weapon.mesh = weapon_mesh
	weapon.position = Vector3(0.3, -0.25, -0.5)
	var weapon_mat := StandardMaterial3D.new()
	weapon_mat.albedo_color = Color(0.2, 0.2, 0.2)
	weapon.material_override = weapon_mat
	camera.add_child(weapon)

	var script := load("res://scripts/player.gd")
	player.set_script(script)

	add_child(player)

	player.health_changed.connect(_on_player_health_changed)
	player.ammo_changed.connect(_on_player_ammo_changed)
	player.player_died.connect(_on_player_died)

func build_hud() -> void:
	var hud_scene := load("res://scenes/hud.tscn")
	if hud_scene:
		hud = hud_scene.instantiate()
		add_child(hud)
	else:
		push_warning("Could not load HUD scene, building fallback")
		build_hud_fallback()

func build_hud_fallback() -> void:
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
	spawn_timer = 0.5
	spawn_interval = max(0.5, 1.5 - current_wave * 0.1)

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
	shape.radius = 0.5
	shape.height = 2.0
	collision.shape = shape
	enemy_node.add_child(collision)

	var sprite := Sprite3D.new()
	sprite.name = "Sprite3D"
	sprite.pixel_size = 0.003
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	var tex_path: String = enemy_textures[randi() % enemy_textures.size()]
	var tex := load(tex_path)
	if tex:
		sprite.texture = tex
	sprite.position.y = 1.0
	enemy_node.add_child(sprite)

	var script := load("res://scripts/enemy.gd")
	enemy_node.set_script(script)

	var health_mult := 1.0 + (current_wave - 1) * 0.2
	enemy_node.max_health = int(100 * health_mult)
	enemy_node.speed = 2.5 + current_wave * 0.3
	enemy_node.money_reward = 10 + current_wave * 2
	enemy_node.attack_damage = 8 + current_wave * 2

	var angle := randf() * TAU
	var dist := randf_range(min_spawn_distance, spawn_radius)
	var spawn_pos := player.global_position + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
	spawn_pos.y = 1.0

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
