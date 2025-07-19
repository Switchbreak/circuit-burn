extends Node3D

@onready var mesh := $Mesh
@onready var animation_player := $Mesh/AnimationPlayer
@onready var explosion := $Explosion
@onready var explosion_area := $ExplosionArea

@export_range(1000.0, 10000.0, 500.0, "or_less", "or_greater") var explosion_strength := 5000.0

var _is_ready := false

func _ready() -> void:
    await get_tree().create_timer(1.2).timeout
    _is_ready = true
    animation_player.play("LandMine|On")

func detonate(_body: Node3D) -> void:
    if _is_ready:
        print_debug('Detonating mine')
        explode.call_deferred()

func explode() -> void:
    mesh.visible = false
    explosion.explode()

    var affected_bodies: Array[Node3D] = explosion_area.get_overlapping_bodies()
    for body: RigidBody3D in affected_bodies:
        body.apply_impulse(Vector3.UP * explosion_strength, global_position - body.global_position)

    process_mode = Node.PROCESS_MODE_DISABLED
    await get_tree().create_timer(0.5).timeout
    queue_free()
