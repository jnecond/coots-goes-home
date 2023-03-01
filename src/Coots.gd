extends KinematicBody2D;

const LEFT  : int = -1;
const RIGHT : int =  1;
const UP    : int = -1;
const DOWN  : int =  1;

var state : int = 0;
var state_frame : int = 0;
var gravity  = Vector2(0, 4.0);
var velocity = Vector2(0, 0);
var velocity_prev = Vector2(0, 0);
var wall_dir : int = 0;
var grounded : int = 0;

func move():
	velocity_prev = velocity;
	velocity += gravity;
	if (velocity.y > 600.0): 
		velocity.y = 600.0;
	velocity = move_and_slide(velocity, Vector2.UP, true);
	grounded = is_on_floor();
	if (!velocity.x):
		if (velocity_prev.x < -1):
			wall_dir = LEFT;
		elif (velocity_prev.x > 1):
			wall_dir = RIGHT;
		elif (velocity.y):
			wall_dir = 0;
	else:
		wall_dir = 0;



enum {
	COOTS_IDLE,
	COOTS_WALK,
	COOTS_JUMP,
	COOTS_FALL,
	COOTS_DOWNKICK,
	COOTS_AIRTUMBLE,
	COOTS_AIRTUMBLE_BOUNCE,
	COOTS_DIVE,
	COOTS_SLIDE,
	COOTS_GAINER,
	COOTS_DEAD,
	COOTS_FROZEN,
	COOTS_STATE_COUNT
};
var state_str = [
	"COOTS_IDLE",
	"COOTS_WALK",
	"COOTS_JUMP",
	"COOTS_FALL",
	"COOTS_DOWNKICK",
	"COOTS_AIRTUMBLE",
	"COOTS_AIRTUMBLE_BOUNCE",
	"COOTS_DIVE",
	"COOTS_SLIDE",
	"COOTS_GAINER",
	"COOTS_DEAD",
	"COOTS_FROZEN",
];
onready var sprites = [
	$Sprite_idle,
	$Sprite_walk,
	$Sprite_jump_fall_land,
	$Sprite_jump_fall_land,
	$Sprite_jump_fall_land,
	$Sprite_airtumble,
	$Sprite_airtumble,
	$Sprite_dive_slide,
	$Sprite_dive_slide,
	$Sprite_jump_fall_land,
	$Sprite_dead,
	null,
];

onready var map = get_node("../TileMap");
var map_rect : Rect2;
onready var collider = $CollisionShape2D
onready var camera = $Camera2D



func advance_sprite() -> int:
	if (sprites[state].frame < sprites[state].hframes-1):
		sprites[state].frame += 1
		return 0
	else:
		sprites[state].frame = 0
		return 1

func get_flip() -> int:
	return sprites[state].scale.x

func set_flip():
	if (horizontal):
		sprites[state].scale.x = horizontal;

var prev_state = COOTS_IDLE;
func change_state(new_state) -> int:
	if (state == new_state):
		return 0;
	sprites[new_state].scale.x = sprites[state].scale.x
	prev_state = state
	sprites[state].visible = 0
	sprites[new_state].visible = 1
	state = new_state
	state_frame = 0
	match (state):
		COOTS_FALL: sprites[state].frame = 2
		COOTS_DOWNKICK: sprites[state].frame = 3
		COOTS_SLIDE: sprites[state].frame = 2
		_: sprites[state].frame = 0
	return 1;



const air_control_vel 	: int 	=  80;
const walk_vel 			: int 	=  100;
const jump_vel 			: int 	= -240;
const airtumble_vel		: int 	=  200;
const airtumble_vel_y	: int 	= -180;
const gainer_vel_x		: int 	=  60;
const gainer_vel_y		: int 	= -320;
const slide_vel			: int 	=  222;
const slide_start_frame : int 	=  1;
const slide_end_frame   : int 	=  110;
const slide_stop_frame  : int 	=  123;
const coyote_frames     : int 	=  10;

var jump_height_gain	: bool 	= 0;
var can_airtumble		: bool 	= 1;
var can_dive			: bool 	= 1;
var can_gainer			: bool 	= 1;
var need_jump			: bool 	= 1;
var need_attack			: bool 	= 1;

var horizontal			: int 	= 0;
var vertical			: int 	= 0;

var coyote				: int 	= 0;


func allow_airmoves():
	can_airtumble = 1;
	can_dive = 1;
	can_gainer = 1;

