extends Node

var music_player: AudioStreamPlayer
var current_stream: AudioStream

func _ready() -> void:
	music_player = AudioStreamPlayer.new()
	music_player.bus = &"music"
	add_child(music_player)
	music_player.finished.connect(_on_music_finished)

func play_music(stream: AudioStream, volume_db: float = 0.0, restart: bool = false) -> void:
	if stream == null or not is_instance_valid(music_player):
		return

	var is_same_stream := current_stream == stream and music_player.stream == stream
	current_stream = stream
	music_player.volume_db = volume_db
	if not is_same_stream:
		music_player.stream = stream

	if restart or not is_same_stream or not music_player.playing:
		music_player.play()

func stop_music() -> void:
	current_stream = null
	if is_instance_valid(music_player):
		music_player.stop()

func _on_music_finished() -> void:
	if current_stream != null and is_instance_valid(music_player):
		music_player.play()
