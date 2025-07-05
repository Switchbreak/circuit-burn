extends GPUParticles3D

const EPSILON := 0.001
const TIRE_TRACK_LENGTH := 4
var rate_scale := (self.lifetime / self.amount) / TIRE_TRACK_LENGTH

@onready var _previous_position := global_position
@onready var _car := get_parent() as RigidBody3D

func _process(delta: float) -> void:
    if _car.get_contact_count() > 0:
        var offset := global_position - _previous_position
        var distance := offset.length()
        var speed := distance / delta

        if distance > EPSILON:
            look_at(global_position + offset)

        speed_scale = speed * rate_scale
    else:
        speed_scale = 0

    _previous_position = global_position
