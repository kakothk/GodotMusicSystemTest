## 楽曲時間に関する計算ユーティリティ
class_name MusicalTimeMath
extends RefCounted


## 1拍の長さを秒で返す
static func beat_duration_sec(bpm: float) -> float:
	if bpm <= 0.0:
		return 0.0
	return 60.0 / bpm


## 1ユニット（16分音符）の長さを秒で返す
static func unit_duration_sec(bpm: float, time_signature: TimeSignature) -> float:
	if time_signature == null:
		return 0.0
	var upb := time_signature.units_per_beat()
	if upb <= 0:
		return 0.0
	return beat_duration_sec(bpm) / float(upb)


## 1小節の長さを秒で返す
static func bar_duration_sec(bpm: float, time_signature: TimeSignature) -> float:
	if time_signature == null:
		return 0.0
	return beat_duration_sec(bpm) * float(time_signature.numerator)


## 指定の BeatGrid の長さを秒で返す
static func grid_duration_sec(grid: BeatGrid.Type, bpm: float, time_signature: TimeSignature) -> float:
	if time_signature == null:
		return 0.0
	var beat_sec := beat_duration_sec(bpm)
	match grid:
		BeatGrid.Type.UNIT:
			return unit_duration_sec(bpm, time_signature)
		BeatGrid.Type.HALF_BEAT:
			return beat_sec / 2.0
		BeatGrid.Type.BEAT:
			return beat_sec
		BeatGrid.Type.HALF_BAR:
			return beat_sec * float(time_signature.numerator) / 2.0
		BeatGrid.Type.BAR:
			return beat_sec * float(time_signature.numerator)
		_:
			return 0.0


## 秒数から Timing を生成する
## [br]
## time_sec が負、または bpm/time_signature が不正なら Timing.error() を返す
static func seconds_to_timing(time_sec: float, bpm: float, time_signature: TimeSignature) -> Timing:
	if time_sec < 0.0 or bpm <= 0.0 or time_signature == null or not time_signature.is_valid():
		return Timing.error()
	
	var unit_sec := unit_duration_sec(bpm, time_signature)
	var units_per_beat := time_signature.units_per_beat()
	var units_per_bar := time_signature.numerator * units_per_beat
	
	# 全体の経過ユニット数を float で出してから、丸めずに切り捨てる
	# （Timing は「現時点で何ユニット目に居るか」を表すため）
	var total_units_f := time_sec / unit_sec
	# 浮動小数点誤差で 1.9999... が 2.0 直前の値になる場合に備えて、
	# ごく小さい epsilon を足してから切り捨てる
	const EPSILON := 1e-9
	var total_units := int(floor(total_units_f + EPSILON))
	
	@warning_ignore("integer_division")
	var bar := total_units / units_per_bar
	var rem := total_units % units_per_bar
	@warning_ignore("integer_division")
	var beat := rem / units_per_beat
	var unit := rem % units_per_beat
	
	return Timing.new(bar, beat, unit)


## Timing を秒数に変換する
## [br]
## timing/bpm/time_signature が不正なら -1.0 を返す
static func timing_to_seconds(timing: Timing, bpm: float, time_signature: TimeSignature) -> float:
	if timing == null or not timing.is_valid():
		return -1.0
	if bpm <= 0.0 or time_signature == null or not time_signature.is_valid():
		return -1.0
	
	var unit_sec := unit_duration_sec(bpm, time_signature)
	var units_per_beat := time_signature.units_per_beat()
	var total_units := timing.bar * time_signature.numerator * units_per_beat + timing.beat * units_per_beat + timing.unit
	return float(total_units) * unit_sec


## 秒数から BeatGridProgress を生成する
static func seconds_to_beat_grid_progress(time_sec: float, bpm: float, time_signature: TimeSignature) -> BeatGridProgress:
	if time_sec < 0.0 or bpm <= 0.0 or time_signature == null or not time_signature.is_valid():
		return BeatGridProgress.zero()
	
	var beat_sec := beat_duration_sec(bpm)
	var bar_sec := beat_sec * float(time_signature.numerator)
	var half_bar_sec := bar_sec / 2.0
	var half_beat_sec := beat_sec / 2.0
	var unit_sec := unit_duration_sec(bpm, time_signature)
	
	var bar_p := fmod(time_sec, bar_sec) / bar_sec
	var half_bar_p := fmod(time_sec, half_bar_sec) / half_bar_sec
	var beat_p := fmod(time_sec, beat_sec) / beat_sec
	var half_beat_p := fmod(time_sec, half_beat_sec) / half_beat_sec
	var unit_p := fmod(time_sec, unit_sec) / unit_sec
	
	return BeatGridProgress.new(bar_p, half_bar_p, beat_p, half_beat_p, unit_p)
