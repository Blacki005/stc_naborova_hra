extends "res://scripts/overlap/hitbox.gd"

@export var SPEED: int = 1500
@export var destroy_effect : PackedScene

func _physics_process(delta: float) -> void:
	var direction = Vector2.RIGHT.rotated(rotation)
	global_position += SPEED * direction * delta

func destroy():
	queue_free()

func _on_area_entered(_area: Area2D) -> void:
	destroy()

func _on_body_entered(_body: Node2D) -> void:
	destroy()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
