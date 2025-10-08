extends Control

signal UI_RESOLUTION_CHANGE(Vector2)
signal ON_RESOLUTION_ARRAY_SET(Array)

@onready var hud = $HUD
@onready var subViewport: SubViewport
@onready var viewport: TextureRect
@onready var subViewportDefaultSize
@onready var bottom_panel: PanelContainer

# I think this value is going to modify a lot of the other UI zoom incrementors here
# - We might need to set them based on this?
@onready var defaultUIzoomSpeed = 5.0

# probably scale this to be 1/4 the distance between each resolution indent 
@onready var proximityToStickToResolution = 50
# Ideally make this number small enough that:
	# The window will snap and the user will have time to realize it and let go (maybe look up average reaction times)
	# If the user keeps scrolling then it won't feel laggy and stop/starty

@onready var timeAfterResolutionSnapBeforeUserCanScrollAgain = 0.5

@onready var timeForAccelerationToOccur = 0.3
@onready var uiZoomAcceleration = 0
@onready var uiZoomAccelerationIncrement = 1

@onready var scroll_input_history_array_size = 5
@onready var scroll_input_history = []
@onready var scroll_clicks_before_snap_check = 3
@onready var canZoom = false
@onready var newScrollInput
@onready var resolutionTrackerLabel: Label
@onready var snapLog: Label

@onready var debugDrawer
@onready var drawer

var current_resolution_value = Vector2(0,0)
var change_in_resolution_value = 0

var ui_expanded = true
var target_size
var resizing = false
var snapping = false
var uiWindowSizes = {
	"16:9": [Vector2(1920, 1080), Vector2(1600, 900), Vector2(1366, 768), Vector2(1280, 720), Vector2(960, 540), Vector2(640, 360)]
}
@onready var uiWindowSizesAfterUIratio
var defaultAspectRatio = "16:9"
var defaultUItoGameWindowRatio = "4:5"
var defaultWindowSize
var uiWindowIndex = 0
var frameCounter = 4


func _ready():
	CustomLogger.log("hud_controller ready!")
	viewport = get_tree().current_scene.find_child("TextureRect")
	subViewport = get_tree().current_scene.find_child("SubViewport")
	subViewportDefaultSize = subViewport.size
	current_resolution_value = subViewportDefaultSize
	resolutionTrackerLabel = get_tree().current_scene.find_child("ResolutionTracker")
	snapLog = get_tree().current_scene.find_child("SnapAndAccelerationLog")
	viewport.anchor_left = 0
	viewport.anchor_right = 0
	viewport.anchor_top = 0
	viewport.anchor_bottom = 0
	viewport.expand = true

	# TODO - see if we can do this function with pointers or references
	uiWindowSizesAfterUIratio = calibrateWindowSizesForAspectRatio(uiWindowSizes, defaultAspectRatio, defaultUItoGameWindowRatio)
	
	defaultWindowSize = uiWindowSizesAfterUIratio[defaultAspectRatio][uiWindowIndex]
	ON_RESOLUTION_ARRAY_SET.emit(uiWindowSizesAfterUIratio[defaultAspectRatio])
	snapLog.text = "Snapping: %s" % [snapping]

	viewport.set_custom_minimum_size(defaultWindowSize)
	resolutionTrackerLabel.text = "[%.2f,%.2f]" % [defaultWindowSize.x, defaultWindowSize.y]
	viewport.stretch_mode = TextureRect.STRETCH_SCALE
	canZoom = true
	# setupDebugDrawer()
	# get_edge_of_viewport()

	await get_tree().process_frame
	
