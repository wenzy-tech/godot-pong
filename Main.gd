extends Node2D

var ball_velocity = Vector2(400, 400)
var ball_position = Vector2(400, 300)
var pad1_pos = Vector2(30, 300)
var pad2_pos = Vector2(770, 300)
var score1 = 0
var score2 = 0
var pad_speed = 400
var ball_radius = 10
var game_over = false
var winner = ""

func _process(delta):
	if game_over:
		update()
		return
	
	# Player 1 movement (W/S keys)
	if Input.is_action_pressed("move_up"):
		pad1_pos.y -= pad_speed * delta
	if Input.is_action_pressed("move_down"):
		pad1_pos.y += pad_speed * delta
	pad1_pos.y = clamp(pad1_pos.y, 50, 550)
	
	# Ball movement
	ball_position += ball_velocity * delta
	if ball_position.y < ball_radius or ball_position.y > 600 - ball_radius:
		ball_velocity.y = -ball_velocity.y
	if ball_position.x < ball_radius:
		score2 += 1
		check_win()
		reset_ball()
	if ball_position.x > 800 - ball_radius:
		score1 += 1
		check_win()
		reset_ball()
	
	# Simple AI for pad2
	if ball_position.y < pad2_pos.y - 30:
		pad2_pos.y -= pad_speed * 0.7 * delta
	if ball_position.y > pad2_pos.y + 30:
		pad2_pos.y += pad_speed * 0.7 * delta
	pad2_pos.y = clamp(pad2_pos.y, 50, 550)
	
	# Ball-paddle collision
	if ball_position.x < 50 and abs(ball_position.y - pad1_pos.y) < 60:
		ball_velocity.x = abs(ball_velocity.x)
	if ball_position.x > 750 and abs(ball_position.y - pad2_pos.y) < 60:
		ball_velocity.x = -abs(ball_velocity.x)
	
	update()

func check_win():
	if score1 >= 11:
		winner = "Player 1"
		game_over = true
	elif score2 >= 11:
		winner = "Computer"
		game_over = true

func reset_ball():
	ball_position = Vector2(400, 300)
	ball_velocity = Vector2(400 * (1 if randf() > 0.5 else -1), 400 * (1 if randf() > 0.5 else -1))

func _draw():
	if game_over:
		var msg = winner + " wins! " + str(score1) + " - " + str(score2)
		draw_string(FontDB.find_matching_or_add("res://fonts/arial.ttf"), Vector2(120, 280), msg, -1, 40, 32, Color.yellow)
		draw_string(FontDB.find_matching_or_add("res://fonts/arial.ttf"), Vector2(180, 330), "Press R to restart", -1, 30, 24, Color.white)
		return
	
	# Draw scores
	draw_string(FontDB.find_matching_or_add("res://fonts/arial.ttf"), Vector2(150, 50), str(score1), -1, 40, 32, Color.white)
	draw_string(FontDB.find_matching_or_add("res://fonts/arial.ttf"), Vector2(550, 50), str(score2), -1, 40, 32, Color.white)
	
	# Draw ball
	draw_circle(ball_position, ball_radius, Color.white)
	# Draw paddles
	draw_rect(Rect2(10, pad1_pos.y - 50, 20, 100), Color.white)
	draw_rect(Rect2(770, pad2_pos.y - 50, 20, 100), Color.white)
	# Draw center line
	for i in range(0, 600, 40):
		draw_rect(Rect2(398, i, 4, 20), Color(0.3, 0.3, 0.3))
