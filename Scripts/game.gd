extends Node2D

## Board Dimensions
const board_dimensions : Vector2i = Vector2i(5, 2)

## Scenes
const METAL : PackedScene = preload("res://Scenes/metal.tscn")
const CARD = preload("res://Scenes/card.tscn")

## Board Container Nodes
@onready var board : GridContainer= $"Play Container/Vertical Container/Board Grid Container"
@onready var hand : HBoxContainer = $"Play Container/Hand Container"
@onready var board_slots : GridContainer = $"Board Container/Vertical Container/Grid Container"

## Audio Manager Node
@onready var audio_manager = $"Audio Manager"

## Board Slot Count
@onready var board_slot_count : int = len(board.get_children())

## Gameplay Resource Label Nodes
@onready var plays_text : Label = $"UI/Plays Text"
@onready var swaps_text : Label = $"UI/Swaps Text"
@onready var infusion_text : Label = $"UI/Infusion Text"

## Infusion Button
@onready var infuse_button = $"Board Container/Vertical Container 2/Infuse Button"

## Metals Manager
@onready var metals : Line2D = $Metals
@onready var available_metal_positions : Array = Array(metals.points)

## Gameplay Resources
var level_data : Level = load("res://Data/Levels/level_"+str(ProgressionTracker.level)+".tres")
@onready var plays_per_infusion : int = level_data.plays_per_infusion
@onready var swaps_per_infusion : int = level_data.swaps_per_infusion
@onready var total_infusions : int = level_data.total_infusions
@onready var available_plays : int = plays_per_infusion
@onready var available_swaps : int = swaps_per_infusion
@onready var available_infusions : int = total_infusions

## Alchemy Tracking
var metal_counts : Dictionary = {"Lead" = 0, "Tin" = 0, "Iron" = 0, "Copper" = 0, "Quicksilver" = 0, "Silver" = 0, "Gold" = 0,}
@export var metal_rules : Array[AlchemyRule]

## A utility function to convert card index to board coordinate
func card_idx_to_coords(index : int, board_width : int) -> Vector2:
	@warning_ignore("integer_division")
	return Vector2(index % board_width, floor(index / board_width))

## A constructor function which runs when the game enters the scene tree for the first time
func _ready() -> void:
	for card_data in level_data.starting_cards:
		var card_node = CARD.instantiate()
		card_node.card_data = card_data
		hand.add_child(card_node)
	
	for card in hand.get_children():
		card.connect("card_dropped", drop_card)
	update_ui_text()

## A "toggle cutscene" function to stop input handling and disable the infuse button
func toggle_cutscene_mode() -> void:
	## TODO STOP INPUT HANDLING FOR CARDS, DISABLE INFUSE BUTTON
	infuse_button.disabled = !infuse_button.disabled

## An "infusion" function to conduct the infusion process when the infuse button is pressed
func infuse() -> bool:
	# Play sound
	audio_manager.infuse.play()
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
		if !(await activate_card(card)): return false
	# Reset plays and swaps
	available_plays = plays_per_infusion
	available_swaps = swaps_per_infusion
	available_infusions -= 1
	update_ui_text()
	if available_infusions == 0:
		await level_failure()
	toggle_cutscene_mode()
	return true

func level_failure():
	print("Level failed.")
	available_plays = 0
	available_swaps = 0
	update_ui_text()
	# Play sound
	audio_manager.loss.play()
	await get_tree().create_timer(3).timeout
	get_tree().reload_current_scene()
	
func level_victory(metal : Metal):
	print("Level succeeded.")
	# Play sound
	audio_manager.victory.play()
	var screen_center : Vector2 = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width")/2, ProjectSettings.get_setting("display/window/size/viewport_height")/2)
	tween_animate(metal, "global_position", screen_center, 0.5, Tween.TRANS_CUBIC, 2)
	await tween_animate(metal, "scale", Vector2(2.0, 2.0), 0.5, Tween.TRANS_CUBIC, 2)
	await get_tree().create_timer(3).timeout
	ProgressionTracker.level += 1
	if ProgressionTracker.level == 4:
		ProgressionTracker.level = 1
	get_tree().reload_current_scene()
	
func tween_animate(object : Object, property : String, final_val : Variant, duration : float, transition : Tween.TransitionType, z_idx_offset_during_anim : int = 0) -> void:
	assert(object.global_position, "Cannot tween move an object with no global_position.")
	object.z_index += z_idx_offset_during_anim
	var tween = get_tree().create_tween()
	tween.tween_property(object, property, final_val, duration).set_trans(transition)
	await get_tree().create_timer(duration).timeout
	object.z_index -= z_idx_offset_during_anim


