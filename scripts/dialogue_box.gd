extends CanvasLayer

signal dialogue_finished

@export var type_speed: float = 0.03

@onready var panel: Panel = $Control/Panel
@onready var name_label: Label = $Control/Panel/NameLabel
@onready var name_box: Panel = $Control/Panel/NameBox
@onready var text_label: RichTextLabel = $Control/Panel/TextLabel
@onready var next_indicator: Label = $Control/Panel/NextIndicator

var dialogue_lines: Array = []
var current_line_index: int = 0
var is_typing: bool = false
var typing_tween: Tween = null

func start(lines: Array) -> void:
	dialogue_lines = lines
	current_line_index = 0
	next_indicator.visible = false
	show_line(dialogue_lines[0])

func _input(event: InputEvent) -> void:
	# cek tombol buat lanjut
	var is_advance = false
	if event.is_action_pressed("ui_accept") or event.is_action_pressed("interact"):
		is_advance = true
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_E or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			is_advance = true
			
	if is_advance:
		get_viewport().set_input_as_handled()
		advance()

func show_line(line_data) -> void:
	var speaker = ""
	var text = ""
	
	if line_data is Dictionary:
		speaker = line_data.get("speaker", "")
		text = line_data.get("text", "")
	else:
		text = str(line_data)
		
	# atur nama pembicara
	if speaker != "":
		name_label.text = speaker
		name_box.visible = true
	else:
		name_box.visible = false
		
	text_label.text = text
	text_label.visible_ratio = 0.0
	next_indicator.visible = false
	is_typing = true
	
	var duration = text.length() * type_speed
	if duration <= 0:
		duration = 0.1
		
	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()
		
	typing_tween = create_tween()
	typing_tween.tween_property(text_label, "visible_ratio", 1.0, duration)
	typing_tween.finished.connect(_on_typing_finished)

func _on_typing_finished() -> void:
	is_typing = false
	next_indicator.visible = true
	# buat efek lampu kedip di indikator lanjut
	var blink_tween = create_tween().set_loops()
	blink_tween.tween_property(next_indicator, "modulate:a", 0.0, 0.4)
	blink_tween.tween_property(next_indicator, "modulate:a", 1.0, 0.4)
	# simpen tween kedip biar bisa dimatiin pas lanjut
	typing_tween = blink_tween

func advance() -> void:
	if is_typing:
		# skip animasi ngetik
		if typing_tween and typing_tween.is_valid():
			typing_tween.kill()
		text_label.visible_ratio = 1.0
		_on_typing_finished()
	else:
		current_line_index += 1
		if current_line_index < dialogue_lines.size():
			show_line(dialogue_lines[current_line_index])
		else:
			if typing_tween and typing_tween.is_valid():
				typing_tween.kill()
			dialogue_finished.emit()
