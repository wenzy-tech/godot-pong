extends Node2D

# ============================================
# GAME CONSTANTS
# ============================================
const SCREEN_SIZE: Vector2 = Vector2(800, 600)
const BALL_INITIAL_SPEED: float = 400.0
const WINNING_SCORE: int = 11

# Colors - Cyberpunk neon palette
const COLOR_BG: Color = Color(0.02, 0.02, 0.08)
const COLOR_GRID: Color = Color(0.15, 0.35, 0.6, 0.5)
const COLOR_BALL_CORE: Color = Color(0.0, 1.0, 0.9)
const COLOR_BALL_GLOW: Color = Color(0.0, 0.8, 0.7, 0.4)
const COLOR_PAD1_CORE: Color = Color(0.2, 0.7, 1.0)
const COLOR_PAD1_GLOW: Color = Color(0.1, 0.4, 0.8, 0.5)
const COLOR_PAD2_CORE: Color = Color(1.0, 0.3, 0.6)
const COLOR_PAD2_GLOW: Color = Color(0.8, 0.15, 0.4, 0.5)
const COLOR_COMBO: Color = Color(1.0, 0.4, 0.0)
const COLOR_POWERUP: Color = Color(1.0, 0.9, 0.2)

# Power-up config: type → {color, label}
const POWERUP_CONFIG: Dictionary = {
	"speed_up": {"color": Color(1.0, 0.3, 0.3), "label": "FAST"},
	"slow": {"color": Color(0.3, 0.5, 1.0), "label": "SLOW"},
	"grow_left": {"color": Color(0.3, 1.0, 0.5), "label": "GROW"},
	"shrink_right": {"color": Color(1.0, 0.8, 0.3), "label": "SHRINK"},
	"shrink_ai": {"color": Color(1.0, 0.6, 0.2), "label": "SHRINK"},
	"big_ball": {"color": Color(1.0, 1.0, 0.4), "label": "BIG"}
}

# ============================================
# BALL STATE
# ============================================
var ball_position: Vector2 = Vector2(400, 300)
var ball_velocity: Vector2 = Vector2(BALL_INITIAL_SPEED, BALL_INITIAL_SPEED)
var ball_radius: float = 10.0
var ball_base_speed: float = BALL_INITIAL_SPEED
var ball_speed_override: float = 0.0  # 0 = no override, >0 = seconds remaining

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
const MAX_PARTICLES: int = 100
var particle_x: Array = []
var particle_y: Array = []
var particle_vel_x: Array = []
var particle_vel_y: Array = []
var particle_life: Array = []
var particle_size: Array = []
var particle_color: Array = []

# ============================================
# VISUAL EFFECTS
# ============================================
var time_elapsed: float = 0.0
var screen_shake: float = 0.0
var glow_intensity: float = 1.0

# ============================================
# GAME STATE
# ============================================
var game_over: bool = false
var winner: String = ""
var final_score: String = ""
var difficulty: String = "NORMAL"

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

func _init_particles() -> void:
	for i in range(MAX_PARTICLES):
		particle_x.append(0.0)
		particle_y.append(0.0)
		particle_vel_x.append(0.0)
		particle_vel_y.append(0.0)
		particle_life.append(0.0)
		particle_size.append(0.0)
		particle_color.append(Color.WHITE)

# ============================================
# GAME LOOP
# ============================================
func _process(delta: float) -> void:
	time_elapsed += delta
	
	if game_over:
		if Input.is_action_just_pressed("ui_accept"):
			# Restart game
			get_tree().change_scene_to_file("res://Main.tscn")
		if Input.is_action_just_pressed("ui_cancel"):
			# Back to menu
			get_tree().change_scene_to_file("res://StartScreen.tscn")
		return
	
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://StartScreen.tscn")
		return
	
	_update_ball(delta)
	_update_paddles(delta)
	_update_combo(delta)
	_update_powerups(delta)
	_update_particles(delta)
	_update_effects(delta)
	queue_redraw()

