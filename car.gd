extends RigidBody3D

@onready var front_axle := $FrontAxle as Marker3D
@onready var spawn_location := owner.find_child("SpawnMarker") as Marker3D

const ACCELERATION_AMOUNT := 1000000.0
const STEERING_AMOUNT := 250000.0

func _ready() -> void:
    _spawn_car()

func _physics_process(delta: float) -> void:
    _apply_input_forces(delta)
    _apply_slip_correction(delta)

    if Input.is_action_just_released("reset_car"):
        _spawn_car()

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

func _spawn_car() -> void:
    position = spawn_location.position
    rotation = spawn_location.rotation

    linear_velocity = Vector3.ZERO
    angular_velocity = Vector3.ZERO
    reset_physics_interpolation()
