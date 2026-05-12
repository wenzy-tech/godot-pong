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

# Combo system
var pad1_combo = 0
var pad2_combo = 0
var combo_display = 0
var combo_timer = 0.0

# Power-ups
var powerup_active = false
var powerup_type = ""
var powerup_position = Vector2(400, 300)
var powerup_radius = 15
var powerup_timer = 0.0
var powerup_duration = 8.0
var powerup_spawn_timer = 0.0
var powerup_spawn_interval = 10.0
var powerup_pulse = 0.0

# Particles
var MAX_PARTICLES = 50
var particle_x = []
var particle_y = []
var particle_vel_x = []
var particle_vel_y = []
var particle_life = []
var particle_r = []
var particle_g = []
var particle_b = []

var _custom_font = null

onready var hit_sound = $hit_sound
onready var score_sound = $score_sound
onready var powerup_sound = $powerup_sound
onready var wall_sound = $wall_sound

const POWERUP_TYPES = ["speed_up", "slow", "grow_left", "shrink_right", "shrink_ai", "big_ball"]
const COLOR_COMBO = Color(1.0, 0.3, 0.0)

func _ready():
	for i in range(MAX_PARTICLES):
		particle_x.append(0.0)
		particle_y.append(0.0)
		particle_vel_x.append(0.0)
		particle_vel_y.append(0.0)
		particle_life.append(0.0)
		particle_r.append(1.0)
		particle_g.append(1.0)
		particle_b.append(1.0)
	
	_custom_font = DynamicFont.new()
	_custom_font.font_data = load("res://font.ttf")

func spawn_particle(x, y, r, g, b):
	var slot = -1
	for i in range(MAX_PARTICLES):
		if particle_life[i] <= 0:
			slot = i
			break
	if slot < 0:
		slot = 0
	var angle = randf() * 2.0 * PI
	var speed = 100.0 + randf() * 150.0
	particle_x[slot] = x
	particle_y[slot] = y
	particle_vel_x[slot] = cos(angle) * speed
	particle_vel_y[slot] = sin(angle) * speed
	particle_life[slot] = 0.3 + randf() * 0.2
	particle_r[slot] = r
	particle_g[slot] = g
	particle_b[slot] = b

func update_particles(delta):
	for i in range(MAX_PARTICLES):
		if particle_life[i] > 0:
			particle_x[i] += particle_vel_x[i] * delta
			particle_y[i] += particle_vel_y[i] * delta
			particle_life[i] -= delta

func _process(delta):
	ball_position += ball_velocity * delta
	
	if ball_position.y < ball_radius or ball_position.y > 600 - ball_radius:
		ball_velocity.y = -ball_velocity.y
		wall_sound.play()
	
	if ball_position.x < 50 and abs(ball_position.y - pad1_pos.y) < pad1_height * 0.5:
		ball_velocity.x = abs(ball_velocity.x)
		pad1_combo += 1
		combo_display = pad1_combo
		combo_timer = 0.0
		hit_sound.play()
		for i in range(3):
			spawn_particle(ball_position.x, ball_position.y, 0.2, 0.6, 1.0)
	
	if ball_position.x > 750 and abs(ball_position.y - pad2_pos.y) < pad2_height * 0.5:
		ball_velocity.x = -abs(ball_velocity.x)
		pad2_combo += 1
		combo_display = pad2_combo
		combo_timer = 0.0
		hit_sound.play()
		for i in range(3):
			spawn_particle(ball_position.x, ball_position.y, 1.0, 0.3, 0.5)
	
	if ball_position.x < ball_radius:
		var pts = get_score_points(pad1_combo)
		score2 += pts
		combo_display = pad1_combo
		pad1_combo = 0
		pad2_combo = 0
		score_sound.play()
		for i in range(8):
			spawn_particle(ball_position.x, ball_position.y, 1.0, 0.3, 0.5)
		reset_ball()
	if ball_position.x > 800 - ball_radius:
		var pts = get_score_points(pad2_combo)
		score1 += pts
		combo_display = pad2_combo
		pad1_combo = 0
		pad2_combo = 0
		score_sound.play()
		for i in range(8):
			spawn_particle(ball_position.x, ball_position.y, 0.2, 0.6, 1.0)
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
	
	if combo_display > 0:
		combo_timer += delta
		if combo_timer > 2.5:
			combo_display = 0
	
	powerup_spawn_timer += delta
	if powerup_spawn_timer >= powerup_spawn_interval and not powerup_active:
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
	queue_redraw()

