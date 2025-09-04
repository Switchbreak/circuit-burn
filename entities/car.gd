extends VehicleBody3D

class_name Car

enum WEAPON {
    NONE,
    ROCKET,
    MORTAR,
    MINE,
    PUNCH,
    KICK
}

const HALF_PI := PI / 2.0
const QUARTER_PI := PI / 4.0

const FOV_FACTOR := 5.0
const MIN_FOV := 75.0
const MAX_FOV := 90.0
const FOV_LERP_SPEED := 0.2
const CAMERA_SHAKE_MIN := 0.0
const CAMERA_SHAKE_MAX := 0.08
const CAMERA_SHAKE_SCALE := 0.06 / 30
const CAMERA_SHAKE_OFFSET := 0.005

const BOT_DRIVER_SPEED := 40.0
const BOT_DRIVER_MIN_SPEED := 3.0
const V_OFFSET := 10.0

const MORTAR_VELOCITY := 15.0
const ROCKET_VELOCITY := 30.0
const ROCKET_RECOIL := 2000.0
const PUNCH_VELOCITY := 10000.0
const KICK_VELOCITY := 30000.0
const PUNCH_FOV := 120.0
const PUNCH_DURATION := 0.5

const DOWNFORCE_AMOUNT := 10000.0
const TOP_SPEED := 40.0
const GEAR_COUNT := 4
const PROPORTIONAL_TOP_SPEED := 30.0
const MIN_STEERING := 0.15

@onready var wheel_fl := $WheelFL as VehicleWheel3D
@onready var wheel_fr := $WheelFR as VehicleWheel3D
@onready var wheel_rl := $WheelRL as VehicleWheel3D
@onready var wheel_rr := $WheelRR as VehicleWheel3D
@onready var front_axle := $FrontAxle as Marker3D
@onready var mortar := $Mortar
@onready var rocket_equip := $Rocket
@onready var mortar_launcher := $MortarLauncher as Marker3D
@onready var mine_location := $MineLocation as Marker3D
@onready var rocket_launcher := $RocketLauncher as Marker3D
@onready var debug_arrow := $DebugArrow as Node3D
@onready var brakelight_l := $BrakelightL
@onready var brakelight_r := $BrakelightR
@onready var trail_l := $TrailL
@onready var trail_r := $TrailR
@onready var motion_blur := ($"../%FollowCamera/MotionBlur" as MeshInstance3D).get_surface_override_material(0) as ShaderMaterial
@onready var melee_collider := $MeleeCollider
@onready var racing_line := $"../%RacingLine" as RacingLine
@onready var engine_sound := $EngineSound
@onready var impact_sound := $ImpactSound
@onready var audio_listener := $AudioListener3D

@export_enum("p1", "p2") var input_prefix := "p1"

@export var spawn_location: Marker3D
@export var camera_following: bool = true
@export var bot: bool = false
@export var color: Color = Color.WHITE

@export_range(0.0, 5000.0) var acceleration := 10000.0
@export_range(0.0, 5.0) var braking_factor := 2.0
@export_range(0.0, HALF_PI, 0.01) var steering_amount := QUARTER_PI
@export_range(1.0, 5.0) var steering_speed := 3.0
@export_range(0.0, 1.0) var rear_friction := 0.7
@export_range(0.0, 1.0) var rear_friction_handbrake := 0.2

var lap: int = 1
var equipped: int = WEAPON.NONE
var checkpoint: int = 0: set = _set_checkpoint
var ammunition: int = 0
var invulnerable: bool = false
var _safe_velocity: Vector3 = Vector3.ZERO

var speed := 0.0
var previous_speed := 0.0
var rpm := 0.4
var gear := 0

var bot_speed: float = BOT_DRIVER_SPEED
var bot_speed_ratio: float = 1.0
var h_offset := 0.0
var ticks := 300

