extends Label

func _ready():
	set_process(true)
	
func _process(_delta: float):
	self.text = 'Window Size: %s' % get_viewport().size