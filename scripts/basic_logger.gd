extends TextEdit 

func _ready():
	# if !CustomLogger.is_connected("new_log", Callable(self, "_on_logger_new_log")):
	CustomLogger.connect("new_log", Callable(self, "_on_logger_new_log"))

func _on_logger_new_log(logMessage):
	# print("emission received")
	emit_new_log(logMessage)
	
func append_log(text):
	# print("appending text")
	self.text += "\n" + text
	# self.text = "test"
	
	

func emit_new_log(log):
	append_log(log)