var _mortar_shell := preload("res://entities/weapons/mortar_shell.tscn")
var _rocket := preload("res://entities/weapons/rocket.tscn")
var _mine := preload("res://entities/weapons/mine.tscn")

func _ready() -> void:
    set_color(color)
    _spawn_car()

    engine_sound.play()

    if not bot:
        debug_arrow.visible = false
        audio_listener.make_current()

func _physics_process(delta: float) -> void:
    previous_speed = speed
    speed = linear_velocity.length()

    if bot:
        _bot_navigation(delta)
    else:
        _vehicle_body_input(delta)
        _weapon_input()
        _special_input()

    engine_noise(delta)
    if camera_following:
        _camera_speed_effects()

    resting_friction_workaround(delta)
    apply_downforce()

func engine_noise(delta: float) -> void:
    if absf(engine_force) > 0.0 or speed >= TOP_SPEED - 10.0:
        rpm = minf(1.0, rpm + delta * 0.1)
    else:
        rpm = move_toward(rpm, 0.4, delta * 0.5)

    var new_gear := mini(ceili(speed / (TOP_SPEED / GEAR_COUNT + 5)), GEAR_COUNT)
    if new_gear > gear:
        rpm = 0.7
    gear = new_gear

    var pitch_scale = rpm
    engine_sound.pitch_scale = pitch_scale

    if absf(speed - previous_speed) > 5.0:
        impact_sound.volume_db = -40
        impact_sound.play()

func is_stopped_or_reversing() -> bool:
    return linear_velocity.dot(basis.z) <= 5.0

func is_at_rest() -> bool:
    return absf(linear_velocity.dot(basis.z)) <= 0.5 \
        and wheel_fl.is_in_contact() \
        and wheel_fr.is_in_contact() \
        and wheel_rl.is_in_contact() \
        and wheel_rr.is_in_contact()

func _vehicle_body_input(delta: float) -> void:
    brake = 0.0
    engine_force = 0.0
    brakelight_l.modulate = Color(1.0, 1.0, 1.0)
    brakelight_r.modulate = Color(1.0, 1.0, 1.0)

    if Input.is_action_pressed(input_prefix + "_drive_accelerate") and speed <= TOP_SPEED:
        engine_force = acceleration
    elif Input.is_action_pressed(input_prefix + "_drive_brake"):
        brakelight_l.modulate = Color(1.0, 0.0, 0.0)
        brakelight_r.modulate = Color(1.0, 0.0, 0.0)
        if is_stopped_or_reversing():
            engine_force = -acceleration
        else:
            brake = 50.0

    var steering_target := 0.0
    var adjusted_steering := maxf(steering_amount * (1.0 - (minf(speed, PROPORTIONAL_TOP_SPEED) / PROPORTIONAL_TOP_SPEED)), MIN_STEERING)
    if Input.is_action_pressed(input_prefix + "_drive_steer_left"):
        steering_target = adjusted_steering
    elif Input.is_action_pressed(input_prefix + "_drive_steer_right"):
        steering_target = -adjusted_steering
    steering = move_toward(steering, steering_target, delta * steering_speed)

    #if Input.is_action_pressed(input_prefix + "_fire"):
        #wheel_rl.wheel_friction_slip = rear_friction_handbrake
        #wheel_rr.wheel_friction_slip = rear_friction_handbrake
    #else:
        #wheel_rl.wheel_friction_slip = rear_friction
        #wheel_rr.wheel_friction_slip = rear_friction

func _weapon_input() -> void:
    if Input.is_key_pressed(KEY_E):
        equip_weapon(WEAPON.ROCKET)
        ammunition = 100
    elif Input.is_key_pressed(KEY_Q):
        equip_weapon(WEAPON.MORTAR)
        ammunition = 100

    if Input.is_action_just_pressed(input_prefix + "_fire") and ammunition > 0:
        match equipped:
            WEAPON.MORTAR:
                fire_mortar()
            WEAPON.ROCKET:
                fire_rocket()
            WEAPON.MINE:
                fire_mine()
            WEAPON.PUNCH:
                fire_punch()
            WEAPON.KICK:
                fire_kick()

        ammunition -= 1
        if ammunition <= 0:
            equip_weapon(WEAPON.NONE)

