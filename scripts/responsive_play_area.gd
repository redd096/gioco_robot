extends Container

@export var landscape_alert_ratio: float = 0.57
@export var portrait_alert_ratio: float = 0.54
@export var gap: float = 12.0
@export var portrait_breakpoint: float = 1.05

var left_handed := false

@onready var alerts_column: Control = $AlertsColumn
@onready var controls_panel: Control = $ControlsPanel


func _ready() -> void:
	resized.connect(_queue_layout)
	_queue_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_SORT_CHILDREN:
		_layout_children()
	elif what == NOTIFICATION_CHILD_ORDER_CHANGED:
		minimum_size_changed.emit()
		queue_sort()


func _get_minimum_size() -> Vector2:
	if not is_instance_valid(alerts_column) or not is_instance_valid(controls_panel):
		return Vector2(640, 430)
	var alerts_min: Vector2 = alerts_column.get_combined_minimum_size()
	var controls_min: Vector2 = controls_panel.get_combined_minimum_size()
	return Vector2(alerts_min.x + controls_min.x + gap, max(alerts_min.y, controls_min.y))


func set_left_handed(value: bool) -> void:
	left_handed = value
	_queue_layout()


func _queue_layout() -> void:
	minimum_size_changed.emit()
	queue_sort()


func _is_portrait() -> bool:
	var viewport_size: Vector2 = get_viewport_rect().size
	return viewport_size.x / max(viewport_size.y, 1.0) < portrait_breakpoint


func _layout_children() -> void:
	if not is_instance_valid(alerts_column) or not is_instance_valid(controls_panel):
		return
	var alert_ratio := portrait_alert_ratio if _is_portrait() else landscape_alert_ratio
	var alerts_width: float = floor((size.x - gap) * alert_ratio)
	var controls_width: float = size.x - alerts_width - gap
	if left_handed:
		fit_child_in_rect(controls_panel, Rect2(0, 0, controls_width, size.y))
		fit_child_in_rect(alerts_column, Rect2(controls_width + gap, 0, alerts_width, size.y))
	else:
		fit_child_in_rect(alerts_column, Rect2(0, 0, alerts_width, size.y))
		fit_child_in_rect(controls_panel, Rect2(alerts_width + gap, 0, controls_width, size.y))
