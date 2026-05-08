## BGM 制御クラス
extends Node

## 再生状態
enum PlayState {
	STOP,
	PLAYING,
	PAUSE,
}

## 再生位置の計算ソース
enum TimingSource {
	## プラットフォームで自動選択（Webなら REAL_CLOCK、それ以外は AUDIO_PLAYER）
	AUTO,
	## AudioStreamPlayer.get_playback_position() ベース
	AUDIO_PLAYER,
	## Time.get_ticks_usec() ベース（実時計）
	REAL_CLOCK,
}

## 再生開始時シグナル
signal started
## 停止時シグナル
signal stopped
## 終了時シグナル
signal finished

## 1小節の同期時シグナル
signal bar_synced
## 1小節の半分の同期時シグナル
signal half_bar_synced
## 1拍の同期時シグナル
signal beat_synced
## 1拍の半分の同期時シグナル
signal half_beat_synced
## 1ユニット（16分音符）の同期時シグナル
signal unit_synced

## オーディオバス
@export var bus: StringName = &"BGM"
## BGM のリソースデータ
@export var bgm_data: BGMData = null
## ボリューム（0.0〜1.0）
@export_range(0.0, 1.0, 0.01) var master_volume: float = 1.0:
	set(value):
		master_volume = clampf(value, 0.0, 1.0)
		_apply_volume()
## 再生位置の計算ソース
@export var timing_source: TimingSource = TimingSource.AUTO:
	set(value):
		timing_source = value
		_resolve_active_timing_source()

var _audio_player: AudioStreamPlayer = null
var output_latency: float = 0.0

var play_state: PlayState = PlayState.STOP
var current_bpm: float = 120.0
var current_time_signature: TimeSignature = TimeSignature.new()
var active_timing_source: TimingSource = TimingSource.AUDIO_PLAYER

# フレームキャッシュ：同フレーム内で同じ値を再計算しないためのもの
var _time_sec_cache: FrameCache = FrameCache.new(0.0)
var _timing_cache: FrameCache = FrameCache.new(Timing.zero())
var _beat_grid_progress_cache: FrameCache = FrameCache.new(BeatGridProgress.zero())

# ジッター対策用：前回フレームで返した時刻
var _last_returned_time_sec: float = 0.0
# ビート発火検知用
var _prev_timing: Timing = Timing.zero()
# STOP 中に seek されたときの予約位置（秒）。-1.0 なら未指定（bgm_data.start_time_sec を使う）
var _pending_start_sec: float = -1.0

# 実時計ベース（REAL_CLOCK）用の状態
# 直近の play()/resume() 時の Time.get_ticks_usec()
var _realclock_segment_begin_usec: int = 0
# 過去のセグメントの累積時間（秒）。pause 時にそこまでの経過が加算される
var _realclock_accumulated_sec: float = 0.0
# play() 直後の遅延補正値（秒）。get_time_to_next_mix() + output_latency
var _realclock_initial_delay_sec: float = 0.0


## リソースデータから BGM 設定を読み込む
func load_bgm_data(p_bgm_data: BGMData) -> void:
	if p_bgm_data == null:
		push_error("[Miximizer] load_bgm_data: bgm_data is null.")
		return
	
	bgm_data = p_bgm_data
	
	current_bpm = p_bgm_data.bpm
	current_time_signature = p_bgm_data.time_signature
	
	if _audio_player == null: _create_audio_player()
	_audio_player.stream = p_bgm_data.bgm_stream


## Audio Stream Player を作成する
func _create_audio_player():
	_audio_player = AudioStreamPlayer.new()
	_audio_player.name = "AudioPlayer"
	_audio_player.bus = bus
	_audio_player.finished.connect(_on_audio_finished)
	add_child(_audio_player)


## 現在の master_volume と bgm_data.volume を _audio_player.volume_db に反映する
func _apply_volume() -> void:
	if _audio_player == null:
		return
	var bgm_vol: float = bgm_data.volume if bgm_data != null else 1.0
	_audio_player.volume_db = linear_to_db(bgm_vol * master_volume)


func _ready() -> void:
	if _audio_player == null:
		_create_audio_player()
	refresh_output_latency()
	_resolve_active_timing_source()


## timing_source の値から、実際に使用される _active_timing_source を決定する
func _resolve_active_timing_source() -> void:
	if timing_source == TimingSource.AUTO:
		active_timing_source = TimingSource.REAL_CLOCK if OS.has_feature("web") else TimingSource.AUDIO_PLAYER
	else:
		active_timing_source = timing_source


