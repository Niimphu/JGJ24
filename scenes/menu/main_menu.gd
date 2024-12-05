extends Control


func _on_play_button_down():
	$AnimationPlayer.play("fade_out")


func _on_quit_pressed():
	get_tree().quit()


func _on_animation_player_animation_finished(_anim_name):
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")
