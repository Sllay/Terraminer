extends Camera3D

@export var target_path: NodePath = NodePath("../Player") # ajuste se o node tiver outro nome
@export var offset: Vector3 = Vector3(0.0, 2.5, 8.0)      # câmera “de lado”/“de frente” dependendo do seu setup
@export var follow_speed: float = 12.0
@export var lock_z: bool = true

var target: Node3D

func _ready() -> void:
	target = get_node_or_null(target_path) as Node3D

func _process(delta: float) -> void:
	if target == null:
		return

	var desired: Vector3 = target.global_position + offset

	if lock_z:
		desired.z = global_position.z

	global_position = global_position.lerp(desired, 1.0 - exp(-follow_speed * delta))

	# opcional: olhar pro player (se quiser câmera fixa, remova)
	look_at(target.global_position, Vector3.UP)
