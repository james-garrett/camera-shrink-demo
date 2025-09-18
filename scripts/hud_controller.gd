extends Control

@onready var hud = $HUD
@onready var subViewport: SubViewport
@onready var subViewportContainer: SubViewportContainer
@onready var viewport: TextureRect

@onready var subViewportDefaultSize
var ui_expanded = true
var target_size
var resizing = false

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


	viewport.set_custom_minimum_size(Vector2(1980, 1080))
	#viewport.size = Vector2(1980, 1080)
	viewport.stretch_mode = TextureRect.STRETCH_SCALE
	
	await get_tree().process_frame
	#subViewportContainer.visible = false

func _input(event):
	if event is InputEventMouseButton:
		# var emb = (InputEventMouseButton)event
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			CustomLogger.log(str(event))
			resize_ui_menu(true)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			CustomLogger.log(str(event))
			resize_ui_menu(false)
	# if event.button_index == MOUSE_BUTTON_WHEEL_UP:
	# 	resize_ui_menu(true)
	# elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
	# 	resize_ui_menu(false)

func _process(delta):
	if resizing:
		var current_size = viewport.custom_minimum_size
		var new_size = current_size.lerp(target_size, 5.0 * delta)
		if new_size == target_size:
			resizing = false
		else:	
			viewport.set_custom_minimum_size(new_size)

# TODO make it an array of values we move up and down
# Get current index, increase to zoom out, decrease to zoom in
func resize_ui_menu(zoomed_in):
	ui_expanded = zoomed_in
	resizing = true
	if zoomed_in:
		#viewport.size = subViewportDefaultSize
		target_size = Vector2(1980, 1080)
		#viewport.set_custom_minimum_size(Vector2(1980, 1080))
	else:
		# viewportContainer.custom_minimum_size = Vector2(subViewportDefaultSize.x / 2, subViewportDefaultSize.y / 2)
		target_size = Vector2(1000, 800)
		#viewport.set_custom_minimum_size(Vector2(1000, 800))
		# viewport.margin_left = viewport.margin_left - 500  
		# viewport.margin_bottom = viewport.margin_bottom - 500
		#viewport.size = Vector2(1000, 800)
