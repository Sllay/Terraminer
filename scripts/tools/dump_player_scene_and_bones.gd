extends Node

@export var player_scene_path: String = "res://scenes/player.tscn"
@export var skeleton_unique_path: NodePath = NodePath("%GeneralSkeleton")
@export var skeleton_fallback_path: NodePath = NodePath("BodyModel/Armature/GeneralSkeleton")

func _ready() -> void:
	var out_path := "user://player_dump.txt"
	var out_abs := ProjectSettings.globalize_path(out_path)

	var lines: PackedStringArray = []
	lines.append("DUMP FILE: " + out_abs)
	lines.append("PLAYER SCENE: " + player_scene_path)
	lines.append("")

	var packed := load(player_scene_path)
	if packed == null:
		lines.append("ERROR: failed to load PackedScene.")
		_write(out_path, lines)
		return

	var inst := (packed as PackedScene).instantiate()
	add_child(inst)

	lines.append("== PLAYER SCENE TREE ==")
	_dump_tree(inst, lines, 0)
	lines.append("")

	var sk: Skeleton3D = inst.get_node_or_null(skeleton_unique_path) as Skeleton3D
	if sk == null:
		sk = inst.get_node_or_null(skeleton_fallback_path) as Skeleton3D

	if sk == null:
		lines.append("ERROR: Skeleton not found using:")
		lines.append("  unique: " + str(skeleton_unique_path))
		lines.append("  fallback: " + str(skeleton_fallback_path))
		_write(out_path, lines)
		return

	lines.append("== SKELETON FOUND ==")
	lines.append("Skeleton node path: " + str(sk.get_path()))
	lines.append("Bone count: " + str(sk.get_bone_count()))
	lines.append("")

	lines.append("== BONE LIST (index -> name) ==")
	var count := sk.get_bone_count()
	var i := 0
	while i < count:
		lines.append(str(i) + " -> " + String(sk.get_bone_name(i)))
		i += 1

	_write(out_path, lines)

func _dump_tree(n: Node, lines: PackedStringArray, depth: int) -> void:
	var indent := "    ".repeat(depth)
	lines.append(indent + n.name + " : " + n.get_class() + "  (" + str(n.get_path()) + ")")
	for c in n.get_children():
		_dump_tree(c, lines, depth + 1)

func _write(path: String, lines: PackedStringArray) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_error("Failed to open file: " + path)
		return
	f.store_string("
".join(lines))
	f.close()
	print("Wrote dump to: ", ProjectSettings.globalize_path(path))
