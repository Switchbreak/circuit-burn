extends RigidBody3D

class_name Car

@onready var front_axle := $FrontAxle as Marker3D
@onready var navigation_agent := $NavigationAgent3D

@export_enum("p1", "p2") var input_prefix := "p1"
@export var spawn_location: Marker3D
@export var camera_following: bool = true
@export var bot: bool = false
@export var color: Color = Color.WHITE

const ACCELERATION_AMOUNT := 1000000.0
const STEERING_AMOUNT := 250000.0

const FOV_FACTOR := 5.0
const MIN_FOV := 75.0
const MAX_FOV := 90.0
const FOV_LERP_SPEED := 0.2

var lap: int = 1
var checkpoint: int = 0
var _nav_checkpoint: int = -1

func _ready() -> void:
    var cab := $CheckerCab/Car as MeshInstance3D
    var material := cab.get_surface_override_material(1).duplicate() as StandardMaterial3D
    material.albedo_color = color
    cab.set_surface_override_material(1, material)

    _spawn_car()

func _physics_process(delta: float) -> void:
    if bot:
        _bot_navigation(delta)
    else:
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
    checkpoint = 0

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

func _bot_navigation(delta: float) -> void:
    if navigation_agent.is_navigation_finished():
        _nav_checkpoint = (_nav_checkpoint + 1) % owner.checkpoints.size()
        _navigate_to_checkpoint()

    var next_direction: Vector3 = navigation_agent.get_next_path_position() - global_position
    var slip := next_direction.dot(global_basis.x)
    var speed := linear_velocity.length()

    # accelerate
    if speed < 2.0:
        apply_central_force(global_basis.z * ACCELERATION_AMOUNT * delta)

    if slip > 0:
        apply_force(global_basis.x * STEERING_AMOUNT * delta, front_axle.global_position - global_position)
    elif slip < 0:
        apply_force(-global_basis.x * STEERING_AMOUNT * delta, front_axle.global_position - global_position)

func _navigate_to_checkpoint() -> void:
    var checkpoint_area := owner.checkpoints[_nav_checkpoint] as Area3D
    navigation_agent.target_position = checkpoint_area.position
