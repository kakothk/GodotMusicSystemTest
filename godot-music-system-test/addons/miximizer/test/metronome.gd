## テスト用メトロノーム
class_name Metronome
extends AudioStreamPlayer

@export var bar_sound: AudioStream = null
@export var beat_sound: AudioStream = null


func _enter_tree() -> void:
	Miximizer.bar_synced.connect(_on_bar_synced)
	Miximizer.beat_synced.connect(_on_beat_synced)


func _exit_tree() -> void:
	Miximizer.bar_synced.disconnect(_on_bar_synced)
	Miximizer.beat_synced.disconnect(_on_beat_synced)


func _on_bar_synced() -> void:
	if not bar_sound == null:
		stream = bar_sound
		play()


func _on_beat_synced() -> void:
	if Miximizer.get_current_timing().beat == 0:
		return
	if not beat_sound == null:
		stream = beat_sound
		play()
