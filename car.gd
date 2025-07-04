extends RigidBody3D

@onready var front_axle = $FrontAxle

const ACCELERATION_AMOUNT := 1000000.0
const STEERING_AMOUNT := 250000.0

func _physics_process(delta: float) -> void:
    _apply_input_forces(delta)
    _apply_slip_correction(delta)

func _apply_input_forces(delta: float) -> void:
    if Input.is_action_pressed("drive_accelerate"):
        apply_central_force(global_basis.z * ACCELERATION_AMOUNT * delta)
    elif Input.is_action_pressed("drive_brake"):
        apply_central_force(-global_basis.z * ACCELERATION_AMOUNT * delta)

    if Input.is_action_pressed("drive_steer_left"):
        apply_force(global_basis.x * STEERING_AMOUNT * delta, front_axle.global_position - global_position)
    elif Input.is_action_pressed("drive_steer_right"):
        apply_force(-global_basis.x * STEERING_AMOUNT * delta, front_axle.global_position - global_position)

func _apply_slip_correction(delta: float) -> void:
    var slip := linear_velocity.dot(global_basis.x)
    var lateral_correction := global_basis.x * -slip / delta
    apply_force(lateral_correction, front_axle.global_position - global_position)
