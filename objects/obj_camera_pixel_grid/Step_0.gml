//toggle zoom in
if(mouse_check_button_pressed(mb_right)){
	zoom_mode++;
	if(zoom_mode > 2) zoom_mode = 0;
	
	switch (zoom_mode) {
		case 0:
			//no zooming
			cam1.zoom(1, GAME_SPEED * 1);
			break;
		case 1:
			//zoom in
			cam1.zoom(0.5, GAME_SPEED * 1);
			break;
		case 2:
			//zoom out
			cam1.zoom(2, GAME_SPEED * 1);
			break;
	}
}
zoom_text = cam1.zoom_amount;

//do a screenshake
if(keyboard_check_pressed(ord("F"))){
	cam1.shake_screen(30, GAME_SPEED * 1);
}

//toggle camera pause
if(keyboard_check_pressed(ord("P"))){
	if(is_instanceof(cam1, stanncam)){
		cam1.toggle_paused();
	}
}

//toggle camera pause
if(keyboard_check_pressed(ord("B"))){
	if(is_instanceof(cam1, stanncam)){
		cam1.smooth_draw = !cam1.smooth_draw;
	}
}

//switch resolutions
if(keyboard_check_pressed(vk_f1)){
	game_res++;
	if(game_res >= array_length(resolutions)) game_res = 0;
	stanncam_set_resolution(resolutions[game_res].w, resolutions[game_res].h);
}

//toggle keep aspect ratio
if(keyboard_check_pressed(vk_f3)){
	stanncam_set_keep_aspect_ratio(!stanncam_get_keep_aspect_ratio());
}

//toggle between window modes
if(keyboard_check_pressed(vk_f4)){
	var _window_mode = global.window_mode;
	_window_mode++;
	if(_window_mode == STANNCAM_WINDOW_MODE.__SIZE){
		_window_mode = 0;
	}
	
	stanncam_set_window_mode(_window_mode);
}

//move camera
var _hinput = keyboard_check(vk_right) - keyboard_check(vk_left);
var _vinput = keyboard_check(vk_down) - keyboard_check(vk_up);

if(_hinput != 0) hspd += _hinput * acceleration_spd;
else hspd -= min(abs(hspd), deacceleration_spd) * sign(hspd);

if(_vinput != 0) vspd += _vinput * acceleration_spd;
else vspd -= min(abs(vspd), deacceleration_spd) * sign(vspd);

hspd = clamp(hspd, -max_spd, max_spd);
vspd = clamp(vspd, -max_spd, max_spd);
	
if(hspd != 0 || vspd != 0){
	var _x = cam1.x + hspd;
	var _y = cam1.y + vspd;
	cam1.move(_x, _y, 0);
}
