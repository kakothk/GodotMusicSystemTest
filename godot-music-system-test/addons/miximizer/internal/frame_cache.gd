## 1フレームに1回のみ更新されるキャッシュ用コンテナ
class_name FrameCache
extends RefCounted

var _value: Variant = null
var _last_update_frame: int = -1


## キャッシュされている値
var value: Variant:
	get: return _value


## 更新が必要かどうか（現在のフレームでまだ更新されていなければ true）
var needs_update: bool:
	get: return _last_update_frame != Engine.get_process_frames()


func _init(initial_value: Variant = null) -> void:
	_value = initial_value


## 値を更新し、更新フレームを記録する
func set_value(new_value: Variant) -> void:
	_value = new_value
	_last_update_frame = Engine.get_process_frames()
