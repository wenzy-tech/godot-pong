extends Control

var time_elapsed: float = 0.0
var selected_difficulty: String = "NORMAL"

@onready var title_label: Label = $CenterContainer/VBox/Title
@onready var easy_btn: Button = $CenterContainer/VBox/DifficultyButtons/EasyBtn
@onready var normal_btn: Button = $CenterContainer/VBox/DifficultyButtons/NormalBtn
@onready var hard_btn: Button = $CenterContainer/VBox/DifficultyButtons/HardBtn

func _ready() -> void:
	_select_difficulty("NORMAL")

func _process(delta: float) -> void:
	time_elapsed += delta
	_update_animations(delta)

func _update_animations(delta: float) -> void:
	var glow = 0.7 + sin(time_elapsed * 2.0) * 0.3
	title_label.modulate = Color(0.0, glow, glow * 0.9, 1.0)

func _select_difficulty(diff: String) -> void:
	selected_difficulty = diff
	
	easy_btn.modulate = Color(0.3, 1.0, 0.5, 0.5)
	normal_btn.modulate = Color(0.2, 0.7, 1.0, 0.5)
	hard_btn.modulate = Color(1.0, 0.3, 0.4, 0.5)
	
	match diff:
		"EASY":
			easy_btn.modulate = Color(0.5, 1.0, 0.5, 1.0)
		"NORMAL":
			normal_btn.modulate = Color(0.8, 0.9, 1.0, 1.0)
		"HARD":
			hard_btn.modulate = Color(1.0, 0.5, 0.6, 1.0)

func _on_easy_pressed() -> void:
	_select_difficulty("EASY")

func _on_normal_pressed() -> void:
	_select_difficulty("NORMAL")

func _on_hard_pressed() -> void:
	_select_difficulty("HARD")

func _on_start_pressed() -> void:
	if has_node("/root/GameState"):
		get_node("/root/GameState").set_difficulty(selected_difficulty)
	
	var main_scene = preload("res://Main.tscn").instantiate()
	get_tree().root.add_child(main_scene)
	queue_free()

func _on_quit_pressed() -> void:
	get_tree().quit()