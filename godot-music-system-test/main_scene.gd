extends Control

@export var next_scene: PackedScene


func _on_button_button_down() -> void:
	get_tree().change_scene_to_packed(next_scene)
