extends Node2D

var player: Player = null
var camera: Camera2D = null
var fade_rect: ColorRect = null

var rku_prompt: Sprite2D = null
var labkom_prompt: Sprite2D = null
var stairs_prompt: Sprite2D = null
var quest_ui = null
var corridor_quest_stage: int = 0

var stairs_dialogue: Array[Dictionary] = [
	{"speaker": "Arga", "expression": "confused", "text": "Pintu ke tangga darurat terkunci... Butuh kartu akses untuk membukanya."},
	{"speaker": "Arga", "expression": "mikir", "text": "Aku harus mencari kartu akses di dalam Labkom..."}
]

var stairs_success_dialogue: Array[Dictionary] = [
	{"speaker": "Arga", "expression": "mikir", "text": "Pintu terbuka! Aku akhirnya bisa keluar dari gedung ini!"}
]

var rku_dialogue: Array[Dictionary] = [
	{"speaker": "Arga", "expression": "mikir", "text": "Pintunya sudah terkunci otomatis... Aku tidak perlu kembali ke dalam kelas."}
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
		
		# Jika player sudah membawa kartu akses dari labkom1
		if DialogueManager.player_has_key:
			quest_ui.set_quest("[s]☐ Cari kartu akses[/s]\n☐ Buka tangga darurat")
		else:
			# Jika player baru saja memulai koridor
			quest_ui.set_quest("☐ Cari jalan keluar")
	
	# Transisi masuk: Fade in selama 1.0 detik
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_rect, "color", Color(0, 0, 0, 0), 1.0)
	await fade_tween.finished
	fade_rect.visible = false
	
	# Balikin kontrol gerak ke player
	if is_instance_valid(player):
		player.can_move = true

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
		# Fade out ke hitam dan kembali ke main menu (karena game selesai)
		if fade_rect:
			fade_rect.visible = true
			var fade_tween = create_tween()
			fade_tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 1.5)
			await fade_tween.finished
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
	else:
		# Jalankan dialog terkunci jika tidak punya kartu akses
		await DialogueManager.start_dialogue(stairs_dialogue)
		
		# Jika ini interaksi pertama, naikkan stage quest ke 1 (disuruh ke Labkom)
		if corridor_quest_stage == 0:
			corridor_quest_stage = 1
			if quest_ui:
				quest_ui.set_quest("☐ Masuk ke Labkom")
				
		# Lepaskan pergerakan player kembali
		if is_instance_valid(player):
			player.can_move = true

func enter_labkom() -> void:
	player.can_move = false
	if fade_rect:
		fade_rect.visible = true
		var fade_tween = create_tween()
		fade_tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 1.0)
		await fade_tween.finished
	get_tree().change_scene_to_file("res://scenes/labkom1.tscn")
