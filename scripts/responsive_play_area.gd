extends Container

@export var landscape_alert_ratio: float = 0.57
@export var gap: float = 12.0
@export var portrait_breakpoint: float = 1.05

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
	if _is_portrait():
		return Vector2(max(alerts_min.x, controls_min.x), alerts_min.y + controls_min.y + gap)
	return Vector2(alerts_min.x + controls_min.x + gap, max(alerts_min.y, controls_min.y))


func _queue_layout() -> void:
	minimum_size_changed.emit()
	queue_sort()


func _is_portrait() -> bool:
	var viewport_size: Vector2 = get_viewport_rect().size
	return viewport_size.x / max(viewport_size.y, 1.0) < portrait_breakpoint


func _layout_children() -> void:
	if not is_instance_valid(alerts_column) or not is_instance_valid(controls_panel):
		return
	if _is_portrait():
		var controls_height: float = controls_panel.get_combined_minimum_size().y
		var alerts_height: float = max(alerts_column.get_combined_minimum_size().y, size.y - controls_height - gap)
		fit_child_in_rect(controls_panel, Rect2(0, 0, size.x, controls_height))
		fit_child_in_rect(alerts_column, Rect2(0, controls_height + gap, size.x, alerts_height))
	else:
		var alerts_width: float = floor((size.x - gap) * landscape_alert_ratio)
		fit_child_in_rect(alerts_column, Rect2(0, 0, alerts_width, size.y))
		fit_child_in_rect(controls_panel, Rect2(alerts_width + gap, 0, size.x - alerts_width - gap, size.y))

