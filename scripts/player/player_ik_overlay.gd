extends Node3D

@export_group("Skeleton")
@export var skeleton_path: NodePath = NodePath("%GeneralSkeleton")

@export_group("Scene Nodes (Feet)")
@export var foot_ray_l_path: NodePath = NodePath("%FootRayL")
@export var foot_ray_r_path: NodePath = NodePath("%FootRayR")
@export var foot_target_l_path: NodePath = NodePath("%FootTargetL")
@export var foot_target_r_path: NodePath = NodePath("%FootTargetR")

@export_group("Scene Nodes (Wall/Hands)")
@export var wall_area_path: NodePath = NodePath("%WallArea")
@export var wall_ray_path: NodePath = NodePath("%WallRay")
@export var hand_target_l_path: NodePath = NodePath("%HandTargetL")
@export var hand_target_r_path: NodePath = NodePath("%HandTargetR")

@export_group("Bones (set to TARGET skeleton)")
@export var leg_root_l: String = ""
@export var leg_tip_l: String = ""
@export var leg_root_r: String = ""
@export var leg_tip_r: String = ""
@export var arm_root_l: String = ""
@export var arm_tip_l: String = ""
@export var arm_root_r: String = ""
@export var arm_tip_r: String = ""

@export_group("Tuning")
@export var foot_height_offset: float = 0.02
@export var max_snap_height: float = 1.2
@export var feet_influence_on_floor: float = 1.0
@export var feet_influence_in_air: float = 0.0
@export var hands_influence: float = 0.9
@export var influence_lerp_speed: float = 12.0
@export var hand_separation: float = 0.18

@onready var parent_body: CharacterBody3D = get_parent() as CharacterBody3D
@onready var sk: Skeleton3D = get_node_or_null(skeleton_path)

@onready var foot_ray_l: RayCast3D = get_node_or_null(foot_ray_l_path) as RayCast3D
@onready var foot_ray_r: RayCast3D = get_node_or_null(foot_ray_r_path) as RayCast3D
@onready var foot_target_l: Marker3D = get_node_or_null(foot_target_l_path) as Marker3D
@onready var foot_target_r: Marker3D = get_node_or_null(foot_target_r_path) as Marker3D

@onready var wall_area: Area3D = get_node_or_null(wall_area_path) as Area3D
@onready var wall_ray: RayCast3D = get_node_or_null(wall_ray_path) as RayCast3D
@onready var hand_target_l: Marker3D = get_node_or_null(hand_target_l_path) as Marker3D
@onready var hand_target_r: Marker3D = get_node_or_null(hand_target_r_path) as Marker3D

var ik_foot_l: SkeletonIK3D
var ik_foot_r: SkeletonIK3D
var ik_hand_l: SkeletonIK3D
var ik_hand_r: SkeletonIK3D

var cur_feet_influence: float = 0.0
var cur_hands_influence: float = 0.0

func _ready() -> void:
    if sk == null:
        push_error("IKOverlay: skeleton_path inválido: " + str(skeleton_path))
        return

    if foot_ray_l == null or foot_ray_r == null:
        push_warning("IKOverlay: FootRayL/FootRayR não encontrados. Sem foot IK.")
    if foot_target_l == null or foot_target_r == null:
        push_warning("IKOverlay: FootTargetL/FootTargetR não encontrados. Sem foot IK.")

    if wall_area == null:
        push_warning("IKOverlay: WallArea não encontrada. Hands IK só vai funcionar se você controlar o 'want_hands' de outra forma.")
    if wall_ray == null:
        push_warning("IKOverlay: WallRay não encontrado. Hands IK não vai ter ponto de toque.")
    if hand_target_l == null or hand_target_r == null:
        push_warning("IKOverlay: HandTargetL/HandTargetR não encontrados. Sem hands IK.")

    ik_foot_l = _make_ik("IKFootL", leg_root_l, leg_tip_l, foot_target_l)
    ik_foot_r = _make_ik("IKFootR", leg_root_r, leg_tip_r, foot_target_r)
    ik_hand_l = _make_ik("IKHandL", arm_root_l, arm_tip_l, hand_target_l)
    ik_hand_r = _make_ik("IKHandR", arm_root_r, arm_tip_r, hand_target_r)

