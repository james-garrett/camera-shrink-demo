extends Control

@onready var hud = $HUD
@onready var subViewport: SubViewport
@onready var subViewportContainer: SubViewportContainer
@onready var viewport: TextureRect

@onready var subViewportDefaultSize
var ui_expanded = true
var target_size
var resizing = false
var uiWindowSizes = {
	"16:9": [Vector2(1920, 1080), Vector2(1600, 900), Vector2(1366, 768), Vector2(1280, 720), Vector2(960, 540), Vector2(640, 360)]
}
@onready var uiWindowSizesAfterUIratio
var defaultAspectRatio = "16:9"
var defaultUItoGameWindowRatio = "4:5"
var defaultWindowSize
var uiWindowIndex = 0

func _ready():
	CustomLogger.log("hud_controller ready!")
	viewport = get_tree().current_scene.find_child("TextureRect")
	subViewport = get_tree().current_scene.find_child("SubViewport")
	subViewportContainer  = get_tree().current_scene.find_child("SubViewportContainer")
	subViewportDefaultSize = subViewport.size
	
	viewport.anchor_left = 0
	viewport.anchor_right = 0
	viewport.anchor_top = 0
	viewport.anchor_bottom = 0
	viewport.expand = true

	# TODO - see if we can do this function with pointers or references
	uiWindowSizesAfterUIratio = calibrateWindowSizesForAspectRatio(uiWindowSizes, defaultAspectRatio, defaultUItoGameWindowRatio)
	
	# TODO - delete after verifying we can calculate all ratios in dict, just use viewport.set_custom_minimum_size(uiWindowSizesAfterUIratio[defaultAspectRatio][uiWindowIndex])
	# var defaultAspectRatioAsFraction = calculate_ratio_as_fraction(defaultAspectRatio)
	# var rdefaultUIRatioAsFraction = calculate_ratio_as_fraction(defaultUItoGameWindowRatio)
	# defaultWindowSize = calculate_ratio_accurate_viewport(defaultAspectRatioAsFraction, rdefaultUIRatioAsFraction, uiWindowSizes[defaultAspectRatio][uiWindowIndex])
	
	defaultWindowSize = uiWindowSizesAfterUIratio[defaultAspectRatio][uiWindowIndex]

	viewport.set_custom_minimum_size(defaultWindowSize)
	viewport.stretch_mode = TextureRect.STRETCH_SCALE
	
	await get_tree().process_frame
	

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			CustomLogger.log(str(event))
			resize_ui_scroll(-1)
			# resize_ui_menu(true)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			CustomLogger.log(str(event))
			resize_ui_scroll(1)
			# resize_ui_menu(false)

func _process(delta):
	if resizing:
		var current_size = viewport.custom_minimum_size
		var new_size = current_size.lerp(target_size, 5.0 * delta)
		if new_size == target_size:
			resizing = false
		else:	
			viewport.set_custom_minimum_size(new_size)

func resize_ui_scroll(direction):
	if direction == 1:
		if uiWindowIndex > 0:
			resizing = true
			uiWindowIndex -= 1
			target_size = uiWindowSizesAfterUIratio[defaultAspectRatio][uiWindowIndex]
	elif direction == -1:
		if uiWindowIndex < uiWindowSizesAfterUIratio[defaultAspectRatio].size() -1:
			resizing = true
			uiWindowIndex += 1
			target_size = uiWindowSizesAfterUIratio[defaultAspectRatio][uiWindowIndex]

# UI ratio is how much of the screen we want taken up by the UI
func calibrateWindowSizesForAspectRatio(window_view_dict, aspect_ratio, uiRatio):
	var uiRatioAsFration = calculate_ratio_as_fraction(uiRatio)
	var aspectRatioAsFraction = calculate_ratio_as_fraction(aspect_ratio)
	var newAspectRatioDict = {}
	newAspectRatioDict[aspect_ratio] = []
	var newResolutionArray = []
	for resolution in window_view_dict[aspect_ratio]:
		var adjustedResolution = calculate_ratio_accurate_viewport(aspectRatioAsFraction, uiRatioAsFration, resolution)
		newResolutionArray.append(adjustedResolution)

	newAspectRatioDict[aspect_ratio].append_array(newResolutionArray)
	return newAspectRatioDict

func calculate_ratio_as_fraction(aspect_ratio_string):
	var ratioArr = aspect_ratio_string.split(":")
	if ratioArr[0] == null || ratioArr[1] == null:
		push_error("invalid ratio given:" + aspect_ratio_string)
	var fraction = ratioArr[0].to_float() / ratioArr[1].to_float() 
	return fraction




func calculate_ratio_accurate_viewport(aspect_ratio_as_fraction, uiRatioAsFration, viewPort_size):
	var max_width = uiRatioAsFration * viewPort_size.x
	var max_height = uiRatioAsFration * viewPort_size.y

	var new_height = max_width / aspect_ratio_as_fraction
	
	if new_height > max_height:
		return Vector2(max_height * aspect_ratio_as_fraction, max_height)
	
	return Vector2(max_width, new_height)
