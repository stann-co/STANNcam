var _len = array_length(global.stanncams);
for (var i = 0; i < _len; ++i){
	if(global.stanncams[i] == -1) continue;
	global.stanncams[i].__step();
}

//constantly checks if the window is being resized and changes the resolution to match
if(global.window_mode == STANNCAM_WINDOW_MODE.WINDOWED && !__switching_window_mode && (resize_width != window_get_width() || resize_height != window_get_height())){
	resize_width = window_get_width();
	resize_height = window_get_height();
	
	if(resize_width != 0 && resize_height != 0){
		stanncam_set_resolution(resize_width, resize_height);
	}
}
