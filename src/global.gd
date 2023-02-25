extends Node

var allow_input 	: int 	= 0;
var played_frames 	: int 	= 0;
var level			: int 	= 0;
var deaths			: int 	= 0;
var input_scheme	: int 	= 0;
var game_beaten		: int 	= 0;
var checkpoint;
var start_t;

enum {
	STATE_MENU,
	STATE_STARTING,
	STATE_END,
	STATE_IN_GAME,
	STATE_LOADING,
	STATE_COUNT
};

var state		: int = STATE_MENU;
var state_frame : int = 0;
var bs 			: int = 0;
var cheat		: int = 0;

const music_vol_default : int = -15;
const vol_disabled : int = -999;

var music_vol_db : int = music_vol_default;
var piano_vol_db : int = vol_disabled;

onready var overlay = $Overlay;
onready var dumb 	= $dumb;
onready var keysmap = $keysmap;

onready var snd_slide = $snd_slide;
onready var snd_death = $snd_death;

onready var snd_gainer 		= $snd_gainer;
onready var snd_jump 		= $snd_jump;
onready var snd_landing 	= $snd_landing;
onready var snd_slide2 		= $snd_slide2;
onready var snd_step1 		= $snd_step1;
onready var snd_step2 		= $snd_step2;
onready var snd_airtumble 	= $snd_airtumble;

onready var piano = [
	snd_gainer,
	snd_jump,
	snd_landing,
	snd_slide2,
	snd_step1,
	snd_step2,
	snd_airtumble
];

onready var music = [
	0,
	$music1,
	$music2,
	$music3,
	$music4,
	0,
];

func set_overlay_alpha(a : float) -> void:
	if (a < 0.03):
		overlay.visible = 0;
		overlay.color.a = 0;
	else:
		overlay.visible = 1;
		overlay.color.a = a;


func change_state(_state_ : int) -> void:
	state = _state_;
	state_frame = 0;
	bs = 0;
	match(state):
		STATE_MENU: 
			tmtext("      ", 45, 26);
			level = 0;
			allow_input = 0
			checkpoint = 0
			cheat = 0;
			deaths = 0;
			set_overlay_alpha(1);


func death() -> void:
	change_state(STATE_LOADING);
	deaths += 1;
	bs = 0;


func tmtext(ss : String, x : int, y : int) -> void:
	var s = ss.to_ascii();
	for c in s:
		dumb.set_cell(x, y, c-32);
		x += 1;



const timer_end_pos_x = 94;
const timer_end_pos_x_skip1 = 92;
const timer_end_pos_x_skip2 = 89;


func timestr(frames : int) -> String:
	var hh = frames * 5 / 3600000;
	var rem = (frames * 5) % 3600000;
	var mm = rem / 60000;
	rem %= 60000;
	var ss = rem / 1000;
	rem %= 1000;
	var cc = rem / 10;
	if (hh):
		return "%d:%02d:%02d.%02d" % [hh, mm, ss, cc];
	elif (mm):
		return "%d:%02d.%02d" % [mm, ss, cc];
	else: #ss
		return "%d.%02d" % [ss, cc];


func timer() -> void:
	played_frames += 1;
	if (!(played_frames & 1)):
		if (played_frames >= 720000):
			return;
		if (played_frames == 12000):
			tmtext("1:00,00", timer_end_pos_x-6, 1);
			return;
		var x : int = timer_end_pos_x;
		var y : int = 1;
		while (1):
			match(x):
				timer_end_pos_x_skip1:
					x -= 1;
				timer_end_pos_x_skip2:
					x -= 1;
			var i = dumb.get_cell(x, y);
			var lt = 25;
			if (x == (timer_end_pos_x-4)):
				lt = 21;
			if (i < lt): 
				if (i < 17):
					dumb.set_cell(x, y, 17);
				else:
					dumb.set_cell(x, y, i+1);
				break;
			else:
				dumb.set_cell(x, y, 16);
				x -= 1;
	return;


func reset_level() -> void:
	match(level):
		1: 
			get_tree().change_scene("res://bullshit/Level1.tscn");
		2: 
			get_tree().change_scene("res://bullshit/Level2.tscn");
		3: 
			get_tree().change_scene("res://bullshit/Level3.tscn");
		4: 
			get_tree().change_scene("res://bullshit/Level4.tscn");



var advancing_level = 0;
func next_level() -> void:
	advancing_level = 1;
	if (!cheat):
		level += 1;
	checkpoint = 0;
	bs = 0
	change_state(STATE_LOADING);


func cheat_next_level() -> void:
	cheat = 1;
	if (level >= 4): 
		level = 1;
	else:
		level += 1;
	next_level();
	state_frame = 148;



func _ready() -> void:
	Engine.set_target_fps(200);
	change_state(STATE_MENU);
	show_keys();
	piano_vol_db = vol_disabled;
	for i in piano:
		i.set_volume_db(piano_vol_db);


var endtext1 = "THANKS FOR PLAYING!";
var endtextc = 0;


func game_end() -> void:
	bs = 0;
	endtextc = 0;
	if (cheat):
		checkpoint = 0;
		change_state(STATE_LOADING);
	else:
		change_state(STATE_END);
		game_beaten = 1;


