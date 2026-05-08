@tool
extends Control
class_name AudioSpectrumDisplay

## 監視するオーディオバス
@export var bus: StringName = &"Master"

## 分割する周波数帯域の数
@export var vu_count: int = 32
## 最大周波数
@export var freq_max: float = 11050.0
## 最小デシベル値
@export var min_db: float = 60.0
## バーの色
@export var color: Color = Color(0.25, 0.88, 0.82, 0.5)
## バーの間の隙間 (px)
@export var spacing: float = 2.0

var _spectrum: AudioEffectSpectrumAnalyzerInstance = null


func _validate_property(property: Dictionary) -> void:
	if property.name == "bus":
		var bus_names: PackedStringArray = []
		for i: int in AudioServer.bus_count:
			bus_names.append(AudioServer.get_bus_name(i))
		property.hint = PROPERTY_HINT_ENUM
		property.hint_string = ",".join(bus_names)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
		
	var bus_idx: int = AudioServer.get_bus_index(bus)
	if bus_idx == -1:
		bus_idx = AudioServer.get_bus_index("Master")
		
	if AudioServer.get_bus_effect_count(bus_idx) > 0:
		_spectrum = AudioServer.get_bus_effect_instance(bus_idx, 0) as AudioEffectSpectrumAnalyzerInstance


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	if Engine.is_editor_hint(): return
	if _spectrum == null: return
	
	var total_spacing: float = spacing * (vu_count - 1)
	var bar_width: float = (size.x - total_spacing) / vu_count
	
	var prev_hz: float = 0.0
	for i: int in range(1, vu_count + 1):
		var hz: float = i * freq_max / vu_count
		var magnitude: Vector2 = _spectrum.get_magnitude_for_frequency_range(prev_hz, hz)
		var energy: float = clampf((linear_to_db(magnitude.length()) + min_db) / min_db, 0.0, 1.0)
		
		var height: float = energy * size.y
		
		var pos_x: float = (bar_width + spacing) * (i - 1)
		var rect: Rect2 = Rect2(pos_x, size.y - height, bar_width, height)
		draw_rect(rect, color)
		
		prev_hz = hz
