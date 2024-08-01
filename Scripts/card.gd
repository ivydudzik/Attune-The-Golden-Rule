class_name Card extends Control

signal card_dropped(card : Panel, index : int)

# Data Variables
@export var card_data : CardDataResource
@export var is_display_card : bool = false
var flipped : bool = false

# Manipulation Variables
var hovering : bool = false
var dragging : bool = false
var returning : bool = false
var drag_start : Vector2
var offset : Vector2
var slot : Panel = null

@onready var placement_area = $"Card Panel/Placement Area"
@onready var area = $"Card Panel/Area"


func _ready() -> void:
	assert(card_data, "No card data provided for card " + str(get_index()) + " in hand.")
	$"Card Panel/Label".text = card_data.title
	$"Card Panel/Sprite".texture = card_data.image
	$"Card Panel/Sprite".scale = card_data.image_scaling
	if card_data.effect_type == "Add/Subtract":
		$"Card Panel/Multiply Label".hide()
	else:
		$"Card Panel/Add Label".hide()

# This card is not a nullcard
func isNullcard() -> bool:
	return false

func end_return() -> void:
	returning = false
	
func return_to_drag_start() ->  void:
	returning = true
	var tween = get_tree().create_tween()
	tween.tween_property(self, "global_position", drag_start, 0.25).set_trans(Tween.TRANS_SINE)
	tween.tween_callback(end_return)

func _process(delta) -> void:
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
				if !is_display_card:
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

func _on_area_mouse_entered() -> void:
	hovering = true

func _on_area_mouse_exited() -> void:
	hovering = false

func _on_placement_area_area_entered(new_area) -> void:
	slot = new_area.get_parent()

func _on_placement_area_area_exited(_area) -> void:
	slot = null
