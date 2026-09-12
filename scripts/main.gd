extends Control

const MISSION_DURATION := 180.0
const BOSS_TIME := 35.0
const SETTINGS_PATH := "user://titan_settings.cfg"
const ALERT_CARD := preload("res://scenes/emergency_card.tscn")

const DIRECTIONS := {
	"left": "SINISTRA",
	"front": "FRONTE",
	"right": "DESTRA",
	"below": "SOTTO",
}

const SYSTEM_COSTS := {
	"shield": [28.0, 0.0],
	"laser": [8.0, 36.0],
	"boost": [5.0, 24.0],
	"rescue": [0.0, 4.0],
}

var tutorial: Array[Dictionary] = [
	_event("tutorial-shield", "MISSILI A SINISTRA", "Primo contatto. Intercetta la raffica in arrivo dal settore sinistro.", 16.0, [["shield", "left"]], "Scudo orientato correttamente. Raffica neutralizzata.", 14.0, 0, "PROVA: seleziona SINISTRA, poi premi SCUDO"),
	_event("tutorial-laser", "DRONE AGGANCIATO SOTTO", "È già ancorato alla corazza: durante l'addestramento distruggilo col laser.", 16.0, [["laser", "below"]], "Drone distrutto. Il laser ha aumentato il calore.", 14.0, 0, "PROVA: seleziona SOTTO, poi premi LASER"),
	_event("tutorial-rescue", "CIVILI A DESTRA", "Una squadra di evacuazione attende nel settore destro.", 16.0, [["rescue", "right"]], "Civili recuperati senza consumare energia.", 0.0, 18, "PROVA: seleziona DESTRA, poi premi SOCCORSO"),
]

var events: Array[Dictionary] = [
	_event("missiles-left", "MISSILI A SINISTRA", "Raffica di missili in arrivo da sinistra. Proteggi il fianco sinistro oppure scatta a destra.", 12.0, [["shield", "left"], ["boost", "right"]], "Missili evitati. Settore sinistro sicuro.", 18.0),
	_event("missiles-right", "MISSILI A DESTRA", "Raffica di missili in arrivo da destra. Proteggi il fianco destro oppure scatta a sinistra.", 12.0, [["shield", "right"], ["boost", "left"]], "Minaccia evitata. Nessun impatto.", 18.0),
	_event("front-cannon", "CANNONE FRONTALE", "Un'unità nemica sta caricando il cannone davanti a noi. Colpiscila oppure para il fuoco frontalmente.", 12.0, [["laser", "front"], ["shield", "front"]], "Attacco frontale neutralizzato.", 22.0),
	_event("mine", "MINA SOMMERSA", "Ordigno esplosivo rilevato sotto lo scafo. Proteggi il ventre oppure allontanati in qualunque direzione sicura.", 11.0, [["shield", "below"], ["boost", "left"], ["boost", "front"], ["boost", "right"]], "Mina superata senza danni.", 20.0),
	_event("civilians-left", "CIVILI A SINISTRA", "Squadra di evacuazione bloccata nel settore sinistro. Invia i soccorsi a sinistra.", 14.0, [["rescue", "left"]], "Civili recuperati senza consumare energia.", 0.0, 14),
	_event("civilians-right", "CIVILI A DESTRA", "Un rifugio sta cedendo nel settore destro. Invia i soccorsi a destra.", 14.0, [["rescue", "right"]], "Rifugio evacuato in tempo.", 0.0, 18),
	_event("collapse", "CROLLO DAVANTI", "Un grattacielo sta crollando sulla nostra traiettoria. Scatta lateralmente per evitarlo.", 11.0, [["boost", "left"], ["boost", "right"]], "Zona di crollo superata con i propulsori.", 16.0),
	_event("drone", "DRONE IN ARRIVO DAL BASSO", "Un drone d'assalto sale verso lo scafo: abbattilo, respingilo verso il basso oppure allontanati in una direzione sicura.", 11.0, [["laser", "below"], ["shield", "below"], ["boost", "left"], ["boost", "front"], ["boost", "right"]], "Drone evitato prima che potesse agganciarsi.", 15.0),
	_event("flank", "NEMICO SUL FIANCO", "Unità corazzata in avvicinamento da sinistra. Attacca, proteggi il fianco o scatta a destra.", 12.0, [["laser", "left"], ["shield", "left"], ["boost", "right"]], "Unità sul fianco neutralizzata o evitata.", 17.0),
	_event("shockwave", "ONDA D'URTO", "Esplosione davanti a noi. I propulsori non bastano: reggi l'impatto.", 10.0, [["shield", "front"]], "Scudo frontale stabile. Onda assorbita.", 20.0),
	_event("torpedo", "SILURO A SINISTRA", "Siluro pesante in rotta d'impatto. Bloccalo o scatta a destra.", 10.0, [["shield", "left"], ["boost", "right"]], "Siluro neutralizzato.", 24.0),
	_event("breaker", "DEMOLITORE DAVANTI", "Il Demolitore carica frontalmente. Colpisci il nucleo oppure schiva lateralmente.", 13.0, [["laser", "front"], ["boost", "left"], ["boost", "right"]], "Carica del Demolitore neutralizzata.", 24.0),
]

