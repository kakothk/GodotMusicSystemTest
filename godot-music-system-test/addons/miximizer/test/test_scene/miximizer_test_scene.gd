extends Control

@export var bgm_data: BGMData = null

@onready var _label_playback_pos = $VBox/AudioStreamPlayer/GridContainer/ValuePlaybackPos
@onready var _label_playing = $VBox/AudioStreamPlayer/GridContainer/ValuePlaying
@onready var _label_stream_paused = $VBox/AudioStreamPlayer/GridContainer/ValuePaused
@onready var _label_bus = $VBox/AudioStreamPlayer/GridContainer/ValueBus
@onready var _label_playback_type = $VBox/AudioStreamPlayer/GridContainer/ValuePlaybackType

@onready var _label_since_mix: Label = $VBox/AudioServer/GridContainer/ValueTimeSinceLastMix
@onready var _label_latency: Label = $VBox/AudioServer/GridContainer/ValueOutputLatency

@onready var _label_play_state: Label = $VBox/MySystem/GridContainer/ValuePlayState
@onready var _label_bpm: Label = $VBox/MySystem/GridContainer/ValueBpm
@onready var _label_time_signature: Label = $VBox/MySystem/GridContainer/ValueTimeSignature
@onready var _label_current_time: Label = $VBox/MySystem/GridContainer/ValueCurrentTime
@onready var _label_current_timing: Label = $VBox/MySystem/GridContainer/ValueCurrentTiming

@onready var _label_timing_source: Label = $VBox2/TimingSource/Labels/ValueTimingSource


func _ready() -> void:
	Miximizer.load_bgm_data(bgm_data)
	_label_latency.text = "%.1f ms" % (Miximizer.output_latency * 1000.0)


@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	# Audio Stream Player
	var audio_player := Miximizer._audio_player
	_label_playback_pos.text = "%.4f s" % audio_player.get_playback_position()
	_label_playing.text = "%s" % audio_player.playing
	_label_stream_paused.text = "%s" % audio_player.stream_paused
	_label_bus.text = audio_player.bus
	var playback_type: String
	match audio_player.playback_type:
		AudioServer.PLAYBACK_TYPE_DEFAULT: playback_type =  "DEFAULT"
		AudioServer.PLAYBACK_TYPE_STREAM: playback_type =  "STREAM"
		AudioServer.PLAYBACK_TYPE_SAMPLE: playback_type =  "SAMPLE"
		_: playback_type = "UNKNOWN"
	_label_playback_type.text = playback_type
	
	# Audio Server
	_label_since_mix.text = "%.4f s" % AudioServer.get_time_since_last_mix()
	
	# Miximizer
	_label_play_state.text = "%s" % Miximizer.PlayState.find_key(Miximizer.play_state)
	_label_bpm.text = "%.1f bpm" % Miximizer.current_bpm
	_label_time_signature.text = "%s" % Miximizer.current_time_signature
	_label_current_time.text = "%.4f s" % Miximizer.get_current_time_sec()
	_label_current_timing.text = "%s" % Miximizer.get_current_timing()
	_label_timing_source.text = "%s" % Miximizer.TimingSource.find_key(Miximizer.active_timing_source)


func _on_play_button_button_down() -> void:
	Miximizer.play()


func _on_pause_button_button_down() -> void:
	match Miximizer.play_state:
		Miximizer.PlayState.PLAYING:
			Miximizer.pause()
		Miximizer.PlayState.PAUSE:
			Miximizer.resume()


func _on_stop_button_button_down() -> void:
	Miximizer.stop()


func _on_button_change_audio_player_mode_button_down() -> void:
	Miximizer.timing_source = Miximizer.TimingSource.AUDIO_PLAYER


func _on_button_change_real_clock_mode_button_down() -> void:
	Miximizer.timing_source = Miximizer.TimingSource.REAL_CLOCK
