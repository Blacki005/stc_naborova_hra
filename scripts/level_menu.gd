extends Node2D

@onready var locks = $locks.get_children(false)
@onready var buttons = $buttons.get_children(false)
@onready var labels = $labels.get_children(false)

func _ready() -> void:
	var levels_completed = Globals.levels_completed
	var new_level_unlocked = Globals.new_level_unlocked
	
	#if all levels has been completed, unlock all levels for replay:
	if levels_completed >= Globals.LEVELS_CNT:
		for i in len(locks):
			locks[i].visible = false
		for i in len(buttons):
			buttons[i].show()
			buttons[i].disabled = false
		return
	
	buttons[0].disabled = levels_completed
	labels[0].visible = levels_completed
	for i in len(locks):
		if i+1 < levels_completed:
			#remove locks of completed levels and disable their buttons
			locks[i].visible = false
			buttons[i+1].visible = true
			buttons[i+1].disabled = true
			labels[i+1].show()
		elif i+1 == levels_completed and new_level_unlocked:
			new_level_unlocked = false
			locks[i].play("unlock")
			Globals.new_level_unlocked = false
		elif i+1 == levels_completed:
			locks[i].hide()
			buttons[i+1].visible = true
			buttons[i+1].disabled = false


func _animate_unlocked_button(btn: Button) -> void:
	btn.visible = true
	btn.pivot_offset = btn.size / 2.0
	btn.scale = Vector2.ZERO

	var mat = ShaderMaterial.new()
	mat.shader = preload("res://shaders/button_sweep.gdshader")
	btn.material = mat

	var tween = create_tween()
	tween.tween_property(btn, "scale", Vector2(1.3, 1.3), 0.25).set_ease(Tween.EASE_OUT)
	tween.tween_property(btn, "scale", Vector2(0.9, 0.9), 0.1).set_ease(Tween.EASE_IN)
	tween.tween_property(btn, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_OUT)

	mat.set_shader_parameter("sweep_progress", -0.5)
	var sweep_tween = create_tween()
	sweep_tween.tween_property(mat, "shader_parameter/sweep_progress", 1.5, 2.0).set_delay(0.1)
	sweep_tween.tween_callback(func(): btn.material = null)


func _on_lock_1_animation_finished() -> void:
	locks[0].visible = false
	_animate_unlocked_button(buttons[1])

func _on_lock_2_animation_finished() -> void:
	locks[1].visible = false
	_animate_unlocked_button(buttons[2])

func _on_lock_3_animation_finished() -> void:
	locks[2].visible = false
	_animate_unlocked_button(buttons[3])

func _on_lock_4_animation_finished() -> void:
	locks[3].visible = false
	_animate_unlocked_button(buttons[4])


func _on_level_1_button_up() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/rekrutacni_pracoviste/rekrutacni_pracoviste.tscn")


func _on_level_2_button_up() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/vojenska_nemocnice/vojenska_nemocnice.tscn")


func _on_level_3_button_up() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/prijmacky/prijmacky.tscn")


func _on_level_4_button_up() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/kruz_zakladni_pripravy/kurz_zakladni_pripravy.tscn")


func _on_level_5_button_up() -> void:
	get_tree().change_scene_to_file("res://scenes/levels/prisaha/prisaha.tscn")