var boss_event := _event("boss", "COLOSSO DEL VARCO", "Tre nuclei davanti. Servono tre laser: usa almeno un raffreddamento o attendi la dissipazione tra i colpi.", BOSS_TIME, [["laser", "front"]], "Nucleo distrutto.", 100.0, 0, "", true)

var phase := "intro"
var integrity := 100.0
var energy := 100.0
var heat := 0.0
var coolant := 100.0
var mission_time := MISSION_DURATION
var score := 0
var civilians := 0
var direction := "front"
var alerts: Array[Dictionary] = []
var spawn_delay := 1.8
var reactor_lock := 0.0
var boss_hp := 3
var boss_defeated := false
var event_count := 0
var next_uid := 0
var last_event_id := ""
var feedback := "Tre emergenze guidate prepareranno i sistemi."
var alarm_sounds := true
var button_sounds := true
var left_handed := false
var denial_time := 0.0
var cards: Dictionary = {}
var audio_player: AudioStreamPlayer
var grid_spacer: Control

@onready var alerts_grid: GridContainer = %AlertsGrid
@onready var radar_idle: PanelContainer = %RadarIdle
@onready var intro_overlay: ColorRect = %IntroOverlay
@onready var result_overlay: ColorRect = %ResultOverlay
@onready var play_area = $Scroll/Margin/Content/PlayArea


static func _event(id: String, title: String, body: String, seconds: float, solutions: Array, success: String, damage: float, rescued := 0, hint := "", boss := false) -> Dictionary:
	return {"id": id, "title": title, "body": body, "seconds": seconds, "solutions": solutions, "success": success, "damage": damage, "civilians": rescued, "hint": hint, "boss": boss}


func _ready() -> void:
	randomize()
	audio_player = AudioStreamPlayer.new()
	add_child(audio_player)
	grid_spacer = Control.new()
	grid_spacer.custom_minimum_size = Vector2(250.0, 1.0)
	grid_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alerts_grid.add_child(grid_spacer)
	grid_spacer.hide()
	_load_preferences()
	%StartButton.pressed.connect(start_mission)
	%RestartButton.pressed.connect(start_mission)
	%AlarmSoundButton.pressed.connect(_toggle_alarm_sound)
	%ButtonSoundButton.pressed.connect(_toggle_button_sound)
	%HandednessButton.pressed.connect(_toggle_handedness)
	%LeftButton.pressed.connect(select_direction.bind("left"))
	%FrontButton.pressed.connect(select_direction.bind("front"))
	%RightButton.pressed.connect(select_direction.bind("right"))
	%BelowButton.pressed.connect(select_direction.bind("below"))
	%ShieldButton.pressed.connect(use_system.bind("shield"))
	%LaserButton.pressed.connect(use_system.bind("laser"))
	%BoostButton.pressed.connect(use_system.bind("boost"))
	%RescueButton.pressed.connect(use_system.bind("rescue"))
	%CoolButton.pressed.connect(use_system.bind("cool"))
	%RepairButton.pressed.connect(use_system.bind("repair"))
	get_viewport().size_changed.connect(_on_viewport_resized)
	%EnergyBar.self_modulate = Color(0.28, 0.67, 1.0)
	%HeatBar.self_modulate = Color(1.0, 0.29, 0.19)
	%CoolantBar.self_modulate = Color(0.36, 0.9, 1.0)
	_render()
	_on_viewport_resized()


