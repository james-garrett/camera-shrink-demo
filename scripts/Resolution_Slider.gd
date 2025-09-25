extends VSlider

# TODO - combine these into one signal
signal SET_TRACKER_LABEL(new_resolution_value, slider_size, ratio)
signal INIT_TRACKER_LABEL(new_resolution_value)

# Set upper and lower limit to biggest and smallest of resolution array
# Snapping should snap to each notch

@onready var resolutionArray: Array
@onready var resolutionLabel: Label
@onready var hud_controller: Control

func _ready():
	self.value = 0
	resolutionLabel = get_tree().current_scene.find_child("ResolutionTracker")
	hud_controller = get_tree().current_scene.find_child("UI")
	hud_controller.UI_RESOLUTION_CHANGE.connect(_on_resolution_update)
	hud_controller.ON_RESOLUTION_ARRAY_SET.connect(_on_resolution_array_init)
	
func _on_resolution_update(new_resolution_value: Vector2): 
	var ratio = set_resolution_ratio(new_resolution_value)
	SET_TRACKER_LABEL.emit(new_resolution_value, self.size.y, ratio)
	self.value = ratio * 100

func _on_resolution_array_init(array):
	resolutionArray = array
	INIT_TRACKER_LABEL.emit(resolutionArray.front())
	# TODO - figure out why tick counters don't align exactly with where the marker snaps
	self.tick_count = resolutionArray.size()

func set_resolution_array(new_resolution_array):
	resolutionArray = new_resolution_array
	if(self.max_value == 0):
		self.max_value = new_resolution_array.first().y

func set_resolution_ratio(current_resolution_value):
	# ratio = (value - minValue) / (maxValue - minValue)
	var ratio = (current_resolution_value.y - resolutionArray.front().y) / (resolutionArray.back().y - resolutionArray.front().y)
	return ratio
