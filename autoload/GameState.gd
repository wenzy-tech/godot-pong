extends Node

var difficulty_multiplier: float = 0.7  # AI speed multiplier
var difficulty_name: String = "NORMAL"

func _ready() -> void:
	pass

func set_difficulty(diff: String) -> void:
	difficulty_name = diff
	match diff:
		"EASY":
			difficulty_multiplier = 0.4
		"NORMAL":
			difficulty_multiplier = 0.7
		"HARD":
			difficulty_multiplier = 0.9