extends VBoxContainer

@export var flash_alpha_strong: float = 1.0
@export var flash_alpha_weak: float = 0.6
@export var flash_duration_max: float = 0.2
@export var normal_alpha: float = 0.1

@onready var _bar_indicator: ColorRect = $Progress/BarIndicator
@onready var _bar_gauge: ProgressBar = $Progress/ProgressBar
@onready var _bar_label: Label = $Progress/ProgressBar/ValueLabel

@onready var _half_bar_indicator: ColorRect = $Progress/HalfBarIndicator
@onready var _half_bar_gauge: ProgressBar = $Progress/ProgressHalfBar
@onready var _half_bar_label: Label = $Progress/ProgressHalfBar/ValueLabel

@onready var _beat_indicator: ColorRect = $Progress/BeatIndicator
@onready var _beat_gauge: ProgressBar = $Progress/ProgressBeat
@onready var _beat_label: Label = $Progress/ProgressBeat/ValueLabel

@onready var _half_beat_indicator: ColorRect = $Progress/HalfBeatIndicator
@onready var _half_beat_gauge: ProgressBar = $Progress/ProgressHalfBeat
@onready var _half_beat_label: Label = $Progress/ProgressHalfBeat/ValueLabel

@onready var _unit_indicator: ColorRect = $Progress/UnitIndicator
@onready var _unit_gauge: ProgressBar = $Progress/ProgressUnit
@onready var _unit_label: Label = $Progress/ProgressUnit/ValueLabel


func _ready() -> void:
	# 初期アルファ値の適用
	_bar_indicator.color.a = normal_alpha
	_half_bar_indicator.color.a = normal_alpha
	_beat_indicator.color.a = normal_alpha
	_half_beat_indicator.color.a = normal_alpha
	_unit_indicator.color.a = normal_alpha


func _enter_tree() -> void:
	Miximizer.bar_synced.connect(_on_bar_synced)
	Miximizer.half_bar_synced.connect(_on_half_bar_synced)
	Miximizer.beat_synced.connect(_on_beat_synced)
	Miximizer.half_beat_synced.connect(_on_half_beat_synced)
	Miximizer.unit_synced.connect(_on_unit_synced)


func _exit_tree() -> void:
	Miximizer.bar_synced.disconnect(_on_bar_synced)
	Miximizer.half_bar_synced.disconnect(_on_half_bar_synced)
	Miximizer.beat_synced.disconnect(_on_beat_synced)
	Miximizer.half_beat_synced.disconnect(_on_half_beat_synced)
	Miximizer.unit_synced.disconnect(_on_unit_synced)


@warning_ignore("unused_parameter")
func _process(delta: float) -> void:
	var progress := Miximizer.get_current_beat_grid_progress()
	
	# ゲージの更新
	_bar_gauge.value = progress.bar_progress
	_half_bar_gauge.value = progress.half_bar_progress
	_beat_gauge.value = progress.beat_progress
	_half_beat_gauge.value = progress.half_beat_progress
	_unit_gauge.value = progress.unit_progress
	
	# テキストの更新
	_bar_label.text = "%.2f" % progress.bar_progress
	_half_bar_label.text = "%.2f" % progress.half_bar_progress
	_beat_label.text = "%.2f" % progress.beat_progress
	_half_beat_label.text = "%.2f" % progress.half_beat_progress
	_unit_label.text = "%.2f" % progress.unit_progress


func _on_bar_synced() -> void:
	_flash_indicator(_bar_indicator, flash_alpha_strong, flash_duration_max)

func _on_half_bar_synced() -> void:
	_flash_indicator(_half_bar_indicator, flash_alpha_weak, flash_duration_max / 2.0)

func _on_beat_synced() -> void:
	_flash_indicator(_beat_indicator, flash_alpha_strong, flash_duration_max / 3.0)

func _on_half_beat_synced() -> void:
	_flash_indicator(_half_beat_indicator, flash_alpha_weak, flash_duration_max / 4.0)

func _on_unit_synced() -> void:
	_flash_indicator(_unit_indicator, flash_alpha_weak, flash_duration_max / 5.0)


func _flash_indicator(indicator: ColorRect, target_alpha: float, duration: float) -> void:
	indicator.color.a = target_alpha
	var tween: Tween = create_tween()
	tween.tween_property(indicator, "color:a", normal_alpha, duration)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
