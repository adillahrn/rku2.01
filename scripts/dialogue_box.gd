extends CanvasLayer

signal dialogue_finished

@export var type_speed: float = 0.03

# preload ekspresi wajah Arga biar ga ngelag pas ganti
const EXPRESSIONS = {
	"confused": preload("res://assets/images/ui/confused.png"),
	"bingung": preload("res://assets/images/ui/bingung.png"),
	"sedih": preload("res://assets/images/ui/sedih.png"),
	"mikir": preload("res://assets/images/ui/mikir.png")
}

@onready var dialogue_panel: TextureRect = $Control/DialoguePanel
@onready var name_label: Label = $Control/DialoguePanel/NameLabel
@onready var text_label: RichTextLabel = $Control/DialoguePanel/TextLabel
@onready var next_indicator: TextureRect = $Control/DialoguePanel/NextIndicator
@onready var portrait_rect: TextureRect = $Control/Portrait
@onready var typewriter_sfx: AudioStreamPlayer = $Control/TypewriterSFX

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
	var expression = ""
	
	if line_data is Dictionary:
		speaker = line_data.get("speaker", "")
		text = line_data.get("text", "")
		expression = line_data.get("expression", "")
	else:
		text = str(line_data)
		
	# atur nama pembicara
	if speaker != "":
		name_label.text = speaker
		name_label.visible = true
	else:
		name_label.visible = false
		
	# atur ekspresi portrait
	if expression != "" and EXPRESSIONS.has(expression):
		portrait_rect.texture = EXPRESSIONS[expression]
		portrait_rect.visible = true
	else:
		# sembunyiin portrait kalau ga ada speaker / narrator
		if speaker == "":
			portrait_rect.visible = false
		else:
			# default ke confused kalau speaker ada tapi ga ada ekspresi spesifik
			portrait_rect.texture = EXPRESSIONS["confused"]
			portrait_rect.visible = true
		
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
	
	if "Sound of typing" in text:
		if typewriter_sfx and not typewriter_sfx.playing:
			typewriter_sfx.play(5.0)
	elif "The typing stops" in text:
		if typewriter_sfx and typewriter_sfx.playing:
			typewriter_sfx.stop()

func _on_typing_finished() -> void:
	is_typing = false
	next_indicator.visible = true

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
			if typewriter_sfx and typewriter_sfx.playing:
				typewriter_sfx.stop()
			dialogue_finished.emit()

func _process(_delta: float) -> void:
	if next_indicator and next_indicator.visible:
		# animasi kedip buat icon surat (next indicator)
		var time = Time.get_ticks_msec() / 1000.0
		next_indicator.modulate.a = 0.35 + abs(sin(time * 4.5)) * 0.65