func input_view() -> void:
	if (Input.is_action_pressed("attack")):
		tmtext("A", 93, 50);
	else:
		dumb.set_cell(93, 50, 0);
	if (Input.is_action_pressed("jump")):
		tmtext("J", 94, 51);
	else:
		dumb.set_cell(94, 51, 0);
	if (Input.is_action_pressed("left")):
		tmtext("<", 89, 51);
	else:
		dumb.set_cell(89, 51, 0);
	if (Input.is_action_pressed("right")):
		tmtext(">", 91, 51);
	else:
		dumb.set_cell(91, 51, 0);
	if (Input.is_action_pressed("up")):
		tmtext("^", 90, 50);
	else:
		dumb.set_cell(90, 50, 0);
	if (Input.is_action_pressed("down")):
		dumb.set_cell(90, 52, 94-32, 0, 1);
	else:
		dumb.set_cell(90, 52, 0);



func wrtkm(bloat, x, y) -> void:
	var sx = x;
	var cool = bloat.to_ascii();
	for c in cool:
		if (c == 10):
			x = sx;
			y += 1;
		else:
			keysmap.set_cell(x, y, c-32);
			x += 1;


func show_keys() -> void:
	wrtkm("ESC / START: EXIT TO MENU\nF1 / SELECT: INPUT SCHEME\n", 1, 1);
	var ver = "V0,LUDJAM";
	wrtkm(ver, 95-ver.length(), 37);
	if (game_beaten):
		wrtkm("SHIFT + F9:  MUSIC\nSHIFT + F10: PIANO SOUNDS\nSHIFT + F12: LEVEL SELECT", 1, 6);


var keys_alpha = 1.0;
func fadeout_keys() -> void:
	if (keys_alpha > 0.0):
		keys_alpha -= 0.02;
		keysmap.set_modulate(Color(0.235,0.235,0.235,keys_alpha));


func fadein_keys() -> void:
	if (keys_alpha < 1.0):
		keys_alpha += 0.02;
		keysmap.set_modulate(Color(0.235,0.235,0.235,keys_alpha));


func start_game() -> void:
	advancing_level = 0;
	allow_input = 0;
	checkpoint = 0;
	level = 1
	change_state(STATE_STARTING);
	tmtext("START", 45, 26);
	for i in [1,2,3,4]:
		if (music[i].playing):
			music[i].stop();




var notif_f = 0;
var notif_c = 0;
var notif_x = 0;
const notif_y = 12;
var notif_len = 0;


func notif_clear(instant) -> void:
	if (instant):
		while (notif_c < notif_len):
			dumb.set_cell(notif_x, notif_y, 0);
			notif_x += 1;
			notif_c += 1;
	elif (notif_c < notif_len):
		notif_f -= 1;
		if (notif_f < 200 && !(notif_f & 3)):
			dumb.set_cell(notif_x, notif_y, 0);
			notif_c += 1;
			notif_x += 1;


func notif_show(string) -> void:
	notif_clear(1);
	notif_len = string.length();
	notif_x = 47 - notif_len/2;
	notif_c = 0;
	notif_f = 400;
	tmtext(string, notif_x, notif_y);



var guide_str = "EACH AIRMOVE CAN BE USED ONCE.    \nTHEY RESET AFTER TOUCHING THE GROUND\nOR BOUNCING OFF A WALL.";
var guide_c = 0;
var guide_x = 0;
var guide_y = 0;

