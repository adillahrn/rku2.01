extends Control

# Ini teks yang bisa kalian custom buat opening cutscene
@export var dialogue_lines: Array[String] = [
	"2:01 AM",
	"After another long night working on the final project...",
	"Arga accidentally falls asleep in RKU 2.01."
]

@export var type_speed: float = 0.04

@onready var dialogue_label: RichTextLabel = $CenterContainer/VBoxContainer/DialogueLabel
@onready var mail_icon: TextureRect = $CenterContainer/VBoxContainer/MailIconContainer/MailIcon
@onready var fade_overlay: ColorRect = $FadeOverlay

var current_line_index: int = 0
var is_typing: bool = false
var typing_tween: Tween = null
var is_transitioning: bool = false

func _ready() -> void:
	AudioManager.play_bgm("res://assets/music/bgm_lost_in_thought.mp3")
	fade_overlay.color = Color(0, 0, 0, 1)
	var fade_in_tween = create_tween()
	fade_in_tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 0), 1.0)
	
	if mail_icon:
		mail_icon.visible = false
	
	if dialogue_lines.size() > 0:
		show_line(dialogue_lines[0])
	else:
		start_transition()

# Function buat ngereact input
func _input(event: InputEvent) -> void:
	if is_transitioning:
		return
		
	# Cek input untuk lanjut dialogue
	var is_advance = false
	if event.is_action_pressed("ui_accept"):
		is_advance = true
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_E or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			is_advance = true
			
	if is_advance:
		get_viewport().set_input_as_handled()
		advance_dialogue()

# Function buat nampilin tiap dialogue
func show_line(text: String) -> void:
	dialogue_label.text = "[center]" + text + "[/center]"
	dialogue_label.visible_ratio = 0.0
	is_typing = true
	if mail_icon:
		mail_icon.visible = false
	
	var duration = text.length() * type_speed
	if duration <= 0:
		duration = 0.1
		
	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()
		
	typing_tween = create_tween()
	typing_tween.tween_property(dialogue_label, "visible_ratio", 1.0, duration)
	typing_tween.finished.connect(_on_typing_finished)

# Function buat handle kalau typing selesai
func _on_typing_finished() -> void:
	is_typing = false
	if mail_icon:
		mail_icon.visible = true

# Function buat lanjut dialogue
func advance_dialogue() -> void:
	if is_typing:
		# Skip animasi typing
		if typing_tween and typing_tween.is_valid():
			typing_tween.kill()
		dialogue_label.visible_ratio = 1.0
		is_typing = false
		if mail_icon:
			mail_icon.visible = true
	else:
		current_line_index += 1
		if current_line_index < dialogue_lines.size():
			show_line(dialogue_lines[current_line_index])
		else:
			start_transition()

# Function buat transition ke game.tscn
func start_transition() -> void:
	is_transitioning = true
	if typing_tween and typing_tween.is_valid():
		typing_tween.kill()

	# Fade ke hitam -> ganti scene	
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_overlay, "color", Color(0, 0, 0, 1), 1.5)
	await fade_tween.finished
	
	get_tree().change_scene_to_file("res://scenes/rku.tscn")

func _process(delta: float) -> void:
	if mail_icon and mail_icon.visible:
		# pulsing alpha biar kayak tombol continue retro yang hidup
		var time = Time.get_ticks_msec() / 1000.0
		mail_icon.modulate.a = 0.35 + abs(sin(time * 4.5)) * 0.65

