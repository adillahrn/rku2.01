extends Node2D

var player: Player = null
var camera: Camera2D = null
var fade_rect: ColorRect = null
var interact_prompt: Sprite2D = null
var quest_ui = null

func _ready() -> void:
	# Set baseline environment redup kebiruan pas start
	self.modulate = Color(0.8, 0.8, 0.95)
	
	# Instance Player
	var player_scene = load("res://scenes/player.tscn")
	if player_scene:
		player = player_scene.instantiate()
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
	
	# Inisialisasi petunjuk interaksi pintu labkom
	create_interact_prompt()
	
	# Inisialisasi QuestUI
	var quest_ui_scene = load("res://scenes/quest_ui.tscn")
	if quest_ui_scene:
		quest_ui = quest_ui_scene.instantiate()
		add_child(quest_ui)
	
	# Transisi masuk: Fade in selama 1.0 detik
	var fade_tween = create_tween()
	fade_tween.tween_property(fade_rect, "color", Color(0, 0, 0, 0), 1.0)
	await fade_tween.finished
	fade_rect.visible = false
	
	# Set quest masuk ke Labkom
	if quest_ui:
		quest_ui.set_quest("☐ Masuk ke Labkom")
	
	# Balikin kontrol gerak ke player
	if is_instance_valid(player):
		player.can_move = true

func _process(_delta: float) -> void:
	if is_instance_valid(player):
		camera.position = player.position
		
	# Update visibility petunjuk interaksi pintu keluar ke Labkom
	if is_instance_valid(player) and player.can_move and not DialogueManager.is_dialogue_active:
		var target_pos = Vector2(200, 230)
		if player.position.distance_to(target_pos) <= 25.0:
			if interact_prompt:
				interact_prompt.visible = true
				# Animasi melayang naik-turun halus (micro-animation)
				var time = Time.get_ticks_msec() / 1000.0
				interact_prompt.position.y = 180.0 + sin(time * 5.0) * 3.0
		else:
			if interact_prompt:
				interact_prompt.visible = false
	else:
		if interact_prompt:
			interact_prompt.visible = false

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

func create_interact_prompt() -> void:
	interact_prompt = Sprite2D.new()
	var tex = load("res://assets/images/ui/enter room.png")
	if tex:
		interact_prompt.texture = tex
	# Posisikan sedikit di atas pintu LABKOM
	interact_prompt.position = Vector2(200, 180)
	interact_prompt.visible = false
	add_child(interact_prompt)

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
		var target_pos = Vector2(200, 230)
		if player.position.distance_to(target_pos) <= 25.0:
			get_viewport().set_input_as_handled()
			enter_labkom()

func enter_labkom() -> void:
	player.can_move = false
	if fade_rect:
		fade_rect.visible = true
		var fade_tween = create_tween()
		fade_tween.tween_property(fade_rect, "color", Color(0, 0, 0, 1), 1.0)
		await fade_tween.finished
	get_tree().change_scene_to_file("res://scenes/labkom.tscn")
