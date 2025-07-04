extends Camera3D

@export var follow_target: Node3D
@export_range(0, 100, 1, "or_less", "or_greater") var follow_distance: float = 10.0
@export_range(0, 5.0, 0.1, "or_less", "or_greater") var move_speed: float = 2.0
@export_range(0, 5.0, 0.1, "or_less", "or_greater") var orbit_speed: float = 2.0

const ROTATION_AMOUNT := PI / 4

func _process(delta: float) -> void:
    var target_rotation := follow_target.global_basis.rotated(follow_target.global_basis.y, PI).rotated(follow_target.global_basis.x, ROTATION_AMOUNT)
    global_basis = global_basis.slerp(target_rotation, orbit_speed * delta)

    var look_vector := -global_basis.z
    var target_position := follow_target.position - look_vector * follow_distance

    position = position.lerp(target_position, move_speed * delta)
