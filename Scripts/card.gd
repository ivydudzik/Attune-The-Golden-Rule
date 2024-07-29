class_name Card extends Control

signal card_dropped(card : Panel, index : int)

# Data Variables
@export var card_data : CardDataResource
var flipped : bool = false

# Manipulation Variables
var hovering : bool = false
var dragging : bool = false
var returning : bool = false
var drag_start : Vector2
var offset : Vector2
var slot : Panel = null

func _ready():
	assert(card_data, "No card data provided for card " + str(get_index()) + " in hand.")
	$"Card Panel/Label".text = card_data.title

# This card is not a nullcard
func isNullcard():
	return false

func end_return():
	returning = false
	
func return_to_drag_start():
	returning = true
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", drag_start, 0.25).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(end_return)

func _process(delta):
	if returning:
		# Set card to default color
		modulate = "ffffff"
	elif dragging:
		# Set card to dragging color
		modulate = "bcbcbc"
		# Move card position towards mouse
		global_position = lerp(global_position, get_global_mouse_position() - offset, 15*delta)
		# If the mouse is released while dragging, stop dragging
		if Input.is_action_just_released("click"):
			dragging = false
			# If there is a valid slot for the card to be dropped into, emit a signal to the game script
			if slot != null:
				emit_signal("card_dropped", self, slot.get_index())
			# Otherwise, send the card back to where it was dragged from
			else:
				return_to_drag_start()
	elif hovering:
		# Set card to hovering color
		modulate = "bcbcbc"
		# If the mouse is clicked while hovering, begin dragging
		if Input.is_action_just_pressed("click"):
			offset = get_global_mouse_position() - global_position
			drag_start = global_position
			dragging = true
	else:
		# Set card to default color
		modulate = "ffffff"

func _on_area_mouse_entered():
	hovering = true

func _on_area_mouse_exited():
	hovering = false

func _on_placement_area_area_entered(area):
	slot = area.get_parent()

func _on_placement_area_area_exited(_area):
	slot = null