func _update_effects(delta: float) -> void:
	# Decay screen shake
	screen_shake *= 0.9
	if screen_shake < 0.1:
		screen_shake = 0.0
	
	# Pulsing glow
	glow_intensity = 1.0 + sin(time_elapsed * 3.0) * 0.2

func _update_ball(delta: float) -> void:
	ball_position += ball_velocity * delta
	
	# Wall collision
	if ball_position.y < ball_radius or ball_position.y > SCREEN_SIZE.y - ball_radius:
		ball_velocity.y = -ball_velocity.y
		wall_sound.play()
	
	# Paddle 1 collision (left)
	if ball_position.x < 50.0 and abs(ball_position.y - pad1_pos.y) < pad1_height * 0.5:
		_on_paddle1_hit()
	
	# Paddle 2 collision (right)
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
	var ai_diff = ball_position.y - pad2_pos.y
	if abs(ai_diff) > 30.0:
		var direction = sign(ai_diff)
		var speed_mult = 0.7
		if has_node("/root/GameState"):
			speed_mult = get_node("/root/GameState").difficulty_multiplier
		pad2_pos.y += direction * pad_speed * speed_mult * delta
	pad2_pos.y = clamp(pad2_pos.y, 50.0, SCREEN_SIZE.y - 50.0)
	
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
	powerup_spawn_timer += delta
	if powerup_spawn_timer >= powerup_spawn_interval and not powerup_active:
		_spawn_powerup()
	
	# Update ball speed override (slow powerup)
	if ball_speed_override > 0:
		ball_speed_override -= delta
		if ball_speed_override <= 0:
			ball_speed_override = 0.0
			# Restore ball speed when timer expires
			var current_speed = ball_velocity.length()
			if current_speed < ball_base_speed * 0.7:
				ball_velocity = ball_velocity.normalized() * ball_base_speed
	
	if powerup_active:
		powerup_timer += delta
		powerup_pulse = 0.7 + sin(powerup_timer * 6.0) * 0.3
		if powerup_timer >= powerup_duration:
			_reset_powerup_effects()
	
	if powerup_active and ball_position.distance_to(powerup_position) < ball_radius + powerup_radius:
		_collect_powerup()

func _update_particles(delta: float) -> void:
	for i in range(MAX_PARTICLES):
		if particle_life[i] > 0:
			particle_x[i] += particle_vel_x[i] * delta
			particle_y[i] += particle_vel_y[i] * delta
			particle_life[i] -= delta
			particle_size[i] *= 0.98

# ============================================
# GAME EVENTS
# ============================================
func _on_paddle1_hit() -> void:
	ball_velocity.x = abs(ball_velocity.x)
	pad1_combo += 1
	combo_display = pad1_combo
	combo_timer = 0.0
	hit_sound.play()
	screen_shake = 5.0
	_spawn_hit_particles(ball_position, COLOR_PAD1_CORE, 5)

func _on_paddle2_hit() -> void:
	ball_velocity.x = -abs(ball_velocity.x)
	pad2_combo += 1
	combo_display = pad2_combo
	combo_timer = 0.0
	hit_sound.play()
	screen_shake = 5.0
	_spawn_hit_particles(ball_position, COLOR_PAD2_CORE, 5)

func _on_score(side: int) -> void:
	var combo = pad1_combo if side == 1 else pad2_combo
	var pts = get_score_points(combo)
	
	if side == 1:
		score2 += pts
		_spawn_score_particles(ball_position, COLOR_PAD1_CORE, 15)
	else:
		score1 += pts
		_spawn_score_particles(ball_position, COLOR_PAD2_CORE, 15)
	
	combo_display = combo
	pad1_combo = 0
	pad2_combo = 0
	score_sound.play()
	screen_shake = 10.0
	
	# Check win
	if score1 >= WINNING_SCORE or score2 >= WINNING_SCORE:
		_trigger_game_over()
	else:
		reset_ball()

func _trigger_game_over() -> void:
	game_over = true
	winner = "PLAYER 1" if score1 >= WINNING_SCORE else "PLAYER 2"
	final_score = "%d - %d" % [score1, score2]
	if has_node("/root/GameState"):
		difficulty = get_node("/root/GameState").difficulty_name
	var game_over_label = $GameOverLabel
	if game_over_label:
		game_over_label.text = "%s WINS!\n%s\nDifficulty: %s\n\nPress SPACE to restart\nPress ESC for menu" % [winner, final_score, difficulty]
		game_over_label.visible = true
	ball_velocity = Vector2.ZERO

