# TODO - replace this with 4.5 custom logger if it makes it redundant

extends Node

signal new_log(logMessage)

@onready var signal_ready = false

func _ready():
	signal_ready = true

func log(logMessage):
	# print("Custom Log" + logMessage)
	print(logMessage)
	emit_signal("new_log", logMessage)

func isReady():
	return signal_ready
