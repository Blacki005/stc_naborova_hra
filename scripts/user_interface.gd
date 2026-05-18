extends CanvasLayer

@onready var health_bar = $health_bar
@onready var shield_bar = $shield_bar
@onready var inventory = $inventory
@onready var shop = $shop
@onready var pause_screen = $pause_screen

#defined for both hotbar and inventory
var holding_item = null #item player is currently holding
var warning_issued : bool = false

func _ready() -> void:
	shield_bar.value = Globals.shield
	health_bar.value = Globals.health
	Globals.health_changed.connect(_on_health_changed)
	Globals.bago_changed.connect(_on_bago_changed)
	Globals.shield_changed.connect(_on_shield_changed)
	_on_health_changed()
	_on_bago_changed()

func _input(event : InputEvent) -> void:
	if not get_tree().paused:
		if event.is_action_pressed("inventory"):
			#toggle visibility of inventory
			inventory.visible = !inventory.visible
			inventory.initialize_inventory()
		elif event.is_action_pressed("scroll_up"):
			PlayerInventory.active_item_scroll_down()
		elif event.is_action_pressed("scroll_down"):
			PlayerInventory.active_item_scroll_up()
		elif event.is_action_pressed("hotbar_slot_1"):
			PlayerInventory.change_active_item(0)
		elif event.is_action_pressed("hotbar_slot_2"):
			PlayerInventory.change_active_item(1)
		elif event.is_action_pressed("hotbar_slot_3"):
			PlayerInventory.change_active_item(2)
		elif event.is_action_pressed("hotbar_slot_4"):
			PlayerInventory.change_active_item(3)
		elif event.is_action_pressed("hotbar_slot_5"):
			PlayerInventory.change_active_item(4)
		elif event.is_action_pressed("hotbar_slot_6"):
			PlayerInventory.change_active_item(5 )
	if event.is_action_pressed("pause"):
		#toggle pause menu
		if not get_tree().paused:
			get_tree().paused = true
			pause_screen.show()
		else:
			_on_continue_button_button_up()



func _on_bago_changed() -> void:
	$bago_label.text = "Bago: " + str(Globals.bago)

func _on_health_changed() -> void:
	if (health_bar.value > Globals.health):
		var tween = create_tween()
		tween.tween_property($screen_damage.material, "shader_parameter/intensity", 1.0, 0.1)
		tween.tween_property($screen_damage.material, "shader_parameter/intensity", 1.0 - (float(Globals.health) / float(Globals.MAX_HEALTH)), 0.4)
	else:
		# Heal: smoothly reduce the damage overlay to match new health
		var target_intensity := 1.0 - (float(Globals.health) / float(Globals.MAX_HEALTH))
		var tween = create_tween()
		tween.tween_property($screen_damage.material, "shader_parameter/intensity", target_intensity, 0.5)

	health_bar.value = Globals.health

func _on_shield_changed() -> void:
	shield_bar.value = Globals.shield
#displays shop named shopName
func display_shop(shopName : String) -> void:
	shop.display(shopName)


func _on_main_menu_button_button_up() -> void:
	#first click = warning, click second time to confirm
	if not warning_issued:
		$pause_screen/VBoxContainer/HBoxContainer/main_menu_button.text = "Fakt? Smaže to neuložený postup."
		warning_issued = true
	else:
		#reset game progress and quit to main menu
		PlayerInventory.reset_inventory()
		Globals.reset()
		get_tree().paused = false
		#no need to reset warning_issued, scene is changed
		get_tree().change_scene_to_file("res://scenes/user_interface/level_menu.tscn")


func _on_continue_button_button_up() -> void:
	get_tree().paused = false
	pause_screen.hide()

func _on_volume_slider_drag_ended(value_changed: bool) -> void:
	if value_changed:
		Globals.volume = $pause_screen/VBoxContainer/volume_slider.value
