extends CharacterBody3D

@onready var navigation_agent := $NavigationAgent3D

var checkpoint_index: int = -1

func navigate_to_checkpoint() -> void:
    var checkpoint := owner.checkpoints[checkpoint_index] as Area3D

    navigation_agent.target_position = checkpoint.position

func _physics_process(_delta: float) -> void:
    if navigation_agent.is_navigation_finished():
        checkpoint_index = (checkpoint_index + 1) % owner.checkpoints.size()
        navigate_to_checkpoint()

    var next_position: Vector3 = navigation_agent.get_next_path_position()
    velocity = global_position.direction_to(next_position) * 2.0
    move_and_slide()
