extends Node2D

var player: Player = null
var camera: Camera2D = null
var fade_rect: ColorRect = null

var rku_prompt: Sprite2D = null
var labkom_prompt: Sprite2D = null
var stairs_prompt: Sprite2D = null
var quest_ui = null
var corridor_quest_stage: int = 0
var is_flickering: bool = true

var stairs_dialogue: Array[Dictionary] = [
	{"speaker": "Arga", "expression": "confused", "text": "Locked."},
	{"speaker": "Arga", "expression": "mikir", "text": "Looks like it needs an access card."}
]

var stairs_success_dialogue: Array[Dictionary] = [
	{"speaker": "Arga", "expression": "mikir", "text": "The emergency stairs door is unlocked. Time to go downstairs."}
]

var rku_dialogue: Array[Dictionary] = [
	{"speaker": "Arga", "expression": "mikir", "text": "The classroom door is locked automatically... I can't go back."}
]

var downstairs_dialogue: Array[Dictionary] = [
	{"speaker": "System", "expression": "", "text": "[Arga unlocks the door and walks down the cold, creaking stairs... The air becomes heavy and damp.]"},
	{"speaker": "Arga", "expression": "sedih", "text": "Ugh... it's even darker down here. The rain is leaking from the ceiling..."},
	{"speaker": "System", "expression": "", "text": "[On the wall, a faded poster reads: 'GKV Presentation Tomorrow - 07:30 AM']"},
	{"speaker": "Arga", "expression": "confused", "text": "Tomorrow?"},
	{"speaker": "Arga", "expression": "mikir", "text": "Wait... today was the presentation day... right?"},
	{"speaker": "Lecturer", "expression": "", "text": "\"Arga... is your revision finished yet?\""},
	{"speaker": "Arga", "expression": "sedih", "text": "...?! Who's there?!"},
	{"speaker": "System", "expression": "", "text": "[But the corridor remains completely empty. Only the distant echo of rain remains.]"}
]

func _ready() -> void:
	# Set baseline environment redup kebiruan pas start
	self.modulate = Color(0.8, 0.8, 0.95)
	
	# Instance Player
	var player_scene = load("res://scenes/player.tscn")
	if player_scene:
		player = player_scene.instantiate()
		if DialogueManager.spawn_at_labkom:
			player.position = Vector2(567, 240) # Posisi keluar dari pintu Labkom
			DialogueManager.spawn_at_labkom = false
		else:
			player.position = Vector2(60, 240) # Posisi keluar dari pintu RKU di kiri
		player.has_bag = DialogueManager.player_has_bag
		player.has_key = DialogueManager.player_has_key
		add_child(player)
		player.can_move = false # Kunci kontrol sementara pas transition masuk
		
	# Instance Camera2D dan ikuti player
	camera = Camera2D.new()
	# Set limit agar kamera tidak scroll keluar batas koridor (1056x384)
	camera.limit_left = 0
	camera.limit_right = 1015
	camera.limit_top = 0
	camera.limit_bottom = 384
	add_child(camera)
	
	# Tambah CanvasLayer & ColorRect buat screen transition (Fade In)
	var screen_effects = CanvasLayer.new()
	add_child(screen_effects)
	
	fade_rect = ColorRect.new()
	fade_rect.color = Color(0, 0, 0, 1) # Mulai dari hitam pekat
	fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	screen_effects.add_child(fade_rect)
	
	# Nonaktifkan collision dari TileSet background agar player tidak menabrak ubin dinding yang salah letak
	var bg_layer = $background
	if bg_layer and bg_layer.tile_set:
		bg_layer.tile_set.set_physics_layer_collision_layer(0, 0)
		bg_layer.tile_set.set_physics_layer_collision_mask(0, 0)
		
	# Inisialisasi padding
	setup_boundaries()
	
	# Inisialisasi petunjuk interaksi pintu rku, labkom dan tangga
	create_interact_prompts()
	
	# Inisialisasi QuestUI
	var quest_ui_scene = load("res://scenes/quest_ui.tscn")
	if quest_ui_scene:
		quest_ui = quest_ui_scene.instantiate()
		add_child(quest_ui)
		
		# Set Quest awal berdasarkan status access card
		if DialogueManager.player_has_key:
			quest_ui.set_quest("[s]☐ Find access card in LABKOM 3[/s]\n☐ Open the emergency stairs")
		else:
			quest_ui.set_quest("☐ Find a way downstairs.")
	
	# Transisi masuk: Fade in selama 1.0 detik
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_rect, "color", Color(0, 0, 0, 0), 1.0)
	await fade_tween.finished
	fade_rect.visible = false
	
	# Mulai Morse Code Lamp berkedip "LAB KOM 3" di lorong
	flicker_morse()
	
	# Balikin kontrol gerak ke player
	if is_instance_valid(player):
		player.can_move = true

