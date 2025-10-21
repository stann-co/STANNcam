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

//toggle camera speed
if(keyboard_check_pressed(vk_tab)){
	speed_mode++;
	if(speed_mode > 3) speed_mode = 0;
	
	switch (speed_mode) {
		case 0:
			//speed 0.5
			cam1.set_speed(0.5, 50);
			break;
		case 1:
			//speed 1
			cam1.set_speed(1, 50);
			break;
		case 2:
			//speed 2
			cam1.set_speed(2, 50);
			break;
		case 3:
			//speed 10
			cam1.set_speed(10, 50);
			break;
	}
}

//toggle if the camera is constrained to the room size
if(keyboard_check_pressed(vk_control)){
	cam1.room_constrain = !cam1.room_constrain;
}

//toggle debug drawing
if(keyboard_check_pressed(vk_shift)){
	cam1.debug_draw = !cam1.debug_draw;
}

//do a screenshake
if(keyboard_check_pressed(ord("F"))){
	cam1.shake_screen(30, GAME_SPEED * 1);
}

//toggle camera pause
if(keyboard_check_pressed(ord("P"))){
	var _paused = false;
	if(is_instanceof(cam1, stanncam)){
		_paused = !cam1.get_paused();
	}
	stanncam_set_cameras_paused(_paused);
}

//toggle drawing camera zones
if(keyboard_check_pressed(ord("Z"))){
	draw_zones = !draw_zones;
	stanncam_debug_set_draw_zones(draw_zones);
}

//switch resolutions
if(keyboard_check_pressed(vk_f1)){
	game_res++;
	if(game_res >= array_length(resolutions)) game_res = 0;
	var _res_w = resolutions[game_res].width;
	var _res_h = resolutions[game_res].height;
	stanncam_set_resolution(_res_w, _res_h);
}

//switch gui resolutions
if(keyboard_check_pressed(vk_f2)){
	gui_res++;
	if(gui_res >= array_length(gui_resolutions)) gui_res = 0;
    
	var _gui_w = gui_resolutions[gui_res].width;
	var _gui_h = gui_resolutions[gui_res].height;
    if(gui_hires){
        stanncam_set_gui_resolution(_gui_w*gui_hires_scale, _gui_h*gui_hires_scale);
    } else {
        stanncam_set_gui_resolution(_gui_w, _gui_h);    
    }
}

//toggle hires gui
if(keyboard_check_pressed(vk_alt)){
	gui_hires = !gui_hires;
    
	var _gui_w = gui_resolutions[gui_res].width;
	var _gui_h = gui_resolutions[gui_res].height;
    if(gui_hires){
        stanncam_set_gui_resolution(_gui_w*gui_hires_scale, _gui_h*gui_hires_scale);
    } else {
        stanncam_set_gui_resolution(_gui_w, _gui_h);    
    }
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

//toggle split-screen
if(keyboard_check_pressed(vk_f5)){
	split_screen = !split_screen;
	
	if(split_screen){
		cam1.set_size(global.game_w * 0.5, global.game_h, GAME_SPEED * 0.5);
	} else {
		cam1.follow = obj_player_sidescroller;
		cam2.follow = obj_player_sidescroller2;
		cam1.set_size(global.game_w, global.game_h, GAME_SPEED * 0.5);
	}
}

//makes the camera look ahead in the direction the player is going
if(cam1.bounds_dist_w != 0){
	if(!lookahead){
		cam1.offset(60 * sign(cam1.bounds_dist_w), 0, GAME_SPEED * 0.5);
		lookahead = true;
	}
} else {
	lookahead = false;
}
