extends RigidBody3D

@onready var explosion := $Explosion
@onready var explosion_area := $ExplosionArea
@onready var mesh := $Mesh

@export_range(1000.0, 10000.0, 500.0, "or_less", "or_greater") var explosion_strength := 5000.0

var _is_ready := false

func _physics_process(_delta: float) -> void:
    _is_ready = true
    global_basis.z = linear_velocity.normalized()

func detonate(_body: Node) -> void:
    if _is_ready:
        print_debug('Detonating mortar shell')
        explode.call_deferred()

func explode() -> void:
    mesh.visible = false
    explosion.explode()

    var camera = get_viewport().get_camera_3d()
    camera.shake_amount = 1.0

    var affected_bodies: Array[Node3D] = explosion_area.get_overlapping_bodies()
    for body: RigidBody3D in affected_bodies:
        if body is Car and body.invulnerable:
            continue
        else:
            body.apply_impulse(Vector3.UP * explosion_strength, global_position - body.global_position)

    process_mode = Node.PROCESS_MODE_DISABLED
    await get_tree().create_timer(0.5).timeout
    queue_free()