func start_idle():
	var landing = 0;
	if (state == COOTS_FALL || state == COOTS_DOWNKICK || state == COOTS_DIVE):
		landing = state
	change_state(COOTS_IDLE);
	if (landing):
		sprites[state].visible = 0
		sprites[COOTS_FALL].visible = 1
		sprites[COOTS_FALL].frame = 4
		if (landing == COOTS_DIVE):
			sprites[COOTS_FALL].frame = 5
		Global.snd_landing.play();

func start_walk():
	set_flip();
	change_state(COOTS_WALK);

func start_jump():
	change_state(COOTS_JUMP);
	jump_height_gain = 1
	need_jump = 0
	need_attack = 0
	if (!Global.snd_landing.playing):
		Global.snd_jump.play();


func start_fall():
	change_state(COOTS_FALL);

func start_airtumble():
	set_flip();
	change_state(COOTS_AIRTUMBLE);
	can_airtumble = 0
	need_jump = 0
	need_attack = 0
	sprites[state].frame = 1;


func start_airtumble_bounce():
	var flip : int = get_flip();
	change_state(COOTS_AIRTUMBLE_BOUNCE);
	sprites[COOTS_AIRTUMBLE_BOUNCE].scale.x = -flip;
	velocity.y = airtumble_vel_y;
	state_frame = 0
	allow_airmoves();
	if (Global.snd_airtumble.playing):
		var sec = Global.snd_airtumble.get_playback_position();
		if (sec > 0.3):
			Global.snd_jump.play();
	else:
		Global.snd_jump.play();


func start_dive():
	set_flip();
	change_state(COOTS_DIVE);
	velocity.y = velocity.y*2/3;
	can_dive = 0
	need_attack = 0
	need_jump = 0

func start_slide():
	set_flip();
	change_state(COOTS_SLIDE);
	need_jump = 0
	need_attack = 0
	velocity = Vector2.ZERO
	state_frame = 0

func start_gainer():
	set_flip();
	change_state(COOTS_GAINER);
	need_jump = 0
	need_attack = 0
	can_gainer = 0
	sprites[state].rotation_degrees = 0;
	velocity.y = gainer_vel_y;
	Global.snd_gainer.play();

func slide_sound():
	if (Global.piano_vol_db != Global.vol_disabled):
		Global.snd_slide2.play();
	else:
		Global.snd_slide.play();
	

func instaslide():
	change_state(COOTS_SLIDE);
	need_jump = 0
	need_attack = 0
	velocity.x = get_flip() * slide_vel
	state_frame = slide_start_frame
	slide_sound();
	


func start_downkick():
	change_state(COOTS_DOWNKICK)
	velocity.x = 0
	if (velocity.y < 100): velocity.y = 100


func air_control():
	if (!Global.allow_input):
		return;
	velocity.x = horizontal * air_control_vel;


func idle_fall_walk_inputs_2() -> int: 
	if (!Global.allow_input):
		if (grounded):
			start_idle();
		else:
			start_fall();
		return 0;

	if (grounded):
		if (need_attack):
			need_attack = 0;
			need_jump = 0;
			set_flip();
			start_slide();
			return state;
		if (need_jump):
			start_jump();
			return state;
		if (vertical == DOWN):
			set_flip();
			start_idle();
			return 0;
		elif (horizontal && horizontal != wall_dir):
			start_walk();
			return state;
		else:
			start_idle();
			return 0;
	else: #falling
		if (coyote > 0 && need_jump):
			start_jump();
			return state;
		if (can_gainer && need_jump):
			start_gainer();
			return state;
		if (can_dive && need_attack && vertical == DOWN):
			start_dive();
			return state;
		if (can_airtumble && need_attack):
			need_attack = 0;
			need_jump = 0;
			start_airtumble();
			return state;
		if (vertical == DOWN && !horizontal):
			start_downkick();
			return state;
		start_fall();
		return 0;
	return 0;


