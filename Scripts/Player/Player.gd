extends CharacterBody3D

var speed
const WALK_SPEED = 5.0
const SPRINT_SPEED = 8.0
var isRunning = false
const JUMP_VELOCITY = 4.5
const MAX_VIEW_ANGLE = 60
const MIN_VIEW_ANGLE = -45
@export var SENSITIVITY_VERTICAL = 0.01
@export var SENSITIVITY_HORIZONTAL = 0.5
var inGame = true

#only for "PlayerTest" model
const HEAD_WALKING = Vector3(-0.02, 1.656, -0.196)
const HEAD_RUNNING = Vector3(-0.02, 1.59, -0.36)

# Bobbing variables
const BOB_FREQ = 2.0
const BOB_AMP = 0.08
# variable passed to the sine function determine how far along the sine wave the camera is at any given moment
var t_bob = 0.0

# FOV variables
const BASE_FOV = 75
const FOV_CHANGE = 1.5

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")

@onready var head = $Head
@onready var camera = $Head/Camera3D
@onready var animation_player = $visuals/model/AnimationPlayer

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

# function called every time up where the player does anything like press a button or move the mouse
func _unhandled_input(event):
	if Input.is_action_just_pressed("ui_escape"):
		inGame = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	if Input.is_action_just_pressed("ui_accept"):
		inGame = true
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# check if the event is a mouse motion event
	if event is InputEventMouseMotion && inGame == true:
		# change the rotation of the head depending on how much the mouse moved relatively multiplied by the sensitivity
		#head.rotate_y(-event.relative.x * SENSITIVITY_HORIZONTAL)
		rotate_y(deg_to_rad(-event.relative.x * SENSITIVITY_HORIZONTAL))
		camera.rotate_x(-event.relative.y * SENSITIVITY_VERTICAL)
		# the clamp function limit the rotation of the camera to a minimum and a maximum value
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(MIN_VIEW_ANGLE), deg_to_rad(MAX_VIEW_ANGLE))

func _physics_process(delta):
	# Add the gravity.
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle Jump.
	"""
	if Input.is_action_just_pressed("ui_jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	"""
	
	# Handle player sprint
	if Input.is_action_pressed("sprint"):
		speed = SPRINT_SPEED
		isRunning = true
	else:
		speed = WALK_SPEED
		isRunning = false

	# Get the input direction and handle the movement/deceleration.
	var input_dir = Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	# the direction is based on where the head is direct
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if is_on_floor():
		if direction:
			if animation_player.current_animation != "walking" || animation_player.current_animation != "running":
				if isRunning == true:
					animation_player.play("running")
					head.position = HEAD_RUNNING
				else:
					animation_player.play("walking")
					head.position = HEAD_WALKING
			
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			if animation_player.current_animation != "idle":
				animation_player.play("idle")
			
			velocity.x = 0.0
			velocity.z = 0.0
	else:
		# lerp change the speed incrementially
		# lerp( init velocity, target velocity, decimal percentage between the two variables )
		velocity.x = lerp(velocity.x, direction.x * speed, delta * 2.0)
		velocity.z = lerp(velocity.z, direction.z * speed, delta * 2.0)
	
	# Head Bobbing
	t_bob += delta * velocity.length() * float(is_on_floor())
	camera.transform.origin = _headbob(t_bob)
	
	# FOV
	# it is necessary to make sure that fov doesn't go too crazy when the player is falling
	var velocity_clampled = clamp(velocity.length(), 0.5, SPRINT_SPEED * 2)
	var target_fov = BASE_FOV + FOV_CHANGE * velocity_clampled
	camera.fov = lerp(camera.fov, target_fov, delta * 8.0)

	move_and_slide()

func _headbob(time) -> Vector3:
	var pos = Vector3.ZERO
	pos.y = sin(time * BOB_FREQ) * BOB_AMP
	pos.x = cos(time * BOB_FREQ / 2) * BOB_AMP
	return pos
