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

# Combo system
var pad1_combo = 0
var pad2_combo = 0
var combo_display = 0
var combo_timer = 0.0

# Visual effects
var ball_trail = []  # Store previous ball positions
var hit_particles = []  # Impact particles
var glow_intensity = 1.0

# Power-up system
var powerup_active = false
var powerup_type = ""
var powerup_position = Vector2(400, 300)
var powerup_radius = 15
var powerup_timer = 0.0
var powerup_duration = 8.0
var powerup_spawn_timer = 0.0
var powerup_spawn_interval = 10.0
var powerup_pulse = 0.0

# Paddle sizes
var pad1_height = 100.0
var pad2_height = 100.0
var pad_width = 20.0

# Screen shake
var shake_amount = 0.0
var shake_offset = Vector2(0, 0)

# Colors - Neon Cyberpunk palette
const COLOR_BG = Color(0.05, 0.05, 0.12)
const COLOR_GRID = Color(0.1, 0.15, 0.3, 0.5)
const COLOR_BALL = Color(0.0, 1.0, 0.8)  # Cyan
const COLOR_PAD1 = Color(0.2, 0.6, 1.0)  # Blue
const COLOR_PAD2 = Color(1.0, 0.3, 0.5)  # Pink/Red
const COLOR_ACCENT = Color(1.0, 0.8, 0.0)  # Gold
const COLOR_COMBO = Color(1.0, 0.3, 0.0)  # Orange
const COLOR_POWERUP = {
	"speed_up": Color(1.0, 0.2, 0.2),
	"slow": Color(0.2, 0.5, 1.0),
	"grow_left": Color(0.2, 1.0, 0.2),
	"shrink_right": Color(1.0, 0.8, 0.2),
	"shrink_ai": Color(1.0, 0.2, 1.0),
	"big_ball": Color(1.0, 1.0, 0.2)
}

onready var hit_sound = $hit_sound
onready var score_sound = $score_sound
onready var powerup_sound = $powerup_sound
onready var wall_sound = $wall_sound

onready var winner_label = get_node("WinnerLabel")
onready var restart_label = get_node("RestartLabel")

var _custom_font = null

const POWERUP_TYPES = ["speed_up", "slow", "grow_left", "shrink_right", "shrink_ai", "big_ball"]

func _ready():
	winner_label.visible = false
	restart_label.visible = false
	
	var font_data = DynamicFontData.new()
	font_data.font_path = "res://font.ttf"
	font_data.size = 28
	_custom_font = DynamicFont.new()
	_custom_font.font_data = font_data
	_custom_font.use_filter = true
	print("DEBUG V14: _ready done, visual mode")

func _process(delta):
	# Decay screen shake
	if shake_amount > 0:
		shake_amount *= 0.85
		shake_offset = Vector2(rand_range(-1, 1), rand_range(-1, 1)) * shake_amount
		if shake_amount < 0.5:
			shake_amount = 0
			shake_offset = Vector2(0, 0)
	
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
	
	# Store ball trail
	ball_trail.insert(0, ball_position)
	if ball_trail.size() > 12:
		ball_trail.pop_back()
	
	ball_position += ball_velocity * delta
	
	if ball_position.y < ball_radius or ball_position.y > 600 - ball_radius:
		wall_sound.play()
		ball_velocity.y = -ball_velocity.y
		add_hit_particles(Vector2(ball_position.x, ball_position.y < ball_radius * 2 ? ball_radius : 600 - ball_radius), Color(0.0, 1.0, 0.8))
	
	if ball_position.x < ball_radius:
		var pts = get_score_points(pad1_combo)
		score2 += pts
		combo_display = pad1_combo
		pad1_combo = 0
		pad2_combo = 0
		score_sound.play()
		add_hit_particles(ball_position, Color(1.0, 0.3, 0.5))
		shake_amount = 8.0
		check_win()
		reset_ball()
	
	if ball_position.x > 800 - ball_radius:
		var pts = get_score_points(pad2_combo)
		score1 += pts
		combo_display = pad2_combo
		pad1_combo = 0
		pad2_combo = 0
		score_sound.play()
		add_hit_particles(ball_position, Color(0.2, 0.6, 1.0))
		shake_amount = 8.0
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
		add_hit_particles(ball_position, COLOR_PAD1)
	
	if ball_position.x > 750 and abs(ball_position.y - pad2_pos.y) < pad2_height * 0.5:
		ball_velocity.x = -abs(ball_velocity.x)
		pad2_combo += 1
		combo_display = pad2_combo
		combo_timer = 0.0
		hit_sound.play()
		shake_amount = 4.0
		add_hit_particles(ball_position, COLOR_PAD2)
	
	powerup_spawn_timer += delta
	if powerup_spawn_timer >= powerup_spawn_interval:
		spawn_random_powerup()
		powerup_spawn_timer = 0.0
	
	if powerup_active:
		powerup_timer += delta
		powerup_pulse = sin(powerup_timer * 6.0) * 0.3 + 0.7
		if powerup_timer >= powerup_duration:
			reset_powerup_effects()
			powerup_active = false
	
	if combo_display > 0:
		combo_timer += delta
		if combo_timer > 2.5:
			combo_display = 0
	
	# Update particles
	update_particles(delta)
	
	if powerup_active:
		if ball_position.distance_to(powerup_position) < ball_radius + powerup_radius:
			apply_powerup()
	
	update()

