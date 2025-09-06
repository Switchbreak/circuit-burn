extends Node3D

var car_scene := preload("res://entities/car.tscn")

@onready var lap_counter := $HUD/LapCounter
@onready var placement := $HUD/Placement
@onready var placement_outline := $HUD/PlacementOutline

@export var spawn_markers: Array[SpawnMarker]
@export var checkpoints: Array[Area3D]

var cars: Array[Car]

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

    cars.append(car)
    add_child(car)

func _physics_process(_delta: float) -> void:
    _set_placements()

func _set_placements() -> void:
    cars.sort_custom(func(a: Car, b: Car): return a.offset > b.offset)

    for index in cars.size():
        cars[index].placement = index + 1
        if cars[index].camera_following:
            var place := _numeric_to_ordinal(index + 1)
            placement.text = place
            placement_outline.text = place

func _numeric_to_ordinal(num: int) -> String:
    var ones := num % 10
    var tens := num % 100 - ones
    var postfix := "th"

    if tens != 10:
        match ones:
            1:
                postfix = "st"
            2:
                postfix = "nd"
            3:
                postfix = "rd"

    return str(num) + postfix

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
