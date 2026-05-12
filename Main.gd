extends Node2D

var ball_position = Vector2(400, 300)
var ball_velocity = Vector2(400, 400)
var ball_radius = 10

var pad1_pos = Vector2(30, 300)
var pad2_pos = Vector2(770, 300)
var pad_speed = 400
var pad1_height = 100.0
var pad2_height = 100.0

var score1 = 0
var score2 = 0

func _ready():
	print("DEBUG V31: _ready called")

func _process(delta):
	ball_position += ball_velocity * delta
	
	if ball_position.y < ball_radius or ball_position.y > 600 - ball_radius:
		ball_velocity.y = -ball_velocity.y
	
	if ball_position.x < 50 and abs(ball_position.y - pad1_pos.y) < pad1_height * 0.5:
		ball_velocity.x = abs(ball_velocity.x)
	
	if ball_position.x > 750 and abs(ball_position.y - pad2_pos.y) < pad2_height * 0.5:
		ball_velocity.x = -abs(ball_velocity.x)
	
	if ball_position.x < ball_radius:
		score2 += 1
		reset_ball()
	if ball_position.x > 800 - ball_radius:
		score1 += 1
		reset_ball()
	
	if ball_position.y < pad2_pos.y - 30:
		pad2_pos.y -= pad_speed * 0.7 * delta
	if ball_position.y > pad2_pos.y + 30:
		pad2_pos.y += pad_speed * 0.7 * delta
	pad2_pos.y = clamp(pad2_pos.y, 50, 550)
	
	if Input.is_action_pressed("move_up"):
		pad1_pos.y -= pad_speed * delta
	if Input.is_action_pressed("move_down"):
		pad1_pos.y += pad_speed * delta
	pad1_pos.y = clamp(pad1_pos.y, 50, 550)
	
	update()

func reset_ball():
	ball_position = Vector2(400, 300)
	ball_velocity = Vector2(400 * (1 if randf() > 0.5 else -1), 400 * (1 if randf() > 0.5 else -1))

func _draw():
	# Background
	draw_rect(Rect2(0, 0, 800, 600), Color(0.05, 0.05, 0.12))
	
	# Ball - solid cyan circle
	draw_circle(ball_position, ball_radius, Color(0.0, 1.0, 0.8))
	
	# Left paddle - solid blue rectangle
	draw_rect(Rect2(10, pad1_pos.y - pad1_height * 0.5, 20, pad1_height), Color(0.2, 0.6, 1.0))
	
	# Right paddle - solid pink rectangle
	draw_rect(Rect2(770, pad2_pos.y - pad2_height * 0.5, 20, pad2_height), Color(1.0, 0.3, 0.5))
	
	# Simple score indicator
	if score1 > 0:
		draw_circle(Vector2(100, 30), 8, Color(0.2, 0.6, 1.0))
	if score2 > 0:
		draw_circle(Vector2(700, 30), 8, Color(1.0, 0.3, 0.5))
	
	print("DEBUG V31: _draw called")
