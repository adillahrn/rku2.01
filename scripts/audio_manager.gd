extends Node

var bgm_player: AudioStreamPlayer
var sfx_players: Array[AudioStreamPlayer] = []
var max_sfx_players: int = 8

func _ready() -> void:
	# Initialize BGM player
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = "Master"
	add_child(bgm_player)
	
	# Initialize a pool of SFX players
	for i in range(max_sfx_players):
		var p = AudioStreamPlayer.new()
		p.name = "SFXPlayer_" + str(i)
		p.bus = "Master"
		add_child(p)
		sfx_players.append(p)

func play_bgm(path: String, fade_duration: float = 1.0) -> void:
	var new_stream = load(path) as AudioStream
	if not new_stream:
		push_error("Failed to load BGM from path: " + path)
		return
		
	# If BGM is already playing the same file, do nothing
	if bgm_player.playing and bgm_player.stream and bgm_player.stream.resource_path == path:
		return

	if fade_duration > 0.0 and bgm_player.playing:
		# Fade out current BGM
		var tween = create_tween()
		tween.tween_property(bgm_player, "volume_db", -80.0, fade_duration)
		await tween.finished
		bgm_player.stop()

	bgm_player.stream = new_stream
	bgm_player.volume_db = 0.0
	bgm_player.play()
	
	if fade_duration > 0.0:
		bgm_player.volume_db = -80.0
		var tween = create_tween()
		tween.tween_property(bgm_player, "volume_db", 0.0, fade_duration)

func stop_bgm(fade_duration: float = 1.0) -> void:
	if not bgm_player.playing:
		return
		
	if fade_duration > 0.0:
		var tween = create_tween()
		tween.tween_property(bgm_player, "volume_db", -80.0, fade_duration)
		await tween.finished
	bgm_player.stop()
	bgm_player.volume_db = 0.0

func play_sfx(path: String) -> void:
	var stream = load(path) as AudioStream
	if not stream:
		push_error("Failed to load SFX from path: " + path)
		return
		
	# Find an idle SFX player from the pool
	var played = false
	for p in sfx_players:
		if not p.playing:
			p.stream = stream
			p.volume_db = 0.0
			p.play()
			played = true
			break
			
	# If all are busy, override the first one
	if not played:
		var p = sfx_players[0]
		p.stream = stream
		p.volume_db = 0.0
		p.play()
