extends Label

@onready var resolutionVslider: VSlider
@onready var defaultXPos

func _ready():
	resolutionVslider = get_tree().current_scene.find_child("VSlider")
	resolutionVslider.SET_TRACKER_LABEL.connect(_on_tracker_label_update)
	defaultXPos = self.global_position.x
	self.position.x = -200.0

# TODO - figure out why this isn't positioning exactly on the y axis of the marker
func _on_tracker_label_update(new_resolution_value, slider_size, ratio):
	var slider = self.get_theme_stylebox("VSlider")
	var sliderHeight = slider.get_offset().y
	# print("current resolution: %s, slider_size: %s, ratio: %s, sliderHeight: %s" % [new_resolution_value, slider_size, ratio, sliderHeight])
	var trackerLabelPosition = ((1 - ratio) * slider_size)
	self.position = Vector2(-200.0, trackerLabelPosition)
	set_resolution_text(new_resolution_value)

func set_resolution_text(new_resolution_value: Vector2):
	self.text = str(Vector2(int(new_resolution_value.x), int(new_resolution_value.y)))
