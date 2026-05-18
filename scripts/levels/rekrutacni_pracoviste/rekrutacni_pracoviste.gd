extends "res://scripts/levels/level_base.gd"

@onready var pracovnik_rekrutacniho_pracoviste = $pracovnik_rekrutacniho_pracoviste


var enemies_cnt : int = 0

#returns count of enemies existing in the tree
func get_enemies_cnt() -> int:
	var cnt : int = 0
	for child in get_children(false):
		if child.is_in_group("enemy"):
			cnt += 1
	return cnt

func _ready() -> void:
	PlayerInventory.connect("inventory_updated", self._on_inventory_updated)
	enemies_cnt = get_enemies_cnt()

	# Show tutorial only on first playthrough
	if Globals.levels_completed == 0:
		_show_tutorial()

# ─── Tutorial ──────────────────────────────────────────────────

const TUTORIAL_MESSAGES: Array[String] = [
	"WASD — pohyb",
	"SHIFT — přískok",
	"Kolečko myši / 1-6 — hotbar",
	"levé tlačítko myši — útok",
	"E — interakce",
	"I — inventář",
	"Q — konzumace",
]
const TUTORIAL_MSG_DURATION: float = 2.5
const TUTORIAL_FADE_TIME: float = 0.3

func _show_tutorial() -> void:
	# Container panel: centered on screen with semi-transparent black bg
	var panel := Panel.new()
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0.5)
	panel_style.set_corner_radius_all(12)
	panel_style.set_content_margin_all(24)
	panel_style.border_color = Color(1, 1, 1, 0.15)
	panel_style.border_width_bottom = 2
	panel_style.border_width_top = 2
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel.add_theme_stylebox_override("panel", panel_style)

	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 1.0
	panel.anchor_bottom = 0.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.z_index = 200
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var ui := get_tree().get_first_node_in_group("user_interface")
	if ui:
		ui.add_child(panel)
	else:
		return

	# Label inside the panel
	var label := Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", load("res://fonts/CozetteVector.otf"))
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_child(label)

	# Size the panel to fit text
	var max_width := 0.0
	for msg in TUTORIAL_MESSAGES:
		var text_width := label.get_theme_font("font").get_string_size(msg, HORIZONTAL_ALIGNMENT_CENTER, -1, 36).x
		if text_width > max_width:
			max_width = text_width
	panel.custom_minimum_size = Vector2(max_width + 60, 80)

	# Play through messages with smooth crossfade
	for i in TUTORIAL_MESSAGES.size():
		label.text = TUTORIAL_MESSAGES[i]
		label.modulate.a = 0.0

		# Fade in
		var tween := panel.create_tween()
		tween.tween_property(label, "modulate:a", 1.0, TUTORIAL_FADE_TIME)
		# Hold
		tween.tween_interval(TUTORIAL_MSG_DURATION - TUTORIAL_FADE_TIME * 2)
		# Fade out (skip on last message — panel removal handles it)
		if i < TUTORIAL_MESSAGES.size() - 1:
			tween.tween_property(label, "modulate:a", 0.0, TUTORIAL_FADE_TIME)
		await tween.finished

	# Final fade: message + panel together
	var final_tween := panel.create_tween().set_parallel(true)
	final_tween.tween_property(label, "modulate:a", 0.0, TUTORIAL_FADE_TIME)
	final_tween.tween_property(panel, "modulate:a", 0.0, TUTORIAL_FADE_TIME)
	final_tween.chain().tween_callback(panel.queue_free)

func _on_inventory_updated() -> void:
	if PlayerInventory.has_item("Pen") and enemies_cnt:
		pracovnik_rekrutacniho_pracoviste.start_id = "CONTINUE"


func _on_child_exiting_tree(exiting_child: Node) -> void:
	if exiting_child.is_in_group("enemy"):
		enemies_cnt -= 1
		if enemies_cnt <= 0:
			pracovnik_rekrutacniho_pracoviste.start_id = "FINISHED"
