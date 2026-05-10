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

# Font for drawing text (built-in)
var _font = null

func _ready():
	# Use DynamicFont as fallback for Godot HTML5
	var f = DynamicFont.new()
	f.size = 24
	_font = f
	print("DEBUG: _ready done, font=", _font)

func _process(delta):
	if game_over:
		if Input.is_action_pressed("ui_accept"):
			restart_game()
		update()
		return
	
	if Input.is_action_pressed("move_up"):
		pad1_pos.y -= pad_speed * delta
	if Input.is_action_pressed("move_down"):
		pad1_pos.y += pad_speed * delta
	pad1_pos.y = clamp(pad1_pos.y, 50, 550)
	
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
	
	if ball_position.y < pad2_pos.y - 30:
		pad2_pos.y -= pad_speed * 0.7 * delta
	if ball_position.y > pad2_pos.y + 30:
		pad2_pos.y += pad_speed * 0.7 * delta
	pad2_pos.y = clamp(pad2_pos.y, 50, 550)
	
	if ball_position.x < 50 and abs(ball_position.y - pad1_pos.y) < 60:
		ball_velocity.x = abs(ball_velocity.x)
	if ball_position.x > 750 and abs(ball_position.y - pad2_pos.y) < 60:
		ball_velocity.x = -abs(ball_velocity.x)
	
	update()

func check_win():
	print("DEBUG check_win: score1=", score1, " score2=", score2, " game_over=", game_over)
	if score1 >= 11:
		winner = "Left Player Wins!"
		game_over = true
		print("DEBUG: LEFT WINS!")
	elif score2 >= 11:
		winner = "Right Player Wins!"
		game_over = true
		print("DEBUG: RIGHT WINS!")

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
	# V6: 4 yellow circles = new version
	draw_circle(Vector2(750, 20), 5, Color(1, 0.84, 0, 1))
	draw_circle(Vector2(765, 20), 5, Color(1, 0.84, 0, 1))
	draw_circle(Vector2(780, 20), 5, Color(1, 0.84, 0, 1))
	draw_circle(Vector2(795, 20), 5, Color(1, 0.84, 0, 1))
	
	# Show "Press SPACE to restart" on the canvas when game is not over
	if not game_over:
		draw_string(Font, Vector2(20, 570), "W/S: move   SPACE: pause", Color(0.7, 0.7, 0.7))
	
	# Game over: draw winner text directly on canvas (no Label nodes needed)
	if game_over:
		# Draw semi-transparent black overlay
		draw_rect(Rect2(200, 200, 400, 200), Color(0, 0, 0, 0.8))
		# Draw yellow border
		draw_rect(Rect2(200, 200, 400, 200), Color(1, 0.84, 0), false, 4)
		# Draw winner text in large font
		var text = winner if winner != "" else "???"
		var color = Color(1, 1, 1) if "Left" in text else Color(1, 1, 0.8)
		draw_string(Font, Vector2(250, 290), text, Color(1, 0.84, 0))
		draw_string(Font, Vector2(260, 340), "Press SPACE to restart", Color(0.8, 0.8, 0.8))
		return
	
	for i in range(0, 600, 40):
		draw_rect(Rect2(398, i, 4, 20), Color(0.3, 0.3, 0.3))
	for i in range(score1):
		draw_circle(Vector2(100 + i * 25, 30), 10, Color.white)
	for i in range(score2):
		draw_circle(Vector2(700 - i * 25, 30), 10, Color.white)
	draw_circle(ball_position, ball_radius, Color.white)
	draw_rect(Rect2(10, pad1_pos.y - 50, 20, 100), Color.white)
	draw_rect(Rect2(770, pad2_pos.y - 50, 20, 100), Color.white)