func setupDebugDrawer():
	# debugDrawer = preload("res://addons/debugdraw2d/DebugDraw2D.gd")
	# drawer = debugDrawer.new()
	
	# subViewport.add_child(subViewport)
	# drawer.position = Vector2(0,0)
	
	DebugDraw3D.scoped_config().set_viewport(subViewport) 	 
	# DebugDraw3D.draw_box(Vector3(screen_center.x, screen_center.y, 0), Quaternion.IDENTITY,Vector3.ONE, Color.PINK)
	# drawer.rect(Vector2(0, 0))
	# drawer.rect(screen_center - Vector2(100, -100), Vector2(50, 25), Color(1, 1, 1))
	# DebugDraw2D.rect(Vector2(0,0))
	# get_edge_of_viewport() 

# func get_edge_of_viewport():
	# DebugDraw2D.rect(viewport.position, viewport.size)

# This is a mess, refactor!
func _process(delta):
	var screen_center = subViewport.size / 2.0
	# if drawer:
	# 	drawer.rect(screen_center)
	DebugDraw3D.draw_box(Vector3(screen_center.x, screen_center.y, 0), Quaternion.IDENTITY,Vector3.ONE, Color.PINK)
	DebugDraw3D.draw_box(Vector3(10, 10, 10), Quaternion.IDENTITY,Vector3.ONE, Color.PINK)
	DebugDraw3D.draw_box(Vector3(0, 0, 0), Quaternion.IDENTITY,Vector3(1,2,1), Color.PINK)
	
	# DebugDraw2D.rect(Vector2(50,50), Vector2(50, 25), Color(1, 1, 1), 1, 1)
	# snapLog.text = "Snapping: %s" % [snapping]
	if resizing:
		if scroll_input_history.size() >= 0:
			resolutionTrackerLabel.text = "[%.2f,%.2f]" % [viewport.size.x, viewport.size.x]
			if newScrollInput != null:
				var newScrollItem = {"direction": newScrollInput, "delta": delta}
				scroll_input_history = Utils.append_fixed_array(newScrollItem, scroll_input_history, scroll_input_history_array_size)
				newScrollInput = null
#			I assume this condition here is if we're resizing but not scrollin - i.e snapping/lerping/locking to a resolution
			# else:
			# 	var lastInputTime = delta
			# 	if scroll_input_history.size() > 0:
			# 		lastInputTime = scroll_input_history.back().delta
			# 	var timeSinceLastInput = abs(delta - lastInputTime)
		frameCounter += 1
		var rerenderViewport = frameCounter % 2000 == 0
		if rerenderViewport:
			frameCounter = 0
		set_new_viewport_size(delta, defaultUIzoomSpeed, rerenderViewport)
			
		
func snap_to_resolution(delta, target_resolution):
	snapping = true
	snapLog.text = "Snapping: %s" % [snapping]
	# TODO - figure out way to pass timeElapsed to calculate_ui_zoom_acceleration_speed without recalculating it here 
	var timeElasped = abs(scroll_input_history.back().delta - scroll_input_history.front().delta) 
	var viewPortGapAcceleration = 0
	if scroll_input_history.back().direction == Enums.cameraZoomDirections.ZOOM_IN:
		viewPortGapAcceleration = (viewport.size / target_resolution)
	else:
		viewPortGapAcceleration = (target_resolution / viewport.size)
	var zoomSpeedMultiplier = 1 - abs((defaultUIzoomSpeed - (10000*timeElasped)) * (1 - viewPortGapAcceleration.y))
	var snapSpeed = calculate_ui_zoom_acceleration_speed(zoomSpeedMultiplier)

	target_size = target_resolution
	
	snapping = false

func update_resolution(target_size, rerenderViewport):
	viewport.set_custom_minimum_size(target_size)
	change_in_resolution_value = current_resolution_value.y -target_size.y
	current_resolution_value = target_size
	if rerenderViewport:
		UI_RESOLUTION_CHANGE.emit(target_size)
	# resize_bottom_panel(abs(change_in_resolution_value))

