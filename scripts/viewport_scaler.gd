extends Node

const MAX_WIDTH := 1920
const MAX_HEIGHT := 1080
const POLL_INTERVAL := 0.25  # seconds between resize checks on web

var _last_size := Vector2i.ZERO
var _timer := Timer.new()


func _ready() -> void:
	_update_content_scale()
	get_viewport().size_changed.connect(_update_content_scale)

	# On web, the size_changed signal is unreliable with viewport stretch mode,
	# so we also poll the actual browser size via a timer.
	if OS.has_feature("web"):
		_timer.wait_time = POLL_INTERVAL
		_timer.process_mode = Node.PROCESS_MODE_ALWAYS
		_timer.timeout.connect(_poll_browser_size)
		add_child(_timer)
		_timer.start()


func _poll_browser_size() -> void:
	var size := _get_actual_display_size()
	if size != _last_size:
		_last_size = size
		_update_content_scale()


func _update_content_scale() -> void:
	var size := _get_actual_display_size()
	_last_size = size
	size.x = mini(int(size.x), MAX_WIDTH)
	size.y = mini(int(size.y), MAX_HEIGHT)
	get_viewport().content_scale_size = size


func _get_actual_display_size() -> Vector2i:
	if OS.has_feature("web"):
		return Vector2i(
			int(JavaScriptBridge.eval("window.innerWidth;")),
			int(JavaScriptBridge.eval("window.innerHeight;"))
		)
	else:
		return DisplayServer.window_get_size()
