@tool
extends Path3D

class_name RacingLine

@export var checkpoints: Array[Dictionary]

func add_point(position: Vector3, normal: Vector3) -> void:
    _add_checkpoint(normal)
    curve.add_point(position)

    notify_property_list_changed()

func _add_checkpoint(normal: Vector3) -> void:
    checkpoints.append({
        "width": 2.0,
        "offset": 0.0,
        "normal": normal,
        "required": false,
        "top_speed": 20.0,
    })

func remove_point(index: int) -> void:
    checkpoints.remove_at(index)
    curve.remove_point(index)

    notify_property_list_changed()

func _on_curve_changed() -> void:
    if curve.point_count < checkpoints.size():
        checkpoints.resize(curve.point_count)
        notify_property_list_changed()
    elif curve.point_count > checkpoints.size():
        for i in curve.point_count - checkpoints.size():
            _add_checkpoint(Vector3.UP)
        notify_property_list_changed()
