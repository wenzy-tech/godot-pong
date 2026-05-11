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

var pad1_combo = 0
var pad2_combo = 0
var combo_display = 0
var combo_timer = 0.0

var powerup_active = false
var powerup_type = ""
var powerup_position = Vector2(400, 300)
var powerup_radius = 15
var powerup_timer = 0.0
var powerup_duration = 8.0
var powerup_spawn_timer = 0.0
var powerup_spawn_interval = 10.0
var powerup_pulse = 0.0

var pad1_height = 100.0
var pad2_height = 100.0
var pad_width = 20.0

var shake_amount = 0.0
var shake_x = 0.0
var shake_y = 0.0

# Particle system - simple fixed arrays
const MAX_PARTICLES = 30
var particle_x = []
var particle_y = []
var particle_vx = []
var particle_vy = []
var particle_life = []
var particle_r = []
var particle_g = []
var particle_b = []
var particle_count = 0

onready var hit_sound = $hit_sound
onready var score_sound = $score_sound
onready var powerup_sound = $powerup_sound
onready var wall_sound = $wall_sound

onready var winner_label = get_node("WinnerLabel")
onready var restart_label = get_node("RestartLabel")

var _custom_font = null

const POWERUP_TYPES = ["speed_up", "slow", "grow_left", "shrink_right", "shrink_ai", "big_ball"]
const C_BALL = Color(0.0, 1.0, 0.8)
const C_PAD1 = Color(0.2, 0.6, 1.0)
const C_PAD2 = Color(1.0, 0.3, 0.5)
const C_COMBO = Color(1.0, 0.3, 0.0)

func _ready():
	winner_label.visible = false
	restart_label.visible = false
	
	# Initialize particle arrays
	for i in range(MAX_PARTICLES):
		particle_x.append(0.0)
		particle_y.append(0.0)
		particle_vx.append(0.0)
		particle_vy.append(0.0)
		particle_life.append(0.0)
		particle_r.append(1.0)
		particle_g.append(1.0)
		particle_b.append(1.0)
	particle_count = 0
	
	var font_data = DynamicFontData.new()
	font_data.font_path = "res://font.ttf"
	font_data.size = 24
	_custom_font = DynamicFont.new()
	_custom_font.font_data = font_data
	_custom_font.use_filter = true
	print("DEBUG V16: _ready done, particles ready")

func add_particle(x, y, r, g, b):
	if particle_count >= MAX_PARTICLES:
		particle_count = 0
	var i = particle_count
	particle_x[i] = x
	particle_y[i] = y
	var angle = rand_range(0, 6.283)
	var speed = rand_range(80, 200)
	particle_vx[i] = cos(angle) * speed
	particle_vy[i] = sin(angle) * speed
	particle_life[i] = 0.4
	particle_r[i] = r
	particle_g[i] = g
	particle_b[i] = b
	particle_count += 1

func update_particles(delta):
	for i in range(MAX_PARTICLES):
		if particle_life[i] > 0:
			particle_x[i] += particle_vx[i] * delta
			particle_y[i] += particle_vy[i] * delta
			particle_life[i] -= delta

