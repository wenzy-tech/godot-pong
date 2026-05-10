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

onready var winner_label = get_node("WinnerLabel")
onready var restart_label = get_node("RestartLabel")

func _ready():
	winner_label.visible = false
	restart_label.visible = false
	restart_label.text = "Press SPACE to restart"

func _process(delta):
	if game_over:
		winner_label.visible = true
		restart_label.visible = true
		# Update label text each frame to ensure correct winner is shown
		winner_label.text = winner
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
	if score1 >= 11:
		winner = "Left Player Wins!"
		game_over = true
	elif score2 >= 11:
		winner = "Right Player Wins!"
		game_over = true

func restart_game():
	score1 = 0
	score2 = 0
	game_over = false
	winner = ""
	winner_label.visible = false
	restart_label.visible = false
	reset_ball()

func reset_ball():
	ball_position = Vector2(400, 300)
	ball_velocity = Vector2(400 * (1 if randf() > 0.5 else -1), 400 * (1 if randf() > 0.5 else -1))

func _draw():
	for i in range(0, 600, 40):
		draw_rect(Rect2(398, i, 4, 20), Color(0.3, 0.3, 0.3))
	for i in range(score1):
		draw_circle(Vector2(100 + i * 25, 30), 10, Color.white)
	for i in range(score2):
		draw_circle(Vector2(700 - i * 25, 30), 10, Color.white)
	draw_circle(ball_position, ball_radius, Color.white)
	draw_rect(Rect2(10, pad1_pos.y - 50, 20, 100), Color.white)
	draw_rect(Rect2(770, pad2_pos.y - 50, 20, 100), Color.white)
