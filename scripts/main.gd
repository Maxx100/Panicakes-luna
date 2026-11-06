extends Node2D

@export var gravity := 350.0:
	set(value):
		gravity = value
		if is_inside_tree():
			_apply_gravity()

@export var floor_y := 680.0

var _last_item: Item
var _last_speed := 0.0
var _peak_height := 0.0


func _ready() -> void:
	_apply_gravity()
	$Grabber.connect("thrown", _on_thrown)


func _apply_gravity() -> void:
	PhysicsServer2D.area_set_param(get_world_2d().space, PhysicsServer2D.AREA_PARAM_GRAVITY, gravity)


func _on_thrown(item: Item, velocity: Vector2) -> void:
	_last_item = item
	_last_speed = velocity.length()
	_peak_height = 0.0


func _process(_delta: float) -> void:
	if _last_item and not _last_item.held:
		_peak_height = maxf(_peak_height, floor_y - _last_item.global_position.y - _last_item.radius)
	queue_redraw()


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var top := (get_canvas_transform().affine_inverse() * get_viewport_rect().position).y
	var info := "g = %d px/s²   бросок: %d px/s   апогей: %d px над полом" % [gravity, _last_speed, _peak_height]
	draw_string(font, Vector2(256, top + 52), info, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.8, 0.8, 0.9))
	for node in get_tree().get_nodes_in_group("items"):
		var item := node as Item
		if item.global_position.y + item.radius >= top:
			continue
		var x := item.global_position.x
		draw_colored_polygon(PackedVector2Array([Vector2(x, top + 6), Vector2(x - 10, top + 24), Vector2(x + 10, top + 24)]), item.color)
		draw_string(font, Vector2(x + 14, top + 24), "%d" % (top - item.global_position.y), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, item.color)
