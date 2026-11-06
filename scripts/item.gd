class_name Item
extends RigidBody2D

signal impacted(item: Item, point: Vector2, normal: Vector2, strength: float)

@export var radius := 28.0
@export var color := Color(0.9, 0.8, 0.5)
@export var texture: Texture2D
@export var texture_body_radius := 60.0
@export var impact_effect: PackedScene
@export var impact_threshold := 140.0
@export var impact_full_strength := 1200.0
@export var squash_amount := 0.32
@export_range(0.05, 1.0) var follow_strength := 0.6
@export var max_drag_speed := 3000.0
@export_flags_2d_physics var world_mask := 1
@export var contact_margin := 1.0

var held := false
var _shape: CircleShape2D
var _target := Vector2.ZERO
var _pending_velocity := Vector2.ZERO
var _has_pending_velocity := false
var _base_gravity_scale := 1.0
var _last_velocity := Vector2.ZERO
var _touching := {}
var _impacts: Array[Dictionary] = []
var _impact_cooldown := 0.0
var _hit_count := 0
var _last_hit := {}
var _tween: Tween

@onready var _squash: Node2D = $Squash
@onready var _sprite: Sprite2D = $Squash/Sprite


func _ready() -> void:
	add_to_group("items")
	add_to_group("probe")
	_shape = CircleShape2D.new()
	_shape.radius = radius
	($Shape as CollisionShape2D).shape = _shape
	_sprite.texture = texture
	_sprite.scale = Vector2.ONE * radius / texture_body_radius
	reset_physics_interpolation()


func grab(target: Vector2) -> void:
	held = true
	_target = target
	_base_gravity_scale = gravity_scale
	gravity_scale = 0.0
	sleeping = false
	_bounce(Vector2.RIGHT, Vector2(1.12, 1.12), 0.35)


func drag_to(target: Vector2) -> void:
	_target = target


func release(velocity: Vector2) -> void:
	held = false
	gravity_scale = _base_gravity_scale
	_pending_velocity = velocity
	_has_pending_velocity = true


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	if _has_pending_velocity:
		state.linear_velocity = _pending_velocity
		_has_pending_velocity = false
	elif held:
		var desired := (_target - state.transform.origin) / state.step
		var velocity := state.linear_velocity.lerp(desired, follow_strength).limit_length(max_drag_speed)
		state.linear_velocity = _stop_at_world(state, velocity)
		state.angular_velocity *= 0.8
	_detect_impacts(state)


func _detect_impacts(state: PhysicsDirectBodyState2D) -> void:
	var touching := {}
	for i in state.get_contact_count():
		var id := state.get_contact_collider_id(i)
		touching[id] = true
		if held or _touching.has(id):
			continue
		var strength := (state.linear_velocity - _last_velocity).length()
		if strength >= impact_threshold:
			_impacts.append({
				"point": state.get_contact_local_position(i),
				"normal": state.get_contact_local_normal(i),
				"strength": strength,
			})
	_touching = touching
	_last_velocity = state.linear_velocity


func _physics_process(delta: float) -> void:
	_impact_cooldown = maxf(_impact_cooldown - delta, 0.0)
	if _impacts.is_empty():
		return
	var hit: Dictionary = _impacts[0]
	for candidate in _impacts:
		if candidate["strength"] > hit["strength"]:
			hit = candidate
	_impacts.clear()
	if _impact_cooldown > 0.0:
		return
	_impact_cooldown = 0.08
	_hit_count += 1
	_last_hit = hit
	var power := clampf(hit["strength"] / impact_full_strength, 0.0, 1.0)
	var k := squash_amount * power
	_bounce(hit["normal"], Vector2(1.0 - k, 1.0 + k * 0.7), 0.5)
	if impact_effect:
		var fx := impact_effect.instantiate() as ImpactEffect
		get_parent().add_child(fx)
		fx.global_position = hit["point"]
		fx.reset_physics_interpolation()
		fx.play(hit["normal"], power)
	impacted.emit(self, hit["point"], hit["normal"], hit["strength"])


func _bounce(axis: Vector2, from_scale: Vector2, duration: float) -> void:
	_squash.rotation = axis.angle() - global_rotation
	_sprite.rotation = -_squash.rotation
	_squash.scale = from_scale
	_squash.reset_physics_interpolation()
	if _tween:
		_tween.kill()
	_tween = create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	_tween.tween_property(_squash, "scale", Vector2.ONE, duration).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _stop_at_world(state: PhysicsDirectBodyState2D, velocity: Vector2) -> Vector2:
	var motion := velocity * state.step
	if motion.is_zero_approx():
		return velocity
	var space := state.get_space_state()
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = _shape
	query.transform = state.transform
	query.collision_mask = world_mask
	query.margin = contact_margin
	var touching: Array[RID] = []
	for i in 2:
		query.exclude = touching
		var contact := space.get_rest_info(query)
		if contact.is_empty():
			break
		motion = _slide(motion, contact["normal"])
		touching.append(contact["rid"])
	query.motion = motion
	var fraction := space.cast_motion(query)
	if fraction[0] < 1.0:
		var safe := motion * fraction[0]
		query.transform.origin += motion * fraction[1]
		query.motion = Vector2.ZERO
		motion = safe + _slide(motion - safe, space.get_rest_info(query).get("normal", Vector2.ZERO))
	return motion / state.step


func _slide(motion: Vector2, normal: Vector2) -> Vector2:
	return motion - normal * minf(motion.dot(normal), 0.0)


func probe_state() -> Dictionary:
	var state := {"held": held, "hits": _hit_count}
	if not _last_hit.is_empty():
		state["hit_at"] = Vector2i(_last_hit["point"])
		state["hit_n"] = Vector2i((_last_hit["normal"] as Vector2) * 10.0)
		state["hit_v"] = int(_last_hit["strength"])
	return state
