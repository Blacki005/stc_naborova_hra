extends Area2D
signal hit

@export var movement_radius: float = 50.0
@export var move_speed: float = 80.0

var _center_position: Vector2
var _move_tween: Tween


func _ready() -> void:
	_center_position = position
	_pick_next_position()


func _pick_next_position() -> void:
	if _move_tween:
		_move_tween.kill()

	var angle := randf_range(0, TAU)
	var dist := randf_range(movement_radius * 0.3, movement_radius)
	var target_pos := _center_position + Vector2(cos(angle), sin(angle)) * dist

	var distance := position.distance_to(target_pos)
	var duration := maxf(distance / move_speed, 0.3)

	_move_tween = create_tween()
	_move_tween.tween_property(self, "position", target_pos, duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_move_tween.tween_callback(_pick_next_position)


func get_hit() -> void:
	emit_signal("hit")
	$AudioStreamPlayer.play()


func play_hit_animation() -> void:
	if _move_tween:
		_move_tween.kill()

	var wiggle_origin := position

	# Color flash
	var color_tw := create_tween()
	color_tw.tween_property(self, "modulate", Color.RED, 0.1)
	color_tw.tween_property(self, "modulate", Color.WHITE, 0.1)

	# Position wiggle – quick jolts, small offsets to preserve pixel art
	var tw := create_tween()
	tw.tween_property(self, "position", wiggle_origin + Vector2(5, -3), 0.05)
	tw.tween_property(self, "position", wiggle_origin + Vector2(-4, 2), 0.05)
	tw.tween_property(self, "position", wiggle_origin + Vector2(3, -1), 0.05)
	tw.tween_property(self, "position", wiggle_origin, 0.05)
	tw.tween_callback(_pick_next_position)


func play_crash_animation() -> void:
	if _move_tween:
		_move_tween.kill()
	set_deferred("monitoring", false)
	$AudioStreamPlayer.stream = load("res://sound/levels/kzp/explosion.mp3")
	$AudioStreamPlayer.play()

	var fall_duration := 1.8
	var start_x := position.x
	var target_y := position.y + 256.0

	# Horizontal jiggle – decreasing sway to keep pixel art readable
	var jiggle := create_tween()
	jiggle.tween_property(self, "position:x", start_x + 6.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	jiggle.tween_property(self, "position:x", start_x - 5.0, 0.25).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	jiggle.tween_property(self, "position:x", start_x + 4.0, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	jiggle.tween_property(self, "position:x", start_x - 3.0, 0.20).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	jiggle.tween_property(self, "position:x", start_x + 2.0, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	jiggle.tween_property(self, "position:x", start_x, 0.15).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# Main fall: gravity acceleration + gentle spin + smoke tint
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "position:y", target_y, fall_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "rotation_degrees", 20.0, fall_duration).set_trans(Tween.TRANS_LINEAR)
	tw.tween_property(self, "modulate", Color(0.5, 0.4, 0.3), fall_duration).set_trans(Tween.TRANS_LINEAR)

	# Explode after the fall
	tw.chain().tween_callback(destroy_target)


func destroy_target() -> void:
	modulate = Color.YELLOW
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 0.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(self, "modulate", Color.ORANGE, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(queue_free)
