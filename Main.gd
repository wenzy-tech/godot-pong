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
	
	# Try to load font
	var fd = DynamicFontData.new()
	fd.font_path = "res://font.ttf"
	fd.size = 24
	_custom_font = DynamicFont.new()
	_custom_font.font_data = fd
	print("DEBUG: Font loaded: ", _custom_font)

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
	
	if ball_position.x < 50 and abs(ball_position.y - pad1_pos.y) < pad1_height * 0.5:
		ball_velocity.x = abs(ball_velocity.x)
		for i in range(3):
			spawn_particle(ball_position.x, ball_position.y, 0.2, 0.6, 1.0)
	
	if ball_position.x > 750 and abs(ball_position.y - pad2_pos.y) < pad2_height * 0.5:
		ball_velocity.x = -abs(ball_velocity.x)
		for i in range(3):
			spawn_particle(ball_position.x, ball_position.y, 1.0, 0.3, 0.5)
	
	if ball_position.x < ball_radius:
		score2 += 1
		for i in range(8):
			spawn_particle(ball_position.x, ball_position.y, 1.0, 0.3, 0.5)
		reset_ball()
	if ball_position.x > 800 - ball_radius:
		score1 += 1
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
	
	update_particles(delta)
	queue_redraw()

func reset_ball():
	ball_position = Vector2(400, 300)
	ball_velocity = Vector2(400 * (1 if randf() > 0.5 else -1), 400 * (1 if randf() > 0.5 else -1))

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
	
	# Left paddle with glow
	draw_rect(Rect2(10, pad1_pos.y - pad1_height * 0.5, 20, pad1_height), Color(0.2, 0.6, 1.0, 0.35), true, 6)
	draw_rect(Rect2(10, pad1_pos.y - pad1_height * 0.5, 20, pad1_height), Color(0.2, 0.6, 1.0))
	
	# Right paddle with glow
	draw_rect(Rect2(770, pad2_pos.y - pad2_height * 0.5, 20, pad2_height), Color(1.0, 0.3, 0.5, 0.35), true, 6)
	draw_rect(Rect2(770, pad2_pos.y - pad2_height * 0.5, 20, pad2_height), Color(1.0, 0.3, 0.5))
	
	# Score dots
	for i in range(score1):
		draw_circle(Vector2(100 + i * 25, 30), 10, Color(0.2, 0.6, 1.0, 0.3))
		draw_circle(Vector2(100 + i * 25, 30), 6, Color(0.2, 0.6, 1.0))
	for i in range(score2):
		draw_circle(Vector2(700 - i * 25, 30), 10, Color(1.0, 0.3, 0.5, 0.3))
		draw_circle(Vector2(700 - i * 25, 30), 6, Color(1.0, 0.3, 0.5))
	
	# Test: Draw simple text using font ONLY if font is loaded
	if _custom_font != null:
		draw_string(_custom_font, Vector2(350, 300), "HELLO", Color(1, 1, 1))
	
	print("DEBUG: _draw called, font=",_custom_font)
