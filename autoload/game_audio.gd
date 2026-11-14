extends Node
## Áudio do jogo (autoload "GameAudio"): efeitos sonoros e música.
## Os arquivos ficam em res://assets/audio/. Para trocar um som, coloque um .ogg, .wav ou .mp3
## com o mesmo nome (ex.: coletar.ogg).

const AUDIO_DIR := "res://assets/audio/"
const EXTENSIONS := ["ogg", "wav", "mp3"]
const SFX_VOICES := 6

var _music: AudioStreamPlayer
var _voices: Array[AudioStreamPlayer] = []
var _cache: Dictionary = {}
var _current_music: String = ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # a música continua com o jogo pausado
	_music = AudioStreamPlayer.new()
	_music.volume_db = -9.0
	add_child(_music)
	for i in SFX_VOICES:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -4.0
		add_child(voice)
		_voices.append(voice)

	# Sons ligados aos eventos do jogo
	Inventory.element_collected.connect(_on_collected)
	Inventory.compound_formed.connect(_on_compound)
	Progress.star_earned.connect(_on_star)
	Progress.mission_completed.connect(_on_mission)
	# Todo botão criado a partir de agora ganha som de clique
	get_tree().node_added.connect(_on_node_added)


func play_sfx(sfx_name: String) -> void:
	var stream := _get_stream(sfx_name)
	if stream == null:
		return
	for voice in _voices:
		if not voice.playing:
			voice.stream = stream
			voice.play()
			return
	_voices[0].stream = stream   # todas ocupadas: reaproveita a primeira
	_voices[0].play()


func play_music(music_name: String) -> void:
	if music_name == _current_music and _music.playing:
		return
	var stream := _get_stream(music_name)
	if stream == null:
		return
	_current_music = music_name
	_music.stream = stream
	_music.play()


func stop_music() -> void:
	_current_music = ""
	_music.stop()


func _get_stream(stream_name: String) -> AudioStream:
	if _cache.has(stream_name):
		return _cache[stream_name]
	for ext in EXTENSIONS:
		var path := "%s%s.%s" % [AUDIO_DIR, stream_name, ext]
		if ResourceLoader.exists(path):
			var stream := load(path) as AudioStream
			if stream != null:
				_make_loop(stream, stream_name)
				_cache[stream_name] = stream
				return stream
	push_warning("GameAudio: som '%s' não encontrado em %s" % [stream_name, AUDIO_DIR])
	_cache[stream_name] = null
	return null


## Músicas (nome começa com "musica") tocam em loop.
func _make_loop(stream: AudioStream, stream_name: String) -> void:
	if not stream_name.begins_with("musica"):
		return
	if stream is AudioStreamWAV:
		var wav := stream as AudioStreamWAV
		wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end = int(wav.get_length() * wav.mix_rate)
	elif "loop" in stream:
		stream.set("loop", true)


func _on_collected(_id: String) -> void:
	play_sfx("coletar")


func _on_compound(_recipe_id: String) -> void:
	play_sfx("combinar")


func _on_star(_recipe: RecipeData, _stars: int, _total: int) -> void:
	play_sfx("estrela")


func _on_mission(_mission: MissionData, _recipe: RecipeData) -> void:
	play_sfx("missao")


func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		(node as BaseButton).pressed.connect(play_sfx.bind("clique"))
