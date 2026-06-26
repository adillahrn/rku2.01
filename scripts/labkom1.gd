extends Node2D

var player: Player = null
var camera: Camera2D = null
var fade_rect: ColorRect = null
var quest_ui = null
var computer_prompt: Sprite2D = null
var exit_prompt: Sprite2D = null
var computer_ui_scene = null
var computer_ui = null
var _player_near_computer: bool = false

# Sprite2D untuk bayangan misterius
var shadow_figure: Sprite2D = null
var is_shadow_vanished: bool = false
var is_computer_completed: bool = false
var is_event_triggered: bool = false

# Variabel screen shake
var shake_intensity: float = 0.0
var shake_time: float = 0.0

# Posisi komputer menyala (layar biru muda) di tilemap labkom1
const COMPUTER_POS: Vector2 = Vector2(337.5, 200)
const COMPUTER_INTERACT_RANGE_X: float = 27.5
const COMPUTER_INTERACT_RANGE_Y: float = 20.0

# Dialogue Scene 3
var typing_dialogue: Array[Dictionary] = [
	{"speaker": "System", "expression": "", "text": "[Sound of typing: Clack, clack, clack... clack, clack... ]"},
	{"speaker": "Arga", "expression": "confused", "text": "...Hello?"},
	{"speaker": "Arga", "expression": "mikir", "text": "Is someone still here?"},
	{"speaker": "System", "expression": "", "text": "[The typing stops. Complete silence.]"}
]

# Dialogue Scene 4
var card_dialogue: Array[Dictionary] = [
	{"speaker": "Arga", "expression": "confused", "text": "What... was that?"},
	{"speaker": "Arga", "expression": "mikir", "text": "Someone was here."},
	{"speaker": "Arga", "expression": "sedih", "text": "I need to leave. Now."}
]

var scare_system_dialogue: Array[Dictionary] = [
	{"speaker": "System", "expression": "", "text": "[Suddenly, all computer monitors in the LABKOM light up simultaneously, displaying Arga's face with empty, hollow eyes...]"},
	{"speaker": "System", "expression": "", "text": "[Heavy footsteps begin to echo loudly from the corridor outside... clomp, clomp, clomp...]"}
]

func _ready() -> void:
	self.modulate = Color(0.8, 0.8, 0.95)
	
	# Instance Player dari koridor
	var player_scene = load("res://scenes/player.tscn")
	if player_scene:
		player = player_scene.instantiate()
		player.position = Vector2(565, 115)
		player.has_bag = DialogueManager.player_has_bag
		player.has_key = DialogueManager.player_has_key
		add_child(player)
		# Scale hanya sprite, bukan seluruh node (agar hitbox tidak ikut mengecil)
		var spr = player.get_node_or_null("Sprite2D")
		if spr:
			spr.scale = Vector2(0.8, 0.8)
		player.can_move = false
		
	# Instance Camera2D dan ikuti player
	if $Camera2D:
		camera = $Camera2D
	else:
		camera = Camera2D.new()
		add_child(camera)
	
	# Set limit kamera ke batas labkom
	camera.limit_left = 0
	camera.limit_right = 575
	camera.limit_top = 0
	camera.limit_bottom = 400
	
	# Inisialisasi batas layar (hanya batas tepi ruangan, objek pakai TileSet collision)
	setup_boundaries()
	
	# Tambah CanvasLayer & ColorRect buat screen transition (Fade In)
	var screen_effects = CanvasLayer.new()
	add_child(screen_effects)
	
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 1) # Mulai dari hitam pekat
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_effects.add_child(fade_rect)
	
	# Inisialisasi QuestUI
	var quest_ui_scene = load("res://scenes/quest_ui.tscn")
	if quest_ui_scene:
		quest_ui = quest_ui_scene.instantiate()
		add_child(quest_ui)

	# Inisialisasi bayangan sosok misterius (modulated black sprite)
	_setup_shadow_figure()

	# Inisialisasi prompt interaksi komputer & pintu keluar
	create_interact_prompts()

	# Preload and instantiate Computer UI (hidden by default)
	computer_ui_scene = load("res://scenes/computer_ui.tscn")
	if computer_ui_scene:
		computer_ui = computer_ui_scene.instantiate()
		add_child(computer_ui)
		computer_ui.computer_closed.connect(_on_computer_closed)
		computer_ui.access_card_obtained.connect(_on_access_card_obtained)
	
	# Transisi masuk: Fade in selama 1.0 detik
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_rect, "color", Color(0, 0, 0, 0), 1.0)
	await fade_tween.finished
	fade_rect.visible = false
	
	# Set quest masuk labkom
	if quest_ui:
		if DialogueManager.player_has_key:
			quest_ui.set_quest("[s]☐ Find access card in LABKOM 3[/s]\n☐ Return to the corridor\n☐ Go downstairs")
		else:
			quest_ui.set_quest("☐ Find access card in LABKOM 3")
	
	# Trigger dialog pengetikan keyboard (SCENE 3)
	await DialogueManager.start_dialogue(typing_dialogue)
	
	# Balikin kontrol gerak ke player
	if is_instance_valid(player):
		player.can_move = true

