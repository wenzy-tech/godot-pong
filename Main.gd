extends Node2D

# Ball
var ball_position: Vector2 = Vector2(400, 300)
var ball_velocity: Vector2 = Vector2(400, 400)
var ball_radius: float = 10.0

# Paddles
var pad1_pos: Vector2 = Vector2(30, 300)
var pad2_pos: Vector2 = Vector2(770, 300)
var pad_speed: float = 400.0
var pad1_height: float = 100.0
var pad2_height: float = 100.0

# Score
var score1: int = 0
var score2: int = 0

# Combo system
var pad1_combo: int = 0
var pad2_combo: int = 0
var combo_display: int = 0
var combo_timer: float = 0.0

# Power-ups
var powerup_active: bool = false
var powerup_type: String = ""
var powerup_position: Vector2 = Vector2(400, 300)
var powerup_radius: float = 15.0
var powerup_timer: float = 0.0
var powerup_duration: float = 8.0
var powerup_spawn_timer: float = 0.0
var powerup_spawn_interval: float = 10.0
var powerup_pulse: float = 0.0

# Particles (fixed arrays)
const MAX_PARTICLES: int = 50
var particle_x: Array = []
var particle_y: Array = []
var particle_vel_x: Array = []
var particle_vel_y: Array = []
var particle_life: Array = []
var particle_r: Array = []
var particle_g: Array = []
var particle_b: Array = []

var _custom_font: DynamicFont = null

onready var hit_sound: AudioStreamPlayer = $hit_sound
onready var score_sound: AudioStreamPlayer = $score_sound
onready var powerup_sound: AudioStreamPlayer = $powerup_sound
onready var wall_sound: AudioStreamPlayer = $wall_sound

const POWERUP_TYPES: Array = ["speed_up", "slow", "grow_left", "shrink_right", "shrink_ai", "big_ball"]
const COLOR_COMBO: Color = Color(1.0, 0.3, 0.0)

func _ready() -> void:
	# Initialize particle arrays
	for i in range(MAX_PARTICLES):
		particle_x.append(0.0)
		particle_y.append(0.0)
		particle_vel_x.append(0.0)
		particle_vel_y.append(0.0)
		particle_life.append(0.0)
		particle_r.append(1.0)
		particle_g.append(1.0)
		particle_b.append(1.0)
	
	# Load font for text rendering
	_custom_font = DynamicFont.new()
	_custom_font.font_data = load("res://font.ttf")
	_custom_font.size = 24

func spawn_particle(x: float, y: float, r: float, g: float, b: float) -> void:
	var slot: int = -1
	for i in range(MAX_PARTICLES):
		if particle_life[i] <= 0:
			slot = i
			break
	if slot < 0:
		slot = 0
	
	var angle: float = randf() * 2.0 * PI
	var speed: float = 100.0 + randf() * 150.0
	particle_x[slot] = x
	particle_y[slot] = y
	particle_vel_x[slot] = cos(angle) * speed
	particle_vel_y[slot] = sin(angle) * speed
	particle_life[slot] = 0.3 + randf() * 0.2
	particle_r[slot] = r
	particle_g[slot] = g
	particle_b[slot] = b

func update_particles(delta: float) -> void:
	for i in range(MAX_PARTICLES):
		if particle_life[i] > 0:
			particle_x[i] += particle_vel_x[i] * delta
			particle_y[i] += particle_vel_y[i] * delta
			particle_life[i] -= delta

func _process(delta: float) -> void:
	ball_position += ball_velocity * delta
	
	# Wall collision
	if ball_position.y < ball_radius or ball_position.y > 600.0 - ball_radius:
		ball_velocity.y = -ball_velocity.y
		wall_sound.play()
	
	# Paddle 1 collision
	if ball_position.x < 50.0 and abs(ball_position.y - pad1_pos.y) < pad1_height * 0.5:
		ball_velocity.x = abs(ball_velocity.x)
		pad1_combo += 1
		combo_display = pad1_combo
		combo_timer = 0.0
		hit_sound.play()
		for i in range(3):
			spawn_particle(ball_position.x, ball_position.y, 0.2, 0.6, 1.0)
	
	# Paddle 2 collision
	if ball_position.x > 750.0 and abs(ball_position.y - pad2_pos.y) < pad2_height * 0.5:
		ball_velocity.x = -abs(ball_velocity.x)
		pad2_combo += 1
		combo_display = pad2_combo
		combo_timer = 0.0
		hit_sound.play()
		for i in range(3):
			spawn_particle(ball_position.x, ball_position.y, 1.0, 0.3, 0.5)
	
	# Score
	if ball_position.x < ball_radius:
		var pts: int = get_score_points(pad1_combo)
		score2 += pts
		combo_display = pad1_combo
		pad1_combo = 0
		pad2_combo = 0
		score_sound.play()
		for i in range(8):
			spawn_particle(ball_position.x, ball_position.y, 1.0, 0.3, 0.5)
		reset_ball()
	if ball_position.x > 800.0 - ball_radius:
		var pts: int = get_score_points(pad2_combo)
		score1 += pts
		combo_display = pad2_combo
		pad1_combo = 0
		pad2_combo = 0
		score_sound.play()
		for i in range(8):
			spawn_particle(ball_position.x, ball_position.y, 0.2, 0.6, 1.0)
		reset_ball()
	
	# AI movement
	if ball_position.y < pad2_pos.y - 30.0:
		pad2_pos.y -= pad_speed * 0.7 * delta
	if ball_position.y > pad2_pos.y + 30.0:
		pad2_pos.y += pad_speed * 0.7 * delta
	pad2_pos.y = clamp(pad2_pos.y, 50.0, 550.0)
	
	# Player input
	if Input.is_action_pressed("move_up"):
		pad1_pos.y -= pad_speed * delta
	if Input.is_action_pressed("move_down"):
		pad1_pos.y += pad_speed * delta
	pad1_pos.y = clamp(pad1_pos.y, 50.0, 550.0)
	
	# Combo timer
	if combo_display > 0:
		combo_timer += delta
		if combo_timer > 2.5:
			combo_display = 0
	
	# Spawn power-up
	powerup_spawn_timer += delta
	if powerup_spawn_timer >= powerup_spawn_interval and not powerup_active:
		powerup_type = POWERUP_TYPES[randi() % POWERUP_TYPES.size()]
		powerup_position = Vector2(250.0 + randf() * 300.0, 150.0 + randf() * 300.0)
		powerup_active = true
		powerup_timer = 0.0
		powerup_pulse = 1.0
		powerup_spawn_timer = 0.0
	
	# Power-up timer
	if powerup_active:
		powerup_timer += delta
		powerup_pulse = 0.7 + sin(powerup_timer * 6.0) * 0.3
		if powerup_timer >= powerup_duration:
			pad1_height = 100.0
			pad2_height = 100.0
			ball_radius = 10.0
			powerup_active = false
	
	# Collect power-up
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

