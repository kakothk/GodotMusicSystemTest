## 楽曲上のタイミング（小節・拍・16分音符）
class_name Timing
extends RefCounted

@export var bar: int = 0
@export var beat: int = 0
@export var unit: int = 0


## コンストラクタ
func _init(p_bar: int = 0, p_beat: int = 0, p_unit: int = 0) -> void:
	bar = p_bar
	beat = p_beat
	unit = p_unit


## 複製
func duplicate_timing() -> Timing:
	return Timing.new(bar, beat, unit)


## 他の Timing から値をコピーして自身を上書きする
## [br]
## アロケーションを避けたい場合に duplicate_timing() の代替として使う
func copy_from(other: Timing) -> void:
	bar = other.bar
	beat = other.beat
	unit = other.unit


## 加算
func add(other: Timing) -> Timing:
	return Timing.new(bar + other.bar, beat + other.beat, unit + other.unit)


## 減算
func subtract(other: Timing) -> Timing:
	return Timing.new(bar - other.bar, beat - other.beat, unit - other.unit)


## 等価判定
func equals(other: Timing) -> bool:
	if other == null:
		return false
	return bar == other.bar and beat == other.beat and unit == other.unit


## 大小比較
## [br]
## self < other なら -1、 self == other なら 0、 self > other なら 1
func compare_to(other: Timing) -> int:
	if bar != other.bar:
		return -1 if bar < other.bar else 1
	if beat != other.beat:
		return -1 if beat < other.beat else 1
	if unit != other.unit:
		return -1 if unit < other.unit else 1
	return 0


## 値が有効かどうか（負の値が含まれていないかどうか）
func is_valid() -> bool:
	return bar >= 0 and beat >= 0 and unit >= 0


func _to_string() -> String:
	return "%d.%d.%d" % [bar, beat, unit]


## 0.0.0
static func zero() -> Timing:
	return Timing.new(0, 0, 0)


## エラー値（-1.-1.-1）
static func error() -> Timing:
	return Timing.new(-1, -1, -1)


## 最大値
static func max_value() -> Timing:
	const I32_MAX := 0x7FFFFFFF
	return Timing.new(I32_MAX, I32_MAX, I32_MAX)