func _process(delta: float) -> void:
	if phase == "running":
		_tick(minf(delta, 0.25))
	_render()


func start_mission() -> void:
	phase = "running"
	integrity = 100.0
	energy = 100.0
	heat = 0.0
	coolant = 100.0
	mission_time = MISSION_DURATION
	score = 0
	civilians = 0
	direction = "front"
	alerts.clear()
	spawn_delay = 1.8
	reactor_lock = 0.0
	boss_hp = 3
	boss_defeated = false
	event_count = 0
	next_uid = 0
	last_event_id = ""
	feedback = "Tre emergenze guidate prepareranno i sistemi."
	denial_time = 0.0
	intro_overlay.hide()
	result_overlay.hide()
	_clear_cards()
	_button_beep(260.0, 0.16)
	_render()


func select_direction(value: String) -> void:
	if phase != "running":
		return
	direction = value
	_render_direction()


func use_system(system: String) -> void:
	if phase != "running":
		return
	_button_beep(180.0 if system == "laser" else 420.0, 0.07)
	Input.vibrate_handheld(25)
	if system == "cool":
		if coolant < 14.0:
			_deny(system, "coolant", "REFRIGERANTE INSUFFICIENTE: servono 14 punti.")
		elif heat < 5.0:
			_deny(system, "", "RAFFREDDAMENTO NON NECESSARIO: temperatura già nominale.")
		else:
			coolant -= 14.0
			heat = clampf(heat - 42.0, 0.0, 100.0)
			reactor_lock = maxf(0.0, reactor_lock - 2.0)
			denial_time = 0.0
			feedback = "RAFFREDDAMENTO: calore ridotto di 42 punti."
		return
	if system == "repair":
		if integrity >= 100.0:
			_deny(system, "", "RIPARAZIONE NON NECESSARIA: integrità già al massimo.")
		elif energy < 18.0:
			_deny(system, "energy", "ENERGIA INSUFFICIENTE: servono 18 punti per riparare.")
		else:
			energy -= 18.0
			heat = clampf(heat + 6.0, 0.0, 100.0)
			integrity = clampf(integrity + 15.0, 0.0, 100.0)
			denial_time = 0.0
			feedback = "RIPARAZIONE: +15 integrità, −18 energia."
		return
	if reactor_lock > 0.0:
		_deny(system, "heat", "REATTORE BLOCCATO: puoi soltanto raffreddare o riparare.")
		return
	var cost: Array = SYSTEM_COSTS[system]
	if energy < cost[0]:
		_deny(system, "energy", "ENERGIA INSUFFICIENTE: servono %d punti per %s." % [roundi(cost[0]), system.to_upper()])
		return
	if heat + cost[1] >= 100.0:
		_deny(system, "heat", "CALORE CRITICO: %s aggiungerebbe %d punti. Raffredda o attendi." % [system.to_upper(), roundi(cost[1])])
		return
	denial_time = 0.0
	energy -= cost[0]
	heat = clampf(heat + cost[1], 0.0, 100.0)
	var match_index := _find_matching_alert(system, direction)
	if match_index < 0:
		var related_index := _find_alert_in_direction(direction)
		if related_index >= 0:
			alerts[related_index]["attempt"] = "%s INEFFICACE IN QUESTO SCENARIO" % system.to_upper()
		feedback = "Comando %s / %s senza effetto." % [system.to_upper(), direction.to_upper()]
		return
	var matching: Dictionary = alerts[match_index]
	if matching.event.boss:
		boss_hp -= 1
		if boss_hp <= 0:
			boss_defeated = true
			score += 400 + roundi(integrity * 10.0) + civilians * 5
			matching.status = "success"
			matching.result = "COLOSSO DISTRUTTO · PORTALE IN COLLASSO"
			matching.result_time = 4.0
			alerts[match_index] = matching
			feedback = "MISSIONE COMPIUTA."
			_finish(true, "Nova Europa è salva. Il portale alieno è collassato.")
		else:
			score += 350
			matching.event = matching.event.duplicate(true)
			matching.event.title = "COLOSSO DEL VARCO · %d NUCLEI" % boss_hp
			matching.attempt = "NUCLEO DISTRUTTO · NE RESTANO %d" % boss_hp
			alerts[match_index] = matching
			feedback = "Nucleo distrutto. Calore reattore: %d%%." % roundi(heat)
		return
	var rescued: int = matching.event.get("civilians", 0)
	var gained := 120 + roundi(matching.time_left * 10.0) + rescued * 8
	matching.status = "success"
	matching.result = matching.event.success
	matching.result_time = 2.2
	matching.attempt = ""
	alerts[match_index] = matching
	civilians += rescued
	score += gained
	feedback = "%s: risolta." % matching.event.title


