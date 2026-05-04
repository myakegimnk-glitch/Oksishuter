extends CharacterBody3D

@export var max_health: int = 100
@export var speed: float = 3.0
@export var attack_damage: int = 10
@export var attack_range: float = 2.0
@export var attack_cooldown: float = 1.0
@export var money_reward: int = 10

var health: int = 100
var target: Node3D = null
var attack_timer: float = 0.0
var is_dead: bool = false
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var sprite: Sprite3D = $Sprite3D

signal enemy_died(reward: int)

func _ready() -> void:
	health = max_health
	find_player()

func find_player() -> void:
	await get_tree().process_frame
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		target = players[0]

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if target and is_instance_valid(target):
		var direction := (target.global_position - global_position)
		direction.y = 0
		var distance := direction.length()

		if distance > attack_range:
			direction = direction.normalized()
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = 0
			velocity.z = 0
			attack_timer -= delta
			if attack_timer <= 0:
				attack(distance)
				attack_timer = attack_cooldown

		if sprite:
			sprite.look_at(target.global_position, Vector3.UP)
			sprite.rotation.x = 0
			sprite.rotation.z = 0

	move_and_slide()

func attack(distance: float) -> void:
	if distance <= attack_range and target.has_method("take_damage"):
		target.take_damage(attack_damage)

func take_damage(amount: int) -> void:
	if is_dead:
		return
	health -= amount

	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate", Color(10, 0.3, 0.3), 0.05)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.15)

	if health <= 0:
		die()

func die() -> void:
	is_dead = true
	emit_signal("enemy_died", money_reward)

	if sprite:
		var tween := create_tween()
		tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
		tween.tween_property(self, "scale", Vector3(0.01, 0.01, 0.01), 0.3)
		tween.tween_callback(queue_free)
