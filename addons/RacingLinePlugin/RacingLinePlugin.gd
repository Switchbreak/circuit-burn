@tool
extends EditorPlugin

var gizmo = preload("res://addons/RacingLinePlugin/RacingLineGizmo.gd").new()

func _enter_tree() -> void:
    add_node_3d_gizmo_plugin(gizmo)

    var inspector = EditorInterface.get_inspector()
    inspector.property_edited.connect(_on_property_edited)

func _exit_tree() -> void:
    remove_node_3d_gizmo_plugin(gizmo)

    var inspector = EditorInterface.get_inspector()
    if inspector.property_edited.is_connected(_on_property_edited):
        inspector.property_edited.disconnect(_on_property_edited)

func _handles(object: Object) -> bool:
    return object is RacingLine

func _forward_3d_gui_input(viewport_camera: Camera3D, event: InputEvent) -> int:
    if not (event is InputEventMouse and event.button_mask & MOUSE_BUTTON_MASK_LEFT):
        return EditorPlugin.AFTER_GUI_INPUT_PASS

    if not event.alt_pressed:
        return EditorPlugin.AFTER_GUI_INPUT_PASS

    var ray_origin = viewport_camera.project_ray_origin(event.position)
    var ray_end = ray_origin + viewport_camera.project_ray_normal(event.position) * 1000.0
    var space_state = viewport_camera.get_world_3d().direct_space_state

    var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
    var result = space_state.intersect_ray(query)

    if not result.is_empty():
        var position = result.position + result.normal * 0.01

        if event.is_pressed():
            _add_control_point(position, result.normal)
        else:
            # Modify width and offset here
            _move_control_point(position)

    return EditorPlugin.AFTER_GUI_INPUT_STOP

func _add_control_point(position: Vector3, normal: Vector3) -> void:
    var editor_interface := get_editor_interface()
    var path_node := EditorInterface.get_selection().get_selected_nodes()[0] as RacingLine
    if path_node == null:
        print("Path not found")
        return

    var undo_redo = get_undo_redo()
    undo_redo.create_action("Add Point to Path3D on surface")
    undo_redo.add_do_method(path_node, "add_point", position, normal)

    var index = path_node.curve.point_count
    undo_redo.add_undo_method(path_node, "remove_point", index)

    undo_redo.commit_action()

func _move_control_point(position: Vector3) -> void:
    var editor_interface = get_editor_interface()
    var path_node = editor_interface.get_selection().get_selected_nodes()[0] as Path3D
    if path_node == null:
        print("Path not found")
        return

    var index = path_node.curve.point_count - 1
    path_node.curve.set_point_position(index, position)

func _on_property_edited(prop: String) -> void:
    if prop == "checkpoints":
        var path_node := EditorInterface.get_selection().get_selected_nodes()[0] as RacingLine
        if path_node == null:
            print("Path not found")
            return

        path_node.update_gizmos()
