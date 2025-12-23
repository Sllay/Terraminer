extends CharacterBody3D

@export var animation_player_path: NodePath = NodePath("BodyModel/AnimationPlayer")

@export_group("Movement")
@export var move_speed: float = 4.5
@export var run_speed: float = 7.5
@export var gravity: float = 22.0
@export var jump_force: float = 7.0
@export var rotation_speed: float = 10.0
@export var snap_len: float = 0.2

@export_group("Anim Names")
@export var anim_idle: String = "Anim/Idle"
@export var anim_walk: String = "Anim/Walk"
@export var anim_run: String = "Anim/Runner"
@export var anim_jump: String = "Anim/Jump"
@export var blend_time: float = 0.12

@onready var anim: AnimationPlayer = get_node_or_null(animation_player_path)

func _ready() -> void:
	floor_snap_length = snap_len

func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_apply_move(delta)
	move_and_slide()
	_update_anim()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		# mantém “colado” no chão pra não ficar voando em pequenas irregularidades
		if velocity.y < 0.0:
			velocity.y = 0.0

	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = jump_force

func _apply_move(delta: float) -> void:
	var v2 := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	var dir := Vector3(v2.x, 0.0, v2.y).normalized()

	var target_speed := run_speed if Input.is_action_pressed("ui_shift") else move_speed

	if dir.length() > 0.001:
		velocity.x = dir.x * target_speed
		velocity.z = dir.z * target_speed

		var target_yaw := atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_yaw, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, target_speed)
		velocity.z = move_toward(velocity.z, 0.0, target_speed)

func _update_anim() -> void:
	if anim == null:
		return

	var name := anim_idle

	if not is_on_floor():
		name = anim_jump
	else:
		var flat_speed := Vector2(velocity.x, velocity.z).length()
		if flat_speed > 0.1:
			name = anim_run if flat_speed > (move_speed + run_speed) * 0.5 else anim_walk

	if anim.has_animation(name) and anim.current_animation != name:
		anim.play(name, blend_time)
