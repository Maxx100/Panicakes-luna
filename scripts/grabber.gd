extends Node2D

signal thrown(item: Item, velocity: Vector2)

@export var throw_scale := 0.6
@export var max_throw_speed := 1200.0
@export var history_window := 0.1
@export_flags_2d_physics var item_mask := 2

var _held: Item
var _offset := Vector2.ZERO
var _pointer := Vector2.ZERO
var _history: Array[Vector3] = []
var _time := 0.0


func _unhandled_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouse
	if mouse == null:
		return
	_pointer = get_canvas_transform().affine_inverse() * mouse.position
	var button := event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT:
		return
	if button.pressed:
		_try_grab()
	elif _held:
		_release()


func _physics_process(delta: float) -> void:
	_time += delta
	if _held == null:
		return
	_history.append(Vector3(_pointer.x, _pointer.y, _time))
	while _history.size() > 2 and _time - _history[0].z > history_window:
		_history.pop_front()
	_held.drag_to(_pointer - _offset)


func _try_grab() -> void:
	var query := PhysicsPointQueryParameters2D.new()
	query.position = _pointer
	query.collision_mask = item_mask
	for hit in get_world_2d().direct_space_state.intersect_point(query, 8):
		var item := hit["collider"] as Item
		if item:
			_held = item
			_offset = _pointer - item.global_position
			_history.clear()
			_history.append(Vector3(_pointer.x, _pointer.y, _time))
			item.grab(_pointer - _offset)
			return


func _release() -> void:
	var velocity := Vector2.ZERO
	var first := _history[0]
	var last := _history[-1]
	if last.z > first.z:
		velocity = Vector2(last.x - first.x, last.y - first.y) / (last.z - first.z)
	velocity = (velocity * throw_scale).limit_length(max_throw_speed)
	_held.release(velocity)
	thrown.emit(_held, velocity)
	_held = null
