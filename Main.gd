extends Node2D

# ============================================
# GAME CONSTANTS
# ============================================
const SCREEN_SIZE: Vector2 = Vector2(800, 600)
const BALL_INITIAL_SPEED: float = 400.0

# Colors
const COLOR_BG: Color = Color(0.05, 0.05, 0.12)
const COLOR_GRID: Color = Color(0.3, 0.5, 0.8, 0.4)
const COLOR_BALL: Color = Color(0.0, 1.0, 0.8)
const COLOR_PAD1: Color = Color(0.2, 0.6, 1.0)
const COLOR_PAD2: Color = Color(1.0, 0.3, 0.5)
const COLOR_COMBO: Color = Color(1.0, 0.3, 0.0)

# Power-up config: type → {color, label, param}
const POWERUP_CONFIG: Dictionary = {
	"speed_up": {"color": Color(1.0, 0.2, 0.2), "label": "FAST", "apply": "speed_up"},
	"slow": {"color": Color(0.2, 0.5, 1.0), "label": "SLOW", "apply": "slow"},
	"grow_left": {"color": Color(0.2, 1.0, 0.2), "label": "GROW", "apply": "grow_left"},
	"shrink_right": {"color": Color(1.0, 0.8, 0.2), "label": "SHRINK", "apply": "shrink_right"},
	"shrink_ai": {"color": Color(1.0, 0.8, 0.2), "label": "SHRINK", "apply": "shrink_ai"},
	"big_ball": {"color": Color(1.0, 1.0, 0.2), "label": "BIG", "apply": "big_ball"}
}

# ============================================
# BALL STATE
# ============================================
var ball_position: Vector2 = Vector2(400, 300)
var ball_velocity: Vector2 = Vector2(BALL_INITIAL_SPEED, BALL_INITIAL_SPEED)
var ball_radius: float = 10.0

# ============================================
# PADDLES STATE
# ============================================
var pad1_pos: Vector2 = Vector2(30, 300)
var pad2_pos: Vector2 = Vector2(770, 300)
var pad_speed: float = 400.0
var pad1_height: float = 100.0
var pad2_height: float = 100.0

# ============================================
# SCORE & COMBO
# ============================================
var score1: int = 0
var score2: int = 0
var pad1_combo: int = 0
var pad2_combo: int = 0
var combo_display: int = 0
var combo_timer: float = 0.0

# ============================================
# POWER-UP STATE
# ============================================
var powerup_active: bool = false
var powerup_type: String = ""
var powerup_position: Vector2 = Vector2(400, 300)
var powerup_radius: float = 15.0
var powerup_timer: float = 0.0
var powerup_duration: float = 8.0
var powerup_spawn_timer: float = 0.0
var powerup_spawn_interval: float = 10.0
var powerup_pulse: float = 0.0

# ============================================
# PARTICLE SYSTEM
# ============================================
const MAX_PARTICLES: int = 50
var particle_x: Array = []
var particle_y: Array = []
var particle_vel_x: Array = []
var particle_vel_y: Array = []
var particle_life: Array = []
var particle_color: Array = []  # Store Color directly

var _custom_font: DynamicFont = null

# ============================================
# AUDIO NODES
# ============================================
onready var hit_sound: AudioStreamPlayer = $hit_sound
onready var score_sound: AudioStreamPlayer = $score_sound
onready var powerup_sound: AudioStreamPlayer = $powerup_sound
onready var wall_sound: AudioStreamPlayer = $wall_sound

# ============================================
# LIFECYCLE
# ============================================
func _ready() -> void:
	_init_particles()
	_load_font()

func _init_particles() -> void:
	for i in range(MAX_PARTICLES):
		particle_x.append(0.0)
		particle_y.append(0.0)
		particle_vel_x.append(0.0)
		particle_vel_y.append(0.0)
		particle_life.append(0.0)
		particle_color.append(Color.WHITE)

func _load_font() -> void:
	pass  # Skip custom font rendering for now - focus on game running first

# ============================================
# GAME LOOP
# ============================================
func _process(delta: float) -> void:
	_update_ball(delta)
	_update_paddles(delta)
	_update_combo(delta)
	_update_powerups(delta)
	_update_particles(delta)
	queue_redraw()

func _update_ball(delta: float) -> void:
	ball_position += ball_velocity * delta
	
	# Wall collision
	if ball_position.y < ball_radius or ball_position.y > SCREEN_SIZE.y - ball_radius:
		ball_velocity.y = -ball_velocity.y
		wall_sound.play()
	
	# Paddle 1 collision (left)
	if _is_hit_paddle1():
		_on_paddle1_hit()
	
	# Paddle 2 collision (right) - check if ball is in paddle zone
	if ball_position.x > 740.0 and ball_position.x < 790.0:
		if abs(ball_position.y - pad2_pos.y) < pad2_height * 0.5:
			_on_paddle2_hit()
	
	# Scoring
	var scoring_side: int = 0
	if ball_position.x < ball_radius:
		scoring_side = 1
	elif ball_position.x > SCREEN_SIZE.x - ball_radius:
		scoring_side = 2
	if scoring_side != 0:
		_on_score(scoring_side)

