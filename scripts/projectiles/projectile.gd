extends "res://scripts/overlap/hitbox.gd"

@export var SPEED: int = 1500
@export var destroy_effect : PackedScene

func _physics_process(delta: float) -> void:
	var direction = Vector2.RIGHT.rotated(rotation)
	global_position += SPEED * direction * delta

func destroy():
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if not area.is_in_group("enemy") and not area.is_in_group("projectiles"):
		destroy()

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemy"):
		destroy()

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
