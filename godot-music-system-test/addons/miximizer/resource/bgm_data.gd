@tool
extends Resource
class_name BGMData

## BGM のオーディオストリーム
@export var bgm_stream: AudioStream = null

## テンポ (BPM)
@export var bpm: float = 120.0

## 拍子
@export var time_signature: TimeSignature = TimeSignature.new()

## 開始時刻（秒）
@export var start_time_sec: float = 0.0

## BGM のボリューム（0.0〜1.0）
@export_range(0.0, 1.0, 0.01) var volume: float = 1.0


func _init() -> void:
	if time_signature == null:
		time_signature = TimeSignature.new()
