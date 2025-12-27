extends Control

#implementace jako ring buffer, prepinani next a previous

@onready var anim = $Anim
@onready var sprite = $Sprite2D
@onready var price_label = $Price
@onready var count_label = $Count
@onready var name_label = $Name

var shop_name : String
var shop_goods : Array
var item_name : String
var item_count : int
var item_price : int
var i : int = 0 #used for indexing goods in array
var buffer_size : int


func display(shop_name : String) -> void:
	#load current shop's data from json
	shop_goods = load_data("res://data/shop_data/" + shop_name + ".json") #["Name", count : int, price : int]
	if shop_goods == null:
		printerr("Error: shop goods not found!")
		return
	#circular buffer to store shop goods:
	buffer_size = shop_goods.size()
	display_item(shop_goods[0])
	
	#this node does not inherit tree physics process
	get_tree().paused = true
	self.visible = true
	anim.play("trans_in")


func display_item(item_data : Array) -> void:
	sprite.texture = load("res://images/items/" + item_data[0] + ".png")
	name_label.text = item_data[0]
	item_name = item_data[0]
	
	#unused feature: limited number of items to sell
	
	#count_label.text = "K dispozici: " + str(item_data[1])
	#item_count = item_data[1]
	
	price_label.text = "Cena: " + str(item_data[2])
	item_price = item_data[2]
	
	if Globals.bago < item_price:
		$shop_button.disabled = true


#function makes sure that shop contents are stored in shop json file and plays exit animatiopn
func _on_close_button_up() -> void:
	#unused feature: limited number of items to sell requires saving on close
	
	#var file = FileAccess.open("res://data/shop_data/" + shop_name + ".json", FileAccess.WRITE)
	#if file != null:
		#file.store_string(JSON.stringify(shop_goods, "\t"))
	#else:
		#print("Error storing goods, file res://data/shop_data/" + shop_name + ".json not found!")
	
	anim.play("trans_out")
	await anim.get_tree().create_timer(0.5).timeout #wait until animation finishes
	self.visible = false
	get_tree().paused = false


#nacte data z json souboru
func load_data(file_path : String) -> Array:
	var json_string: String = FileAccess.get_file_as_string(file_path)
	var json = JSON.new()
	json.parse(json_string)
	return json.get_data()


func _on_shop_button_button_up() -> void:
	#TODO dodelat nejaky cool efekty, kdyz nema dost penez
	if Globals.bago >= item_price: #&& item_count > 0: - part of unused limited items to sell
		Globals.bago -= item_price
		item_count -= 1
		
		#ignoring item count feature for now
		if Globals.bago < item_price:
			$shop_button.disabled=true
		
		#decrease available goods - unused
		#shop_goods[i][1] -= 1
		#count_label.text = str(item_count)
		
		PlayerInventory.add_item(item_name, 1)
		
		#update globals state according to bought item
		match item_name:
			"Monitor":
				Globals.has_monitor=true
			"Keyboard":
				Globals.has_keyboard=true
			"Computer":
				Globals.has_computer=true


func _on_next_button_button_up() -> void:
	#display next item in array
	i += 1
	i %= buffer_size
	display_item(shop_goods[i])


func _on_previous_button_button_up() -> void:
	i -= 1
	i %= buffer_size
	display_item(shop_goods[i])
