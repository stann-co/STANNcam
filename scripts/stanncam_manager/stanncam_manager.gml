// Feather disable all

enum STANNCAM_WINDOW_MODE {
	WINDOWED,
	FULLSCREEN,
	BORDERLESS,
	__SIZE
}

/// @function stanncam_init
/// @description set game dimensions, display resolution, and gui dimensions, it's the same as game scale by default
/// @param {Real} _game_w
/// @param {Real} _game_h
/// @param {Real} [_resolution_w=_game_w]
/// @param {Real} [_resolution_h=_game_h]
/// @param {Real} [_gui_w=_game_w]
/// @param {Real} [_gui_h=_game_h]
/// @param {Real} [_window_mode=STANNCAM_WINDOW_MODE.WINDOWED]
function stanncam_init(_game_w, _game_h, _resolution_w=_game_w, _resolution_h=_game_h, _gui_w=_game_w, _gui_h=_game_h, _window_mode=STANNCAM_WINDOW_MODE.WINDOWED){
	
	//if one already exists it is destroyed
	if(instance_exists(__obj_stanncam_manager)){
		instance_destroy(__obj_stanncam_manager);
	}
	
	instance_create_depth(0, 0, 0, __obj_stanncam_manager);
	
	global.stanncams = array_create(8, -1);
	global.game_w = _game_w;
	global.game_h = _game_h;
	global.gui_w = _gui_w;
	global.gui_h = _gui_h;
	global.res_w = _resolution_w;
	global.res_h = _resolution_h;
	global.window_mode = _window_mode;
    
    __obj_stanncam_manager.__gui_res_w = global.gui_w; 
    __obj_stanncam_manager.__gui_res_h = global.gui_h;
	
	var _len = array_length(view_camera);
	for (var i = 0; i < _len; ++i){
		camera_destroy(view_camera[i]);
	}
	
	application_surface_draw_enable(false);
	
    stanncam_set_resolution(_resolution_w,_resolution_h); 
    stanncam_set_window_mode(_window_mode);
	
	//check if stanncam manager has been deactivated and if so throw an error
	global.stanncam_time_source = time_source_create(time_source_global, 1, time_source_units_frames, function(){
	if(!instance_exists(__obj_stanncam_manager)){
			instance_activate_object(__obj_stanncam_manager);
			if(instance_exists(__obj_stanncam_manager)){
				show_error("__obj_stanncam_manager has been deactivated.\nMake sure that it is never deactivated.\nConsider using instance_activate_object(__obj_stanncam_manager)\nin the same step you deactivate other stuff.", true);
			}
		}
	}, [], -1);
	time_source_start(global.stanncam_time_source);
}

/// @function stanncam_destroy
/// @description removes all stanncam references from the game, the opposite of stanncam_init
/// @param {Bool} [_application_surface_draw_enable=true]
function stanncam_destroy(_application_surface_draw_enable=true){
	application_surface_draw_enable(_application_surface_draw_enable);
	
	time_source_destroy(global.stanncam_time_source, true);
	for (var i = 0; i < array_length(global.stanncams); ++i){
		if(global.stanncams[i] != -1){
			global.stanncams[i].destroy();
		}
	}
	instance_destroy(__obj_stanncam_manager);
}

/// @function stanncam_set_resolution
/// @description updates the camera resolution, has no visible effect when fullscreened
/// @param {Real} _resolution_w
/// @param {Real} _resolution_h
function stanncam_set_resolution(_resolution_w, _resolution_h){
	__obj_stanncam_manager.display_res_w = _resolution_w;
	__obj_stanncam_manager.display_res_h = _resolution_h;
	__stanncam_update_resolution();
}

/// @function stanncam_set_window_mode(_window_mode)
/// @param {Real} _window_mode
/// @description set game to be windowed/fullscreen/borderless
function stanncam_set_window_mode(_window_mode){
	global.window_mode = _window_mode;
    __obj_stanncam_manager.__switching_window_mode = true;
	switch (_window_mode) {
		case STANNCAM_WINDOW_MODE.WINDOWED:
			window_set_fullscreen(false);
			window_set_showborder(true);
            __stanncam_center(20,20);
			break;
		case STANNCAM_WINDOW_MODE.FULLSCREEN:
			window_set_fullscreen(true);
			window_set_showborder(false);
			break;
		case STANNCAM_WINDOW_MODE.BORDERLESS:
			window_set_fullscreen(false);
			window_set_showborder(false);
			break;
	}
	call_later(10, time_source_units_frames, function(){
        __obj_stanncam_manager.__switching_window_mode = false;
		__stanncam_update_resolution();
	});
}

/// @function stanncam_set_windowed()
/// @description set windowed
function stanncam_set_windowed(){
	stanncam_set_window_mode(STANNCAM_WINDOW_MODE.WINDOWED);
}

/// @function stanncam_set_fullscreen()
/// @description set fullscreen
function stanncam_set_fullscreen(){
	stanncam_set_window_mode(STANNCAM_WINDOW_MODE.FULLSCREEN);
}