func add_hit_particles(pos, color):
	for i in range(8):
		var angle = rand_range(0, 2 * PI)
		var speed = rand_range(80, 200)
		hit_particles.append({
			"pos": pos,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"color": color,
			"life": 0.4
		})

func update_particles(delta):
	for p in hit_particles:
		p["pos"] += p["vel"] * delta
		p["life"] -= delta
	hit_particles = hit_particles.filter(func(p): return p["life"] > 0)

func get_score_points(combo):
	if combo >= 8:
		return 3
	elif combo >= 5:
		return 2
	else:
		return 1

func spawn_random_powerup():
	powerup_type = POWERUP_TYPES[randi() % POWERUP_TYPES.size()]
	powerup_position = Vector2(250 + randi() % 300, 150 + randi() % 300)
	powerup_active = true
	powerup_timer = 0.0
	powerup_pulse = 1.0
	print("DEBUG V14: powerup spawned: ", powerup_type)

func apply_powerup():
	powerup_sound.play()
	print("DEBUG V14: applying powerup: ", powerup_type)
	match powerup_type:
		"speed_up":
			ball_velocity = ball_velocity.normalized() * (ball_velocity.length() * 1.5)
		"slow":
			ball_velocity = ball_velocity.normalized() * (ball_velocity.length() * 0.55)
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
	print("DEBUG V14: powerup effects reset")

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
	ball_trail = []
	hit_particles = []
	shake_amount = 0
	shake_offset = Vector2(0, 0)
	winner_label.visible = false
	restart_label.visible = false
	reset_ball()

func reset_ball():
	ball_position = Vector2(400, 300)
	ball_velocity = Vector2(400 * (1 if randf() > 0.5 else -1), 400 * (1 if randf() > 0.5 else -1))
	ball_trail = []

