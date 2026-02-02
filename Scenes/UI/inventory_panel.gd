extends PanelContainer
class_name InventoryPanel

@export var title_text := "Inventory"
@export var cap_align := HORIZONTAL_ALIGNMENT_RIGHT
@export var cap_min_width := 168.0

@onready var title_label: Label = $Content/Header/HeaderRow/Title
@onready var cap_label: Label = $Content/Header/HeaderRow/CapLabel
@onready var cap_bar: ProgressBar = $Content/CapBar/CapProgress
@onready var list: VBoxContainer = $Content/ListScroll/List

func _ready() -> void:
	if title_label:
		title_label.text = title_text
	if cap_label:
		cap_label.horizontal_alignment = cap_align
		cap_label.custom_minimum_size = Vector2(cap_min_width, 0)
