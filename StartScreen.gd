extends Control

var time_elapsed: float = 0.0
var animation_playing: bool = true

@onready var title_label: Label = $Title
@onready var subtitle_label: Label = $Subtitle
@onready var start_btn: Button = $StartBtn

func _ready() -> void:
	# Show quit button on web (since we can't really quit on web)
	$QuitBtn.visible = false  # Hide for now, can enable for desktop
	
	# Animate title
	_animate_title()

func _process(delta: float) -> void:
	time_elapsed += delta
	if animation_playing:
		_update_animations(delta)

func _update_animations(delta: float) -> void:
	# Title glow pulse
	var glow = 0.7 + sin(time_elapsed * 2.0) * 0.3
	title_label.modulate = Color(0.0, glow, glow * 0.9, 1.0)
	
	# Subtitle flicker
	var flicker = 0.6 + sin(time_elapsed * 5.0) * 0.2 + sin(time_elapsed * 7.3) * 0.2
	subtitle_label.modulate = Color(0.3 * flicker, 0.5 * flicker, 0.8 * flicker, 1.0)
	
	# Button hover effect (via modulate)
	if start_btn:
		start_btn.modulate = Color(0.9 + sin(time_elapsed * 3.0) * 0.1, 1.0, 1.0, 1.0)

func _animate_title() -> void:
	animation_playing = true

func _on_start_pressed() -> void:
	# Transition to game
	var main_scene = preload("res://Main.tscn").instantiate()
	get_tree().root.add_child(main_scene)
	queue_free()

func _on_quit_pressed() -> void:
	# For desktop - quit the game
	get_tree().quit()