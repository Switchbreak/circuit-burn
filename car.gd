extends RigidBody3D

@onready var front_axle := $FrontAxle as Marker3D

@export_enum("p1", "p2") var input_prefix := "p1"
@export var spawn_location: Marker3D
@export var camera_following: bool = true

const ACCELERATION_AMOUNT := 1000000.0
const STEERING_AMOUNT := 250000.0

const FOV_FACTOR := 5.0
const MIN_FOV := 75.0
const MAX_FOV := 90.0
const FOV_LERP_SPEED := 0.2

func _ready() -> void:
    _spawn_car()

func _physics_process(delta: float) -> void:
    _apply_input_forces(delta)
    _apply_slip_correction(delta)

    if Input.is_action_just_released(input_prefix + "_reset_car"):
        _spawn_car()

    if camera_following:
        _camera_speed_effects()

func _apply_input_forces(delta: float) -> void:
    if Input.is_action_pressed(input_prefix + "_drive_accelerate"):
        apply_central_force(global_basis.z * ACCELERATION_AMOUNT * delta)
    elif Input.is_action_pressed(input_prefix + "_drive_brake"):
        apply_central_force(-global_basis.z * ACCELERATION_AMOUNT * delta)

    if Input.is_action_pressed(input_prefix + "_drive_steer_left"):
        apply_force(global_basis.x * STEERING_AMOUNT * delta, front_axle.global_position - global_position)
    elif Input.is_action_pressed(input_prefix + "_drive_steer_right"):
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

func _camera_speed_effects() -> void:
    var speed := linear_velocity.length()
    var camera := get_viewport().get_camera_3d()
    var target_fov := clampf(speed * FOV_FACTOR, MIN_FOV, MAX_FOV)

    camera.fov = lerpf(camera.fov, target_fov, FOV_LERP_SPEED)
    camera.shake_amount = clampf(0.06 * speed / 30 + 0.005, 0.0, 0.08)