func get_score_points(combo: int) -> int:
	if combo >= 8: return 3
	elif combo >= 5: return 2
	return 1

func reset_ball() -> void:
	ball_position = Vector2(400.0, 300.0)
	ball_base_speed = BALL_INITIAL_SPEED
	ball_speed_override = 0.0
	var sign_x = 1.0 if randf() > 0.5 else -1.0
	var sign_y = 1.0 if randf() > 0.5 else -1.0
	ball_velocity = Vector2(BALL_INITIAL_SPEED * sign_x, BALL_INITIAL_SPEED * sign_y)

# ============================================
# PARTICLES
# ============================================
func _spawn_hit_particles(pos: Vector2, color: Color, count: int) -> void:
	for i in range(count):
		_spawn_single_particle(pos, color, 3.0 + randf() * 4.0)

func _spawn_score_particles(pos: Vector2, color: Color, count: int) -> void:
	for i in range(count):
		_spawn_single_particle(pos, color, 5.0 + randf() * 6.0)

func _spawn_single_particle(pos: Vector2, color: Color, speed: float) -> void:
	var slot = _find_free_particle_slot()
	var angle = randf() * 2.0 * PI
	particle_x[slot] = pos.x
	particle_y[slot] = pos.y
	particle_vel_x[slot] = cos(angle) * speed * 50.0
	particle_vel_y[slot] = sin(angle) * speed * 50.0
	particle_life[slot] = 0.4 + randf() * 0.4
	particle_size[slot] = 4.0 + randf() * 4.0
	particle_color[slot] = color

func _find_free_particle_slot() -> int:
	for i in range(MAX_PARTICLES):
		if particle_life[i] <= 0:
			return i
	return 0

# ============================================
# POWER-UPS
# ============================================
func _spawn_powerup() -> void:
	var types = POWERUP_CONFIG.keys()
	powerup_type = types[randi() % types.size()]
	powerup_position = Vector2(250.0 + randf() * 300.0, 150.0 + randf() * 300.0)
	powerup_active = true
	powerup_timer = 0.0
	powerup_pulse = 1.0
	powerup_spawn_timer = 0.0

func _collect_powerup() -> void:
	powerup_sound.play()
	ball_base_speed = ball_velocity.length()  # Remember current speed
	match powerup_type:
		"speed_up":
			ball_velocity = ball_velocity.normalized() * (ball_base_speed * 1.5)
		"slow":
			ball_speed_override = 8.0  # Slow for 8 seconds
			ball_velocity = ball_velocity.normalized() * (ball_base_speed * 0.55)
		"grow_left":
			pad1_height = 160.0
		"shrink_right":
			pad2_height = 50.0
		"shrink_ai":
			pad2_height = 60.0
		"big_ball":
			ball_radius = 18.0
	_spawn_powerup_particles(powerup_position)
	powerup_active = false

func _spawn_powerup_particles(pos: Vector2) -> void:
	for i in range(12):
		_spawn_single_particle(pos, COLOR_POWERUP, 8.0 + randf() * 4.0)

func _reset_powerup_effects() -> void:
	pad1_height = 100.0
	pad2_height = 100.0
	ball_radius = 10.0
	powerup_active = false

# ============================================
# RENDERING
# ============================================
func _draw() -> void:
	var shake_offset = Vector2(
		randf() * screen_shake - screen_shake * 0.5,
		randf() * screen_shake - screen_shake * 0.5
	)
	
	_draw_background(shake_offset)
	_draw_center_line(shake_offset)
	_draw_particles(shake_offset)
	_draw_powerup(shake_offset)
	_draw_ball(shake_offset)
	_draw_paddles(shake_offset)
	_draw_score(shake_offset)
	_draw_combo_text()
	_draw_scanline_overlay()

