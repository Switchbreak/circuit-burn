extends Node3D

func _ready() -> void:
    var heightmap_texture := ResourceLoader.load("res://textures/landscape-depth-map.exr") as Texture2D
    var heightmap_image := heightmap_texture.get_image()

    heightmap_image.convert(Image.FORMAT_RF)

    var height_min = 0.0
    var height_max = 17

    var heightmap := $Landscape_007/StaticBody3D/CollisionShape3D.shape as HeightMapShape3D
    heightmap.update_map_data_from_image(heightmap_image, height_min, height_max)
