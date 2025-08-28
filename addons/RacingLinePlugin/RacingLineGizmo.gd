@tool
extends EditorNode3DGizmoPlugin

func _get_gizmo_name() -> String:
    return "Racing Line Gizmo"

func _has_gizmo(for_node_3d: Node3D) -> bool:
    return for_node_3d is RacingLine

func _init() -> void:
    create_material("main", Color.YELLOW, false, true)

func _redraw(gizmo: EditorNode3DGizmo) -> void:
    gizmo.clear()

    var racing_line := gizmo.get_node_3d() as RacingLine

    var lines = PackedVector3Array()

    for i in racing_line.curve.point_count:
        var next_index := i + 1
        if i >= racing_line.curve.point_count - 1:
            next_index = max(i - 1, 0)

        var checkpoint := racing_line.checkpoints[i]

        var position := racing_line.curve.get_point_position(i)
        var next_position := (racing_line.curve.get_point_position(next_index) - position).normalized()
        var orthonormal: Vector3 = next_position.cross(checkpoint.normal)

        lines.append(position - orthonormal * (checkpoint.width / 2.0 - checkpoint.offset))
        lines.append(position + orthonormal * (checkpoint.width / 2.0 + checkpoint.offset))

    gizmo.add_lines(lines, get_material("main", gizmo), false)
