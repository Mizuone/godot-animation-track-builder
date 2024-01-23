extends CharacterBody3D

const SENSITIVITY = 0.0016

var speed = 5

@export var WALK_SPEED = 5
@export var JUMP_VELOCITY = 4.5
@export var AIR_CONTROL_AMOUNT = 10.0

const BASE_FOV = 75.0
const FOV_CHANGE = 1.5

@onready var camera: Camera3D = $Camera3D

@onready var mesh = camera.get_node("Mesh")
@onready var animation_player: AnimationPlayer = mesh.get_node("AnimationPlayer")
@onready var m230_pistol: Pistol = mesh.get_node("root/Skeleton3D/Weapon_Bone/Attachment/M230_Pistol")

@onready var player_animation_tree: AnimationTree = $PlayerAnimationTree

var gravity = ProjectSettings.get_setting("physics/3d/default_gravity")
var path_to_player_node: NodePath = ""

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED);

	var animation_player_root_node = animation_player.get_parent()

	path_to_player_node = animation_player_root_node.get_path_to(self)

	setup_pistol_track_events()

func _physics_process(_delta):
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	if Input.is_action_just_pressed("escape"):
		get_tree().quit()

	if Input.is_action_just_pressed("reload"):
		if !reload_animation_playing() && m230_pistol.get_ready_to_fire():
			play_reload_animation()

func _process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("fire"):
		if m230_pistol.get_ready_to_fire():
			m230_pistol.fire()
			play_fire_animation()

	update_velocity_with_basis(transform.basis, is_on_floor(), delta)

	move_and_slide()

func update_velocity_with_basis(entity_basis: Basis, on_floor: bool, delta: float):
	var input_dir = Input.get_vector("left", "right", "forward", "backward")
	var direction = (entity_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if on_floor:
		if direction:
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = lerp(velocity.x, direction.x * speed, delta * AIR_CONTROL_AMOUNT)
			velocity.z = lerp(velocity.z, direction.z * speed, delta * AIR_CONTROL_AMOUNT)
	else:
		var air_control_speed = speed / 2 + WALK_SPEED

		velocity.x = lerp(velocity.x, direction.x * air_control_speed, delta * AIR_CONTROL_AMOUNT)
		velocity.z = lerp(velocity.z, direction.z * air_control_speed, delta * AIR_CONTROL_AMOUNT)

func _input(event):
	if event is InputEventMouseMotion:
		camera_rotation(event.relative)


func camera_rotation(event: Vector2):
	rotate_y(-event.x * SENSITIVITY)
	camera.rotate_x(-event.y * SENSITIVITY)

	camera.rotation.x = clampf(camera.rotation.x, -deg_to_rad(90), deg_to_rad(90))


######### Animation Player Track Builder Methods #########
func setup_pistol_track_events():
	const WIELD_PISTOL_FIRE = "Wield_Pistol_Fire"
	const WIELD_PISTOL_RELOAD = "Wield_Pistol_Reload"

	var wield_pistol_fire: Animation = animation_player.get_animation(WIELD_PISTOL_FIRE)
	var wield_pistol_reload: Animation = animation_player.get_animation(WIELD_PISTOL_RELOAD)

	track_builder(wield_pistol_fire, path_to_player_node, wield_pistol_fire.length - .2, track_key_details("ready_to_fire", []))
	track_builder(wield_pistol_reload, path_to_player_node, wield_pistol_reload.length - .2, track_key_details("reload_revolver", []))

func track_key_details(method_name: String, method_arguments):
	return { "method": method_name, "args": method_arguments, }

func track_builder(animation: Animation, path_to_node: NodePath, timestamp: float, track_details):
	var animation_track = animation.add_track(Animation.TYPE_METHOD)

	animation.track_set_path(animation_track, path_to_node)
	animation.track_insert_key(animation_track, timestamp, track_details)

##########################################################################

## Animation Track Methods ############
func ready_to_fire():
	m230_pistol.fire_finished()

func reload_revolver():
	m230_pistol.reload_finished()
##########################################################################

func play_fire_animation():
	player_animation_tree["parameters/fire/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE

func play_reload_animation():
	player_animation_tree["parameters/reload/request"] = AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE

func reload_animation_playing():
	return player_animation_tree.get("parameters/reload/active")