func flicker_morse() -> void:
	# Morse code for "LAB KOM 3"
	# L: .-..  A: .-  B: -...
	# K: -.-   O: ---  M: --
	# 3: ...--
	var sequence = [
		# L: .-..
		"dot", "dash", "dot", "dot", "letter_space",
		# A: .-
		"dot", "dash", "letter_space",
		# B: -...
		"dash", "dot", "dot", "dot", "word_space",
		# K: -.-
		"dash", "dot", "dash", "letter_space",
		# O: ---
		"dash", "dash", "dash", "letter_space",
		# M: --
		"dash", "dash", "word_space",
		# 3: ...--
		"dot", "dot", "dot", "dash", "dash", "word_space"
	]
	
	while is_flickering:
		for action in sequence:
			if not is_flickering or not is_instance_valid(self):
				break
			match action:
				"dot":
					if not is_instance_valid(self): return
					self.modulate = Color(0.8, 0.8, 0.95)
					await get_tree().create_timer(0.2).timeout
					if not is_instance_valid(self): return
					self.modulate = Color(0.45, 0.45, 0.55)
					await get_tree().create_timer(0.2).timeout
				"dash":
					if not is_instance_valid(self): return
					self.modulate = Color(0.8, 0.8, 0.95)
					await get_tree().create_timer(0.6).timeout
					if not is_instance_valid(self): return
					self.modulate = Color(0.45, 0.45, 0.55)
					await get_tree().create_timer(0.2).timeout
				"letter_space":
					if not is_instance_valid(self): return
					self.modulate = Color(0.45, 0.45, 0.55)
					await get_tree().create_timer(0.6).timeout
				"word_space":
					if not is_instance_valid(self): return
					self.modulate = Color(0.45, 0.45, 0.55)
					await get_tree().create_timer(1.4).timeout

func _exit_tree() -> void:
	is_flickering = false

func _process(_delta: float) -> void:
	if is_instance_valid(player):
		camera.position = player.position
		
	# Update visibility petunjuk interaksi pintu keluar ke Labkom, tangga, dan Rku
	if is_instance_valid(player) and player.can_move and not DialogueManager.is_dialogue_active:
		var time = Time.get_ticks_msec() / 1000.0
		var p_pos = player.position
		
		# Cek RKU (X: 130-205, Y: 210-260)
		if p_pos.x >= 130.0 and p_pos.x <= 205.0 and p_pos.y >= 210.0 and p_pos.y <= 260.0:
			if rku_prompt:
				rku_prompt.visible = true
				rku_prompt.position.y = 180.0 + sin(time * 5.0) * 3.0
		else:
			if rku_prompt:
				rku_prompt.visible = false
		
		# Cek Tangga (selalu aktif terlepas dari quest stage)
		if p_pos.x >= 950.0 and p_pos.x <= 1015.0 and p_pos.y >= 210.0 and p_pos.y <= 260.0:
			if stairs_prompt:
				stairs_prompt.visible = true
				stairs_prompt.position.y = 180.0 + sin(time * 5.0) * 3.0
		else:
			if stairs_prompt:
				stairs_prompt.visible = false
				
		# Cek Labkom (hanya aktif setelah berinteraksi dengan tangga, i.e., corridor_quest_stage == 1)
		# Jika player sudah punya kunci (akses tangga), pintu labkom tidak perlu aktif interaksinya lagi
		if (corridor_quest_stage == 1 or DialogueManager.player_has_key) and not DialogueManager.player_has_key and p_pos.x >= 530.0 and p_pos.x <= 605.0 and p_pos.y >= 210.0 and p_pos.y <= 260.0:
			if labkom_prompt:
				labkom_prompt.visible = true
				labkom_prompt.position.y = 180.0 + sin(time * 5.0) * 3.0
		else:
			if labkom_prompt:
				labkom_prompt.visible = false
	else:
		if rku_prompt:
			rku_prompt.visible = false
		if stairs_prompt:
			stairs_prompt.visible = false
		if labkom_prompt:
			labkom_prompt.visible = false

