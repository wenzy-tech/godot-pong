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
		if Input.is_action_pressed("ui_accept"):
			restart_game()
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
		winner = "Left"
		game_over = true
	elif score2 >= 11:
		winner = "Right"
		game_over = true

func restart_game():
	score1 = 0
	score2 = 0
	game_over = false
	winner = ""
	reset_ball()

func reset_ball():
	ball_position = Vector2(400, 300)
	ball_velocity = Vector2(400 * (1 if randf() > 0.5 else -1), 400 * (1 if randf() > 0.5 else -1))

func _draw():
	if game_over:
		var msg = winner + " Player Wins!"
		draw_string(FontDB.find_matching_or_add("res://fonts/arial.ttf"), Vector2(150, 280), msg, -1, 40, 32, Color.yellow)
		draw_string(FontDB.find_matching_or_add("res://fonts/arial.ttf"), Vector2(200, 330), "Press SPACE to restart", -1, 30, 24, Color.white)
		return
	
	# Draw center scoreboard
	var score_text = str(score1) + "  -  " + str(score2)
	draw_string(FontDB.find_matching_or_add("res://fonts/arial.ttf"), Vector2(320, 50), score_text, -1, 40, 32, Color.white)
	
	# Draw ball
	draw_circle(ball_position, ball_radius, Color.white)
	# Draw paddles
	draw_rect(Rect2(10, pad1_pos.y - 50, 20, 100), Color.white)
	draw_rect(Rect2(770, pad2_pos.y - 50, 20, 100), Color.white)
	# Draw center line
	for i in range(0, 600, 40):
		draw_rect(Rect2(398, i, 4, 20), Color(0.3, 0.3, 0.3))