func _input(event):
	if canZoom:
		if event is InputEventMouseButton:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
				newScrollInput = Enums.cameraZoomDirections.ZOOM_IN
			elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
				newScrollInput = Enums.cameraZoomDirections.ZOOM_OUT
			# CustomLogger.log(str(event))
			resize_ui_scroll(newScrollInput)
	
# =============== Viewport Resizing =================
func set_new_viewport_size(delta, snapSpeed, rerenderViewport):
	var new_size = viewport.custom_minimum_size.lerp(target_size, snapSpeed * delta)
	var distance = 0
	if scroll_input_history[0].direction == Enums.cameraZoomDirections.ZOOM_IN:
		distance = abs(new_size.y - target_size.y) 
	else:
		distance = abs(target_size.y - new_size.y)
	# if distance < 15:
		#resizing = false
		# subViewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		# snap_to_resolution(delta, target_size)
	# else:	
		# update_resolution(new_size)
		# viewport.set_custom_minimum_size(new_size)
		# UI_RESOLUTION_CHANGE.emit(new_size)
	# TODO - put all set_custom_minimum_size calls in one function so we can also emit in one place
	
	change_in_resolution_value = viewport.custom_minimum_size.y -new_size.y
	resize_bottom_panel(abs(change_in_resolution_value))
	update_resolution(new_size, rerenderViewport)

func resize_ui_scroll(direction):
	if direction == Enums.cameraZoomDirections.ZOOM_OUT:
		if uiWindowIndex > 0:
			resizing = true
			uiWindowIndex -= 1
			target_size = uiWindowSizesAfterUIratio[defaultAspectRatio][uiWindowIndex]
	elif direction == Enums.cameraZoomDirections.ZOOM_IN:
		if uiWindowIndex < uiWindowSizesAfterUIratio[defaultAspectRatio].size() -1:
			resizing = true
			uiWindowIndex += 1
			target_size = uiWindowSizesAfterUIratio[defaultAspectRatio][uiWindowIndex]


# If: 
	# the array is at its full size 
	# time between the first and last input is

	# Get the time between the first and the last 
func calculate_ui_zoom_acceleration_speed(zoomMultiplier):
	# get the time between the first and the last input
	# If it's below a certain number, add the difference to the scroll speed?
	var timeElasped = abs(scroll_input_history.back().delta - scroll_input_history.front().delta) 
	var accelerationSpeed = defaultUIzoomSpeed
	if timeElasped > defaultUIzoomSpeed:
		accelerationSpeed = defaultUIzoomSpeed * zoomMultiplier
	return accelerationSpeed


func calculate_ratio_accurate_viewport(aspect_ratio_as_fraction, uiRatioAsFration, viewPort_size):
	var max_width = uiRatioAsFration * viewPort_size.x
	var max_height = uiRatioAsFration * viewPort_size.y

	var new_height = max_width / aspect_ratio_as_fraction
	
	if new_height > max_height:
		return Vector2(max_height * aspect_ratio_as_fraction, max_height)
	
	return Vector2(max_width, new_height)


# UI ratio is how much of the screen we want taken up by the UI
func calibrateWindowSizesForAspectRatio(window_view_dict, aspect_ratio, uiRatio):
	var uiRatioAsFration = Utils.calculate_ratio_as_fraction(uiRatio)
	var aspectRatioAsFraction = Utils.calculate_ratio_as_fraction(aspect_ratio)
	var newAspectRatioDict = {}
	newAspectRatioDict[aspect_ratio] = []
	var newResolutionArray = []
	for resolution in window_view_dict[aspect_ratio]:
		var adjustedResolution = calculate_ratio_accurate_viewport(aspectRatioAsFraction, uiRatioAsFration, resolution)
		newResolutionArray.append(adjustedResolution)

	newAspectRatioDict[aspect_ratio].append_array(newResolutionArray)
	return newAspectRatioDict