func _draw_background(shake: Vector2) -> void:
	# Dark background with gradient feel
	draw_rect(Rect2(shake, SCREEN_SIZE), COLOR_BG)
	
	# Subtle grid
	for i in range(0, 600, 40):
		var alpha = 0.1 + 0.05 * sin(time_elapsed + i * 0.01)
		draw_rect(Rect2(shake + Vector2(0, i), Vector2(800, 1)), Color(0.1, 0.2, 0.4, alpha))
	for i in range(0, 800, 40):
		var alpha = 0.1 + 0.05 * sin(time_elapsed + i * 0.01)
		draw_rect(Rect2(shake + Vector2(i, 0), Vector2(1, 600)), Color(0.1, 0.2, 0.4, alpha))

func _draw_center_line(shake: Vector2) -> void:
	# Glowing center line
	var line_pos = Vector2(400.0, 0.0) + shake
	for i in range(0, 600, 20):
		var pulse = 0.4 + 0.2 * sin(time_elapsed * 2.0 + i * 0.05)
		draw_rect(Rect2(line_pos + Vector2(-2, i + 5), Vector2(4, 10)), 
		         Color(0.3, 0.5, 0.8, pulse))

func _draw_center_circle(shake: Vector2) -> void:
	# Center circle glow
	var center = Vector2(400, 300) + shake
	var pulse = 0.5 + 0.2 * sin(time_elapsed * 1.5)
	draw_circle(center, 60, Color(0.15, 0.35, 0.6, pulse * 0.2))
	draw_circle(center, 50, Color(0.15, 0.35, 0.6, pulse * 0.3))
	draw_arc(center, 50, 0, 2 * PI, 32, Color(0.3, 0.5, 0.8, pulse * 0.5), 2.0, true)

func _draw_particles(shake: Vector2) -> void:
	for i in range(MAX_PARTICLES):
		if particle_life[i] > 0:
			var alpha = particle_life[i] / 0.8
			var col = particle_color[i]
			var pos = Vector2(particle_x[i], particle_y[i]) + shake
			
			# Glow
			draw_circle(pos, particle_size[i] * 2.0 * alpha, 
			           Color(col.r, col.g, col.b, alpha * 0.3))
			# Core
			draw_circle(pos, particle_size[i] * alpha, 
			           Color(col.r, col.g, col.b, alpha))

func _draw_powerup(shake: Vector2) -> void:
	if not powerup_active:
		return
	
	var config = POWERUP_CONFIG[powerup_type]
	var col = config["color"]
	var pos = powerup_position + shake
	
	# Outer pulsing glow
	var outer_size = powerup_radius * (2.0 + powerup_pulse * 0.5)
	draw_circle(pos, outer_size, Color(col.r, col.g, col.b, 0.15))
	draw_circle(pos, outer_size * 0.7, Color(col.r, col.g, col.b, 0.2))
	
	# Inner glow
	draw_circle(pos, powerup_radius * 1.3, Color(col.r, col.g, col.b, 0.4))
	
	# Core
	draw_circle(pos, powerup_radius, col)
	
	# Sparkle effect
	var sparkle = sin(time_elapsed * 8.0) * 0.5 + 0.5
	draw_circle(pos, powerup_radius * 0.5, Color(1.0, 1.0, 1.0, sparkle * 0.8))

func _draw_ball(shake: Vector2) -> void:
	var pos = ball_position + shake
	var glow = glow_intensity
	
	# Outer glow layers
	draw_circle(pos, ball_radius * 3.0 * glow, Color(0.0, 0.6, 0.5, 0.1))
	draw_circle(pos, ball_radius * 2.2 * glow, Color(0.0, 0.8, 0.7, 0.15))
	draw_circle(pos, ball_radius * 1.6 * glow, Color(0.0, 1.0, 0.9, 0.2))
	
	# Trail effect (motion blur)
	var trail_dir = -ball_velocity.normalized() * 0.5
	for j in range(3):
		var trail_pos = pos + trail_dir * (j + 1) * 3
		var trail_alpha = 0.15 - j * 0.05
		var trail_size = ball_radius * (1.0 - j * 0.2)
		draw_circle(trail_pos, trail_size, Color(0.0, 0.9, 0.8, trail_alpha))
	
	# Core
	draw_circle(pos, ball_radius, COLOR_BALL_CORE)
	
	# Highlight
	draw_circle(pos + Vector2(-3, -3), ball_radius * 0.4, Color(1.0, 1.0, 1.0, 0.6))

