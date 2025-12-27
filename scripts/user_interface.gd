extends CanvasLayer

@onready var health_bar = $health_bar
@onready var inventory = $inventory
@onready var shop = $shop

#defined for both hotbar and inventory
var holding_item = null #item player is currently holding
var warning_issued : bool = false

func _ready() -> void:
	Globals.health_changed.connect(_on_health_changed)
	Globals.bago_changed.connect(_on_bago_changed)
	_on_health_changed()
	_on_bago_changed()


func _input(event : InputEvent) -> void:
	if event.is_action_pressed("inventory") and not get_tree().paused:
		#toggle visibility of inventory
		inventory.visible = !inventory.visible
		inventory.initialize_inventory()
	if event.is_action_pressed("pause"):
		#toggle pause menu
		if not get_tree().paused:
			get_tree().paused = true
			$pause_screen.show()
			$continue_button.show()
			$main_menu_button.show()
			$save_game_button.show()
			$save_filename.show()
			$save_message.show()
			$save_message.text = "Jméno souboru pro uložení hry:"
		else:
			_on_continue_button_button_up()
	if event.is_action_pressed("scroll_up") and not get_tree().paused:
		PlayerInventory.active_item_scroll_down()
	elif event.is_action_pressed("scroll_down") and not get_tree().paused:
		PlayerInventory.active_item_scroll_up()


func _on_bago_changed() -> void:
	$bago_label.text = "Bago: " + str(Globals.bago)


func _on_health_changed() -> void:
	health_bar.value = Globals.health


#displays shop named shopName
func display_shop(shopName : String) -> void:
	shop.display(shopName)


func _on_main_menu_button_button_up() -> void:
	#first click = warning, click second time to confirm
	if not warning_issued:
		$main_menu_button.text = "Fakt? Smaže to neuložený postup."
		warning_issued = true
	else:
		#reset game progress and quit to main menu
		PlayerInventory.reset_inventory()
		Globals.reset()
		get_tree().paused = false
		#no need to reset warning_issued, scene is changed
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")


func _on_continue_button_button_up() -> void:
	get_tree().paused = false
	$pause_screen.hide()
	$continue_button.hide()
	$main_menu_button.hide()
	$save_game_button.hide()
	$save_filename.hide()
	$save_message.hide()


func _on_save_game_button_up() -> void:
	var save_file = Globals.save_game($save_filename.text)
	if  save_file == "":
		$save_message.text = "Saving failed, save name probably already exists!"
	else:
		$save_message.text = "Game saved in ./saves/" + save_file + ".json"