## A card activation function to activate cards (visually and functionally) during infusion
func activate_card(card : Card) -> bool:
	# Play sound
	audio_manager.activate_card.play()
	card.z_index += 1
	await tween_animate(card, "scale", Vector2(1.5, 1.5), 0.1, Tween.TRANS_CUBIC)
	
	if card.card_data.effect_type == "Add/Subtract":
		# "Add" Code:
		var offscreen_center_above : Vector2 = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width")/2, -ProjectSettings.get_setting("display/window/size/viewport_height")/2)
		if !(await create_metal(card.card_data.metal_type, offscreen_center_above)): return false
	elif card.card_data.effect_type == "Multiply/Divide":
		## CRY
		pass
	else:
		printerr("A card was activated that did not have a valid effect type, invalid effect type: ", card.card_data.effect_type)

	await tween_animate(card, "scale", Vector2(1.0, 1.0), 0.25, Tween.TRANS_CUBIC)
	card.z_index -= 1
	if !(await react()): return false
	return true

func create_metal(metal_type : String, starting_position : Vector2) -> bool:
	var metal : Node2D = METAL.instantiate()
	metal.metal_type = metal_type
	metals.add_child(metal)
	assert(len(available_metal_positions) != 0, "There are no remaining positions at which to place metals.")
	var position_index : int = randi_range(0, len(available_metal_positions) - 1)
	metal.global_position = starting_position
	# Move metal from starting position to random metals point
	await tween_animate(metal, "global_position", available_metal_positions[position_index], 0.5, Tween.TRANS_CUBIC, 2)
	available_metal_positions.pop_at(position_index)
	# Update metal counts
	metal_counts[metal.metal_type] += 1
	print("[+1 ", metal.metal_type, "]")
	# Play sound
	audio_manager.metal_impact.play()
	# Check win condition
	if metal.metal_type == level_data.goal_metal:
		await level_victory(metal)
		return false
	return true


## A "reaction" function to conduct the reactions that occur when the metal counts change
func react() -> bool:
	## TESTS RULES IN ORDER FROM LOWEST RARITY TO HIGHEST
	for rule : AlchemyRule in metal_rules:
		if rule_met(rule, metal_counts): 
			print(rule.name, " is triggered!")
			# Play out reaction according to rule
			
			# Find reactant nodes
			var reactant_nodes : Array[Metal] = []
			for reactant : AlchemySubstance in rule.reactants:
				var metal_nodes_to_find : int = reactant.amount
				for metal_node : Metal in metals.get_children():
					if metal_node.metal_type == reactant.name:
						reactant_nodes.push_back(metal_node)
						metal_nodes_to_find -= 1
						if metal_nodes_to_find == 0:
							break
			
			# Make metals collide
			var screen_center : Vector2 = Vector2(ProjectSettings.get_setting("display/window/size/viewport_width")/2, ProjectSettings.get_setting("display/window/size/viewport_height")/2)
			for reactant_node : Metal in reactant_nodes:
				available_metal_positions.push_back(reactant_node.global_position)
				tween_animate(reactant_node, "global_position", screen_center, 0.5, Tween.TRANS_CUBIC, 2)
			await get_tree().create_timer(0.5).timeout
			
			# Destroy reactant nodes
			for reactant_node : Metal in reactant_nodes:
				metal_counts[reactant_node.metal_type] -= 1
				print("[-1 ", reactant_node.metal_type, "]")
				reactant_node.queue_free()
			
			# Create new metal on the board
			assert(rule.product.amount == 1, "The code is currently written to only allow 1 product to be generated. Modify it to allow more.")
			if !(await create_metal(rule.product.name, screen_center)): return false
			if !(await react()): return false
			return true
	return true

## A "rule evaluation" function to check if the current metal counts are sufficient
func rule_met(rule : AlchemyRule, substance_counts : Dictionary) -> bool:
	# Check if there are insufficient reactants
	for reactant in rule.reactants:
		if substance_counts[reactant.name] < reactant.amount: 
			return false
	# Play sound
	audio_manager.reaction.play()
	# If there are sufficient reactants, return true
	return true
	

## A UI function which updates the text on screen when the values they represent change
func update_ui_text() -> void:
	plays_text.text = str(available_plays)
	swaps_text.text = str(available_swaps)
	infusion_text.text = str(available_infusions)

## A card drop function that determines whether a card is being played or swapped
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

## A card swapping function
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
	# Play sound
	audio_manager.swap_cards.play()
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
	
## A card playing function
func play_new_card(card : Control, index : int) -> void:
	print("Playing card to slot ", index, ".")
	if board.get_child(index).isNullcard():
		# Play sound
		audio_manager.play_card.play()
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
		var card_placement_area : Area2D = card.placement_area
		card_placement_area.set_collision_mask_value(4, true)
		# Subtract 1 from the remaining available plays
		available_plays -= 1
	else:
		print("Not a valid place for card.")

# Triggered when the player presses the infusion button
func _on_infuse_button_pressed() -> void:
	infuse()
