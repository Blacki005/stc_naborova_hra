extends Control
const SlotClass = preload("res://scripts/slot.gd")

@onready var hotbar_slots = $hotbar_slots.get_children()

func _ready() -> void:
	#initialize hotbar_slots and inventory
	for i in range(hotbar_slots.size()):
		#gui input je signal entity slot, slot_gui_input je fce na kterou to chci bindnout
		hotbar_slots[i].gui_input.connect(slot_gui_input.bind(hotbar_slots[i]))
		
		#call slot.refresh_style when active_item_updated signal is emitted:
		PlayerInventory.active_item_updated.connect(hotbar_slots[i].refresh_style)
		hotbar_slots[i].slot_index = i
		hotbar_slots[i].slot_type = SlotClass.SlotType.HOTBAR
	initialize_hotbar()


#handles mouse input on slots
func slot_gui_input(event: InputEvent, slot: SlotClass) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT && event.pressed:
			if find_parent("user_interface").holding_item != null:
				if !slot.item: #place holding item to slot
					left_click_empty_slot(slot)
				else:
					if find_parent("user_interface").holding_item.item_name != slot.item.item_name: #different items, so swap
						left_click_different_item(event, slot)
					else: #same item, try to merge
						left_click_same_item(slot)
			elif slot.item:
				left_click_not_holding(slot)

#handles item movement with mouse when holding it
func _input(_event : InputEvent) -> void:
	if find_parent("user_interface").holding_item:
		find_parent("user_interface").holding_item.global_position = get_global_mouse_position()


#swap holding item with item in clicked slot
func left_click_different_item(event: InputEvent, slot: SlotClass) -> void:
	PlayerInventory.erase_item(slot, true)
	PlayerInventory.add_item_to_empty_slot(find_parent("user_interface").holding_item, slot, true)
	var temp_item = slot.item
	slot.pickFromSlot()
	temp_item.global_position = event.global_position
	slot.putIntoSlot(find_parent("user_interface").holding_item)
	find_parent("user_interface").holding_item = temp_item


#add item to empty slot
func left_click_empty_slot(slot: SlotClass) -> void:
	PlayerInventory.add_item_to_empty_slot(find_parent("user_interface").holding_item, slot, true)
	slot.putIntoSlot(find_parent("user_interface").holding_item)
	find_parent("user_interface").holding_item = null


#try to add holding item to clicked slot, keep the rest as holding
func left_click_same_item(slot: SlotClass) -> void:
	var stack_size = int(JsonData.item_data[slot.item.item_name]["StackSize"])
	var able_to_add = stack_size - slot.item.item_quantity
	if able_to_add >= find_parent("user_interface").holding_item.item_quantity:
		PlayerInventory.add_item_quantity(slot, find_parent("user_interface").holding_item.item_quantity, true)
		slot.item.add_item_quantity(find_parent("user_interface").holding_item.item_quantity)
		find_parent("user_interface").holding_item.queue_free()
		find_parent("user_interface").holding_item = null
	else:
		PlayerInventory.add_item_quantity(slot, able_to_add, true)
		slot.item.add_item_quantity(able_to_add)
		find_parent("user_interface").holding_item.decrease_item_quantity(able_to_add)


#pick item from clicked slot
func left_click_not_holding(slot: SlotClass) -> void:
	PlayerInventory.erase_item(slot, true)
	find_parent("user_interface").holding_item = slot.item
	slot.pickFromSlot()
	find_parent("user_interface").holding_item.global_position = get_global_mouse_position()

#is called whenever inventory is opened, refresh hotbar_slots according to inventory array
func initialize_hotbar() -> void:
	for i in range(hotbar_slots.size()):
		if PlayerInventory.hotbar.has(i):
			hotbar_slots[i].initialize_item(PlayerInventory.hotbar[i][0], PlayerInventory.hotbar[i][1])

func _on_mouse_entered() -> void:
	Globals.able_to_attack = false


func _on_mouse_exited() -> void:
	Globals.able_to_attack = true