func _setup_shadow_figure() -> void:
	shadow_figure = Sprite2D.new()
	var tex = load("res://assets/images/karakter/idle_down.png")
	if tex:
		shadow_figure.texture = tex
	# Posisikan sosok bayangan berdiri tepat di belakang/dekat komputer utama
	shadow_figure.position = Vector2(COMPUTER_POS.x, COMPUTER_POS.y - 25)
	shadow_figure.modulate = Color(0.0, 0.0, 0.0, 0.6) # Bayangan hitam semi-transparan
	add_child(shadow_figure)

func create_interact_prompts() -> void:
	var tex = load("res://assets/images/ui/enter room.png")
	
	# Prompt komputer kuis
	computer_prompt = Sprite2D.new()
	if tex:
		computer_prompt.texture = tex
	computer_prompt.position = COMPUTER_POS
	computer_prompt.visible = false
	add_child(computer_prompt)
	
	# Prompt pintu keluar ke koridor (X=565, Y=115)
	exit_prompt = Sprite2D.new()
	if tex:
		exit_prompt.texture = tex
	exit_prompt.position = Vector2(545, 95)
	exit_prompt.visible = false
	add_child(exit_prompt)

func shake_camera(intensity: float, duration: float) -> void:
	shake_intensity = intensity
	shake_time = duration

func _process(delta: float) -> void:
	if is_instance_valid(player) and camera:
		camera.position = player.position
		
	# Kamera screen shake handler
	if shake_time > 0.0:
		shake_time -= delta
		if camera:
			camera.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
	else:
		if camera:
			camera.offset = Vector2.ZERO
	
	# Tampilkan prompt interaksi komputer / keluar saat dekat
	if is_instance_valid(player) and player.can_move and not DialogueManager.is_dialogue_active:
		var p = player.position
		var time = Time.get_ticks_msec() / 1000.0
		
		# Cek proximity untuk menghilangkan sosok bayangan (jika belum hilang)
		if not is_shadow_vanished and is_instance_valid(shadow_figure):
			var dist = p.distance_to(shadow_figure.position)
			if dist <= 65.0:
				_vanish_shadow()
		
		# Jarak ke komputer
		var inside_comp_x = abs(p.x - COMPUTER_POS.x) <= COMPUTER_INTERACT_RANGE_X
		var inside_comp_y = abs(p.y - COMPUTER_POS.y) <= COMPUTER_INTERACT_RANGE_Y
		if inside_comp_x and inside_comp_y:
			if not _player_near_computer:
				_player_near_computer = true
			if computer_prompt:
				computer_prompt.visible = true
				computer_prompt.position.y = (COMPUTER_POS.y - 20) + sin(time * 5.0) * 3.0
		else:
			if _player_near_computer:
				_player_near_computer = false
			if computer_prompt:
				computer_prompt.visible = false
				
		# Jarak ke pintu keluar (spawns/exits at 565, 115)
		var inside_exit = abs(p.x - 565.0) <= 25.0 and abs(p.y - 115.0) <= 25.0
		if inside_exit:
			if exit_prompt:
				exit_prompt.visible = true
				exit_prompt.position.y = 95.0 + sin(time * 5.0) * 3.0
		else:
			if exit_prompt:
				exit_prompt.visible = false
	else:
		if computer_prompt:
			computer_prompt.visible = false
		if exit_prompt:
			exit_prompt.visible = false

