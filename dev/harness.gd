extends Node

const INJECTED_DEVICE := 4242
const HEADLESS_SIZE := Vector2i(1280, 720)

var _frame := 0
var _quit_at := -1
var _probe_every := 0
var _stats_every := 0
var _shot_frames: Array[int] = []
var _shot_dir := ""
var _events: Dictionary = {}
var _resizes: Dictionary = {}
var _mouse_pos := Vector2.ZERO
var _button_mask := 0
var _filter_mouse := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var opts := _parse(OS.get_cmdline_user_args())
	set_physics_process(not opts.is_empty())
	set_process_input(not opts.is_empty())
	if opts.is_empty():
		return
	_filter_mouse = opts.has("input")
	if DisplayServer.get_name() == "headless":
		get_window().size = HEADLESS_SIZE
	get_viewport().size_changed.connect(_snap_camera)
	_quit_at = int(opts.get("quit", "-1"))
	_probe_every = int(opts.get("probe", "0"))
	_stats_every = int(opts.get("stats", "0"))
	_shot_dir = opts.get("shot-dir", ProjectSettings.globalize_path("res://tools/shots"))
	if opts.has("shots"):
		for s in String(opts["shots"]).split(",", false):
			_shot_frames.append(int(s))
		DirAccess.make_dir_recursive_absolute(_shot_dir)
	if opts.has("input"):
		_load_input(opts["input"])
	for spec in String(opts.get("resize", "")).to_lower().split(",", false):
		var parts := spec.split("@")
		var size := parts[0].split("x")
		if parts.size() != 2 or size.size() != 2 or int(parts[1]) < 1:
			push_error("HARNESS bad --resize spec '%s', expected WxH@frame" % spec)
			get_tree().quit(1)
			return
		_resizes[int(parts[1])] = Vector2i(int(size[0]), int(size[1]))
	if opts.has("window-mode"):
		get_window().mode = int(opts["window-mode"]) as Window.Mode
	print("HARNESS ready %s" % opts)


func _parse(args: PackedStringArray) -> Dictionary:
	var out := {}
	for a in args:
		if a.begins_with("--"):
			var kv := a.substr(2).split("=", true, 1)
			out[kv[0]] = kv[1] if kv.size() > 1 else "true"
	return out


func _load_input(path: String) -> void:
	var steps: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(steps) != TYPE_ARRAY:
		push_error("HARNESS bad input file %s" % path)
		return
	var cursor := Vector2.ZERO
	for step: Dictionary in steps:
		var f := int(step["f"])
		var kind: String = step["t"]
		var target := Vector2(step.get("x", cursor.x), step.get("y", cursor.y))
		if kind == "drag":
			var n := maxi(1, int(step.get("frames", 1)))
			for i in range(1, n + 1):
				_queue(f + i - 1, "move", cursor.lerp(target, float(i) / n))
		else:
			_queue(f, kind, target)
		cursor = target


func _queue(frame: int, kind: String, pos: Vector2) -> void:
	if not _events.has(frame):
		_events[frame] = []
	_events[frame].append({"t": kind, "pos": pos})


func _input(event: InputEvent) -> void:
	if event.device == INJECTED_DEVICE:
		return
	if event is InputEventKey or (_filter_mouse and event is InputEventMouse):
		get_viewport().set_input_as_handled()


func _snap_camera() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera:
		camera.reset_physics_interpolation()
		camera.force_update_scroll()


func _physics_process(_delta: float) -> void:
	_frame += 1
	if _resizes.has(_frame):
		get_window().size = _resizes[_frame]
		_snap_camera()
		print("HARNESS resize f=%d requested=%s actual=%s" % [_frame, _resizes[_frame], get_window().size])
	for e: Dictionary in _events.get(_frame, []):
		_inject(e["t"], e["pos"])
	if _probe_every > 0 and _frame % _probe_every == 0:
		_probe()
	if _stats_every > 0 and _frame % _stats_every == 0:
		var viewport := get_viewport()
		print("STATS f=%d mode=%d window=%s visible=%s oversampling=%.3f fps=%d tps=%d frac=%.2f" % [_frame,
			get_window().mode, get_window().size, viewport.get_visible_rect().size, viewport.get_oversampling(),
			Engine.get_frames_per_second(), Engine.physics_ticks_per_second, Engine.get_physics_interpolation_fraction()])
	if _frame in _shot_frames:
		_shoot(_frame)
	if _frame == _quit_at:
		if DisplayServer.get_name() != "headless":
			await RenderingServer.frame_post_draw
		print("HARNESS quit f=%d" % _frame)
		get_tree().quit()


func _inject(kind: String, world_pos: Vector2) -> void:
	var viewport := get_viewport()
	var win_pos := viewport.get_final_transform() * (viewport.get_canvas_transform() * world_pos)
	var ev: InputEventMouse
	if kind == "move":
		var m := InputEventMouseMotion.new()
		m.relative = win_pos - _mouse_pos
		m.screen_relative = m.relative
		m.velocity = m.relative * Engine.physics_ticks_per_second
		m.screen_velocity = m.velocity
		ev = m
	else:
		var b := InputEventMouseButton.new()
		b.button_index = MOUSE_BUTTON_LEFT
		b.pressed = kind == "down"
		_button_mask = MOUSE_BUTTON_MASK_LEFT if b.pressed else 0
		ev = b
	ev.device = INJECTED_DEVICE
	ev.window_id = DisplayServer.INVALID_WINDOW_ID
	ev.button_mask = _button_mask
	ev.position = win_pos
	ev.global_position = win_pos
	_mouse_pos = win_pos
	Input.parse_input_event(ev)


func _probe() -> void:
	for n in get_tree().get_nodes_in_group("probe"):
		var line := "PROBE f=%d %s" % [_frame, n.name]
		var n2d := n as Node2D
		if n2d:
			line += " pos=(%.1f, %.1f) rot=%.2f" % [n2d.global_position.x, n2d.global_position.y, n2d.global_rotation]
		var rb := n as RigidBody2D
		if rb:
			line += " vel=(%.1f, %.1f) sleep=%s" % [rb.linear_velocity.x, rb.linear_velocity.y, rb.sleeping]
		var cb := n as CharacterBody2D
		if cb:
			line += " vel=(%.1f, %.1f)" % [cb.velocity.x, cb.velocity.y]
		if n.has_method("probe_state"):
			line += " %s" % n.call("probe_state")
		print(line)


func _shoot(frame: int) -> void:
	await RenderingServer.frame_post_draw
	var path := _shot_dir.path_join("f%05d.png" % frame)
	get_viewport().get_texture().get_image().save_png(path)
	print("HARNESS shot %s" % path)