# ============== HUD Management =================
func resize_bottom_panel(ySpaceResized):
	#  move to global var
	var bottom_panel = get_tree().current_scene.find_child("BottomPanel")
	var windowDimensions = get_viewport().size
	# var spaceBetweenViewPortAndWindow = Vector2(windowDimensions.x - viewport.size.x, windowDimensions.y - viewport.size.y)
	# CustomLogger.log("Space between windows: %s,%s" % [spaceBetweenViewPortAndWindow.x, spaceBetweenViewPortAndWindow.y])
	# bottom_panel.size.y = spaceBetweenViewPortAndWindow.y
	var lastInputTime = scroll_input_history.front()
	if (lastInputTime):
		if (lastInputTime.direction == Enums.cameraZoomDirections.ZOOM_IN):
			bottom_panel.position.y = (bottom_panel.position.y - (ySpaceResized /2))
			# bottom_panel.position.y = (subViewport.size.y - bottom_panel.size.y)
		elif (lastInputTime.direction == Enums.cameraZoomDirections.ZOOM_OUT):
			bottom_panel.position.y = (bottom_panel.position.y + (ySpaceResized /2))
			# bottom_panel.position.y = (subViewport.size.y - bottom_panel.size.y)

# TODO 
# - function which calculates window sizes after UI ratio changes
	# - the UI ratio will change when the UI reaches set intervals, the UI will change size
	# - Possible that we'll want to have the dict evolve to have the topmost layer be the UI ratio, then a list of aspect ratios, then resolutions
	# -- {UI_ratio: {Aspect_ratio: [resolution_Array]}}
	# -- I think this'd be for the best.
# - FIX NAMING CONVERSATIONS, camelcase or underscore - PICK ONE (or figure out whether we name variables one way, func names another)
# - Get functions we don't think will be re-used and put them into their parent, to reduce function spam
# - Add function returnTypes and typedefs
# - Upgrade to Godot 4.5 - it has a customized
# - Resolution snap always targets smallest resolution
# -- Should target next resolution that's the closest in the direction that we're heading
# -- The direction part is the issue!
# --- Ok no it's part of the issue but we shouldn't still be shrinking to the lowest resolution but the closest, SOLVE THAT FIRST
# - Scrolling needs to consider touchpads (ugh)
# - https://www.youtube.com/watch?v=rGgxRsaGdcA
	
	
# PERFORMANCE Considerations
# - Lerp interval can be faster
# - Moving between resolutions on such small intervals is causing slowdown
# - Can we lower render resolution after it reaches certain intervals?


# BLACK HOLE DISSASOCIATIVE EFFECT
# - What you see outside the borders of the ui
# - Disappears as more and more UI is taken up 
# - A composite of data moshing, swirling black hole
# - Have a glow around the edges of the UI
# --https://www.esa.int/var/esa/storage/images/esa_multimedia/images/2022/04/black_hole_artist_s_impression/24046562-1-eng-GB/Black_hole_artist_s_impression_pillars.jpg
# --Some examples of space shaders I like:
	# https://duckduckgo.com/?t=ffab&q=generative+space+art+shader+godot&ia=images&iax=images
	# https://duckduckgo.com/?t=ffab&q=generative+space+art+shader+godot&ia=images&iax=images&iai=http%3A%2F%2Fgodotshaders.com%2Fwp-content%2Fuploads%2F2025%2F06%2Fimage_2025-06-03_195721838.jpg
	# This search: https://duckduckgo.com/?t=ffab&q=generative+space+art+shader+godot&ia=images&iax=images
# --https://fineartamerica.com/featured/dissociation-jornum-munroj.html
# --https://www.youtube.com/watch?v=v-l0pmPnwp4
# --https://duckduckgo.com/?t=ffab&q=90s+digital+space+art&ia=images&iax=images&iai=https%3A%2F%2Fd2jv9003bew7ag.cloudfront.net%2Fuploads%2FAndy-Warhol-Campbells-Image-via-computerhistoryorg.jpg
# --https://github.com/txnsor/godot-datamosher
