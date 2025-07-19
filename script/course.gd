extends Node3D

var car_scene := preload("res://entities/car.tscn")

@onready var lap_counter := $HUD/LapCounter

@export var spawn_markers: Array[SpawnMarker]
@export var checkpoints: Array[Area3D]

func _ready() -> void:
    for index in spawn_markers.size():
        _spawn_car(spawn_markers[index], "p%d" % (index + 1), index == 0)

    for index in checkpoints.size():
        checkpoints[index].body_entered.connect(_on_checkpoint_entered.bind(index))

func _spawn_car(spawn_marker: SpawnMarker, input_prefix: String, player_car: bool) -> void:
    var car := car_scene.instantiate()

    car.input_prefix = input_prefix
    car.spawn_location = spawn_marker
    car.camera_following = player_car
    car.bot = !player_car
    car.color = spawn_marker.color

    if player_car:
        $FollowCamera.follow_target = car

    add_child(car)

func _on_checkpoint_entered(body: Node3D, checkpoint_index: int) -> void:
    if body is Car:
        print_debug("Car hit checkpoint %d" % checkpoint_index)

        if body.checkpoint == checkpoint_index:
            body.checkpoint += 1
            if body.checkpoint >= checkpoints.size():
                _complete_lap(body)

func _complete_lap(car: Car) -> void:
    car.checkpoint = 0
    car.lap += 1

    if car.camera_following:
        lap_counter.text = "Lap: %d" % car.lap