func _tick(delta: float) -> void:
	mission_time = clampf(mission_time - delta, 0.0, MISSION_DURATION)
	denial_time = maxf(0.0, denial_time - delta)
	energy = clampf(energy + 1.35 * delta, 0.0, 100.0)
	heat = clampf(heat - 1.15 * delta, 0.0, 100.0)
	reactor_lock = maxf(0.0, reactor_lock - delta)
	spawn_delay -= delta
	var damage := 0.0
	var missed_civilians := false
	var remaining: Array[Dictionary] = []
	for alert in alerts:
		if alert.status != "active":
			alert.result_time -= delta
			if alert.result_time > 0.0:
				remaining.append(alert)
			continue
		alert.time_left -= delta
		alert.attempt = ""
		if alert.time_left > 0.0:
			remaining.append(alert)
		elif alert.event.boss:
			alert.time_left = 0.0
			remaining.append(alert)
		else:
			alert.time_left = 0.0
			alert.status = "failure"
			alert.result_time = 2.6
			if alert.event.damage > 0.0:
				damage += alert.event.damage
				alert.result = "IMPATTO · −%d INTEGRITÀ" % roundi(alert.event.damage)
			else:
				missed_civilians = true
				alert.result = "EVACUAZIONE FALLITA"
			remaining.append(alert)
	alerts = remaining
	if damage > 0.0:
		integrity = clampf(integrity - damage, 0.0, 100.0)
		score = maxi(0, score - roundi(damage * 4.0))
		feedback = "%d danni subiti: troppe emergenze ignorate." % roundi(damage)
		_flash_impact()
		Input.vibrate_handheld(180)
	elif missed_civilians:
		score = maxi(0, score - 40)
		feedback = "Evacuazione fallita."
	if integrity <= 0.0:
		_finish(false, "PROTOCOLLO TITAN distrutto in combattimento.")
		return
	if heat >= 100.0 and reactor_lock <= 0.0:
		heat = 92.0
		reactor_lock = 5.0
		integrity = clampf(integrity - 8.0, 0.0, 100.0)
		feedback = "SOVRACCARICO: reattore bloccato e corazza danneggiata."
		_flash_impact()
	if mission_time <= BOSS_TIME and not _has_boss() and not boss_defeated:
		_spawn_alert(boss_event, true)
		spawn_delay = 999.0
		feedback = "BERSAGLIO FINALE: distruggi i tre nuclei prima del collasso."
	var boss_alert := _get_active_boss()
	if not boss_alert.is_empty() and boss_alert.time_left <= 0.0:
		_finish(false, "Il Colosso ha completato l'attivazione del portale.")
		return
	if mission_time <= 0.0:
		_finish(boss_defeated, "Nova Europa è salva." if boss_defeated else "Il portale alieno è rimasto attivo.")
		return
	if spawn_delay <= 0.0 and _active_count() < _alert_capacity() and mission_time > BOSS_TIME:
		var selected: Dictionary
		if event_count < tutorial.size():
			selected = tutorial[event_count]
		else:
			selected = _choose_event()
		_spawn_alert(selected)
		event_count += 1
		last_event_id = selected.id
		spawn_delay = _next_spawn_delay()
		feedback = selected.hint if selected.hint != "" else "%d minacce richiedono attenzione." % _active_count()