func get_score_points(combo: int) -> int:
	if combo >= 8:
		return 3
	elif combo >= 5:
		return 2
	return 1

func reset_ball() -> void:
	ball_position = Vector2(400.0, 300.0)
	ball_velocity = Vector2(400.0 * (1.0 if randf() > 0.5 else -1.0), 
                            400.0 * (1.0 if randf() > 0.5 else -1.0))

func get_powerup_color() -> Color:
	if powerup_type == "speed_up":
		return Color(1.0, 0.2, 0.2)
	elif powerup_type == "slow":
		return Color(0.2, 0.5, 1.0)
	elif powerup_type == "grow_left":
		return Color(0.2, 1.0, 0.2)
	elif powerup_type == "shrink_right" or powerup_type == "shrink_ai":
		return Color(1.0, 0.8, 0.2)
	return Color(1.0, 1.0, 0.2)

func get_powerup_label() -> String:
	var label: String = powerup_type
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

func _draw() -> void:
	# Background
	draw_rect(Rect2(0, 0, 800, 600), Color(0.05, 0.05, 0.12))
	
	# Grid lines
	for i in range(0, 600, 20):
		draw_rect(Rect2(398, i + 5, 4, 10), Color(0.3, 0.5, 0.8, 0.4))
	
	# Particles
	for i in range(MAX_PARTICLES):
		if particle_life[i] > 0:
			var alpha: float = particle_life[i] / 0.5
			var sz: float = 4.0 * alpha
			draw_circle(Vector2(particle_x[i], particle_y[i]), sz, 
			             Color(particle_r[i], particle_g[i], particle_b[i], alpha))
	
	# Ball glow (3 layers)
	draw_circle(ball_position, ball_radius * 1.8, Color(0.0, 0.8, 0.6, 0.2))
	draw_circle(ball_position, ball_radius * 1.4, Color(0.0, 1.0, 0.8, 0.3))
	draw_circle(ball_position, ball_radius, Color(0.0, 1.0, 0.8))
	
	# Left paddle glow + solid
	draw_rect(Rect2(10, pad1_pos.y - pad1_height * 0.5, 20, pad1_height), 
	         Color(0.2, 0.6, 1.0, 0.35))
	draw_rect(Rect2(10, pad1_pos.y - pad1_height * 0.5, 20, pad1_height), 
	         Color(0.2, 0.6, 1.0))
	
	# Right paddle glow + solid
	draw_rect(Rect2(770, pad2_pos.y - pad2_height * 0.5, 20, pad2_height), 
	         Color(1.0, 0.3, 0.5, 0.35))
	draw_rect(Rect2(770, pad2_pos.y - pad2_height * 0.5, 20, pad2_height), 
	         Color(1.0, 0.3, 0.5))
	
	# Score dots
	for i in range(score1):
		draw_circle(Vector2(100 + i * 25, 30), 10, Color(0.2, 0.6, 1.0, 0.3))
		draw_circle(Vector2(100 + i * 25, 30), 6, Color(0.2, 0.6, 1.0))
	for i in range(score2):
		draw_circle(Vector2(700 - i * 25, 30), 10, Color(1.0, 0.3, 0.5, 0.3))
		draw_circle(Vector2(700 - i * 25, 30), 6, Color(1.0, 0.3, 0.5))
	
	# Combo text
	if combo_display > 1 and _custom_font != null:
		var pts: int = get_score_points(combo_display)
		var txt: String = "x" + str(combo_display)
		if pts > 1:
			txt = txt + " [" + str(pts) + "P]"
		draw_string(_custom_font, Vector2(320, 575), txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 
		            Color.WHITE)
	
	# Power-up indicator
	if powerup_active:
		var col: Color = get_powerup_color()
		draw_circle(powerup_position, powerup_radius * 1.5 * powerup_pulse, 
		           Color(col.r, col.g, col.b, 0.3))
		draw_circle(powerup_position, powerup_radius, col)
		if _custom_font != null:
			var label: String = get_powerup_label()
			draw_string(_custom_font, powerup_position + Vector2(-25, -25), label, 
			            HORIZONTAL_ALIGNMENT_CENTER, -1, Color.WHITE)