func _special_input() -> void:
    if Input.is_action_just_released(input_prefix + "_reset_car"):
        _respawn_car()

func resting_friction_workaround(delta: float) -> void:
    if engine_force == 0.0 and is_at_rest():
        linear_damp = move_toward(linear_damp, 25.0, delta * 10.0)
    else:
        linear_damp = 0.0

func apply_downforce() -> void:
    if wheel_fl.is_in_contact() || wheel_fr.is_in_contact() || wheel_rl.is_in_contact() || wheel_rr.is_in_contact():
        var force_amount := DOWNFORCE_AMOUNT * (minf(speed, PROPORTIONAL_TOP_SPEED) / PROPORTIONAL_TOP_SPEED)
        apply_central_force(-global_basis.y * force_amount)

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

    if bot:
        _set_bot_line()

func _respawn_car() -> void:
    var target_offset := racing_line.curve.get_closest_offset(global_position - racing_line.global_position)
    var target_transform := racing_line.curve.sample_baked_with_rotation(target_offset - V_OFFSET)

    position = target_transform.origin
    quaternion = target_transform.basis.rotated(target_transform.basis.y, PI).get_rotation_quaternion()

    linear_velocity = Vector3.ZERO
    angular_velocity = Vector3.ZERO
    reset_physics_interpolation()

    if bot:
        _set_bot_line()

func _set_bot_line(randomize_offset: bool = false) -> void:
    if randomize_offset:
        h_offset = randf_range(-2.5, 2.5)
    else:
        var target_point := racing_line.curve.get_closest_point(global_position - racing_line.global_position) + racing_line.global_position
        var projected := global_basis.x.dot(target_point - global_position)
        h_offset = projected / 2.0

    bot_speed_ratio = randf_range(0.7, 1.0)
    ticks = randi_range(120, 300)

func _set_checkpoint(set_checkpoint: int) -> void:
    checkpoint = set_checkpoint

func _camera_speed_effects() -> void:
    var camera := get_viewport().get_camera_3d()
    var target_fov := camera.fov
    var target_shake_amount: float

    if invulnerable:
        target_fov = PUNCH_FOV
        target_shake_amount = CAMERA_SHAKE_MAX
        camera.follow_distance = 1.0
        motion_blur.set_shader_parameter("intensity", 1.0)
    else:
        target_fov = clampf(speed * FOV_FACTOR, MIN_FOV, MAX_FOV)
        target_shake_amount = clampf(CAMERA_SHAKE_SCALE * speed + CAMERA_SHAKE_OFFSET, CAMERA_SHAKE_MIN, CAMERA_SHAKE_MAX)
        camera.follow_distance = 10.0
        motion_blur.set_shader_parameter("intensity", 0.28)

    camera.fov = lerpf(camera.fov, target_fov, FOV_LERP_SPEED)
    camera.shake_amount = lerpf(camera.shake_amount, target_shake_amount, FOV_LERP_SPEED)

func _bot_navigation(delta: float) -> void:
    var target_offset := racing_line.curve.get_closest_offset(global_position - racing_line.global_position)
    var target_transform := racing_line.curve.sample_baked_with_rotation(target_offset + V_OFFSET)
    var target_point := target_transform.origin + target_transform.basis.x * h_offset
    debug_arrow.look_at(target_point, global_basis.y, true)

    var steering_target := global_basis.z.signed_angle_to(target_point - global_position, global_basis.y)
    steering = move_toward(steering, clampf(steering_target, -QUARTER_PI, QUARTER_PI), delta * steering_speed)

    var turn_speed_ratio := 1.0 - absf(steering_target / HALF_PI)
    var target_speed := maxf(bot_speed * turn_speed_ratio * bot_speed_ratio, BOT_DRIVER_MIN_SPEED)

    # Hack to go faster before the jump
    if target_offset > 1200 and target_offset < 1500:
        target_speed = 45.0

    if speed < target_speed:
        engine_force = acceleration
    else:
        engine_force = 0

    ticks -= 1
    if ticks <= 0 and target_speed < 45.0:
        _set_bot_line(true)

