extends RigidBody3D

class_name Car

@onready var front_axle := $FrontAxle as Marker3D
@onready var mortar_launcher := $MortarLauncher as Marker3D
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
const CAMERA_SHAKE_MIN := 0.0
const CAMERA_SHAKE_MAX := 0.08
const CAMERA_SHAKE_SCALE := 0.06 / 30
const CAMERA_SHAKE_OFFSET := 0.005
const BOT_DRIVER_SPEED := 3.0
const MORTAR_VELOCITY := 15.0

var lap: int = 1
var checkpoint: int = 0
var _nav_checkpoint: int = -1
var _safe_velocity: Vector3 = Vector3.ZERO
var _mortar_shell := preload("res://entities/weapons/mortar_shell.tscn")

func _ready() -> void:
    set_color(color)
    _spawn_car()

    if bot:
        $Mortar.visible = false

func _physics_process(delta: float) -> void:
    if bot:
        _bot_navigation(delta)
    else:
        _apply_input_forces(delta)
    _apply_slip_correction(delta)

    if Input.is_action_just_released(input_prefix + "_reset_car"):
        _spawn_car()
    if Input.is_action_just_pressed(input_prefix + "_fire"):
        fire_mortar()

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

func set_color(new_color: Color) -> void:
    var cab := $CheckerCab/Car as MeshInstance3D
    var material := cab.get_surface_override_material(1).duplicate() as StandardMaterial3D

    material.albedo_color = new_color
    cab.set_surface_override_material(1, material)

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
    camera.shake_amount = clampf(CAMERA_SHAKE_SCALE * speed + CAMERA_SHAKE_OFFSET, CAMERA_SHAKE_MIN, CAMERA_SHAKE_MAX)

func _bot_navigation(delta: float) -> void:
    if navigation_agent.is_navigation_finished():
        _nav_checkpoint = (_nav_checkpoint + 1) % get_parent().checkpoints.size()
        _navigate_to_checkpoint()

    navigation_agent.velocity = linear_velocity
    var next_direction: Vector3 = navigation_agent.get_next_path_position() - global_position # _safe_velocity
    var slip := next_direction.dot(global_basis.x)
    var speed := linear_velocity.length()

    # accelerate
    if speed < BOT_DRIVER_SPEED:
        apply_central_force(global_basis.z * ACCELERATION_AMOUNT * delta)

    if slip > 0:
        apply_force(global_basis.x * STEERING_AMOUNT * delta, front_axle.global_position - global_position)
    elif slip < 0:
        apply_force(-global_basis.x * STEERING_AMOUNT * delta, front_axle.global_position - global_position)

func _navigate_to_checkpoint() -> void:
    var checkpoint_area := get_parent().checkpoints[_nav_checkpoint] as Area3D
    navigation_agent.target_position = checkpoint_area.position

func _on_velocity_computed(safe_velocity: Vector3) -> void:
    _safe_velocity = safe_velocity

func fire_mortar() -> void:
    var mortar_shell: RigidBody3D = _mortar_shell.instantiate()
    mortar_shell.linear_velocity = linear_velocity

    get_parent().add_child(mortar_shell)
    mortar_shell.global_position = mortar_launcher.global_position
    mortar_shell.global_rotation = mortar_launcher.global_rotation
    mortar_shell.apply_central_impulse(mortar_shell.global_basis.z * MORTAR_VELOCITY)

    print_debug('Mortar shell fired')
