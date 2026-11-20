
extends CharacterBody2D

# Camera
@onready var player_camera: Camera2D = $Camera2D
# Spawn
var respawn_position: Vector2

# Movement
const MAX_SPEED: float = 500
const ACCELERATION: float = 800
const DECELERATION: float = 1250
const TURN_ACCELERATION: float = 2000

var facing_direction: float = 1.0

# Jumping
const JUMP_VELOCITY: float = 600
const JUMP_CUT_MULTIPLIER: float = 0.5
const COYOTE_TIME: float = 0.12
const JUMP_BUFFER: float = 0.1
const FALL_GRAVITY_MULTIPLIER: float = 1.5

var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0

# Wall movement
const WALL_SLIDE_SPEED: float = 100.0
const WALL_JUMP_VELOCITY: float = 450.0
const WALL_JUMP_PUSH: float = 350.0
const WALL_COYOTE_TIME: float = 0.12

var wall_coyote_timer: float = 0.0
var last_wall_direction: float = 0.0

# Dashing
const DASH_SPEED: float = 950
const DASH_DURATION: float = 0.3
const DASH_COOLDOWN: float = 1.0
var dash_direction: Vector2 = Vector2.ZERO
var dash_timer: float = 0.0
var dash_cooldown_timer: float = 0.0
var can_dash: bool = true
const DASH_BUFFER: float = 0.5
const DASH_END_UPWARD_SPEED: float = 250.0
var dash_buffer_timer: float = 0.0


func _physics_process(delta: float) -> void:
	update_jump_buffer(delta)
	handle_dash(delta)
	handle_horizontal_movement(delta)
	handle_wall_slide()
	update_coyote_time(delta)
	update_wall_coyote_time(delta)
	apply_gravity(delta)
	handle_jumping()
	handle_jump_cut()
	move_and_slide()
	check_spike_collision()
	out_of_bounds()
	
func _ready() -> void:
	respawn_position = global_position
# --------------------
# HORIZONTAL MOVEMENT
# --------------------
func handle_horizontal_movement(delta: float) -> void:
	if dash_timer > 0.0:
		return

	if Input.is_action_pressed("right"):
		facing_direction = 1.0

		if velocity.x < 0:
			velocity.x = move_toward(
				velocity.x, MAX_SPEED, TURN_ACCELERATION * delta
			)
		else:
			velocity.x = move_toward(
				velocity.x, MAX_SPEED, ACCELERATION * delta
			)

	elif Input.is_action_pressed("left"):
		facing_direction = -1.0

		if velocity.x > 0:
			velocity.x = move_toward(
				velocity.x, -MAX_SPEED, TURN_ACCELERATION * delta
			)
		else:
			velocity.x = move_toward(
				velocity.x, -MAX_SPEED, ACCELERATION * delta
			)

	else:
		velocity.x = move_toward(
			velocity.x, 0, DECELERATION * delta
		)


# --------------------
# DASHING
# --------------------


func handle_dash(delta: float) -> void:
	# Dash cooldown
	dash_cooldown_timer = max(dash_cooldown_timer - delta, 0.0)

	# Remember dash input
	if Input.is_action_just_pressed("dash"):
		dash_buffer_timer = DASH_BUFFER
	else:
		dash_buffer_timer = max(dash_buffer_timer - delta, 0.0)

	# Continue active dash
	if dash_timer > 0.0:
		dash_timer = max(dash_timer - delta, 0.0)

		if dash_timer <= 0.0:
			# Limit momentum in the dash direction
			if dash_direction.x != 0.0:
				velocity.x = clampf(
					velocity.x,
					min(0.0, dash_direction.x * DASH_END_UPWARD_SPEED),
					max(0.0, dash_direction.x * DASH_END_UPWARD_SPEED)
				)

			if dash_direction.y != 0.0:
				velocity.y = clampf(
					velocity.y,
					min(0.0, dash_direction.y * DASH_END_UPWARD_SPEED),
					max(0.0, dash_direction.y * DASH_END_UPWARD_SPEED)
				)

		return

	# Start buffered dash when available
	if dash_buffer_timer > 0.0 and can_dash and dash_cooldown_timer <= 0.0 and velocity.y >= 0.0:
		can_dash = false
		dash_timer = DASH_DURATION
		dash_cooldown_timer = DASH_COOLDOWN
		dash_buffer_timer = 0.0

		dash_direction = Input.get_vector("left", "right", "up", "down")

		if dash_direction == Vector2.ZERO:
			if is_on_wall() and not is_on_floor():
				dash_direction = Vector2(get_wall_normal().x, 0.0)
			else:
				dash_direction = Vector2(facing_direction, 0.0)

		dash_direction = dash_direction.normalized()
		velocity = dash_direction * DASH_SPEED