func _on_velocity_computed(safe_velocity: Vector3) -> void:
    _safe_velocity = safe_velocity

func equip_weapon(weapon_type: WEAPON) -> void:
    equipped = weapon_type

    mortar.visible = false
    rocket_equip.visible = false
    match equipped:
        Car.WEAPON.MORTAR:
            mortar.visible = true
            ammunition = 3
        Car.WEAPON.ROCKET:
            rocket_equip.visible = true
            ammunition = 4
        Car.WEAPON.MINE:
            ammunition = 2
        Car.WEAPON.PUNCH:
            ammunition = 1
        Car.WEAPON.KICK:
            ammunition = 1

func fire_mortar() -> void:
    var mortar_shell: RigidBody3D = _mortar_shell.instantiate()
    mortar_shell.linear_velocity = linear_velocity

    get_parent().add_child(mortar_shell)
    mortar_shell.global_position = mortar_launcher.global_position
    mortar_shell.global_rotation = mortar_launcher.global_rotation
    mortar_shell.apply_central_impulse(mortar_shell.global_basis.z * MORTAR_VELOCITY)

    print_debug('Mortar shell fired')

func fire_rocket() -> void:
    apply_central_impulse(-global_basis.z * ROCKET_RECOIL)

    var rocket: RigidBody3D = _rocket.instantiate()
    rocket.linear_velocity = linear_velocity

    get_parent().add_child(rocket)
    rocket.global_position = rocket_launcher.global_position
    rocket.global_rotation = rocket_launcher.global_rotation
    rocket.apply_central_impulse(rocket.global_basis.z * ROCKET_VELOCITY)

    print_debug('Rocket fired')

func fire_mine() -> void:
    var mine: RigidBody3D = _mine.instantiate()

    get_parent().add_child(mine)
    mine.global_position = mine_location.global_position
    mine.global_rotation = mine_location.global_rotation

    mine.apply_central_impulse(-mine.global_basis.y * 5.0)
    mine.angular_velocity = -mine.global_basis.x * 3.0

    print_debug('Mine laid')

func fire_punch() -> void:
    apply_central_impulse(global_basis.z * PUNCH_VELOCITY)

    invulnerable = true
    set_collision_mask_value(2, false)
    melee_collider.process_mode = Node.PROCESS_MODE_INHERIT
    trail_l.emitting = true
    trail_r.emitting = true

    await get_tree().create_timer(0.5).timeout

    invulnerable = false
    melee_collider.process_mode = Node.PROCESS_MODE_DISABLED
    set_collision_mask_value(2, true)
    trail_l.emitting = false
    trail_r.emitting = false

    print_debug('Punch fired')

func fire_kick() -> void:
    apply_central_impulse(global_basis.x * KICK_VELOCITY)

    invulnerable = true
    set_collision_mask_value(2, false)
    melee_collider.process_mode = Node.PROCESS_MODE_INHERIT
    trail_l.emitting = true
    trail_r.emitting = true

    await get_tree().create_timer(0.2).timeout

    invulnerable = false
    melee_collider.process_mode = Node.PROCESS_MODE_DISABLED
    set_collision_mask_value(2, true)
    trail_l.emitting = false
    trail_r.emitting = false

    print_debug('Kick fired')

func _on_melee_collider_body_entered(body: Node3D) -> void:
    var camera = get_viewport().get_camera_3d()
    camera.shake_amount = 1.0

    body.apply_impulse(Vector3.UP * 5000.0, global_position - body.global_position)
