extends Node


func _ready() -> void:
	set_process_input(OS.has_feature("web"))


func _unhandled_key_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key.pressed and not key.echo and key.keycode == KEY_ESCAPE and not OS.has_feature("web"):
		get_tree().quit()


func _input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and button.button_index == MOUSE_BUTTON_LEFT and not button.pressed \
			and DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN \
			and JavaScriptBridge.eval("!!(document.fullscreenEnabled || document.webkitFullscreenEnabled)"):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
