extends TextureRect

@onready var subViewport

func _ready():
    subViewport = get_tree().current_scene.find_child("SubViewport")
    self.texture = subViewport.get_texture()