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

# Power-up system
var powerup_active = false
var powerup_type = ""  # "speed_up", "slow", "grow_left", "shrink_left", "grow_right", "shrink_right"
var powerup_position = Vector2(400, 300)
var powerup_radius = 15
var powerup_timer = 0
var powerup_duration = 8.0  # seconds
var powerup_spawn_timer = 0
var powerup_spawn_interval = 10.0  # spawn every 10 seconds

# Combo system
var combo_count = 0
var combo_display = 0
var combo_timer = 0

# Audio
var hit_sound_played = false

onready var winner_label = get_node("WinnerLabel")
onready var restart_label = get_node("RestartLabel")

var _custom_font = null
var _audio_hit = null
var _audio_score = null
var _audio_powerup = null

func _ready():
	winner_label.visible = false
	restart_label.visible = false
	
	# Load custom font
	var font_data = DynamicFontData.new()
	font_data.font_path = "res://font.ttf"
	font_data.size = 24
	_custom_font = DynamicFont.new()
	_custom_font.font_data = font_data
	_custom_font.use_filter = true
	
	# Pre-load sounds (use generated tones as fallback)
	print("DEBUG: _ready done")

func _process(delta):
	if game_over:
		winner_label.visible = true
		restart_label.visible = true
		winner_label.text = winner
		if Input.is_action_pressed("ui_accept"):
			restart_game()
		update()
		return
	
	# Move left paddle with W/S
	if Input.is_action_pressed("move_up"):
		pad1_pos.y -= pad_speed * delta
	if Input.is_action_pressed("move_down"):
		pad1_pos.y += pad_speed * delta
	pad1_pos.y = clamp(pad1_pos.y, 50, 550)
	
	# Move ball
	ball_position += ball_velocity * delta
	
	# Ball bounce top/bottom
	if ball_position.y < ball_radius or ball_position.y > 600 - ball_radius:
		ball_velocity.y = -ball_velocity.y
	
	# Ball out left - right scores
	if ball_position.x < ball_radius:
		score2 += 1
		combo_count = 0
		spawn_powerup()
		check_win()
		reset_ball()
	
	# Ball out right - left scores
	if ball_position.x > 800 - ball_radius:
		score1 += 1
		combo_count = 0
		spawn_powerup()
		check_win()
		reset_ball()
	
	# AI paddle movement (right side)
	var ai_speed = pad_speed * 0.7
	if ball_position.y < pad2_pos.y - 30:
		pad2_pos.y -= ai_speed * delta
	if ball_position.y > pad2_pos.y + 30:
		pad2_pos.y += ai_speed * delta
	pad2_pos.y = clamp(pad2_pos.y, 50, 550)
	
	# Collision with left paddle
	if ball_position.x < 50 and abs(ball_position.y - pad1_pos.y) < 60:
		ball_velocity.x = abs(ball_velocity.x)
		combo_count += 1
		combo_display = combo_count
	
	# Collision with right paddle
	if ball_position.x > 750 and abs(ball_position.y - pad2_pos.y) < 60:
		ball_velocity.x = -abs(ball_velocity.x)
	
	# Power-up spawning
	powerup_spawn_timer += delta
	if powerup_spawn_timer >= powerup_spawn_interval and not powerup_active:
		spawn_powerup_item()
		powerup_spawn_timer = 0
	
	# Power-up active timer
	if powerup_active:
		powerup_timer += delta
		if powerup_timer >= powerup_duration:
			deactivate_powerup()
	
	# Combo timer decay
	if combo_display > 0:
		combo_timer += delta
		if combo_timer > 2.0:
			combo_display = 0
			combo_timer = 0
	
	# Check powerup collision
	if powerup_active:
		if ball_position.distance_to(powerup_position) < ball_radius + powerup_radius:
			apply_powerup()
	
	update()

func spawn_powerup():
	powerup_spawn_timer = 0

func spawn_powerup_item():
	var types = ["speed_up", "slow", "grow_left", "shrink_right", "multiball"]
	powerup_type = types[randi() % types.size()]
	powerup_position = Vector2(200 + randi() % 400, 150 + randi() % 300)
	powerup_active = true
	powerup_timer = 0
	print("DEBUG: powerup spawned: ", powerup_type, " at ", powerup_position)