func setup_boundaries() -> void:
	# Ukuran koridor 1056x384. Batas atas jalan koridor disesuaikan agar tidak menembus dinding atas (y=210)
	var left = 0.0
	var right = 1015.0
	var top = 210.0
	var bottom = 384.0
	
	# Buat StaticBody2D
	var boundaries = StaticBody2D.new()
	boundaries.name = "ScreenBoundaries"
	add_child(boundaries)
	
	# Tambahkan collision shape untuk masing-masing sisi
	
	# Kiri
	var left_shape = CollisionShape2D.new()
	var left_segment = SegmentShape2D.new()
	left_segment.a = Vector2(left, top)
	left_segment.b = Vector2(left, bottom)
	left_shape.shape = left_segment
	boundaries.add_child(left_shape)
	
	# Kanan
	var right_shape = CollisionShape2D.new()
	var right_segment = SegmentShape2D.new()
	right_segment.a = Vector2(right, top)
	right_segment.b = Vector2(right, bottom)
	right_shape.shape = right_segment
	boundaries.add_child(right_shape)
	
	# Atas
	var top_shape = CollisionShape2D.new()
	var top_segment = SegmentShape2D.new()
	top_segment.a = Vector2(left, top)
	top_segment.b = Vector2(right, top)
	top_shape.shape = top_segment
	boundaries.add_child(top_shape)
	
	# Bawah
	var bottom_shape = CollisionShape2D.new()
	var bottom_segment = SegmentShape2D.new()
	bottom_segment.a = Vector2(left, bottom)
	bottom_segment.b = Vector2(right, bottom)
	bottom_shape.shape = bottom_segment
	boundaries.add_child(bottom_shape)

func create_interact_prompts() -> void:
	var tex = load("res://assets/images/ui/enter room.png")
	
	# Prompt pintu RKU (X=130-205, center 167.5)
	rku_prompt = Sprite2D.new()
	if tex:
		rku_prompt.texture = tex
	rku_prompt.position = Vector2(167, 180)
	rku_prompt.visible = false
	add_child(rku_prompt)
	
	# Prompt pintu Labkom (X=530-605, center 567.5)
	labkom_prompt = Sprite2D.new()
	if tex:
		labkom_prompt.texture = tex
	labkom_prompt.position = Vector2(567, 180)
	labkom_prompt.visible = false
	add_child(labkom_prompt)
	
	# Prompt tangga darurat (X=950-1015, center 982.5)
	stairs_prompt = Sprite2D.new()
	if tex:
		stairs_prompt.texture = tex
	stairs_prompt.position = Vector2(982, 180)
	stairs_prompt.visible = false
	add_child(stairs_prompt)

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
		var p_pos = player.position
		
		# Interaksi RKU (X: 130-205, Y: 210-260)
		if p_pos.x >= 130.0 and p_pos.x <= 205.0 and p_pos.y >= 210.0 and p_pos.y <= 260.0:
			get_viewport().set_input_as_handled()
			interact_with_rku()
		
		# Interaksi Tangga (X: 950-1015, Y: 210-260)
		elif p_pos.x >= 950.0 and p_pos.x <= 1015.0 and p_pos.y >= 210.0 and p_pos.y <= 260.0:
			get_viewport().set_input_as_handled()
			interact_with_stairs()
			
		# Interaksi Labkom (X: 530-605, Y: 210-260) - Hanya aktif jika corridor_quest_stage == 1 dan belum punya kunci
		elif (corridor_quest_stage == 1 or DialogueManager.player_has_key) and not DialogueManager.player_has_key and p_pos.x >= 530.0 and p_pos.x <= 605.0 and p_pos.y >= 210.0 and p_pos.y <= 260.0:
			get_viewport().set_input_as_handled()
			enter_labkom()

func interact_with_rku() -> void:
	player.can_move = false
	await DialogueManager.start_dialogue(rku_dialogue)
	if is_instance_valid(player):
		player.can_move = true

func interact_with_stairs() -> void:
	# Bekukan pergerakan player
	player.can_move = false
	
	if DialogueManager.player_has_key:
		# Jalankan dialog sukses jika punya kartu akses
		await DialogueManager.start_dialogue(stairs_success_dialogue)
		# Fade out ke hitam (karena tangga dimulai)
		if fade_rect:
			fade_rect.visible = true
			var fade_tween = create_tween()
			fade_tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 1.5)
			await fade_tween.finished
		
		# Jalankan dialog pasca turun tangga pada latar hitam pekat (SCENE 5)
		await DialogueManager.start_dialogue(downstairs_dialogue)
		
		# Kembali ke main menu setelah kengerian selesai
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	else:
		# Jalankan dialog terkunci jika tidak punya kartu akses
		await DialogueManager.start_dialogue(stairs_dialogue)
		
		# Jika ini interaksi pertama, naikkan stage quest ke 1 (disuruh ke Labkom 3)
		if corridor_quest_stage == 0:
			corridor_quest_stage = 1
			if quest_ui:
				quest_ui.set_quest("☐ Find a way downstairs.\n☐ Find access card in LABKOM 3")
				
		# Lepaskan pergerakan player kembali
		if is_instance_valid(player):
			player.can_move = true

func enter_labkom() -> void:
	player.can_move = false
	is_flickering = false # Matikan lampu berkedip saat keluar scene
	if fade_rect:
		fade_rect.visible = true
		var fade_tween = create_tween()
		fade_tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 1.0)
		await fade_tween.finished
	get_tree().change_scene_to_file("res://scenes/labkom1.tscn")
