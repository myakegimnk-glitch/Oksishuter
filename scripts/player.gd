extends CharacterBody3D

const SPEED := 5.0
const JUMP_VELOCITY := 4.5
const MOUSE_SENSITIVITY := 0.003
const TOUCH_LOOK_SENSITIVITY := 0.005

@export var max_health: int = 100
var health: int = 100
var ammo: int = 30
var max_ammo: int = 30
var reserve_ammo: int = 90
var is_reloading: bool = false
var reload_time: float = 1.5
var reload_timer: float = 0.0
var fire_rate: float = 0.12
var fire_timer: float = 0.0
var damage_per_shot: int = 25

var joystick_input := Vector2.ZERO
var look_touch_index: int = -1
var look_touch_start := Vector2.ZERO
var look_touch_current := Vector2.ZERO

@onready var head: Node3D = $Head
@onready var camera: Camera3D = $Head/Camera3D
@onready var raycast: RayCast3D = $Head/Camera3D/RayCast3D
@onready var muzzle_flash: OmniLight3D = $Head/Camera3D/MuzzleFlash
@onready var weapon_mesh: MeshInstance3D = $Head/Camera3D/WeaponMesh

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

signal health_changed(new_health: int)
signal ammo_changed(current: int, reserve: int)
signal player_died

func _ready() -> void:
	health = max_health
	if muzzle_flash:
		muzzle_flash.visible = false

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta

	var input_dir := Vector2.ZERO

	if joystick_input.length() > 0.1:
		input_dir = joystick_input
	else:
		input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")

	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)

	move_and_slide()

	if fire_timer > 0:
		fire_timer -= delta
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0:
			finish_reload()

	if muzzle_flash and muzzle_flash.visible:
		muzzle_flash.light_energy -= delta * 30
		if muzzle_flash.light_energy <= 0:
			muzzle_flash.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		head.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		head.rotation.x = clamp(head.rotation.x, -PI / 2, PI / 2)

	if event.is_action_pressed("shoot"):
		try_shoot()
	if event.is_action_pressed("reload"):
		start_reload()

func apply_touch_look(relative: Vector2) -> void:
	rotate_y(-relative.x * TOUCH_LOOK_SENSITIVITY)
	head.rotate_x(-relative.y * TOUCH_LOOK_SENSITIVITY)
	head.rotation.x = clamp(head.rotation.x, -PI / 2, PI / 2)

func try_shoot() -> void:
	if is_reloading or fire_timer > 0 or ammo <= 0:
		return
	ammo -= 1
	fire_timer = fire_rate
	emit_signal("ammo_changed", ammo, reserve_ammo)

	if muzzle_flash:
		muzzle_flash.visible = true
		muzzle_flash.light_energy = 3.0

	animate_weapon_recoil()

	if raycast and raycast.is_colliding():
		var collider = raycast.get_collider()
		if collider.has_method("take_damage"):
			collider.take_damage(damage_per_shot)

	if ammo <= 0 and reserve_ammo > 0:
		start_reload()

func animate_weapon_recoil() -> void:
	if weapon_mesh:
		var tween := create_tween()
		tween.tween_property(weapon_mesh, "position:z", 0.05, 0.04)
		tween.tween_property(weapon_mesh, "position:z", 0.0, 0.08)

func start_reload() -> void:
	if is_reloading or reserve_ammo <= 0 or ammo == max_ammo:
		return
	is_reloading = true
	reload_timer = reload_time

func finish_reload() -> void:
	var needed := max_ammo - ammo
	var available := min(needed, reserve_ammo)
	ammo += available
	reserve_ammo -= available
	is_reloading = false
	emit_signal("ammo_changed", ammo, reserve_ammo)

func take_damage(amount: int) -> void:
	health -= amount
	health = max(health, 0)
	emit_signal("health_changed", health)
	if health <= 0:
		emit_signal("player_died")

func set_joystick_input(input: Vector2) -> void:
	joystick_input = input
