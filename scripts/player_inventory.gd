extends Node

#signal to tell a slot to update it's visual style
signal active_item_updated
signal inventory_updated

const NUM_INVENTORY_SLOTS = 12
const SlotClass = preload("res://scripts/slot.gd")
const ItemClass = preload("res://scripts/item.gd")
const NUM_HOTBAR_SLOTS = 6

#Initial values of hotbar and inventory
var inventory : Dictionary = {
}

var hotbar : Dictionary = {
	#0 : ["GreenPotion", 4],
	#1 : ["RedPotion", 4],
	#2 : ["BluePotion", 4]
}

#current active item slot
var active_item_slot : int = 0
@onready var audiostreamplayer : AudioStreamPlayer

func _ready() -> void:
	audiostreamplayer = AudioStreamPlayer.new()
	audiostreamplayer.stream = load("res://sound/consuming.mp3")
	add_child(audiostreamplayer)

func _input(event: InputEvent) -> void:
	if event.is_action_released("consume") and hotbar.has(active_item_slot):
		var active_item_name : String = PlayerInventory.hotbar[PlayerInventory.active_item_slot][0]
		if JsonData.item_data[active_item_name]["ItemCategory"] == "Consumable":
			remove_item(active_item_name, 1)
			Globals.health += JsonData.item_data[active_item_name]["Healing"]
			Globals.shield += JsonData.item_data[active_item_name]["Shield"]
			audiostreamplayer.play()


#add item_quantity of item_name in inventory
func add_item(item_name: String, item_quantity: int) -> bool:
	for item : int in inventory:
		if inventory[item][0] == item_name:
			#there already is this item type in inventory, try to add to it
			var stack_size : int = int(JsonData.item_data[item_name]["StackSize"])
			var able_to_add : int = stack_size - inventory[item][1]
			if able_to_add >= item_quantity:
				inventory[item][1] += item_quantity
				update_slot_visual(item, inventory[item][0], inventory[item][1], false)
				emit_signal("inventory_updated")
				return true
			else:
				inventory[item][1] += able_to_add
				update_slot_visual(item, inventory[item][0], inventory[item][1], false)
				item_quantity -= able_to_add
	
	#item doesn't exist in inventory yet, add to an empty slot
	for i in range(NUM_HOTBAR_SLOTS):
		if hotbar.has(i) == false:
			hotbar[i] = [item_name, item_quantity]
			update_slot_visual(i, hotbar[i][0], hotbar[i][1], true)
			emit_signal("inventory_updated")
			return true
	
	for i in range(NUM_INVENTORY_SLOTS):
		if inventory.has(i) == false:
			inventory[i] = [item_name, item_quantity]
			update_slot_visual(i, inventory[i][0], inventory[i][1], false)
			emit_signal("inventory_updated")
			return true
	return false


#TODO: different skins for empty and full slots
func update_slot_visual(slot_index : int, item_name : String, new_quantity : int, is_hotbar : bool) -> void:
	var slot : SlotClass 
	if is_hotbar:
		slot = get_tree().get_first_node_in_group("user_interface").get_node("./hotbar/hotbar_slots/hotbar_slot_" + str(slot_index + 1))
	else:
		slot = get_tree().get_first_node_in_group("user_interface").get_node("./inventory/GridContainer/Slot" + str(slot_index + 1))
	
	if slot == null:
		printerr("Error: Slot node not found!")
		return
	
	if slot.item != null:
		#item already exists, update quantity
		if new_quantity == 0:
			slot.remove_child(slot.item)
			erase_item(slot, is_hotbar)
			return
		slot.item.set_item(item_name, new_quantity)
	else:
		#initialize slot with item that has not been in that slot
		slot.initialize_item(item_name, new_quantity)


func erase_item(slot : SlotClass, is_hotbar : bool = false) -> void:
	if is_hotbar:
		hotbar.erase(slot.slot_index)
	else:
		inventory.erase(slot.slot_index)
	emit_signal("inventory_updated")


func remove_item(item_name : String, item_quantity : int) -> bool:
	for item : int in hotbar:
			#remove from hotbar first if it is there
		if hotbar[item][0] == item_name:
			var able_to_remove : int = hotbar[item][1]
			if able_to_remove >= item_quantity:
				hotbar[item][1] -= item_quantity
				update_slot_visual(item, hotbar[item][0], hotbar[item][1], true)
				emit_signal("inventory_updated")
				return true
			else:
				item_quantity -= hotbar[item][1]
				hotbar[item][1] = 0
				update_slot_visual(item, hotbar[item][0], hotbar[item][1], true)
	for item : int in inventory:
		if inventory[item][0] == item_name:
			#item found, remove it as much as possible
			var able_to_remove : int = inventory[item][1]
			if able_to_remove >= item_quantity:
				#we can remove just from the one slot, no need ti find another
				inventory[item][1] -= item_quantity
				update_slot_visual(item, inventory[item][0], inventory[item][1], false)
				emit_signal("inventory_updated")
				return true
			else:
				item_quantity -= inventory[item][1]
				inventory[item][1] = 0
				update_slot_visual(item, inventory[item][0], inventory[item][1], false)
	#we werent able to remove enough
	emit_signal("inventory_updated")
	return false


func add_item_to_empty_slot(item: ItemClass, slot: SlotClass, is_hotbar: bool = false) -> void:
	if is_hotbar:
		hotbar[slot.slot_index] = [item.item_name, item.item_quantity]
	else:
		inventory[slot.slot_index] = [item.item_name, item.item_quantity]


func add_item_quantity(slot: SlotClass, quantity_to_add: int, is_hotbar:bool = false) -> void:
	if is_hotbar:
		hotbar[slot.slot_index][1] += quantity_to_add
	else:
		inventory[slot.slot_index][1] += quantity_to_add

func reset_inventory() -> void:
	inventory.clear()
	emit_signal("inventory_updated")


func has_item(item_name : String) -> bool:
	for item : int in hotbar:
		if hotbar[item][0] == item_name:
			return true
	for item : int in inventory:
		if inventory[item][0] == item_name:
			return true
	return false


#hotbar functions:
func change_active_item(slot_number : int) -> void:
	active_item_slot = slot_number
	emit_signal("active_item_updated")

func active_item_scroll_up() -> void:
	if InteractionManager.can_interact:
		change_active_item((active_item_slot + 1) % NUM_HOTBAR_SLOTS)

func active_item_scroll_down() -> void:
	if InteractionManager.can_interact:
		if active_item_slot == 0:
			change_active_item(NUM_HOTBAR_SLOTS - 1)
		else:
			change_active_item(active_item_slot-1)