func apply_powerup():
	print("DEBUG: applying powerup: ", powerup_type)
	match powerup_type:
		"speed_up":
			var speed = ball_velocity.length() * 1.5
			ball_velocity = ball_velocity.normalized() * speed
		"slow":
			var speed = ball_velocity.length() * 0.6
			ball_velocity = ball_velocity.normalized() * speed
		"grow_left":
			# Temporary grow left paddle handled in draw
		"shrink_right":
			# Temporary shrink right paddle handled in draw
	powerup_active = false

func deactivate_powerup():
	powerup_active = false
	powerup_timer = 0

func check_win():
	if score1 >= 11:
		winner = "Left Player Wins!"
		game_over = true
		winner_label.text = winner
	elif score2 >= 11:
		winner = "Right Player Wins!"
		game_over = true
		winner_label.text = winner

func restart_game():
	score1 = 0
	score2 = 0
	combo_count = 0
	combo_display = 0
	game_over = false
	winner = ""
	powerup_active = false
	powerup_timer = 0
	powerup_spawn_timer = 0
	winner_label.visible = false
	restart_label.visible = false
	reset_ball()

func reset_ball():
	ball_position = Vector2(400, 300)
	var dir_x = 1 if randf() > 0.5 else -1
	var dir_y = 1 if randf() > 0.5 else -1
	ball_velocity = Vector2(400 * dir_x, 400 * dir_y)

func _draw():
	# V9 indicator: 5 circles (gold)
	draw_circle(Vector2(740, 20), 5, Color(1, 0.84, 0, 1))
	draw_circle(Vector2(755, 20), 5, Color(1, 0.84, 0, 1))
	draw_circle(Vector2(770, 20), 5, Color(1, 0.84, 0, 1))
	draw_circle(Vector2(785, 20), 5, Color(1, 0.84, 0, 1))
	draw_circle(Vector2(800, 20), 5, Color(1, 0.84, 0, 1))
	
	# Draw center dashed line
	for i in range(0, 600, 40):
		draw_rect(Rect2(398, i, 4, 20), Color(0.3, 0.3, 0.3))
	
	# Draw scores using big circles
	for i in range(score1):
		draw_circle(Vector2(100 + i * 25, 30), 10, Color.white)
	for i in range(score2):
		draw_circle(Vector2(700 - i * 25, 30), 10, Color.white)
	
	# Draw ball
	draw_circle(ball_position, ball_radius, Color.white)
	
	# Draw paddles
	draw_rect(Rect2(10, pad1_pos.y - 50, 20, 100), Color.white)
	draw_rect(Rect2(770, pad2_pos.y - 50, 20, 100), Color.white)
	
	# Draw combo indicator
	if combo_display > 1 and _custom_font:
		draw_string(_custom_font, Vector2(350, 580), "x" + str(combo_display) + " COMBO!", Color(1, 0.5, 0))
	
	# Draw powerup if active
	if powerup_active and _custom_font:
		draw_circle(powerup_position, powerup_radius, Color(0.5, 0, 1))
		var label = powerup_type.replace("_", " ").to_upper()
		draw_string(_custom_font, powerup_position + Vector2(-30, 5), label, Color.white)
		# Draw timer bar
		var remaining = powerup_duration - powerup_timer
		var bar_width = (remaining / powerup_duration) * 60
		draw_rect(Rect2(powerup_position.x - 30, powerup_position.y + 20, 60, 5), Color(0.3, 0.3, 0.3))
		draw_rect(Rect2(powerup_position.x - 30, powerup_position.y + 20, bar_width, 5), Color(0, 1, 0))
	
	# Game over overlay
	if game_over:
		draw_rect(Rect2(150, 150, 500, 300), Color(0, 0, 0, 0.85))
		draw_rect(Rect2(150, 150, 500, 300), Color(1, 0.84, 0), false, 4)
		if _custom_font:
			draw_string(_custom_font, Vector2(180, 260), winner, Color(1, 0.84, 0))
			draw_string(_custom_font, Vector2(200, 320), "Press SPACE to restart", Color(0.8, 0.8, 0.8))