func _spawn_alert(event: Dictionary, prepend := false) -> void:
	next_uid += 1
	var alert := {"uid": next_uid, "event": event.duplicate(true), "time_left": event.seconds, "status": "active", "result": "", "result_time": 0.0, "attempt": ""}
	if prepend:
		alerts.push_front(alert)
	else:
		alerts.append(alert)
	_alarm_beep(120.0 if event.boss else 760.0, 0.35 if event.boss else 0.12)
	Input.vibrate_handheld(220 if event.boss else 80)


func _find_matching_alert(system: String, wanted_direction: String) -> int:
	var found := -1
	var least_time := INF
	for i in alerts.size():
		var alert := alerts[i]
		if alert.status != "active":
			continue
		for solution in alert.event.solutions:
			if solution[0] == system and solution[1] == wanted_direction and alert.time_left < least_time:
				found = i
				least_time = alert.time_left
	return found


func _find_alert_in_direction(wanted_direction: String) -> int:
	var found := -1
	var least_time := INF
	for i in alerts.size():
		var alert := alerts[i]
		if alert.status != "active":
			continue
		for solution in alert.event.solutions:
			if solution[1] == wanted_direction and alert.time_left < least_time:
				found = i
				least_time = alert.time_left
	return found


func _choose_event() -> Dictionary:
	var choices: Array[Dictionary] = []
	for event in events:
		if event.id != last_event_id:
			choices.append(event)
	return choices.pick_random()


func _active_count() -> int:
	var count := 0
	for alert in alerts:
		if alert.status == "active":
			count += 1
	return count


func _alert_capacity() -> int:
	if event_count <= tutorial.size():
		return 1
	return 2 if mission_time > 75.0 else 3


func _next_spawn_delay() -> float:
	# event_count has already been incremented when this is called.
	if event_count <= tutorial.size():
		return 2.2
	if mission_time > 110.0:
		return 6.5
	if mission_time > 65.0:
		return 5.0
	return 4.0


func _has_boss() -> bool:
	for alert in alerts:
		if alert.event.boss:
			return true
	return false


func _get_active_boss() -> Dictionary:
	for alert in alerts:
		if alert.event.boss and alert.status == "active":
			return alert
	return {}


func _finish(won: bool, reason: String) -> void:
	if phase != "running":
		return
	phase = "won" if won else "lost"
	%ResultTitle.text = "MISSIONE COMPIUTA · GRADO %s" % _grade() if won else "MISSIONE FALLITA"
	%ResultTitle.modulate = Color(1.0, 0.76, 0.4) if won else Color(1.0, 0.3, 0.23)
	%ResultReason.text = reason
	%ResultStats.text = "PUNTEGGIO %d   ·   CIVILI %d   ·   INTEGRITÀ %d%%" % [score, civilians, roundi(integrity)]
	result_overlay.show()


func _grade() -> String:
	if score >= 2700 and integrity >= 65.0 and civilians >= 30:
		return "S"
	if score >= 2000 and integrity >= 40.0:
		return "A"
	if score >= 1250:
		return "B"
	return "C"