func _vanish_shadow() -> void:
	is_shadow_vanished = true
	if is_instance_valid(shadow_figure):
		# Animasi memudar perlahan
		var tween = create_tween()
		tween.tween_property(shadow_figure, "modulate:a", 0.0, 0.4)
		await tween.finished
		shadow_figure.queue_free()

func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(player) or not player.can_move or DialogueManager.is_dialogue_active:
		return
	
	var is_interact = false
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		is_interact = true
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_ENTER or event.keycode == KEY_SPACE:
			is_interact = true
	
	if is_interact:
		var p = player.position
		
		# Interaksi komputer
		if abs(p.x - COMPUTER_POS.x) <= COMPUTER_INTERACT_RANGE_X and abs(p.y - COMPUTER_POS.y) <= COMPUTER_INTERACT_RANGE_Y:
			get_viewport().set_input_as_handled()
			_open_computer()
			
		# Interaksi pintu keluar ke koridor
		elif abs(p.x - 565.0) <= 25.0 and abs(p.y - 115.0) <= 25.0:
			get_viewport().set_input_as_handled()
			_exit_to_corridor()

func _open_computer() -> void:
	player.can_move = false
	if computer_prompt:
		computer_prompt.visible = false
	if computer_ui:
		computer_ui.open()

func _on_computer_closed() -> void:
	print("[DEBUG LABKOM] _on_computer_closed called. is_computer_completed: ", is_computer_completed, ", is_event_triggered: ", is_event_triggered)
	if is_computer_completed and not is_event_triggered:
		_trigger_post_quiz_event()
	else:
		if is_instance_valid(player):
			player.can_move = true

func _on_access_card_obtained() -> void:
	print("[DEBUG LABKOM] _on_access_card_obtained called. Setting is_computer_completed = true")
	# Kuis komputer berhasil diselesaikan
	is_computer_completed = true

func _trigger_post_quiz_event() -> void:
	print("[DEBUG LABKOM] _trigger_post_quiz_event called.")
	is_event_triggered = true
	player.can_move = false
	
	# Jalankan dialog penemuan/penerimaan access card (SCENE 4)
	await DialogueManager.start_dialogue(card_dialogue)
	
	# Efek kejut (SCENE 4): Flash layar merah redup, camera shake, dan bunyi langkah kaki luar
	self.modulate = Color(1.0, 0.4, 0.4) # Lingkungan berubah menjadi merah redup mencekam
	shake_camera(3.0, 1.5)
	
	await DialogueManager.start_dialogue(scare_system_dialogue)
	
	# Tandai access card didapatkan di global state
	DialogueManager.player_has_key = true
	
	if quest_ui:
		quest_ui.set_quest("[s]☐ Find access card in LABKOM 3[/s]\n☐ Return to the corridor\n☐ Go downstairs")
		
	if is_instance_valid(player):
		player.can_move = true

func _exit_to_corridor() -> void:
	player.can_move = false
	# Simpan data player dan atur spawn_at_labkom = true agar keluar tepat di pintu labkom
	DialogueManager.player_has_bag = player.has_bag
	DialogueManager.player_has_key = DialogueManager.player_has_key or is_computer_completed
	DialogueManager.spawn_at_labkom = true
	
	if fade_rect:
		fade_rect.visible = true
		var fade_tween = create_tween()
		fade_tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 1.0)
		await fade_tween.finished
		
	get_tree().change_scene_to_file("res://scenes/koridor.tscn")

func setup_boundaries() -> void:
	# Batas sesuai ukuran ruangan labkom1 (576x384)
	# Batas atas disetel ke Y=100 agar player tidak menembus baris meja
	var left   = 0.0
	var right  = 576.0
	var top    = 100.0
	var bottom = 384.0
	
	var bounds = StaticBody2D.new()
	bounds.name = "ScreenBoundaries"
	add_child(bounds)
	
	for seg in [
		[Vector2(left, top),   Vector2(left, bottom)],   # Kiri
		[Vector2(right, top),  Vector2(right, bottom)],  # Kanan
		[Vector2(left, top),   Vector2(right, top)],     # Atas
		[Vector2(left, bottom),Vector2(right, bottom)],  # Bawah
	]:
		var shape_node = CollisionShape2D.new()
		var seg_shape  = SegmentShape2D.new()
		seg_shape.a = seg[0]
		seg_shape.b = seg[1]
		shape_node.shape = seg_shape
		bounds.add_child(shape_node)