func _update_paddles(delta: float) -> void:
	# AI movement (paddle 2)
	var ai_target: float = pad2_pos.y
	var ai_diff: float = ball_position.y - pad2_pos.y
	if abs(ai_diff) > 30.0:
		ai_target = pad2_pos.y + sign(ai_diff) * pad_speed * 0.7 * delta
	pad2_pos.y = clamp(ai_target, 50.0, SCREEN_SIZE.y - 50.0)
	
	# Player input (paddle 1)
	if Input.is_action_pressed("move_up"):
		pad1_pos.y -= pad_speed * delta
	if Input.is_action_pressed("move_down"):
		pad1_pos.y += pad_speed * delta
	pad1_pos.y = clamp(pad1_pos.y, 50.0, SCREEN_SIZE.y - 50.0)

func _update_combo(delta: float) -> void:
	if combo_display > 0:
		combo_timer += delta
		if combo_timer > 2.5:
			combo_display = 0

func _update_powerups(delta: float) -> void:
	# Spawn timer
	powerup_spawn_timer += delta
	if powerup_spawn_timer >= powerup_spawn_interval and not powerup_active:
		_spawn_powerup()
	
	# Active timer
	if powerup_active:
		powerup_timer += delta
		powerup_pulse = 0.7 + sin(powerup_timer * 6.0) * 0.3
		if powerup_timer >= powerup_duration:
			_reset_powerup_effects()
	
	# Collection check
	if powerup_active and _is_ball_near_powerup():
		_collect_powerup()

func _update_particles(delta: float) -> void:
	for i in range(MAX_PARTICLES):
		if particle_life[i] > 0:
			particle_x[i] += particle_vel_x[i] * delta
			particle_y[i] += particle_vel_y[i] * delta
			particle_life[i] -= delta

# ============================================
# COLLISION HELPERS
# ============================================
func _is_hit_paddle1() -> bool:
	return ball_position.x < 50.0 and abs(ball_position.y - pad1_pos.y) < pad1_height * 0.5

func _is_hit_paddle2() -> bool:
	return ball_position.x > 750.0 and abs(ball_position.y - pad2_pos.y) < pad2_height * 0.5

func _on_paddle1_hit() -> void:
	ball_velocity.x = abs(ball_velocity.x)
	pad1_combo += 1
	combo_display = pad1_combo
	combo_timer = 0.0
	hit_sound.play()
	_spawn_hit_particles(ball_position, COLOR_PAD1)

func _on_paddle2_hit() -> void:
	ball_velocity.x = -abs(ball_velocity.x)
	pad2_combo += 1
	combo_display = pad2_combo
	combo_timer = 0.0
	hit_sound.play()
	_spawn_hit_particles(ball_position, COLOR_PAD2)

func _is_ball_near_powerup() -> bool:
	return ball_position.distance_to(powerup_position) < ball_radius + powerup_radius

# ============================================
# SCORING
# ============================================
func _on_score(side: int) -> void:
	var combo: int = pad1_combo if side == 1 else pad2_combo
	var pts: int = get_score_points(combo)
	
	if side == 1:
		score2 += pts
		_spawn_score_particles(ball_position, COLOR_PAD1)
	else:
		score1 += pts
		_spawn_score_particles(ball_position, COLOR_PAD2)
	
	combo_display = combo
	pad1_combo = 0
	pad2_combo = 0
	score_sound.play()
	reset_ball()

func get_score_points(combo: int) -> int:
	if combo >= 8: return 3
	elif combo >= 5: return 2
	return 1

func reset_ball() -> void:
	ball_position = Vector2(400.0, 300.0)
	var sign_x: float = 1.0 if randf() > 0.5 else -1.0
	var sign_y: float = 1.0 if randf() > 0.5 else -1.0
	ball_velocity = Vector2(BALL_INITIAL_SPEED * sign_x, BALL_INITIAL_SPEED * sign_y)

# ============================================
# PARTICLES
# ============================================
func _spawn_hit_particles(pos: Vector2, color: Color) -> void:
	for i in range(3):
		_spawn_single_particle(pos, color)

func _spawn_score_particles(pos: Vector2, color: Color) -> void:
	for i in range(8):
		_spawn_single_particle(pos, color)

func _spawn_single_particle(pos: Vector2, color: Color) -> void:
	var slot: int = _find_free_particle_slot()
	var angle: float = randf() * 2.0 * PI
	var speed: float = 100.0 + randf() * 150.0
	
	particle_x[slot] = pos.x
	particle_y[slot] = pos.y
	particle_vel_x[slot] = cos(angle) * speed
	particle_vel_y[slot] = sin(angle) * speed
	particle_life[slot] = 0.3 + randf() * 0.2
	particle_color[slot] = color

