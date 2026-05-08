## 小節・拍・ユニットなど、音楽的な時間の区切り単位
class_name BeatGrid
extends RefCounted

enum Type {
	UNIT,      ## ユニット（16分音符）
	HALF_BEAT, ## 拍の半分
	BEAT,      ## 拍
	HALF_BAR,  ## 小節の半分
	BAR,       ## 小節
}
