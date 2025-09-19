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
var defaultAspectRatio = "16:9"
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
	
	#subViewportContainer.visible = false

	defaultWindowSize = calculate_ratio_accurate_viewport(defaultAspectRatio, uiWindowSizes[defaultAspectRatio][uiWindowIndex])
	viewport.set_custom_minimum_size(defaultWindowSize)
	# viewport.set_custom_minimum_size(defaultWindowSize)
	viewport.stretch_mode = TextureRect.STRETCH_SCALE
	
	await get_tree().process_frame
	#subViewportContainer.visible = false
	

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
			target_size = uiWindowSizes[defaultAspectRatio][uiWindowIndex]
	elif direction == -1:
		if uiWindowIndex < uiWindowSizes[defaultAspectRatio].size() -1:
			resizing = true
			uiWindowIndex += 1
			target_size = uiWindowSizes[defaultAspectRatio][uiWindowIndex]

func calculate_aspect_ratio_as_fraction(aspect_ratio_string):
	var ratioArr = aspect_ratio_string.split(":")
	if ratioArr[0] == null || ratioArr[1] == null:
		push_error("invalid ratio given:" + aspect_ratio_string)
	var fraction = ratioArr[0].to_float() / ratioArr[1].to_float() 
	return fraction




func calculate_ratio_accurate_viewport(target_aspect_ratio, viewPort_size):
	var aspect_ratio_fraction = calculate_aspect_ratio_as_fraction(target_aspect_ratio)
	# 0.8 for 4/5 of screen space
	var max_width = 0.8 * viewPort_size.x
	var max_height = 0.8 * viewPort_size.y

	var new_height = max_width / aspect_ratio_fraction
	
	var new_width = new_height * aspect_ratio_fraction
	
	if new_height > max_height:
		return Vector2(max_height * aspect_ratio_fraction, max_height)
	
	return Vector2(max_width, new_height)
