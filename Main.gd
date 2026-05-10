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

# Combo system (separate per player)
var pad1_combo = 0  # How many times pad1 hit ball consecutively
var pad2_combo = 0  # How many times pad2 hit ball consecutively
var combo_display = 0
var combo_timer = 0.0

# Score multiplier
var multiplier = 1

# Power-up system
var powerup_active = false
var powerup_type = ""
var powerup_position = Vector2(400, 300)
var powerup_radius = 15
var powerup_timer = 0.0
var powerup_duration = 8.0
var powerup_spawn_timer = 0.0
var powerup_spawn_interval = 10.0

# Paddle sizes (can be modified by power-ups)
var pad1_height = 100.0
var pad2_height = 100.0
var pad_width = 20.0

onready var winner_label = get_node("WinnerLabel")
onready var restart_label = get_node("RestartLabel")

var _custom_font = null

# Power-up type definitions
const POWERUP_TYPES = ["speed_up", "slow", "grow_left", "shrink_right", "shrink_ai", "big_ball"]
const POWERUP_COLORS = {
	"speed_up": Color(1, 0.2, 0.2),
	"slow": Color(0.2, 0.5, 1),
	"grow_left": Color(0.2, 1, 0.2),
	"shrink_right": Color(1, 0.8, 0.2),
	"shrink_ai": Color(1, 0.2, 1),
	"big_ball": Color(1, 1, 0.2)
}

func _ready():
	winner_label.visible = false
	restart_label.visible = false
	
	var font_data = DynamicFontData.new()
	font_data.font_path = "res://font.ttf"
	font_data.size = 24
	_custom_font = DynamicFont.new()
	_custom_font.font_data = font_data
	_custom_font.use_filter = true
	print("DEBUG V12: _ready done")

func _process(delta):
	if game_over:
		winner_label.visible = true
		restart_label.visible = true
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
	
	# Ball out left - right scores (left paddle missed / right player scores)
	if ball_position.x < ball_radius:
		# Left missed, right scores. Left combo resets.
		var points = get_score_points(pad1_combo)
		score2 += points
		combo_display = pad1_combo
		pad1_combo = 0
		pad2_combo = 0
		check_win()
		reset_ball()
	
	# Ball out right - left scores (right paddle missed / left player scores)
	if ball_position.x > 800 - ball_radius:
		# Right missed, left scores. Right combo resets.
		var points = get_score_points(pad2_combo)
		score1 += points
		combo_display = pad2_combo
		pad1_combo = 0
		pad2_combo = 0
		check_win()
		reset_ball()
	
	# AI paddle movement
	if ball_position.y < pad2_pos.y - 30:
		pad2_pos.y -= pad_speed * 0.7 * delta
	if ball_position.y > pad2_pos.y + 30:
		pad2_pos.y += pad_speed * 0.7 * delta
	pad2_pos.y = clamp(pad2_pos.y, 50, 550)
	
	# Paddle collisions - pad1 hit
	if ball_position.x < 50 and abs(ball_position.y - pad1_pos.y) < pad1_height * 0.5:
		ball_velocity.x = abs(ball_velocity.x)
		pad1_combo += 1
		combo_display = pad1_combo
		combo_timer = 0.0
	
	# Paddle collisions - pad2 hit
	if ball_position.x > 750 and abs(ball_position.y - pad2_pos.y) < pad2_height * 0.5:
		ball_velocity.x = -abs(ball_velocity.x)
		pad2_combo += 1
		combo_display = pad2_combo
		combo_timer = 0.0
	
	# Power-up spawning
	powerup_spawn_timer += delta
	if powerup_spawn_timer >= powerup_spawn_interval:
		spawn_random_powerup()
		powerup_spawn_timer = 0.0
	
	# Power-up timer
	if powerup_active:
		powerup_timer += delta
		if powerup_timer >= powerup_duration:
			reset_powerup_effects()
			powerup_active = false
	
	# Combo display decay
	if combo_display > 0:
		combo_timer += delta
		if combo_timer > 2.0:
			combo_display = 0
	
	# Power-up collision
	if powerup_active:
		if ball_position.distance_to(powerup_position) < ball_radius + powerup_radius:
			apply_powerup()
	
	update()

func get_score_points(combo):
	# 5 combo = 2 points, 8+ combo = 3 points (max)
	if combo >= 8:
		return 3
	elif combo >= 5:
		return 2
	else:
		return 1