func _process(delta):
	# Screen shake decay
	if shake_amount > 0:
		shake_amount *= 0.85
		if shake_amount < 0.5:
			shake_amount = 0
			shake_x = 0
			shake_y = 0
		else:
			shake_x = rand_range(-1, 1) * shake_amount
			shake_y = rand_range(-1, 1) * shake_amount
	
	if game_over:
		winner_label.visible = true
		restart_label.visible = true
		winner_label.text = winner
		if Input.is_action_pressed("ui_accept"):
			restart_game()
		update_particles(delta)
		update()
		return
	
	if Input.is_action_pressed("move_up"):
		pad1_pos.y -= pad_speed * delta
	if Input.is_action_pressed("move_down"):
		pad1_pos.y += pad_speed * delta
	pad1_pos.y = clamp(pad1_pos.y, 50, 550)
	
	ball_position += ball_velocity * delta
	
	if ball_position.y < ball_radius or ball_position.y > 600 - ball_radius:
		wall_sound.play()
		ball_velocity.y = -ball_velocity.y
		add_particle(ball_position.x, ball_position.y < ball_radius * 2 ? ball_radius : 600 - ball_radius, 0.0, 0.8, 0.6)
	
	if ball_position.x < ball_radius:
		var pts = get_score_points(pad1_combo)
		score2 += pts
		combo_display = pad1_combo
		pad1_combo = 0
		pad2_combo = 0
		score_sound.play()
		shake_amount = 8.0
		add_particle(ball_position.x, ball_position.y, 1.0, 0.3, 0.5)
		check_win()
		reset_ball()
	
	if ball_position.x > 800 - ball_radius:
		var pts = get_score_points(pad2_combo)
		score1 += pts
		combo_display = pad2_combo
		pad1_combo = 0
		pad2_combo = 0
		score_sound.play()
		shake_amount = 8.0
		add_particle(ball_position.x, ball_position.y, 0.2, 0.6, 1.0)
		check_win()
		reset_ball()
	
	if ball_position.y < pad2_pos.y - 30:
		pad2_pos.y -= pad_speed * 0.7 * delta
	if ball_position.y > pad2_pos.y + 30:
		pad2_pos.y += pad_speed * 0.7 * delta
	pad2_pos.y = clamp(pad2_pos.y, 50, 550)
	
	if ball_position.x < 50 and abs(ball_position.y - pad1_pos.y) < pad1_height * 0.5:
		ball_velocity.x = abs(ball_velocity.x)
		pad1_combo += 1
		combo_display = pad1_combo
		combo_timer = 0.0
		hit_sound.play()
		shake_amount = 4.0
		add_particle(ball_position.x, ball_position.y, 0.2, 0.6, 1.0)
	
	if ball_position.x > 750 and abs(ball_position.y - pad2_pos.y) < pad2_height * 0.5:
		ball_velocity.x = -abs(ball_velocity.x)
		pad2_combo += 1
		combo_display = pad2_combo
		combo_timer = 0.0
		hit_sound.play()
		shake_amount = 4.0
		add_particle(ball_position.x, ball_position.y, 1.0, 0.3, 0.5)
	
	powerup_spawn_timer += delta
	if powerup_spawn_timer >= powerup_spawn_interval:
		powerup_type = POWERUP_TYPES[randi() % POWERUP_TYPES.size()]
		powerup_position = Vector2(250 + randi() % 300, 150 + randi() % 300)
		powerup_active = true
		powerup_timer = 0.0
		powerup_pulse = 1.0
		powerup_spawn_timer = 0.0
	
	if powerup_active:
		powerup_timer += delta
		powerup_pulse = 0.7 + sin(powerup_timer * 6.0) * 0.3
		if powerup_timer >= powerup_duration:
			pad1_height = 100.0
			pad2_height = 100.0
			ball_radius = 10.0
			powerup_active = false
	
	if combo_display > 0:
		combo_timer += delta
		if combo_timer > 2.5:
			combo_display = 0
	
	if powerup_active:
		if ball_position.distance_to(powerup_position) < ball_radius + powerup_radius:
			powerup_sound.play()
			if powerup_type == "speed_up":
				ball_velocity = ball_velocity.normalized() * (ball_velocity.length() * 1.5)
			elif powerup_type == "slow":
				ball_velocity = ball_velocity.normalized() * (ball_velocity.length() * 0.55)
			elif powerup_type == "grow_left":
				pad1_height = 160.0
			elif powerup_type == "shrink_right":
				pad2_height = 50.0
			elif powerup_type == "shrink_ai":
				pad2_height = 60.0
			elif powerup_type == "big_ball":
				ball_radius = 18.0
			powerup_active = false
	
	update_particles(delta)
	update()

func get_score_points(combo):
	if combo >= 8:
		return 3
	elif combo >= 5:
		return 2
	return 1

func get_powerup_color():
	if powerup_type == "speed_up":
		return Color(1.0, 0.2, 0.2)
	elif powerup_type == "slow":
		return Color(0.2, 0.5, 1.0)
	elif powerup_type == "grow_left":
		return Color(0.2, 1.0, 0.2)
	elif powerup_type == "shrink_right" or powerup_type == "shrink_ai":
		return Color(1.0, 0.8, 0.2)
	elif powerup_type == "big_ball":
		return Color(1.0, 1.0, 0.2)
	return Color(1.0, 1.0, 1.0)

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
	game_over = false
	winner = ""
	powerup_active = false
	powerup_timer = 0.0
	powerup_spawn_timer = 0.0
	pad1_height = 100.0
	pad2_height = 100.0
	ball_radius = 10.0
	shake_amount = 0
	shake_x = 0
	shake_y = 0
	for i in range(MAX_PARTICLES):
		particle_life[i] = 0.0
	winner_label.visible = false
	restart_label.visible = false
	reset_ball()

func reset_ball():
	ball_position = Vector2(400, 300)
	ball_velocity = Vector2(400 * (1 if randf() > 0.5 else -1), 400 * (1 if randf() > 0.5 else -1))

