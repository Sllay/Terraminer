extends CharacterBody3D

@export var plane_z: float = 0.0
@export var lock_rotation_xz: bool = true

func _ready() -> void:
    global_position.z = plane_z

func _physics_process(_delta: float) -> void:
    global_position.z = plane_z
    velocity.z = 0.0

    if lock_rotation_xz:
        rotation.x = 0.0
        rotation.z = 0.0