# --------------------
# WALL SLIDING
# --------------------

func is_wall_jumpable() -> bool:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		if abs(collision.get_normal().x) == 1:
			var collider = collision.get_collider()
			if collider is TileMapLayer:
				if collider.is_in_group("jumpable_walls"):
					return true
	return false

func handle_wall_slide() -> void:
	if is_on_wall() and not is_on_floor() and velocity.y > 0 and -get_wall_normal().x == Input.get_axis("left", "left") and is_wall_jumpable():
		velocity.y = min(velocity.y, WALL_SLIDE_SPEED)


# --------------------
# COYOTE TIME
# --------------------

func update_coyote_time(delta: float) -> void:
	if dash_timer > 0.0:
		return
	if is_on_floor():
		coyote_timer = COYOTE_TIME
		can_dash = true
	else:
		coyote_timer = max(coyote_timer - delta, 0.0)


# --------------------
# WALL COYOTE TIME
# --------------------

func update_wall_coyote_time(delta: float) -> void:
	if dash_timer > 0.0:
		return
	if is_on_wall() and not is_on_floor() and is_wall_jumpable():
		last_wall_direction = get_wall_normal().x
		wall_coyote_timer = WALL_COYOTE_TIME

		dash_cooldown_timer = 0.0
		can_dash = true
	else:
		wall_coyote_timer = max(wall_coyote_timer - delta, 0.0)


# --------------------
# GRAVITY
# --------------------

func apply_gravity(delta: float) -> void:
	if not is_on_floor() and dash_timer <= 0.0:
		if velocity.y > 0:
			velocity.y += get_gravity().y * delta * FALL_GRAVITY_MULTIPLIER
		else:
			velocity.y += get_gravity().y * delta


# --------------------
# JUMP BUFFER
# --------------------

func update_jump_buffer(delta: float) -> void:
	if not Input.is_action_just_pressed("up"):
		jump_buffer_timer = max(jump_buffer_timer - delta, 0.0)


# --------------------
# JUMPING AND WALL JUMPING
# --------------------

func handle_jumping() -> void:
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = JUMP_BUFFER

	if wall_coyote_timer > 0 and not is_on_floor() and jump_buffer_timer > 0:
		velocity.y = -WALL_JUMP_VELOCITY
		velocity.x = last_wall_direction * WALL_JUMP_PUSH

		if not Input.is_action_pressed("ui_accept") and dash_timer <= 0.0:
			velocity.y = -WALL_JUMP_VELOCITY * JUMP_CUT_MULTIPLIER

		wall_coyote_timer = 0
		jump_buffer_timer = 0

	elif coyote_timer > 0 and jump_buffer_timer > 0:
		coyote_timer = 0
		jump_buffer_timer = 0

		velocity.y = -JUMP_VELOCITY

		if not Input.is_action_pressed("ui_accept"):
			velocity.y = -JUMP_VELOCITY * JUMP_CUT_MULTIPLIER


# --------------------
# VARIABLE JUMP HEIGHT
# --------------------

func handle_jump_cut() -> void:
	if Input.is_action_just_released("ui_accept"):
		if velocity.y < 0:
			velocity.y *= JUMP_CUT_MULTIPLIER

# --------------------
# HAZARDS
# --------------------
func check_spike_collision() -> void:
	for i in range(get_slide_collision_count()):
		var collision = get_slide_collision(i)
		var collider = collision.get_collider()

		if collider is TileMapLayer and collider.is_in_group("spikes"):
			respawn()
			return
	#---------------------
# RESPAWNING
#---------------------
func respawn() -> void:
	global_position = respawn_position
	velocity = Vector2.ZERO
	dash_timer = 0

func out_of_bounds() -> void:
	if global_position.y >= 4000:
		respawn()

func _on_spike_body_entered(body: Node2D) -> void:
	if body == self:
		respawn()
	else:
		pass


func _on_spike_2_body_entered(body: Node2D) -> void:
	if body == self:
		respawn()
	else:
		pass
