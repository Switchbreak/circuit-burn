extends VehicleBody3D

const ACCELERATE_FORCE := 150.0
const STEERING_AMOUNT := PI / 4

func _physics_process(_delta: float) -> void:
    if Input.is_action_pressed("drive_accelerate"):
        engine_force = ACCELERATE_FORCE
    elif Input.is_action_pressed("drive_brake"):
        engine_force = -ACCELERATE_FORCE
    else:
        engine_force = 0.0

    if Input.is_action_pressed("drive_steer_left"):
        steering = STEERING_AMOUNT
    elif Input.is_action_pressed("drive_steer_right"):
        steering = -STEERING_AMOUNT
    else:
        steering = 0