func _draw():
	var ox = shake_x
	var oy = shake_y
	
	# Background
	draw_rect(Rect2(0, 0, 800, 600), Color(0.05, 0.05, 0.12))
	
	# Grid
	for x in range(0, 800, 50):
		draw_line(Vector2(x, 0), Vector2(x, 600), Color(0.1, 0.15, 0.3, 0.5), 1.0)
	for y in range(0, 600, 50):
		draw_line(Vector2(0, y), Vector2(800, y), Color(0.1, 0.15, 0.3, 0.5), 1.0)
	
	# Center line
	for i in range(0, 600, 20):
		draw_rect(Rect2(398, i + 5, 4, 10), Color(0.3, 0.5, 0.8, 0.4))
	
	# Particles
	for i in range(MAX_PARTICLES):
		if particle_life[i] > 0:
			var alpha = particle_life[i] / 0.4
			var size = 3.0 * alpha
			draw_circle(Vector2(particle_x[i] + ox, particle_y[i] + oy), size, Color(particle_r[i], particle_g[i], particle_b[i], alpha))
	
	# Ball glow
	draw_circle(Vector2(ball_position.x + ox, ball_position.y + oy), ball_radius * 1.8, Color(0.0, 0.8, 0.6, 0.2))
	draw_circle(Vector2(ball_position.x + ox, ball_position.y + oy), ball_radius * 1.4, Color(0.0, 1.0, 0.8, 0.3))
	draw_circle(Vector2(ball_position.x + ox, ball_position.y + oy), ball_radius, C_BALL)
	
	# Paddles with glow
	draw_rect(Rect2(10 + ox, pad1_pos.y - pad1_height * 0.5 + oy, pad_width, pad1_height), Color(C_PAD1.r, C_PAD1.g, C_PAD1.b, 0.35), true, 6)
	draw_rect(Rect2(10 + ox, pad1_pos.y - pad1_height * 0.5 + oy, pad_width, pad1_height), C_PAD1)
	
	draw_rect(Rect2(770 + ox, pad2_pos.y - pad2_height * 0.5 + oy, pad_width, pad2_height), Color(C_PAD2.r, C_PAD2.g, C_PAD2.b, 0.35), true, 6)
	draw_rect(Rect2(770 + ox, pad2_pos.y - pad2_height * 0.5 + oy, pad_width, pad2_height), C_PAD2)
	
	# Score dots with glow
	for i in range(score1):
		draw_circle(Vector2(100 + i * 25 + ox, 30 + oy), 10, Color(C_PAD1.r, C_PAD1.g, C_PAD1.b, 0.3))
		draw_circle(Vector2(100 + i * 25 + ox, 30 + oy), 6, C_PAD1)
	for i in range(score2):
		draw_circle(Vector2(700 - i * 25 + ox, 30 + oy), 10, Color(C_PAD2.r, C_PAD2.g, C_PAD2.b, 0.3))
		draw_circle(Vector2(700 - i * 25 + ox, 30 + oy), 6, C_PAD2)
	
	# Combo
	if combo_display > 1 and _custom_font != null:
		var pts = get_score_points(combo_display)
		var txt = "x" + str(combo_display)
		if pts > 1:
			txt = txt + " [" + str(pts) + " PTS]"
		draw_string(_custom_font, Vector2(310 + ox, 570 + oy), txt, C_COMBO)
	
	# Power-up
	if powerup_active and _custom_font != null:
		var col = get_powerup_color()
		draw_circle(Vector2(powerup_position.x + ox, powerup_position.y + oy), powerup_radius * 1.5 * powerup_pulse, Color(col.r, col.g, col.b, 0.3))
		draw_circle(Vector2(powerup_position.x + ox, powerup_position.y + oy), powerup_radius, col)
		var label = "?"
		if powerup_type == "speed_up":
			label = "FAST"
		elif powerup_type == "slow":
			label = "SLOW"
		elif powerup_type == "grow_left":
			label = "GROW"
		elif powerup_type == "shrink_right" or powerup_type == "shrink_ai":
			label = "SHRINK"
		elif powerup_type == "big_ball":
			label = "BIG"
		draw_string(_custom_font, Vector2(powerup_position.x - 30 + ox, powerup_position.y - 25 + oy), label, Color.white)
		var remaining = powerup_duration - powerup_timer
		var bar_w = (remaining / powerup_duration) * 50
		draw_rect(Rect2(powerup_position.x - 25 + ox, powerup_position.y + 20 + oy, 50, 4), Color(0.2, 0.2, 0.2, 0.8))
		draw_rect(Rect2(powerup_position.x - 25 + ox, powerup_position.y + 20 + oy, bar_w, 4), Color(0, 1, 0.4))
	
	# Game over
	if game_over:
		draw_rect(Rect2(150 + ox, 150 + oy, 500, 300), Color(0, 0, 0, 0.85))
		draw_rect(Rect2(150 + ox, 150 + oy, 500, 300), Color(1, 0.84, 0), false, 3)
		if _custom_font != null:
			draw_string(_custom_font, Vector2(180 + ox, 260 + oy), winner, Color(1, 0.84, 0))
			draw_string(_custom_font, Vector2(200 + ox, 330 + oy), "Press SPACE to restart", Color(0.7, 0.7, 0.7))