func idle_fall_walk_inputs() -> int: 
	if (!Global.allow_input):
		if (grounded):
			start_idle();
		else:
			start_fall();
		return 0;
	if (can_gainer && need_attack && vertical == UP):
		start_gainer();
		return state;
	if (grounded):
		if (vertical == DOWN && need_jump):
			set_flip();
			start_slide();
			return state;
		if (need_jump):
			start_jump();
			return state;
		if (vertical == DOWN):
			set_flip();
			start_idle();
			return 0;
		elif (horizontal && horizontal != wall_dir):
			start_walk();
			return state;
		else:
			start_idle();
			return 0;
	else: #falling
		if (coyote > 0 && need_jump):
			start_jump();
			return state;
		if (can_airtumble && need_jump):
			start_airtumble();
			return state;
		if (can_dive && need_attack && vertical != UP):
			start_dive();
			return state;
		if (vertical == DOWN && !horizontal):
			start_downkick();
			return state;
		start_fall();
		return 0;
	return 0;


func inputs_to_action() -> int:
	match(Global.input_scheme):
		0: 
			return idle_fall_walk_inputs();
		1: 
			return idle_fall_walk_inputs_2();
	return idle_fall_walk_inputs();


func idle_frame():
	velocity.x = 0
	if (inputs_to_action()):
		if ((state < 2 || state > 4) && state != COOTS_GAINER):
			sprites[COOTS_FALL].visible = 0
		return;
	else:
		if (vertical == DOWN):
			sprites[COOTS_FALL].visible = 0
			sprites[state].visible = 1
		if (!(state_frame & 31)):
			if (sprites[COOTS_FALL].visible):
				if (sprites[COOTS_FALL].frame < 6):
					sprites[COOTS_FALL].frame += 1;
				else:
					sprites[COOTS_FALL].visible = 0
					sprites[state].visible = 1
					sprites[state].frame = 0
			else:
				advance_sprite();


func walk_frame():
	set_flip();
	if (inputs_to_action() != COOTS_WALK): 
		return;
	if (get_flip() == wall_dir):
		start_idle();
		return;
	velocity.x = get_flip() * walk_vel
	if (!(state_frame % 20)): 
		advance_sprite();
		match (sprites[state].frame):
			0:	Global.snd_step1.play();
			4:	Global.snd_step2.play();




func jump_inputs() -> int:
	if (Global.allow_input):
		match(Global.input_scheme):
			0:
				if (state_frame > 60 || !Input.is_action_pressed("jump")):
					jump_height_gain = 0;
					sprites[state].frame = 1;
				if (can_gainer && need_attack && vertical == UP):
					start_gainer();
					return 1;
				if (can_dive && need_attack):
					start_dive();
					return 1;
				if (can_airtumble && need_jump):
					start_airtumble();
					return 1;
			1:
				if (state_frame > 60 || !Input.is_action_pressed("jump")):
					jump_height_gain = 0;
					sprites[state].frame = 1;
				if (can_gainer && need_jump):
					start_gainer();
					return 1;
				if (can_dive && need_attack && vertical == DOWN):
					start_dive();
					return 1;
				if (can_airtumble && need_attack):
					start_airtumble();
					return 1;
	else:
		jump_height_gain = 0;
	return 0;


func jump_frame():
	set_flip();
	if (jump_inputs()):
		return;
	air_control();
	if (jump_height_gain):
		velocity.y = jump_vel - (jump_vel * state_frame / 250);
	if (velocity.y >= 0 && state_frame > 10):
		start_fall();
		return


func fall_frame():
	if (inputs_to_action()):
		return;
	if (state_frame > 700):
		die();
		return;
	air_control();
	set_flip()
	if (coyote > (coyote_frames>>1)):
		velocity.y = 1;
	if (velocity.y > 375):
		sprites[state].frame = 3


func airtumble_frame():
	velocity.y = 0
	gravity.y = 0
	if (!Global.allow_input || state_frame >= 144):
		start_fall();
		return;
	if (state_frame == 20):
		if (!Global.snd_airtumble.playing):
			Global.snd_airtumble.play();
	match(Global.input_scheme):
		0:
			if (!Input.is_action_pressed("jump")):
				start_fall();
				return;
		1:
			if (!Input.is_action_pressed("attack")):
				start_fall();
				return;
	if (!(state_frame % 11)):
		advance_sprite();
	velocity.x = airtumble_vel;
	if (get_flip() == -1):
		velocity.x = -velocity.x;
	if (wall_dir == get_flip()):
		start_airtumble_bounce();
		return;