func _render() -> void:
	%MissionClock.text = _format_time(mission_time)
	%IntegrityText.text = "INTEGRITÀ %d%%" % roundi(integrity)
	%EnergyText.text = "ENERGIA %d%%" % roundi(energy)
	%HeatText.text = "CALORE %d%%" % roundi(heat)
	%CoolantText.text = "REFRIGERANTE %d%%" % roundi(coolant)
	%IntegrityBar.value = integrity
	%EnergyBar.value = energy
	%HeatBar.value = heat
	%CoolantBar.value = coolant
	%StatusLabel.text = "● BLOCCO REATTORE %.1fs" % reactor_lock if reactor_lock > 0.0 else "● SISTEMI OPERATIVI"
	%StatusLabel.modulate = Color(1.0, 0.3, 0.22) if reactor_lock > 0.0 else Color(0.42, 1.0, 0.8)
	%ThreatsLabel.text = "MINACCE %d" % _active_count()
	%CiviliansLabel.text = "CIVILI %03d" % civilians
	%ScoreLabel.text = "PUNTI %05d" % score
	%FeedbackLabel.text = feedback
	%FeedbackCaption.text = "NEGATO" if denial_time > 0.0 else "COMANDO"
	%FeedbackCaption.modulate = Color(1.0, 0.25, 0.2) if denial_time > 0.0 else Color(1.0, 0.54, 0.27)
	%IdleFeedback.text = feedback
	_render_direction()
	_sync_alert_cards()


func _render_direction() -> void:
	%DirectionValue.text = DIRECTIONS[direction]
	%LeftButton.set_pressed_no_signal(direction == "left")
	%FrontButton.set_pressed_no_signal(direction == "front")
	%RightButton.set_pressed_no_signal(direction == "right")
	%BelowButton.set_pressed_no_signal(direction == "below")


func _sync_alert_cards() -> void:
	var current_ids := {}
	for alert in alerts:
		var uid: int = alert.uid
		current_ids[uid] = true
		if not cards.has(uid):
			var card = ALERT_CARD.instantiate()
			cards[uid] = card
			alerts_grid.add_child(card)
		cards[uid].render_alert(alert)
	for uid in cards.keys():
		if not current_ids.has(uid):
			cards[uid].queue_free()
			cards.erase(uid)
	radar_idle.visible = alerts.is_empty()
	_update_grid_spacer()


func _clear_cards() -> void:
	for card in cards.values():
		card.queue_free()
	cards.clear()
	radar_idle.show()
	_update_grid_spacer()


func _update_grid_spacer() -> void:
	if not is_instance_valid(grid_spacer):
		return
	if grid_spacer.get_index() != alerts_grid.get_child_count() - 1:
		alerts_grid.move_child(grid_spacer, alerts_grid.get_child_count() - 1)
	grid_spacer.visible = alerts_grid.columns > 1 and not alerts.is_empty() and alerts.size() % alerts_grid.columns != 0


func _deny(system: String, resource: String, message: String) -> void:
	feedback = message
	denial_time = 0.75
	var buttons := {
		"shield": %ShieldButton,
		"laser": %LaserButton,
		"boost": %BoostButton,
		"rescue": %RescueButton,
		"cool": %CoolButton,
		"repair": %RepairButton,
	}
	_pulse_denied(buttons.get(system))
	var meters := {
		"energy": %EnergyBar,
		"heat": %HeatBar,
		"coolant": %CoolantBar,
	}
	if resource != "":
		_pulse_denied(meters.get(resource))
	_pulse_denied(%FeedbackPanel)


func _pulse_denied(control: Control) -> void:
	if not is_instance_valid(control):
		return
	var original_color := control.self_modulate
	var original_x := control.position.x
	var color_tween := create_tween()
	color_tween.tween_property(control, "self_modulate", Color(1.0, 0.12, 0.1), 0.06)
	color_tween.tween_interval(0.18)
	color_tween.tween_property(control, "self_modulate", original_color, 0.18)
	var shake_tween := create_tween()
	shake_tween.tween_property(control, "position:x", original_x - 6.0, 0.04)
	shake_tween.tween_property(control, "position:x", original_x + 6.0, 0.07)
	shake_tween.tween_property(control, "position:x", original_x - 4.0, 0.06)
	shake_tween.tween_property(control, "position:x", original_x + 4.0, 0.06)
	shake_tween.tween_property(control, "position:x", original_x, 0.05)


