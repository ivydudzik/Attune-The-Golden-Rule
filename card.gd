extends Panel

signal card_dropped(card : Panel, index : int)

var hovering : bool = false
var dragging : bool = false
var returning : bool = false
var drag_start : Vector2
var offset : Vector2
var slot : Panel = null

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
	if dragging:
		# Set card to dragging color
		modulate = "bcbcbc"
		# Move card position towards mouse
		global_position = lerp(global_position, get_global_mouse_position() - offset, 15*delta)
		# If the mouse is released while dragging, stop dragging
		if Input.is_action_just_released("click") and !returning:
			dragging = false
			# If there is a valid slot for the card to be dropped into, emit a signal to the game script
			if slot != null:
				emit_signal("card_dropped", self, slot.get_index())
				## TEMP Make the card stationary once it has been set down
				#$Area.input_pickable = false
			# Otherwise, send the card back to where it was dragged from
			else:
				return_to_drag_start()
	elif hovering:
		# Set card to hovering color
		modulate = "bcbcbc"
		# If the mouse is clicked while hovering, begin dragging
		if Input.is_action_just_pressed("click") and !returning:
			offset = get_global_mouse_position() - global_position
			drag_start = global_position
			dragging = true
	else:
		# Set card to default color
		modulate = "ffffff"

func _on_area_mouse_entered():
	hovering = true

func _on_area_mouse_exited():
	if hovering:
		hovering = false

func _on_placement_area_area_entered(area):
	slot = area.get_parent()

func _on_placement_area_area_exited(area):
	slot = null