func airtumble_bounce_frame():
	if(grounded && state_frame > 1):
		start_idle();
		return;
	if (!Global.allow_input || state_frame > 150):
		start_fall();
		return;
	match(Global.input_scheme):
			0:
				if (!Input.is_action_pressed("jump")):
					start_fall();
					return;
			1:
				if (!Input.is_action_pressed("attack")):
					start_fall();
					return;
	gravity.y = 2.0;
	if (wall_dir == get_flip() && state_frame > 1):
		start_airtumble_bounce();
		return;
	if (is_on_ceiling() && velocity.y < 0 && state_frame > 1):
		velocity.y = 0
	if (!(state_frame % 11)): 
		advance_sprite();
	velocity.x = get_flip() * (airtumble_vel - (airtumble_vel * state_frame / 300));




func dive_frame():
	if (grounded):
		if (!Global.allow_input):
			start_idle();
			return;
		match(Global.input_scheme):
			0:
				if (need_jump && Input.is_action_pressed("down")):
					instaslide();
					return;
			1:
				if (need_attack):
					instaslide();
					return;
		start_idle();
		return;
	match (state_frame):
		16: sprites[state].frame = 1
		32: sprites[state].frame = 2
		48: sprites[state].frame = 3
		64: sprites[state].frame = 2
		80: 
			start_idle();
			return;
	gravity.y = 5.0;
	velocity.x = get_flip() * 180;


func downkick_frame():
	if (grounded):
		start_idle();
		return;
	if (state_frame > 700):
		die();
		return;
	if (velocity.y < 300):
		gravity.y = 12.0 - velocity.y/45.0;
	else:
		gravity.y = 5;


func slide_frame():
	if (!grounded):
		sprites[COOTS_IDLE].visible = 0;
		start_fall();
		return;
	if (wall_dir == get_flip()):
		start_idle();
		return;
	if (!(state_frame & 15)):
		sprites[state].frame ^= 1;
	match(Global.input_scheme):
		0:
			if (!Input.is_action_pressed("jump") && state_frame < slide_end_frame):
				state_frame = slide_end_frame;
		1:
			if (!Input.is_action_pressed("attack") && state_frame < slide_end_frame):
				state_frame = slide_end_frame;

	if (state_frame >= slide_stop_frame):
		start_idle();
		return;
	elif (state_frame >= slide_end_frame):
		sprites[COOTS_SLIDE].visible = 0;
		sprites[COOTS_IDLE].visible = 1;
		velocity.x = get_flip() * slide_vel/2;
	elif (state_frame >= slide_start_frame):
		if (state_frame == slide_start_frame):
			slide_sound();
		sprites[COOTS_SLIDE].visible = 1;
		sprites[COOTS_IDLE].visible = 0;
		velocity.x = get_flip() * slide_vel;
		
	


func dead_frame():
	gravity.y = 0
	if (state_frame > 10 && sprites[state].visible && !(state_frame & 15)):
		velocity.x = 0
		velocity.y = 0
		if (advance_sprite()):
			sprites[state].visible = 0;
	return;


func gainer_frame():
	match (state_frame):
		30:
			sprites[state].frame = 1;
			sprites[state].rotation_degrees -= 30 * get_flip();
		60: 
			sprites[state].frame = 2;
			sprites[state].rotation_degrees -= 45 * get_flip();
		90:
			sprites[state].rotation_degrees = 0;
			start_fall();
			return;
	velocity.x = get_flip() * gainer_vel_x;
	if (!(state_frame & 15)):
		sprites[state].rotation_degrees -= 50 * get_flip();


func die():
	if (state != COOTS_DEAD):
		change_state(COOTS_DEAD);
		sprites[COOTS_JUMP].visible = 0
		sprites[COOTS_IDLE].visible = 0
		Global.death();
		velocity /= 3.0;
		Global.snd_death.play();


func frozen_frame():
	gravity.y = 0
	velocity.x = 0
	velocity.y = 0
	






const checkpoint_x = [
	0,
	44,
	44,
	50,
	66,
];




