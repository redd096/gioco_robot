extends PanelContainer

@onready var category_label: Label = %CategoryLabel
@onready var timer_label: Label = %TimerLabel
@onready var title_label: Label = %TitleLabel
@onready var body_label: Label = %BodyLabel
@onready var hint_label: Label = %HintLabel
@onready var progress_bar: ProgressBar = %ProgressBar


func render_alert(alert: Dictionary) -> void:
	var event: Dictionary = alert.event
	var status: String = alert.status
	category_label.text = "ADDESTRAMENTO" if event.get("hint", "") != "" else ("BERSAGLIO FINALE" if event.get("boss", false) else "EMERGENZA")
	timer_label.text = ("%.1fs" % alert.time_left) if status == "active" else ("RISOLTA" if status == "success" else "FALLITA")
	title_label.text = event.title
	body_label.text = event.body if status == "active" else alert.result
	var extra: String = event.get("hint", "") if alert.attempt == "" else alert.attempt
	hint_label.text = extra
	hint_label.visible = status == "active" and extra != ""
	progress_bar.value = clampf((alert.time_left / event.seconds) * 100.0, 0.0, 100.0) if status == "active" else 100.0
	match status:
		"success": modulate = Color(0.62, 1.0, 0.82)
		"failure": modulate = Color(1.0, 0.48, 0.42)
		_: modulate = Color(1.0, 0.92, 0.88) if not event.get("boss", false) else Color(1.0, 0.82, 0.42)

