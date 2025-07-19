extends Node3D

@onready var flash = $Flash
@onready var sparks = $Sparks
@onready var fire = $Fire
@onready var smoke = $Smoke

func explode() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = true

    flash.restart()
    sparks.restart()
    fire.restart()
    smoke.restart()

func _on_finished() -> void:
    queue_free()