func _physics_process(_delta: float) -> void:
	if (Input.is_action_just_pressed("change_inputs")):
		input_scheme ^= 1;
		match (input_scheme):
			0:
				notif_show("INPUT SCHEME: DEFAULT");
			1:
				notif_show("INPUT SCHEME: VERSION 2");
	notif_clear(0);
	input_view();
	
	if (Input.is_action_just_pressed("music_toggle")):
		if (music_vol_db == music_vol_default):
			if (music[level]):
				music[level].stop();
			music_vol_db = vol_disabled;
			notif_show("MUSIC: OFF");
		else:
			music_vol_db = music_vol_default;
			if (music[level]):
				music[level].set_volume_db(music_vol_db);
				music[level].play();
			notif_show("MUSIC: ON ");

	if (Input.is_action_just_pressed("piano_toggle")):
		if (piano_vol_db == music_vol_default):
			piano_vol_db = vol_disabled;
			notif_show("PIANO: OFF");
		else:
			piano_vol_db = music_vol_default;
			notif_show("PIANO: ON ");
		for i in piano:
			i.set_volume_db(piano_vol_db);

	if (state != STATE_END):
		if (Input.is_action_just_pressed("cheat_next_level")):
				cheat = 1;
				if (level >= 4 || state == STATE_MENU):
					start_game();
				else:
					tmtext("      ", 45, 26);
					cheat_next_level();
					return;
		if (Input.is_action_just_pressed("reset")):
			tmtext("        ", 94-7, 1);
			change_state(STATE_MENU);
			return;
	if (state != STATE_MENU):
		fadeout_keys();

	match(state):
		STATE_MENU:
			fadein_keys();
			for i in [1,2,3,4]:
				if (music[i].playing):
					var vol : float = music[i].get_volume_db();
					if (vol < -60.0):
						music[i].stop();
					else:
						music[i].set_volume_db(vol-0.15);
			if(Input.is_action_just_pressed("ui_accept") 
			|| Input.is_action_just_pressed("jump")
			|| Input.is_action_just_pressed("attack")):
				start_game();
				return;
			match(state_frame):
				8:  tmtext("S", 45, 26);
				16: tmtext("T", 46, 26);
				24: tmtext("A", 47, 26);
				32: tmtext("R", 48, 26);
				40: tmtext("T", 49, 26);
		STATE_STARTING:
			if (state_frame >= 70):
				var a : float = 1.0 - (float(state_frame) - 70.0) / 150.0;
				set_overlay_alpha(a);
				if (state_frame == 70):
					reset_level();
					tmtext("        ", 94-7, 3);
					tmtext("    0,00", 94-7, 1);
					if (music_vol_db != vol_disabled):
						music[1].set_volume_db(music_vol_db);
						music[1].play();
				if (state_frame >= 70+150):
					allow_input = 1
					set_overlay_alpha(0);
					change_state(STATE_IN_GAME);
					checkpoint = 0
					played_frames = 0
					start_t = Time.get_ticks_msec();
					return;
			else:
				set_overlay_alpha(1.0);
				if (!(state_frame & 7)):
					dumb.set_cell(45+bs, 26, 0);
					bs += 1;
		STATE_IN_GAME:
			match(level):
				1:
					if (state_frame == 100):
						var textmap = get_node("../Level1/textmap");
						if (textmap):
							guide_c = 0;
							guide_x = 21;
							guide_y = 29;
							for i in range(0, 37):
								textmap.set_cell(guide_x+i, 29, 0);
					elif (guide_c < guide_str.length() 
					&& state_frame >= 600 && !(state_frame%12)):
						var textmap = get_node("../Level1/textmap");
						var real = guide_str.to_ascii();
						if (textmap):
							if (real[guide_c] == 10): #'\n'
								guide_y += 2;
								guide_x = 21;
							else:
								textmap.set_cell(guide_x, guide_y, real[guide_c]-32);
								guide_x += 1;
							guide_c += 1;
				4:
					if (state_frame == 500 && !cheat):
						var textmap = get_node("../Level4/textmap");
						if (textmap):
							var k;
							if (deaths >= 9):
								k = "CATS HAVE AT LEAST %d LIVES     " % (deaths+1);
							elif (deaths == 8):
								k = "1 LIFE REMAINING                ";
							else:
								k = "%d LIVES REMAINING              " % (9-deaths);
							var strr = k.to_ascii();
							var x = 2;
							for c in strr:
								textmap.set_cell(x, 10, c-32);
								x += 1;
		STATE_LOADING:
			if (!bs):
				overlay.visible = 1
				if (state_frame == 150):
					set_overlay_alpha(1.0);
					reset_level();
					if (advancing_level):
						if (music[level-1]):
							music[level-1].stop();
						if (music_vol_db != vol_disabled):
							music[level].set_volume_db(music_vol_db);
							music[level].play();
						advancing_level = 0;
					allow_input = 0
					bs = 1;
					state_frame = 0
				else:
					set_overlay_alpha(float(state_frame) / 150.0);
					if (advancing_level):
						if (music[level-1]):
							var vol = music[level-1].get_volume_db();
							music[level-1].set_volume_db(vol - 0.15);
			else:
				if (state_frame == 150):
					if (cheat):
						played_frames = 0;
						tmtext("    0.00", 94-7, 1);
					set_overlay_alpha(0);
					change_state(STATE_IN_GAME);
					allow_input = 1
				else:
					set_overlay_alpha(1.0 - float(state_frame) / 150.0);
		STATE_END:
			overlay.visible = 1
			if (!bs):
				if (state_frame == 1):
					var time2str = timestr((Time.get_ticks_msec() - start_t)/5);
					tmtext(time2str, 95-time2str.length(), 3);
					
				if (!(state_frame & 7)):
					var hmm = endtext1.substr(endtextc, 1);
					tmtext(hmm, 38+endtextc, 24);
					endtextc += 1;
				var a = float(state_frame) / 300.0;
				if (a > 1.0): a = 1.0;
				set_overlay_alpha(a);
				if(Input.is_action_just_pressed("ui_accept")
				|| Input.is_action_just_pressed("reset")
				|| Input.is_action_just_pressed("jump")
				|| Input.is_action_just_pressed("attack")):
					tmtext(endtext1, 38, 24);
					endtextc = 0;
					bs = 1;
					state_frame = 0;
					set_overlay_alpha(1.0);
			else:
				if (!(state_frame & 7)):
					tmtext(" ", 38+endtextc, 24);
					endtextc += 1;
				if (state_frame >= 300):
					change_state(STATE_MENU);
					show_keys();
	state_frame += 1;
	
	if (state >= STATE_IN_GAME):
		if (!cheat || state != STATE_LOADING):
			timer();


