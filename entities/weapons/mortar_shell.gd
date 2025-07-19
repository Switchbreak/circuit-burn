extends RigidBody3D

@onready var explosion := $Explosion
@onready var explosion_area := $ExplosionArea
@onready var mesh := $Mesh

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

    explosion_area.process_mode = Node.PROCESS_MODE_ALWAYS
    process_mode = Node.PROCESS_MODE_DISABLED
    await get_tree().create_timer(0.5).timeout

    queue_free()
