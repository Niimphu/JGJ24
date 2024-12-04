extends Sprite2D


enum { MENU, GAMING }

var state := GAMING


func _process(_delta):
	if state == GAMING:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		global_position = get_global_mouse_position()
	elif state == MENU:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
