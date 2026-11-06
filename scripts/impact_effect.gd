class_name ImpactEffect
extends Node2D

@export var strong_threshold := 0.45


func play(normal: Vector2, power: float) -> void:
	var k := clampf(power, 0.15, 1.0)
	var longest := 0.0
	for child in get_children():
		var particles := child as CPUParticles2D
		if particles == null:
			continue
		if particles.get_meta("strong_only", false) and power < strong_threshold:
			particles.queue_free()
			continue
		particles.direction = normal
		particles.amount = maxi(1, roundi(particles.amount * k))
		particles.initial_velocity_min *= lerpf(0.55, 1.0, k)
		particles.initial_velocity_max *= lerpf(0.55, 1.0, k)
		particles.restart()
		particles.emitting = true
		longest = maxf(longest, particles.lifetime)
	get_tree().create_timer(longest + 0.2).timeout.connect(queue_free)