func _physics_process(delta: float) -> void:
    if sk == null or parent_body == null:
        return

    # FEET influence
    var desired_feet: float = feet_influence_on_floor if parent_body.is_on_floor() else feet_influence_in_air
    cur_feet_influence = lerp(cur_feet_influence, desired_feet, delta * influence_lerp_speed)

    if ik_foot_l != null:
        ik_foot_l.set_influence(cur_feet_influence)
    if ik_foot_r != null:
        ik_foot_r.set_influence(cur_feet_influence)

    if foot_ray_l != null and foot_target_l != null:
        _update_foot_from_raycast(delta, foot_ray_l, foot_target_l)
    if foot_ray_r != null and foot_target_r != null:
        _update_foot_from_raycast(delta, foot_ray_r, foot_target_r)

    # HANDS influence
    var want_hands: bool = _wall_is_close()
    var desired_hands: float = hands_influence if want_hands else 0.0
    cur_hands_influence = lerp(cur_hands_influence, desired_hands, delta * influence_lerp_speed)

    if ik_hand_l != null:
        ik_hand_l.set_influence(cur_hands_influence)
    if ik_hand_r != null:
        ik_hand_r.set_influence(cur_hands_influence)

    if want_hands:
        _place_hands_on_wall(delta)

func _update_foot_from_raycast(delta: float, rc: RayCast3D, target: Marker3D) -> void:
    rc.force_raycast_update()
    if not rc.is_colliding():
        return

    var hit_pos: Vector3 = rc.get_collision_point()
    var foot_pos: Vector3 = rc.global_position
    var dy: float = hit_pos.y - foot_pos.y
    if abs(dy) > max_snap_height:
        return

    var desired: Vector3 = target.global_position
    desired.x = foot_pos.x
    desired.z = foot_pos.z
    desired.y = hit_pos.y + foot_height_offset
    target.global_position = target.global_position.lerp(desired, delta * 18.0)

func _wall_is_close() -> bool:
    if wall_area != null:
        # Se você preferir: use get_overlapping_bodies/areas e um filtro por grupo "wall"
        # Aqui é só um gatilho simples: qualquer overlap.
        if wall_area.has_overlapping_bodies() or wall_area.has_overlapping_areas():
            return true
    if wall_ray != null:
        wall_ray.force_raycast_update()
        return wall_ray.is_colliding()
    return false

func _place_hands_on_wall(delta: float) -> void:
    if wall_ray == null or hand_target_l == null or hand_target_r == null:
        return

    wall_ray.force_raycast_update()
    if not wall_ray.is_colliding():
        return

    var p: Vector3 = wall_ray.get_collision_point()

    # Em 2.5D geralmente separar as mãos no eixo "lado" do personagem (aqui usei basis.z).
    var side: Vector3 = parent_body.global_transform.basis.z.normalized()
    hand_target_l.global_position = hand_target_l.global_position.lerp(p - side * hand_separation, delta * 18.0)
    hand_target_r.global_position = hand_target_r.global_position.lerp(p + side * hand_separation, delta * 18.0)

func _make_ik(name: String, root: String, tip: String, target: Node3D) -> SkeletonIK3D:
    if target == null:
        return null
    if root == "" or tip == "":
        push_warning("IKOverlay: IK " + name + " não criado (root/tip vazio).")
        return null
    if sk.find_bone(root) == -1 or sk.find_bone(tip) == -1:
        push_warning("IKOverlay: IK " + name + " não criado (bones não existem no skeleton alvo). root=" + root + " tip=" + tip)
        return null

    var ik: SkeletonIK3D = SkeletonIK3D.new()
    ik.name = name
    sk.add_child(ik)
    ik.root_bone = root
    ik.tip_bone = tip
    ik.target_node = target.get_path()
    ik.start()
    ik.set_influence(0.0)
    return ik
