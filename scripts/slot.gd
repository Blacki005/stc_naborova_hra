extends Panel

var ItemClass = preload("res://scenes/item.tscn")
var item = null
var slot_index : int
var slot_type

enum SlotType {
	HOTBAR = 0,
	INVENTORY,
}

func _ready() -> void:
	refresh_style()


func pickFromSlot() -> void:
	remove_child(item)
	var inventoryNode = find_parent("user_interface")
	if inventoryNode != null:
		inventoryNode.add_child(item)
		item = null
	refresh_style()


func putIntoSlot(new_item) -> void:
	item = new_item
	item.position = Vector2(0,0)
	var inventoryNode = find_parent("user_interface")
	inventoryNode.remove_child(item)
	add_child(item)
	refresh_style()


func initialize_item(item_name : String, item_quantity : int) -> void:
	if item == null:
		item = ItemClass.instantiate()
		add_child(item)
		item.set_item(item_name, item_quantity)
	else:
		item.set_item(item_name, item_quantity)
	refresh_style()


#TODO: refresh style of slot if its empty or full
func refresh_style():
	if slot_type == SlotType.HOTBAR:
		if PlayerInventory.active_item_slot == slot_index:
			self.self_modulate = Color(1,1,1,1) #TODO set selected item style
		else:
			self.self_modulate = Color(1,1,1,0.25) #TODO set unselected item style
	
	if item != null:
		self.tooltip_text = JsonData.item_data[item.item_name]["Description"]
	else:
		self.tooltip_text = ""
