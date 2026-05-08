## 拍子記号
class_name TimeSignature
extends Resource

## 拍子の分子（例: 2/4 なら 2）
@export var numerator: int = 4

## 拍子の分母（例: 2/4 なら 4）
@export var denominator: int = 4


## コンストラクタ
func _init(p_numerator: int = 4, p_denominator: int = 4) -> void:
	numerator = p_numerator
	denominator = p_denominator


## 値が有効かどうか（numerator/denominator が共に正かどうか）
func is_valid() -> bool:
	return numerator > 0 and denominator > 0


## 等価判定
func equals(other: TimeSignature) -> bool:
	if other == null:
		return false
	return numerator == other.numerator and denominator == other.denominator


## 1拍あたりのユニット数（16分音符換算）
func units_per_beat() -> int:
	@warning_ignore("integer_division")
	return 16 / denominator


## 1小節あたりのユニット数（16分音符換算）
func units_per_bar() -> int:
	return numerator * units_per_beat()


func _to_string() -> String:
	return "%d/%d" % [numerator, denominator]
