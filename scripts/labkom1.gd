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

# Posisi komputer menyala (layar biru muda) di tilemap labkom1
# Area interaksi: x = 310..365, y = 195..205
# Center dan half-size dipakai oleh pemeriksaan jarak
const COMPUTER_POS: Vector2 = Vector2(337.5, 200)
const COMPUTER_INTERACT_RANGE_X: float = 27.5
const COMPUTER_INTERACT_RANGE_Y: float = 20.0

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
			quest_ui.set_quest("[s]☐ Cari kartu akses[/s]\n☐ Kembali ke koridor")
		else:
			quest_ui.set_quest("☐ Cari kartu akses")
	
	# Balikin kontrol gerak ke player
	if is_instance_valid(player):
		player.can_move = true

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

func _process(_delta: float) -> void:
	if is_instance_valid(player) and camera:
		camera.position = player.position
	
	# Tampilkan prompt interaksi komputer / keluar saat dekat
	if is_instance_valid(player) and player.can_move and not DialogueManager.is_dialogue_active:
		var p = player.position
		var time = Time.get_ticks_msec() / 1000.0
		
		# Jarak ke komputer
		var inside_comp_x = abs(p.x - COMPUTER_POS.x) <= COMPUTER_INTERACT_RANGE_X
		var inside_comp_y = abs(p.y - COMPUTER_POS.y) <= COMPUTER_INTERACT_RANGE_Y
		if inside_comp_x and inside_comp_y:
			if not _player_near_computer:
				_player_near_computer = true
				print("[labkom] player entered computer area: pos=", p)
			if computer_prompt:
				computer_prompt.visible = true
				computer_prompt.position.y = (COMPUTER_POS.y - 20) + sin(time * 5.0) * 3.0
		else:
			if _player_near_computer:
				_player_near_computer = false
				print("[labkom] player left computer area: pos=", p)
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
		var inside_comp_x = abs(p.x - COMPUTER_POS.x) <= COMPUTER_INTERACT_RANGE_X
		var inside_comp_y = abs(p.y - COMPUTER_POS.y) <= COMPUTER_INTERACT_RANGE_Y
		if inside_comp_x and inside_comp_y:
			print("[labkom] interact in range -> opening computer")
			get_viewport().set_input_as_handled()
			_open_computer()
			
		# Interaksi pintu keluar ke koridor
		elif abs(p.x - 565.0) <= 25.0 and abs(p.y - 115.0) <= 25.0:
			print("[labkom] interact near exit -> returning to corridor")
			get_viewport().set_input_as_handled()
			_exit_to_corridor()

func _open_computer() -> void:
	player.can_move = false
	if computer_prompt:
		computer_prompt.visible = false
	if computer_ui:
		computer_ui.open()

func _on_computer_closed() -> void:
	if is_instance_valid(player):
		player.can_move = true

func _on_access_card_obtained() -> void:
	DialogueManager.player_has_key = true
	if quest_ui:
		quest_ui.set_quest("[s]☐ Cari kartu akses[/s]\n☐ Kembali ke koridor")

func _exit_to_corridor() -> void:
	player.can_move = false
	# Simpan data player dan atur spawn_at_labkom = true agar keluar tepat di pintu labkom
	DialogueManager.player_has_bag = player.has_bag
	DialogueManager.player_has_key = DialogueManager.player_has_key or player.has_key
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
