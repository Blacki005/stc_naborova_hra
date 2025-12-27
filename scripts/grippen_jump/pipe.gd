extends Area2D

signal hit
signal scored

func _on_body_entered(_body: Node2D) -> void:
	emit_signal("hit")


func _on_score_area_body_entered(_body: Node2D) -> void:
	emit_signal("scored")