func _draw():
	# Apply screen shake
	var offset = shake_offset
	
	# Draw background gradient (simulated with multiple rects)
	for i in range(8):
		var c = lerp(Color(0.03, 0.03, 0.08), Color(0.08, 0.05, 0.15), i / 8.0)
		draw_rect(Rect2(0, i * 75, 800, 75), c)
	
	# Draw background grid
	for x in range(0, 800, 50):
		draw_line(Vector2(x, 0) + offset, Vector2(x, 600) + offset, COLOR_GRID, 1.0)
	for y in range(0, 600, 50):
		draw_line(Vector2(0, y) + offset, Vector2(800, y) + offset, COLOR_GRID, 1.0)
	
	# Draw center line (glowing)
	for i in range(0, 600, 20):
		draw_rect(Rect2(398, i + 5, 4, 10), Color(0.3, 0.5, 0.8, 0.4))
	
	# Draw particles
	for p in hit_particles:
		var alpha = p["life"] / 0.4
		var size = 4.0 * alpha
		draw_circle(p["pos"] + offset, size, Color(p["color"].r, p["color"].g, p["color"].b, alpha))
	
	# Draw ball trail (fading)
	for i in range(ball_trail.size()):
		var alpha = 1.0 - (i / float(ball_trail.size()))
		var size = ball_radius * (1.0 - i * 0.06)
		var trail_color = Color(COLOR_BALL.r, COLOR_BALL.g, COLOR_BALL.b, alpha * 0.5)
		draw_circle(ball_trail[i] + offset, size, trail_color)
	
	# Draw ball (glowing)
	draw_circle(ball_position + offset, ball_radius, COLOR_BALL)
	# Ball glow
	draw_circle(ball_position + offset, ball_radius * 1.8, Color(COLOR_BALL.r, COLOR_BALL.g, COLOR_BALL.b, 0.15))
	draw_circle(ball_position + offset, ball_radius * 1.4, Color(COLOR_BALL.r, COLOR_BALL.g, COLOR_BALL.b, 0.25))
	
	# Draw paddles with glow
	# Left paddle (blue)
	draw_rect(Rect2(10, pad1_pos.y - pad1_height * 0.5, pad_width, pad1_height) + offset, COLOR_PAD1)
	draw_rect(Rect2(10, pad1_pos.y - pad1_height * 0.5, pad_width, pad1_height) + offset, Color(COLOR_PAD1.r, COLOR_PAD1.g, COLOR_PAD1.b, 0.3), false, 8)
	
	# Right paddle (pink)
	draw_rect(Rect2(770, pad2_pos.y - pad2_height * 0.5, pad_width, pad2_height) + offset, COLOR_PAD2)
	draw_rect(Rect2(770, pad2_pos.y - pad2_height * 0.5, pad_width, pad2_height) + offset, Color(COLOR_PAD2.r, COLOR_PAD2.g, COLOR_PAD2.b, 0.3), false, 8)
	
	# Score indicators (glowing dots)
	for i in range(score1):
		draw_circle(Vector2(100 + i * 25, 30) + offset, 8, COLOR_PAD1)
		draw_circle(Vector2(100 + i * 25, 30) + offset, 12, Color(COLOR_PAD1.r, COLOR_PAD1.g, COLOR_PAD1.b, 0.3))
	for i in range(score2):
		draw_circle(Vector2(700 - i * 25, 30) + offset, 8, COLOR_PAD2)
		draw_circle(Vector2(700 - i * 25, 30) + offset, 12, Color(COLOR_PAD2.r, COLOR_PAD2.g, COLOR_PAD2.b, 0.3))
	
	# Combo display
	if combo_display > 1 and _custom_font != null:
		var pts = get_score_points(combo_display)
		var txt = "x" + str(combo_display)
		if pts > 1:
			txt += " [" + str(pts) + " PTS]"
		draw_string(_custom_font, Vector2(310, 570) + offset, txt, COLOR_COMBO)
	
	# Power-up if active
	if powerup_active and _custom_font != null:
		var col = COLOR_POWERUP.get(powerup_type, Color.white)
		# Glow
		draw_circle(powerup_position + offset, powerup_radius * 1.5 * powerup_pulse, Color(col.r, col.g, col.b, 0.3))
		draw_circle(powerup_position + offset, powerup_radius, col)
		# Label
		var label = powerup_type.replace("_", " ").to_upper()
		draw_string(_custom_font, powerup_position + Vector2(-40, -25) + offset, label, Color.white)
		# Timer bar
		var remaining = powerup_duration - powerup_timer
		var bar_w = (remaining / powerup_duration) * 60
		draw_rect(Rect2(powerup_position.x - 30, powerup_position.y + 20, 60, 5) + offset, Color(0.2, 0.2, 0.2, 0.8))
		draw_rect(Rect2(powerup_position.x - 30, powerup_position.y + 20, bar_w, 5) + offset, Color(0, 1, 0.4))
	
	# Game over overlay
	if game_over:
		draw_rect(Rect2(150, 150, 500, 300) + offset, Color(0, 0, 0, 0.8))
		draw_rect(Rect2(150, 150, 500, 300) + offset, Color(1, 0.84, 0), false, 3)
		if _custom_font != null:
			draw_string(_custom_font, Vector2(180, 260) + offset, winner, Color(1, 0.84, 0))
			draw_string(_custom_font, Vector2(200, 330) + offset, "Press SPACE to restart", Color(0.7, 0.7, 0.7))