func _find_free_particle_slot() -> int:
	for i in range(MAX_PARTICLES):
		if particle_life[i] <= 0:
			return i
	return 0  # Wrap around if full

# ============================================
# POWER-UPS
# ============================================
func _spawn_powerup() -> void:
	var types: Array = POWERUP_CONFIG.keys()
	powerup_type = types[randi() % types.size()]
	powerup_position = Vector2(250.0 + randf() * 300.0, 150.0 + randf() * 300.0)
	powerup_active = true
	powerup_timer = 0.0
	powerup_pulse = 1.0
	powerup_spawn_timer = 0.0

func _collect_powerup() -> void:
	powerup_sound.play()
	var config: Dictionary = POWERUP_CONFIG[powerup_type]
	
	match config["apply"]:
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

func _reset_powerup_effects() -> void:
	pad1_height = 100.0
	pad2_height = 100.0
	ball_radius = 10.0
	powerup_active = false

# ============================================
# RENDERING
# ============================================
func _draw() -> void:
	_draw_background()
	_draw_particles()
	_draw_ball()
	_draw_paddles()
	_draw_score()
	_draw_combo_text()
	_draw_powerup()

func _draw_background() -> void:
	draw_rect(Rect2(Vector2.ZERO, SCREEN_SIZE), COLOR_BG)
	
	# Center grid
	for i in range(0, 600, 20):
		draw_rect(Rect2(398, i + 5, 4, 10), COLOR_GRID)

func _draw_particles() -> void:
	for i in range(MAX_PARTICLES):
		if particle_life[i] > 0:
			var alpha: float = particle_life[i] / 0.5
			var sz: float = 4.0 * alpha
			var col: Color = particle_color[i]
			draw_circle(Vector2(particle_x[i], particle_y[i]), sz, Color(col.r, col.g, col.b, alpha))

func _draw_ball() -> void:
	# Outer glow
	draw_circle(ball_position, ball_radius * 1.8, Color(0.0, 0.8, 0.6, 0.2))
	draw_circle(ball_position, ball_radius * 1.4, Color(0.0, 1.0, 0.8, 0.3))
	# Core
	draw_circle(ball_position, ball_radius, COLOR_BALL)

func _draw_paddles() -> void:
	# Paddle 1 (left) - glow + solid
	_draw_paddle_with_glow(10, pad1_pos.y, pad1_height, COLOR_PAD1)
	
	# Paddle 2 (right) - glow + solid
	_draw_paddle_with_glow(770, pad2_pos.y, pad2_height, COLOR_PAD2)

func _draw_paddle_with_glow(x: float, y: float, height: float, color: Color) -> void:
	var rect: Rect2 = Rect2(x, y - height * 0.5, 20, height)
	draw_rect(rect, Color(color.r, color.g, color.b, 0.35))  # Glow
	draw_rect(rect, color)  # Solid

func _draw_score() -> void:
	# Player 1 score (left side, blue dots)
	for i in range(score1):
		var pos: Vector2 = Vector2(100 + i * 25, 30)
		draw_circle(pos, 10, Color(COLOR_PAD1.r, COLOR_PAD1.g, COLOR_PAD1.b, 0.3))
		draw_circle(pos, 6, COLOR_PAD1)
	
	# Player 2 score (right side, pink dots)
	for i in range(score2):
		var pos: Vector2 = Vector2(700 - i * 25, 30)
		draw_circle(pos, 10, Color(COLOR_PAD2.r, COLOR_PAD2.g, COLOR_PAD2.b, 0.3))
		draw_circle(pos, 6, COLOR_PAD2)

func _draw_combo_text() -> void:
	if combo_display > 1 and _custom_font != null:
		var pts: int = get_score_points(combo_display)
		var txt: String = "x" + str(combo_display)
		if pts > 1:
			txt = "%s [%dP]" % [txt, pts]
		draw_string(_custom_font, Vector2(320, 575), txt, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color.WHITE)

func _draw_powerup() -> void:
	if not powerup_active:
		return
	
	var config: Dictionary = POWERUP_CONFIG[powerup_type]
	var col: Color = config["color"]
	
	# Pulsing glow + core
	draw_circle(powerup_position, powerup_radius * 1.5 * powerup_pulse, Color(col.r, col.g, col.b, 0.3))
	draw_circle(powerup_position, powerup_radius, col)
	
	# Label
	if _custom_font != null:
		var label: String = config["label"]
		draw_string(_custom_font, powerup_position + Vector2(-25, -25), label, HORIZONTAL_ALIGNMENT_CENTER, -1, 24, Color.WHITE)