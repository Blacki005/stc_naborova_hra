extends Area2D
signal hit

@export var hit_points: int = 4


func get_hit():
	emit_signal("hit")
	$AudioStreamPlayer.play()
	play_hit_animation()
	self.hit_points -= 1


func play_hit_animation():
	# Flash or shake effect
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.RED, 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)

func destroy_target():
	# Play explosion/destroy animation
	queue_free()