func _flash_impact() -> void:
	var flash: ColorRect = %ImpactFlash
	var tween := create_tween()
	tween.tween_property(flash, "color", Color(1.0, 0.08, 0.04, 0.0), 0.38).from(Color(1.0, 0.08, 0.04, 0.65))


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key_event := event as InputEventKey
	if not key_event.pressed or key_event.echo:
		return
	var directions_by_key := {KEY_LEFT: "left", KEY_UP: "front", KEY_RIGHT: "right", KEY_DOWN: "below"}
	var systems_by_key := {KEY_1: "shield", KEY_2: "laser", KEY_3: "boost", KEY_4: "rescue", KEY_5: "cool", KEY_6: "repair"}
	if directions_by_key.has(key_event.physical_keycode):
		select_direction(directions_by_key[key_event.physical_keycode])
		get_viewport().set_input_as_handled()
	elif systems_by_key.has(key_event.physical_keycode):
		use_system(systems_by_key[key_event.physical_keycode])
		get_viewport().set_input_as_handled()


func _on_viewport_resized() -> void:
	var viewport_size := get_viewport_rect().size
	alerts_grid.columns = 2 if viewport_size.x >= 920.0 and viewport_size.x > viewport_size.y else 1
	var portrait := viewport_size.x < viewport_size.y * 1.05
	%Title.add_theme_font_size_override("font_size", 23 if portrait else 29)
	%HeaderControls.columns = 2 if portrait else 3
	%DirectionGrid.columns = 2 if portrait else 4
	%SystemsGrid.columns = 2 if portrait else 3
	play_area.queue_sort()
	_update_grid_spacer()


func _toggle_alarm_sound() -> void:
	alarm_sounds = not alarm_sounds
	%AlarmSoundButton.text = "ALLARMI ON" if alarm_sounds else "ALLARMI OFF"
	_save_preferences()


func _toggle_button_sound() -> void:
	button_sounds = not button_sounds
	%ButtonSoundButton.text = "PULSANTI ON" if button_sounds else "PULSANTI OFF"
	if button_sounds:
		_button_beep(520.0, 0.07)
	_save_preferences()


func _toggle_handedness() -> void:
	left_handed = not left_handed
	play_area.set_left_handed(left_handed)
	%HandednessButton.text = "COMANDI SX" if left_handed else "COMANDI DX"
	_button_beep(520.0, 0.07)
	_save_preferences()


func _load_preferences() -> void:
	var config := ConfigFile.new()
	if config.load(SETTINGS_PATH) == OK:
		alarm_sounds = bool(config.get_value("audio", "alarms", true))
		button_sounds = bool(config.get_value("audio", "buttons", true))
		left_handed = bool(config.get_value("layout", "left_handed", false))
	%AlarmSoundButton.text = "ALLARMI ON" if alarm_sounds else "ALLARMI OFF"
	%ButtonSoundButton.text = "PULSANTI ON" if button_sounds else "PULSANTI OFF"
	%HandednessButton.text = "COMANDI SX" if left_handed else "COMANDI DX"
	play_area.set_left_handed(left_handed)


func _save_preferences() -> void:
	var config := ConfigFile.new()
	config.set_value("audio", "alarms", alarm_sounds)
	config.set_value("audio", "buttons", button_sounds)
	config.set_value("layout", "left_handed", left_handed)
	config.save(SETTINGS_PATH)


func _button_beep(frequency: float, duration: float) -> void:
	if button_sounds:
		_beep(frequency, duration)


func _alarm_beep(frequency: float, duration: float) -> void:
	if alarm_sounds:
		_beep(frequency, duration)


func _beep(frequency: float, duration: float) -> void:
	var sample_rate := 22050
	var frame_count := int(sample_rate * duration)
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	for i in frame_count:
		var envelope := 1.0 - float(i) / float(frame_count)
		var sample := int(sin(TAU * frequency * float(i) / float(sample_rate)) * 2800.0 * envelope)
		bytes[i * 2] = sample & 0xff
		bytes[i * 2 + 1] = (sample >> 8) & 0xff
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = bytes
	audio_player.stream = stream
	audio_player.play()


func _format_time(seconds: float) -> String:
	var value := maxi(0, ceili(seconds))
	return "%02d:%02d" % [int(value / 60.0), value % 60]
