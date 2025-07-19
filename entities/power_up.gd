extends Node3D

@export var type: Car.WEAPON = Car.WEAPON.MORTAR
@export_range(0.0, 1.0, 0.1, "or_greater") var bob_amount := 0.5
@export_range(0.0, 5.0, 0.1, "or_greater") var bob_speed := 2.0
@export_range(0.0, 10.0, 0.1, "or_greater") var respawn_time := 5.0

var phase := 0.0
var bob_direction := 1.0

@onready var home_position := position
@onready var mesh := $MeshInstance3D
@onready var area := $Area3D
@onready var icon := $Sprite3D
@onready var light := $OmniLight3D
@onready var break_anim := $Break

func _ready() -> void:
    match type:
        Car.WEAPON.MORTAR:
            icon.texture = load("res://mortar.svg")
        Car.WEAPON.ROCKET:
            icon.texture = load("res://rocket.svg")
        Car.WEAPON.MINE:
            icon.texture = load("res://landmine.svg")

func _process(delta: float) -> void:
    phase = fmod(phase + delta * bob_speed, 2 * PI)
    var offset := sin(phase) * bob_amount

    position.y = home_position.y + offset

func _on_collected(body: Node3D) -> void:
    if body is Car:
        collect.call_deferred(body)

func collect(car: Car) -> void:
    mesh.visible = false
    icon.visible = false
    light.visible = false

    break_anim.restart()
    area.process_mode = Node.PROCESS_MODE_DISABLED

    car.equip_weapon(type)

    respawn_timer()

func respawn_timer() -> void:
    await get_tree().create_timer(5.0).timeout

    mesh.visible = true
    icon.visible = true
    light.visible = true
    area.process_mode = Node.PROCESS_MODE_INHERIT
