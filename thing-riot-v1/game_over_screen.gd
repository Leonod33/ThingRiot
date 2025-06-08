extends Control

func _on_restart_button_pressed():
	# To restart the game, you can reload the main scene or return to title
	# get_tree().change_scene_to_file("res://main.tscn")
	# Or if you want to return to title:
	get_tree().change_scene_to_file("res://title_screen.tscn")