func _draw_paddles(shake: Vector2) -> void:
	# Paddle 1 (left) - cyan/blue
	_draw_paddle_advanced(10.0, pad1_pos.y, pad1_height, COLOR_PAD1_CORE, COLOR_PAD1_GLOW, shake)
	
	# Paddle 2 (right) - magenta/pink
	_draw_paddle_advanced(770.0, pad2_pos.y, pad2_height, COLOR_PAD2_CORE, COLOR_PAD2_GLOW, shake)

func _draw_paddle_advanced(x: float, y: float, height: float, core: Color, glow: Color, shake: Vector2) -> void:
	var pos = Vector2(x, y) + shake
	var rect = Rect2(pos.x, pos.y - height * 0.5, 20, height)
	
	# Outer glow
	draw_rect(rect.grow(8), Color(glow.r, glow.g, glow.b, 0.15))
	draw_rect(rect.grow(4), Color(glow.r, glow.g, glow.b, 0.25))
	
	# Inner glow
	draw_rect(rect.grow(2), Color(glow.r, glow.g, glow.b, 0.4))
	
	# Core
	draw_rect(rect, core)
	
	# Highlight edge
	draw_rect(Rect2(rect.position, Vector2(3, rect.size.y)), Color(1.0, 1.0, 1.0, 0.3))

func _draw_score(shake: Vector2) -> void:
	# Player 1 score (left) - cyan dots
	for i in range(score1):
		var dot_pos = Vector2(100 + i * 25, 30) + shake
		var pulse = 0.8 + 0.2 * sin(time_elapsed * 2.0 + i * 0.3)
		draw_circle(dot_pos, 12 * pulse, Color(COLOR_PAD1_CORE.r, COLOR_PAD1_CORE.g, COLOR_PAD1_CORE.b, 0.2))
		draw_circle(dot_pos, 8 * pulse, Color(COLOR_PAD1_CORE.r, COLOR_PAD1_CORE.g, COLOR_PAD1_CORE.b, 0.5))
		draw_circle(dot_pos, 5, COLOR_PAD1_CORE)
	
	# Player 2 score (right) - magenta dots
	for i in range(score2):
		var dot_pos = Vector2(700 - i * 25, 30) + shake
		var pulse = 0.8 + 0.2 * sin(time_elapsed * 2.0 + i * 0.3)
		draw_circle(dot_pos, 12 * pulse, Color(COLOR_PAD2_CORE.r, COLOR_PAD2_CORE.g, COLOR_PAD2_CORE.b, 0.2))
		draw_circle(dot_pos, 8 * pulse, Color(COLOR_PAD2_CORE.r, COLOR_PAD2_CORE.g, COLOR_PAD2_CORE.b, 0.5))
		draw_circle(dot_pos, 5, COLOR_PAD2_CORE)

func _draw_combo_text() -> void:
	var combo_label = $ComboLabel
	if combo_label:
		if combo_display > 1:
			combo_label.visible = true
			var pts = get_score_points(combo_display)
			var txt = "x" + str(combo_display)
			if pts > 1:
				txt = "%s [%dP]" % [txt, pts]
			combo_label.text = txt
		else:
			combo_label.visible = false

func _draw_scanline_overlay() -> void:
	# Subtle vignette effect
	var center = SCREEN_SIZE * 0.5
	var corner_dist = center.length()
	
	for i in range(10):
		var t = i / 10.0
		var alpha = t * t * 0.15
		var size = SCREEN_SIZE.length() * (1.0 - t * 0.3)
		var rect = Rect2(center - Vector2(size * 0.5, size * 0.375), Vector2(size, size * 0.75))
		# Just a subtle corner darkening - we skip actual drawing for performance
		# Real scanlines would be done via shader on a fullscreen quad