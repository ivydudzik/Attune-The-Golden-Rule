extends Node2D

@onready var board := $"Play Container/Vertical Container/Board Grid Container"
@onready var hand := $"Play Container/Hand Container"
@onready var board_slots := $"Board Container/Vertical Container/Grid Container"

@onready var plays_text = $"UI/Plays Text"
@onready var swaps_text = $"UI/Swaps Text"

@export var available_plays : int
@export var available_swaps : int

func _ready():
	for card in hand.get_children():
		card.connect("card_dropped", drop_card)

	#available_plays = 1
	#available_swaps = 1
	update_ui_text()

func update_ui_text():
	plays_text.text = str(available_plays)
	swaps_text.text = str(available_swaps)

func drop_card(card : Panel, index : int) -> void:
	print("Dropping card to slot ", index, ".")
	if card in board.get_children():
		if available_swaps == 0: 
			print("Cannot swap card, no more available swaps.")
			card.return_to_drag_start()
			return
		move_card(card, index)
		available_swaps -= 1
		update_ui_text()
	else:
		if available_plays == 0: 
			print("Cannot play card, no more available plays.")
			card.return_to_drag_start()
			return
		play_new_card(card, index)
		available_plays -= 1
		update_ui_text()

func move_card(card : Panel, index : int) -> void:
	var displaced_child : Panel = board.get_child(index)
	var old_index : int = card.get_index()
	if old_index == index: 
		print("Cannot move card to slot ", index, " from ", old_index, " because it is already there.")
		card.return_to_drag_start()
		return
	print("Moving card to slot ", index, " from ", old_index, ".")
	if board.get_child(index).isNullcard():
		# Switch which slot is on the "full" and "empty" collision layters
		var empty_board_slot_placement_area : Area2D = board_slots.get_child(index).get_child(0)
		empty_board_slot_placement_area.set_collision_layer_value(3, false)
		empty_board_slot_placement_area.set_collision_layer_value(4, true)
		var full_board_slot_placement_area : Area2D = board_slots.get_child(old_index).get_child(0)
		full_board_slot_placement_area.set_collision_layer_value(3, true)
		full_board_slot_placement_area.set_collision_layer_value(4, false)
	# Switch cards
	board.move_child(card, index)
	board.move_child(displaced_child, old_index)
	

func play_new_card(card : Panel, index : int) -> void:
	print("Playing card to slot ", index, ".")
	if board.get_child(index).isNullcard():
		# Delete the Nullcard
		board.get_child(index).queue_free()
		# Remove the new card from the hand
		hand.remove_child(card)
		# Add the new card to the board
		board.add_child(card)
		board.move_child(card, index)
		# Make board slot full instead of empty
		var board_slot_placement_area : Area2D = board_slots.get_child(index).get_child(0)
		board_slot_placement_area.set_collision_layer_value(3, false)
		board_slot_placement_area.set_collision_layer_value(4, true)
		# Make new card look for full slots as well as empty
		var card_placement_area : Area2D = card.get_child(2)
		card_placement_area.set_collision_mask_value(4, true)
	else:
		print("Not a valid place for card.")
