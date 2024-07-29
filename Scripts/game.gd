extends Node2D

@onready var board := $"Play Container/Vertical Container/Board Grid Container"
@onready var hand := $"Play Container/Hand Container"
@onready var board_slots := $"Board Container/Vertical Container/Grid Container"

@onready var board_slot_count : int = len(board.get_children())

@onready var plays_text := $"UI/Plays Text"
@onready var swaps_text := $"UI/Swaps Text"
@onready var infusion_text = $"UI/Infusion Text"

@export var plays_per_infusion : int
@export var swaps_per_infusion : int
@export var total_infusions : int

@onready var available_plays : int = plays_per_infusion
@onready var available_swaps : int = swaps_per_infusion
@onready var available_infusions : int = total_infusions

const board_dimensions : Vector2i = Vector2i(5, 2)

const METAL : PackedScene = preload("res://Scenes/metal.tscn")

## Utility function to convert card index to board coordinate
func card_idx_to_coords(index : int, board_width : int) -> Vector2:
	return Vector2(index % board_width, floor(index / board_width))

func _ready() -> void:
	for card in hand.get_children():
		card.connect("card_dropped", drop_card)
	update_ui_text()

func toggle_cutscene_mode() -> void:
	## STOP INPUT HANDLING FOR CARDS, DISABLE INFUSE BUTTON
	pass

func infuse() -> void:
	toggle_cutscene_mode()
	for index in board_slot_count:
		var card : Control = board.get_child(index)
		var slot : Control = board_slots.get_child(index)
		# Skip null cards
		if card.isNullcard():
			continue
		# Skip dormant cards
		if slot.slot_type == "Dormant":
			continue
		# Wait for the card activation animations to play before moving on
		await activate_card(card)
	# Reset plays and swaps
	available_plays = plays_per_infusion
	available_swaps = swaps_per_infusion
	available_infusions -= 1
	update_ui_text()

func activate_card(card : Card) -> void:
	var tween = get_tree().create_tween()
	tween.tween_property(card, "scale", Vector2(1.5, 1.5), 0.1).set_trans(Tween.TRANS_CUBIC)
	await get_tree().create_timer(0.1).timeout

	if card.card_data.effect_type == "Add/Subtract":
		var metal : Node2D = METAL.instantiate()
		metal.metal_type = card.card_data.metal_type
		$Metals.add_child(metal)
		# Move metal to [TEST: MOUSE POSITION]
		metal.global_position = get_global_mouse_position()
		
		#var tween2 = get_tree().create_tween()
		#tween2.tween_property(card, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_CUBIC)
		#await get_tree().create_timer(0.25).timeout
	
	if card.card_data.effect_type == "Multiply/Divide":
		## CRY
		pass
		#var metal : Node2D = METAL.instantiate()
		#metal.metal_type = card.card_data.metal_type
		#$"Board Container/Metals Grid Container".add_child(metal)
		#metal.global_position = get_global_mouse_position()

	var tween2 = get_tree().create_tween()
	tween2.tween_property(card, "scale", Vector2(1.0, 1.0), 0.25).set_trans(Tween.TRANS_CUBIC)
	await get_tree().create_timer(0.25).timeout
	

func update_ui_text() -> void:
	plays_text.text = str(available_plays)
	swaps_text.text = str(available_swaps)
	infusion_text.text = str(available_infusions)

func drop_card(card : Control, index : int) -> void:
	print("Dropping card to slot ", index, ".")
	if card in board.get_children():
		if available_swaps == 0: 
			print("Cannot swap card, no more available swaps.")
			card.return_to_drag_start()
			return
		move_card(card, index)
		update_ui_text()
	else:
		if available_plays == 0: 
			print("Cannot play card, no more available plays.")
			card.return_to_drag_start()
			return
		play_new_card(card, index)
		update_ui_text()

func move_card(card : Control, index : int) -> void:
	var displaced_child : Control = board.get_child(index)
	var old_index : int = card.get_index()
	if old_index == index: 
		print("Cannot move card to slot ", index, " from ", old_index, " because it is already there.")
		card.return_to_drag_start()
		return
	if card_idx_to_coords(index, board_dimensions.x).distance_to(card_idx_to_coords(old_index, board_dimensions.x)) > 1:
		print("Cannot move card to slot ", index, " from ", old_index, " because it is not adjacent.")
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
	# Subtract 1 from the remaining available swaps
	available_swaps -= 1
	

func play_new_card(card : Control, index : int) -> void:
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
		var card_placement_area : Area2D = card.get_child(0).get_child(2)
		card_placement_area.set_collision_mask_value(4, true)
		# Subtract 1 from the remaining available plays
		available_plays -= 1
	else:
		print("Not a valid place for card.")


func _on_infuse_button_pressed() -> void:
	infuse()
