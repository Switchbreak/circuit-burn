extends Node3D

@onready var flash = $Flash
@onready var sparks = $Sparks
@onready var fire = $Fire
@onready var smoke = $Smoke
@onready var light = $OmniLight3D
@onready var blast = $Blast

func explode() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    visible = true
    light.visible = true

    flash.restart()
    sparks.restart()
    fire.restart()
    smoke.restart()
    blast.play()

func _on_finished() -> void:
    queue_free()
