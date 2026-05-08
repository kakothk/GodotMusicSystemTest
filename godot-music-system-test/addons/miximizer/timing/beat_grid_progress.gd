## 各ビート幅における進行度（0〜1）を保持するクラス
class_name BeatGridProgress
extends RefCounted

var bar_progress: float = 0.0
var half_bar_progress: float = 0.0
var beat_progress: float = 0.0
var half_beat_progress: float = 0.0
var unit_progress: float = 0.0


## コンストラクタ
func _init(p_bar: float = 0.0, p_half_bar: float = 0.0,
	p_beat: float = 0.0, p_half_beat: float = 0.0,
	p_unit: float = 0.0) -> void:
	bar_progress = clampf(p_bar, 0.0, 1.0)
	half_bar_progress = clampf(p_half_bar, 0.0, 1.0)
	beat_progress = clampf(p_beat, 0.0, 1.0)
	half_beat_progress = clampf(p_half_beat, 0.0, 1.0)
	unit_progress = clampf(p_unit, 0.0, 1.0)


## 指定した [BeatGrid] の進行度を返す
func get_progress(grid: BeatGrid.Type) -> float:
	match grid:
		BeatGrid.Type.UNIT: return unit_progress
		BeatGrid.Type.HALF_BEAT: return half_beat_progress
		BeatGrid.Type.BEAT: return beat_progress
		BeatGrid.Type.HALF_BAR: return half_bar_progress
		BeatGrid.Type.BAR: return bar_progress
		_: return 0.0


func _to_string() -> String:
	return "Bar:%.3f HalfBar:%.3f Beat:%.3f HalfBeat:%.3f Unit:%.3f" % [
		bar_progress, half_bar_progress, beat_progress, half_beat_progress, unit_progress
	]


static func zero() -> BeatGridProgress:
	return BeatGridProgress.new(0.0, 0.0, 0.0, 0.0, 0.0)