/// @function stanncam_set_borderless()
/// @description set borderless
function stanncam_set_borderless(){
	stanncam_set_window_mode(STANNCAM_WINDOW_MODE.BORDERLESS);
}

/// @function stanncam_set_keep_aspect_ratio
/// @description set display keep_aspect_ratio
/// @param {Bool} _on_off
function stanncam_set_keep_aspect_ratio(_on_off){
	__obj_stanncam_manager.keep_aspect_ratio = _on_off;
	__stanncam_update_resolution();
}

/// @function stanncam_set_gui_keep_aspect_ratio
/// @description set gui keep_aspect_ratio
/// @param {Bool} _on_off
function stanncam_set_gui_keep_aspect_ratio(_on_off){
	__obj_stanncam_manager.gui_keep_aspect_ratio = _on_off;
	__stanncam_update_resolution();
}

/// @function stanncam_get_keep_aspect_ratio
/// @description get whether the display has keep_aspect_ratio on
/// @returns {Bool}
function stanncam_get_keep_aspect_ratio(){
	return __obj_stanncam_manager.keep_aspect_ratio;
}

/// @function stanncam_get_gui_keep_aspect_ratio
/// @description get whether the display has gui_keep_aspect_ratio on
/// @returns {Bool}
function stanncam_get_gui_keep_aspect_ratio(){
	return __obj_stanncam_manager.gui_keep_aspect_ratio;
}

/// @function stanncam_ratio_compensate_x
/// @description if keep_aspect_ratio is on it offsets the x value so the render is in the middle
/// @returns {Real}
function stanncam_ratio_compensate_x(){
	if(stanncam_get_keep_aspect_ratio()){
		return (window_get_width() - (global.game_w * __obj_stanncam_manager.__display_scale_x)) * 0.5;
	}
	return 0;
}

/// @function stanncam_ratio_compensate_y
/// @description if keep_aspect_ratio is on it offsets the y value so the render is in the middle
/// @returns {Real}
function stanncam_ratio_compensate_y(){
	if(stanncam_get_keep_aspect_ratio()){
		return (window_get_height() - (global.game_h * __obj_stanncam_manager.__display_scale_y)) * 0.5;
	}
	return 0;
}

/// @function stanncam_set_gui_resolution
/// @description set the gui resolution
/// @param {Real} _gui_w
/// @param {Real} _gui_h
function stanncam_set_gui_resolution(_gui_w, _gui_h){
	__obj_stanncam_manager.__gui_res_w = _gui_w;
	__obj_stanncam_manager.__gui_res_h = _gui_h;
	__stanncam_update_resolution();
}

/// @function stanncam_get_gui_scale_x
/// @description gets how much bigger gui is from game
/// @returns {Real}
function stanncam_get_gui_scale_x(){
	return global.gui_w / global.game_w;
}

/// @function stanncam_get_gui_scale_y
/// @description gets how much bigger gui is from game
/// @returns {Real}
function stanncam_get_gui_scale_y(){
	return global.gui_h / global.game_h;
}

/// @function stanncam_get_res_scale_x
/// @description gets how much bigger res is from game
/// @returns {Real}
function stanncam_get_res_scale_x(){
	return global.res_w / global.game_w;
}

/// @function stanncam_get_res_scale_y
/// @description gets how much bigger res is from game
/// @returns {Real}
function stanncam_get_res_scale_y(){
	return global.res_h / global.game_h;
}

/// @function __stanncam_update_resolution
/// @description updates the camera resolution
/// @ignore
function __stanncam_update_resolution(){
	switch (global.window_mode) {
		//fullscreen
		case STANNCAM_WINDOW_MODE.FULLSCREEN:
		//borderless windowed
		case STANNCAM_WINDOW_MODE.BORDERLESS:
			if(__obj_stanncam_manager.keep_aspect_ratio){
				var _ratio = global.game_w / global.game_h;
				global.res_w = display_get_height() * _ratio;
				global.res_h = display_get_height();
			} else {
				global.res_w = display_get_width();
				global.res_h = display_get_height();
			}
		
			window_set_size(display_get_width(), display_get_height());
			__stanncam_center();
			break;
		//windowed
		case STANNCAM_WINDOW_MODE.WINDOWED: 
			if(__obj_stanncam_manager.keep_aspect_ratio){
				var _res_ratio = (__obj_stanncam_manager.display_res_w / __obj_stanncam_manager.display_res_h) / (global.game_w / global.game_h);
				var _game_ratio = global.game_w / global.game_h;
				if(_res_ratio >= 1){
					global.res_w = __obj_stanncam_manager.display_res_h * _game_ratio;
					global.res_h = __obj_stanncam_manager.display_res_h;
				} else {
					global.res_w = __obj_stanncam_manager.display_res_w;
					global.res_h = __obj_stanncam_manager.display_res_w / _game_ratio;
				}
			} else {
				global.res_w = __obj_stanncam_manager.display_res_w;
				global.res_h = __obj_stanncam_manager.display_res_h;
			}
        	
            window_set_size(__obj_stanncam_manager.display_res_w, __obj_stanncam_manager.display_res_h);
			break;
	}
	
	with(__obj_stanncam_manager){
        
        __gui_x_scale = global.res_w / __gui_res_w; 
        __gui_y_scale = global.res_h / __gui_res_h;
        
        global.gui_w = __gui_res_w;
        global.gui_h = __gui_res_h;
        
		if(stanncam_get_keep_aspect_ratio()){
			var _ratio = (global.res_w / global.res_h) / (global.game_w / global.game_h);
			if(_ratio > 1){
				__display_scale_x = stanncam_get_res_scale_y();
				__display_scale_y = __display_scale_x;
			} else {
				__display_scale_x = stanncam_get_res_scale_x();
				__display_scale_y = __display_scale_x;
			}
		} else {
			__display_scale_x = stanncam_get_res_scale_x();
			__display_scale_y = stanncam_get_res_scale_y();
            
    		if(stanncam_get_gui_keep_aspect_ratio()){
                global.gui_w *= (__gui_x_scale / __gui_y_scale);
                __gui_x_scale = __gui_y_scale;
            }
        } 
        display_set_gui_maximize(__gui_x_scale , __gui_y_scale, stanncam_ratio_compensate_x(), stanncam_ratio_compensate_y());
	}
}