func spawn_random_powerup():
	var types = POWERUP_TYPES
	powerup_type = types[randi() % types.size()]
	powerup_position = Vector2(250 + randi() % 300, 150 + randi() % 300)
	powerup_active = true
	powerup_timer = 0.0
	print("DEBUG V12: powerup spawned: ", powerup_type)

func apply_powerup():
	print("DEBUG V12: applying powerup: ", powerup_type)
	match powerup_type:
		"speed_up":
			var speed = ball_velocity.length() * 1.5
			ball_velocity = ball_velocity.normalized() * speed
		"slow":
			var speed = ball_velocity.length() * 0.55
			ball_velocity = ball_velocity.normalized() * speed
		"grow_left":
			pad1_height = 160.0
		"shrink_right":
			pad2_height = 50.0
		"shrink_ai":
			pad2_height = 60.0
		"big_ball":
			ball_radius = 18.0
	powerup_active = false

func reset_powerup_effects():
	pad1_height = 100.0
	pad2_height = 100.0
	ball_radius = 10.0
	print("DEBUG V12: powerup effects reset")

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
	pad1_combo = 0
	pad2_combo = 0
	combo_display = 0
	multiplier = 1
	game_over = false
	winner = ""
	powerup_active = false
	powerup_timer = 0.0
	powerup_spawn_timer = 0.0
	pad1_height = 100.0
	pad2_height = 100.0
	ball_radius = 10.0
	winner_label.visible = false
	restart_label.visible = false
	reset_ball()

func reset_ball():
	ball_position = Vector2(400, 300)
	ball_velocity = Vector2(400 * (1 if randf() > 0.5 else -1), 400 * (1 if randf() > 0.5 else -1))

func _draw():
	# V12 indicator: 6 circles
	draw_circle(Vector2(700, 20), 5, Color(1, 0.84, 0, 1))
	draw_circle(Vector2(715, 20), 5, Color(1, 0.84, 0, 1))
	draw_circle(Vector2(730, 20), 5, Color(1, 0.84, 0, 1))
	draw_circle(Vector2(745, 20), 5, Color(1, 0.84, 0, 1))
	draw_circle(Vector2(760, 20), 5, Color(1, 0.84, 0, 1))
	draw_circle(Vector2(775, 20), 5, Color(0.4, 0.4, 0.4, 1))
	
	# Center dashed line
	for i in range(0, 600, 40):
		draw_rect(Rect2(398, i, 4, 20), Color(0.3, 0.3, 0.3))
	
	# Score circles
	for i in range(score1):
		draw_circle(Vector2(100 + i * 25, 30), 10, Color.white)
	for i in range(score2):
		draw_circle(Vector2(700 - i * 25, 30), 10, Color.white)
	
	# Ball
	draw_circle(ball_position, ball_radius, Color.white)
	
	# Paddles
	draw_rect(Rect2(10, pad1_pos.y - pad1_height * 0.5, pad_width, pad1_height), Color.white)
	draw_rect(Rect2(770, pad2_pos.y - pad2_height * 0.5, pad_width, pad2_height), Color.white)
	
	# Combo display with score multiplier
	if combo_display > 1 and _custom_font != null:
		var pts = get_score_points(combo_display)
		var txt = "x" + str(combo_display)
		if pts > 1:
			txt += " [" + str(pts) + " PTS]"
		draw_string(_custom_font, Vector2(310, 570), txt, Color(1, 0.5, 0))
	
	# Power-up if active
	if powerup_active and _custom_font != null:
		var col = POWERUP_COLORS.get(powerup_type, Color.white)
		draw_circle(powerup_position, powerup_radius, col)
		var label = powerup_type.replace("_", " ").to_upper()
		draw_string(_custom_font, powerup_position + Vector2(-35, -20), label, Color.white)
		var remaining = powerup_duration - powerup_timer
		var bar_w = (remaining / powerup_duration) * 60
		draw_rect(Rect2(powerup_position.x - 30, powerup_position.y + 20, 60, 5), Color(0.3, 0.3, 0.3))
		draw_rect(Rect2(powerup_position.x - 30, powerup_position.y + 20, bar_w, 5), Color(0, 1, 0.2))
	
	# Game over
	if game_over:
		draw_rect(Rect2(150, 150, 500, 300), Color(0, 0, 0, 0.85))
		draw_rect(Rect2(150, 150, 500, 300), Color(1, 0.84, 0), false, 4)
		if _custom_font != null:
			draw_string(_custom_font, Vector2(180, 260), winner, Color(1, 0.84, 0))
			draw_string(_custom_font, Vector2(200, 320), "Press SPACE to restart", Color(0.8, 0.8, 0.8))