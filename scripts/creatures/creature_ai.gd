extends CharacterBody3D

class_name CreatureAI

@export var move_speed: float = 5.0
@export var gravity: float = 9.8
@export var wander_range: float = 10.0

var wander_timer: float = 0.0
var wander_direction: Vector3 = Vector3.FORWARD

func _physics_process(delta: float) -> void:
  velocity.y -= gravity * delta
  
  wander_timer -= delta
  if wander_timer <= 0:
    wander_direction = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
    wander_timer = randf_range(2, 5)
  
  velocity.x = wander_direction.x * move_speed
  velocity.z = wander_direction.z * move_speed
  
  move_and_slide()
