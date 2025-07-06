extends Node3D

var car_scene := preload("res://car.tscn")

@export var spawn_markers: Array[SpawnMarker]

func _ready() -> void:
    for index in spawn_markers.size():
        _spawn_car(spawn_markers[index], "p%d" % (index + 1), index == 0)

func _spawn_car(spawn_marker: SpawnMarker, input_prefix: String, player_car: bool) -> void:
    var car := car_scene.instantiate()

    car.input_prefix = input_prefix
    car.spawn_location = spawn_marker
    car.camera_following = player_car
    car.color = spawn_marker.color

    if player_car:
        $FollowCamera.follow_target = car

    add_child(car)
