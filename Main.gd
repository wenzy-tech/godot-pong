extends Node2D

func _ready():
	print("DEBUG: _ready called")

func _draw():
	# Simple background
	draw_rect(Rect2(0, 0, 800, 600), Color(0.1, 0.1, 0.2))
	
	# Ball
	draw_circle(Vector2(400, 300), 20, Color(0, 1, 0.8))
	
	# Left paddle
	draw_rect(Rect2(10, 250, 20, 100), Color(0.2, 0.6, 1.0))
	
	# Right paddle
	draw_rect(Rect2(770, 250, 20, 100), Color(1.0, 0.3, 0.5))
	
	# Center line
	draw_line(Vector2(400, 0), Vector2(400, 600), Color(0.3, 0.5, 0.8), 3.0)
	
	print("DEBUG: _draw called")