func _physics_process(_delta: float):
	move();
	if (grounded):
		coyote = coyote_frames;
	else:
		coyote -= 1;
	gravity.y = 4.0;
		
	var a : int = Input.is_action_pressed("right")
	var b : int = Input.is_action_pressed("left")
	horizontal = a-b;
	a = Input.is_action_pressed("down")
	b = Input.is_action_pressed("up")
	vertical = a-b;
	if (Input.is_action_just_pressed("jump")):
		need_jump = 1;
	if (Input.is_action_just_pressed("attack")):
		need_attack = 1;
	if (!Input.is_action_pressed("jump")):
		need_jump = 0;
	if (!Input.is_action_pressed("attack")):
		need_attack = 0;
	var prevstate = state;
	match(state):
		COOTS_IDLE: idle_frame();
		COOTS_WALK: walk_frame();
		COOTS_JUMP: jump_frame();
		COOTS_FALL: fall_frame();
		COOTS_AIRTUMBLE: airtumble_frame();
		COOTS_AIRTUMBLE_BOUNCE: airtumble_bounce_frame();
		COOTS_DIVE: dive_frame();
		COOTS_DOWNKICK: downkick_frame();
		COOTS_SLIDE: slide_frame();
		COOTS_GAINER: gainer_frame();
		COOTS_DEAD: dead_frame();
		COOTS_FROZEN: frozen_frame();
		_: print("coots: unknown state ", state);
	state_frame += 1;
	if (grounded):
		allow_airmoves();
	if (Global.state == 3): # IN GAME
		if (state != COOTS_FROZEN):
			map = get_node("../TileMap");
			var mypos = position + collider.position;
			var tile_coords = map.world_to_map(mypos - map.position);
			var tile_type = map.get_cellv(tile_coords);
			map_rect = map.get_used_rect();
			if (!Global.checkpoint):
				if (checkpoint_x[Global.level] && tile_coords.x >= checkpoint_x[Global.level]):
					Global.checkpoint = tile_coords;
					camera.limit_left  = tile_coords.x * 16 + map.position.x;
					camera.limit_right = map_rect.end.x * 16 + map.position.x
					position.x = camera.limit_left + 8;
					if (state == COOTS_SLIDE):
						state_frame = slide_start_frame+1;
						sprites[COOTS_IDLE].visible = 0;
						sprites[COOTS_SLIDE].visible = 1;
					else:
						state_frame = 0;
					return;
					
			if (position.x < camera.limit_left+4):
				position.x = camera.limit_left+4;
			if (position.y > camera.limit_bottom):
				die();
				return;
			if (position.y-2 < camera.limit_top):
				Global.game_end();
				state = COOTS_FROZEN;
				return;
			if (tile_coords.x >= map_rect.end.x):
				Global.next_level();
				state = COOTS_FROZEN;
				return;
			if (state != COOTS_DEAD):
				match(tile_type):
					19:
						var pos2 = mypos;
						pos2.y -= 5;
						var coords2 = map.world_to_map(pos2 - map.position);
						if (velocity.y >= 0 && coords2.y == tile_coords.y):
							die();
					20:
						var pos2 = mypos;
						pos2.y += 5;
						var coords2 = map.world_to_map(pos2 - map.position);
						if (velocity.y <= 0 && coords2.y == tile_coords.y):
							die(); 
					21:
						var pos2 = mypos;
						pos2.x += 5;
						var coords2 = map.world_to_map(pos2 - map.position);
						if (velocity.x <= 0 && coords2.x == tile_coords.x):
							die(); 
					22:
						var pos2 = mypos;
						pos2.x -= 5;
						var coords2 = map.world_to_map(pos2 - map.position);
						if (velocity.x >= 0 && coords2.x == tile_coords.x):
							die();
#		if (prevstate != state):
#			print("started ", state_str[state])


func _ready():
	request_ready();
	collider = $CollisionShape2D
	camera = $Camera2D
	map = get_node("../TileMap");
	map_rect = map.get_used_rect();
	camera.limit_left = map_rect.position.x * 16 + map.position.x;
	camera.limit_right = map_rect.end.x * 16 + map.position.x;
	camera.limit_top = map_rect.position.y * 16 + map.position.y;
	camera.limit_bottom = map_rect.end.y * 16 + map.position.y;
	if (Global.checkpoint):
		camera.limit_left = Global.checkpoint.x * 16 + map.position.x;
		position.x = camera.limit_left + 8;
		position.y = (Global.checkpoint.y+1) * 16 + map.position.y;
	else:
		if (checkpoint_x[Global.level]):
			camera.limit_right = checkpoint_x[Global.level] * 16 + map.position.x;
	velocity.x = 0;
	velocity.y = 500;
	start_idle();
	if (Global.DEBUG):
		var cells = map.get_used_cells();
		for c in cells:
			var type = map.get_cellv(c);
			if (type >= 19 && type <= 22 
			&& (map.is_cell_x_flipped(c.x, c.y) || map.is_cell_y_flipped(c.x, c.y) || map.is_cell_transposed(c.x, c.y)) 
			):
				print("spikes at [ ", c, " ] are bugged");