func get_score_points(combo):
	if combo >= 8:
		return 3
	elif combo >= 5:
		return 2
	return 1

func reset_ball():
	ball_position = Vector2(400, 300)
	ball_velocity = Vector2(400 * (1 if randf() > 0.5 else -1), 400 * (1 if randf() > 0.5 else -1))

func get_powerup_color():
	if powerup_type == "speed_up":
		return Color(1.0, 0.2, 0.2)
	elif powerup_type == "slow":
		return Color(0.2, 0.5, 1.0)
	elif powerup_type == "grow_left":
		return Color(0.2, 1.0, 0.2)
	elif powerup_type == "shrink_right" or powerup_type == "shrink_ai":
		return Color(1.0, 0.8, 0.2)
	return Color(1.0, 1.0, 0.2)

func get_powerup_label():
	var label = powerup_type
	if powerup_type == "grow_left":
		label = "GROW"
	elif powerup_type == "shrink_right" or powerup_type == "shrink_ai":
		label = "SHRINK"
	elif powerup_type == "speed_up":
		label = "FAST"
	elif powerup_type == "slow":
		label = "SLOW"
	elif powerup_type == "big_ball":
		label = "BIG"
	return label

func _draw():
	draw_rect(Rect2(0, 0, 800, 600), Color(0.05, 0.05, 0.12))
	
	for i in range(0, 600, 20):
		draw_rect(Rect2(398, i + 5, 4, 10), Color(0.3, 0.5, 0.8, 0.4))
	
	# Particles
	for i in range(MAX_PARTICLES):
		if particle_life[i] > 0:
			var alpha = particle_life[i] / 0.5
			var sz = 4.0 * alpha
			draw_circle(Vector2(particle_x[i], particle_y[i]), sz, Color(particle_r[i], particle_g[i], particle_b[i], alpha))
	
	# Ball glow
	draw_circle(ball_position, ball_radius * 1.8, Color(0.0, 0.8, 0.6, 0.2))
	draw_circle(ball_position, ball_radius * 1.4, Color(0.0, 1.0, 0.8, 0.3))
	draw_circle(ball_position, ball_radius, Color(0.0, 1.0, 0.8))
	
	# Left paddle glow (filled with alpha)
	draw_rect(Rect2(10, pad1_pos.y - pad1_height * 0.5, 20, pad1_height), Color(0.2, 0.6, 1.0, 0.35))
	# Left paddle solid
	draw_rect(Rect2(10, pad1_pos.y - pad1_height * 0.5, 20, pad1_height), Color(0.2, 0.6, 1.0))
	
	# Right paddle glow
	draw_rect(Rect2(770, pad2_pos.y - pad2_height * 0.5, 20, pad2_height), Color(1.0, 0.3, 0.5, 0.35))
	# Right paddle solid
	draw_rect(Rect2(770, pad2_pos.y - pad2_height * 0.5, 20, pad2_height), Color(1.0, 0.3, 0.5))
	
	# Score dots
	for i in range(score1):
		draw_circle(Vector2(100 + i * 25, 30), 10, Color(0.2, 0.6, 1.0, 0.3))
		draw_circle(Vector2(100 + i * 25, 30), 6, Color(0.2, 0.6, 1.0))
	for i in range(score2):
		draw_circle(Vector2(700 - i * 25, 30), 10, Color(1.0, 0.3, 0.5, 0.3))
		draw_circle(Vector2(700 - i * 25, 30), 6, Color(1.0, 0.3, 0.5))
	
	# Combo text
	if combo_display > 1 and _custom_font != null:
		var pts = get_score_points(combo_display)
		var txt = "x" + str(combo_display)
		if pts > 1:
			txt = txt + " [" + str(pts) + "P]"
		draw_string(_custom_font, Vector2(320, 575), txt, HORIZONTAL_ALIGNMENT_CENTER, -1)
	
	# Power-up on screen
	if powerup_active:
		var col = get_powerup_color()
		draw_circle(powerup_position, powerup_radius * 1.5 * powerup_pulse, Color(col.r, col.g, col.b, 0.3))
		draw_circle(powerup_position, powerup_radius, col)
		if _custom_font != null:
			var label = get_powerup_label()
			draw_string(_custom_font, powerup_position + Vector2(-25, -25), label, HORIZONTAL_ALIGNMENT_CENTER, -1)