func _process(_delta: float) -> void:
	if play_state != PlayState.PLAYING:
		return
	
	# 現在タイミングを取得
	var timing := get_current_timing()
	
	# 変化がなければスキップ
	if timing.equals(_prev_timing):
		return
	
	## ビート同期コールバックの発火
	_emit_beat_sync_signals(timing)
	_prev_timing.copy_from(timing)


## ビート同期コールバックの発火
func _emit_beat_sync_signals(timing: Timing) -> void:
	var units_per_beat := current_time_signature.units_per_beat()
	var numerator := current_time_signature.numerator
	
	# Bar発火（Barが変化したとき）
	if _prev_timing.bar != timing.bar:
		bar_synced.emit()
	
	# Beat 発火（Beat が変化したとき）
	if _prev_timing.beat != timing.beat or _prev_timing.bar != timing.bar:
		# HalfBar発火（beat が 0 か numerator / 2 のとき）
		if numerator > 0:
			@warning_ignore("integer_division")
			var half_beat_in_bar := numerator / 2
			if timing.beat == 0 or (half_beat_in_bar > 0 and timing.beat == half_beat_in_bar):
				half_bar_synced.emit()
		beat_synced.emit()
	
	# HalfBeat 発火（unit が 0 か units_per_beat / 2 のとき）
	if units_per_beat > 0:
		@warning_ignore("integer_division")
		var half_unit := units_per_beat / 2
		if timing.unit == 0 or (half_unit > 0 and timing.unit == half_unit):
			half_beat_synced.emit()
	
	# Unit 発火（最小単位なので毎回発火）
	unit_synced.emit()


## 再生する
func play() -> void:
	if _audio_player.stream == null:
		push_error("[Miximizer] bgm_stream is not set.")
		return
	
	match play_state:
		PlayState.PLAYING:
			return
		PlayState.PAUSE:
			return
		PlayState.STOP:
			play_state = PlayState.PLAYING
			
			# 再生開始位置を設定。seek() による予約があればそれを優先、なければ bgm_data.start_time_sec
			var start_time_sec: float = _pending_start_sec if _pending_start_sec >= 0.0 else bgm_data.start_time_sec
			_pending_start_sec = -1.0
			
			# 再生開始
			refresh_output_latency()
			_apply_volume()
			_apply_position_sec(start_time_sec)
			_audio_player.play(start_time_sec)
			
			# 実時計ベースの状態を初期化
			# get_time_to_next_mix() は play() 直後に呼ぶことで、最初の音が鳴るまでの遅延を取得できる
			_realclock_accumulated_sec = start_time_sec
			_realclock_segment_begin_usec = Time.get_ticks_usec()
			_realclock_initial_delay_sec = AudioServer.get_time_to_next_mix() + output_latency
			
			# 再生開始時シグナル
			started.emit()


## 一時停止する
func pause() -> void:
	if play_state == PlayState.PLAYING:
		play_state = PlayState.PAUSE
		
		# 実時計ベース：現在のセグメントの経過時間を累積に加算
		var segment_elapsed: float = (Time.get_ticks_usec() - _realclock_segment_begin_usec) / 1000000.0
		_realclock_accumulated_sec += segment_elapsed - _realclock_initial_delay_sec
		# 累積時間にはレイテンシ補正を含めないので、ここで補正分を引いておく
		# （次の resume() 時に再度 initial_delay_sec を引かないように、補正は1回だけ）
		_realclock_initial_delay_sec = 0.0
		
		_audio_player.stream_paused = true


## 一時停止を解除する
func resume() -> void:
	if play_state == PlayState.PAUSE:
		play_state = PlayState.PLAYING
		_realclock_segment_begin_usec = Time.get_ticks_usec() # 実時計ベース：起点を現在に再設定
		_audio_player.stream_paused = false


## 停止する
func stop() -> void:
	if play_state != PlayState.STOP:
		play_state = PlayState.STOP
		_audio_player.stop()
		
		# 各種状態をリセット
		_prev_timing = Timing.zero()
		_last_returned_time_sec = 0.0
		_pending_start_sec = -1.0
		_realclock_accumulated_sec = 0.0
		_realclock_segment_begin_usec = 0
		_realclock_initial_delay_sec = 0.0
		
		stopped.emit()


