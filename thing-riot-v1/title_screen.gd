extends Control

func _on_start_button_pressed():
	get_tree().change_scene_to_file("res://main.tscn")
	
func _unhandled_input(event):
	if Input.is_action_just_pressed("start_game"):
		_start_game()

func _start_game():
	get_tree().change_scene_to_file("res://main.tscn")