/// @function __stanncam_center
/// @description moves the window to the center of whichever window it's within
/// @param {Real} [_x=0] x offset
/// @param {Real} [_y=0] y offset
/// @ignore
function __stanncam_center(_x=0, _y=0){
	var _wx = window_get_x();
	var _wy = window_get_y();
	var _ww = window_get_width();
	var _wh = window_get_height();
	var _display_data = window_get_visible_rects(_wx, _wy, _wx + _ww, _wy + _wh);
	var _display_num = array_length(_display_data) / 8;
	
	//deletes all the overlay data as it's not needed
	for (var i = 0; i < _display_num; ++i){
		array_delete(_display_data, i * 4, 4);
	}
	
	var _middle_x = _wx + (_ww * 0.5);
	var _middle_y = _wy + (_wh * 0.5);
	
	var _outside_view = true;
	//checks which monitor the window is within
	for (var i = 0; i < _display_num; ++i){
		var _x1 = _display_data[(i * 4) + 0];
		var _y1 = _display_data[(i * 4) + 1];
		var _x2 = _display_data[(i * 4) + 2];
		var _y2 = _display_data[(i * 4) + 3];
		
		if(_middle_x > _x1 && _middle_x < _x2 && _middle_y > _y1 && _middle_y < _y2){
			window_set_position(_x1 + _x, _y1 + _y);
			_outside_view = false;
			break;
		}
	}
	//in case it somehow appears outside any of the monitors views it will go back to the first monitor
	if(_outside_view){
		window_set_position(_x, _y);
	}
}

/// @function stanncam_get_preset_resolution
/// @description gets a resolution preset
/// @param {Real} _preset_index
/// @returns {Struct}
function stanncam_get_preset_resolution(_preset_index){
	return global.stanncam_res_presets[@ _preset_index];
}

/// @function stanncam_get_preset_resolution_range
/// @description returns an array of preset resolutions using a starting index and an end index
/// @param {Real} [_start_i=0]
/// @param {Real} [_end_i=array_length(global.stanncam_res_presets)-1]
/// @returns {Array<Struct>}
function stanncam_get_preset_resolution_range(_start_i=0, _end_i=array_length(global.stanncam_res_presets)-1){
	var _start = min(_start_i, _end_i);
	var _end = max(_start_i, _end_i);
	var _res_array = [];
	for (var i = _start; i <= _end; ++i){
		array_push(_res_array, stanncam_get_preset_resolution(i));
	}
	return _res_array;
}

/// @function stanncam_debug_set_draw_zones
/// @description sets whether or not zones should be drawn in the room, for debugging
/// @param {Bool} _should_draw
function stanncam_debug_set_draw_zones(_should_draw){
	__obj_stanncam_manager.draw_zones = _should_draw;
}

/// @function stanncam_toggle_cameras_paused
/// @description toggles camera's paused state
function stanncam_toggle_cameras_paused(){
	var _len = array_length(global.stanncams);
	for (var i = 0; i < _len; ++i){
		var _camera = global.stanncams[i];
		if(is_instanceof(_camera, stanncam)){
			_camera.toggle_paused();
		}
	}
}

/// @function stanncam_set_cameras_paused
/// @description sets all cameras to paused state
/// @param {Bool} _paused
function stanncam_set_cameras_paused(_paused){
	var _len = array_length(global.stanncams);
	for (var i = 0; i < _len; ++i){
		var _camera = global.stanncams[i];
		if(is_instanceof(_camera, stanncam)){
			_camera.set_paused(_paused);
		}
	}
}

/// @function stanncam_cameras_pause
/// @description sets all cameras to paused state
function stanncam_cameras_pause(){
	return stanncam_set_cameras_paused(true);
}

/// @function stanncam_cameras_unpause
/// @description sets all cameras to an unpaused state
function stanncam_cameras_unpause(){
	return stanncam_set_cameras_paused(false);
}