## 指定秒数の位置にシークする
func seek(seek_sec: float) -> void:
	if seek_sec < 0.0:
		seek_sec = 0.0
	
	_apply_position_sec(seek_sec)
	
	match play_state:
		PlayState.PLAYING, PlayState.PAUSE:
			# 即時シーク
			_audio_player.seek(seek_sec)
			# 実時計ベース：起点をリセットし、累積時間をシーク位置に上書き
			_realclock_accumulated_sec = seek_sec
			_realclock_segment_begin_usec = Time.get_ticks_usec()
			_realclock_initial_delay_sec = 0.0
		PlayState.STOP:
			# 次の play() の開始位置として予約しておく
			_pending_start_sec = seek_sec


## 指定 Timing の位置にシークする
func seek_timing(seek_timing: Timing) -> void:
	var seek_sec := MusicalTimeMath.timing_to_seconds(seek_timing, current_bpm, current_time_signature)
	seek(seek_sec)


## 現在の再生位置（秒）を返す
func get_current_time_sec() -> float:
	if play_state == PlayState.STOP:
		return 0.0
	
	# ポーズ中は時刻が進まないので、最後に返した値をそのまま返す
	if play_state == PlayState.PAUSE:
		return _last_returned_time_sec
	
	# 同フレーム内ならキャッシュを使う
	if not _time_sec_cache.needs_update:
		return _time_sec_cache.value
	
	# 再生位置を計算（timing source に応じて分岐）
	var corrected: float
	match active_timing_source:
		TimingSource.REAL_CLOCK:
			corrected = _calc_time_sec_realclock()
		_:
			corrected = _calc_time_sec_audio_player()
	
	# ジッター対策、前回より小さい値は採用しない
	if corrected < _last_returned_time_sec:
		corrected = _last_returned_time_sec
	else:
		_last_returned_time_sec = corrected
	
	# キャッシュ更新
	_time_sec_cache.set_value(corrected)
	return corrected


## AudioStreamPlayer.get_playback_position() ベースで再生位置を計算する
func _calc_time_sec_audio_player() -> float:
	var raw_pos := _audio_player.get_playback_position()
	var since_mix := AudioServer.get_time_since_last_mix()
	return raw_pos + since_mix - output_latency


## Time.get_ticks_usec() ベースで再生位置を計算する
func _calc_time_sec_realclock() -> float:
	var segment_elapsed: float = (Time.get_ticks_usec() - _realclock_segment_begin_usec) / 1000000.0
	return maxf(0.0, _realclock_accumulated_sec + segment_elapsed - _realclock_initial_delay_sec)


## 現在の Timing を返す。同フレーム内では計算結果をキャッシュする
func get_current_timing() -> Timing:
	if not _timing_cache.needs_update:
		return _timing_cache.value
	
	var t := get_current_time_sec()
	var result := MusicalTimeMath.seconds_to_timing(t, current_bpm, current_time_signature)
	
	_timing_cache.set_value(result)
	return result


## 現在の進行度を返す。同フレーム内では計算結果をキャッシュする
func get_current_beat_grid_progress() -> BeatGridProgress:
	if not _beat_grid_progress_cache.needs_update:
		return _beat_grid_progress_cache.value
	
	var t := get_current_time_sec()
	var result := MusicalTimeMath.seconds_to_beat_grid_progress(t, current_bpm, current_time_signature)
	
	_beat_grid_progress_cache.set_value(result)
	return result


## オーディオドライバの出力レイテンシを再取得してキャッシュを更新する
func refresh_output_latency() -> void:
	output_latency = AudioServer.get_output_latency()


## 再生中か
func is_playing() -> bool:
	return play_state == PlayState.PLAYING


## 指定秒数の位置を、Miximizer の内部タイミング状態に適用する
func _apply_position_sec(position_sec: float) -> void:
	_time_sec_cache.set_value(position_sec)
	_last_returned_time_sec = position_sec
		
	# current_timing の即時更新
	var current_timing := MusicalTimeMath.seconds_to_timing(
		position_sec, current_bpm, current_time_signature)
	_timing_cache.set_value(current_timing)
	
	# prev_timing は少し手前に設定（開始直後のビート検知を漏らさないため）
	const PREV_TIMING_BUFFER_SEC: float = 0.01  # 10ms
	var prev_time_sec: float = position_sec - PREV_TIMING_BUFFER_SEC
	var new_prev_timing := MusicalTimeMath.seconds_to_timing(prev_time_sec, current_bpm, current_time_signature)
	_prev_timing.copy_from(new_prev_timing)


## 終了時コールバック
func _on_audio_finished() -> void:
	play_state = PlayState.STOP
	_prev_timing = Timing.zero()
	_last_returned_time_sec = 0.0
	_realclock_accumulated_sec = 0.0
	_realclock_segment_begin_usec = 0
	_realclock_initial_delay_sec = 0.0
	finished.emit()
