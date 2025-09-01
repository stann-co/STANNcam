//chooses pixel font or hires font
if(gui_hires){
	draw_set_font(f_hires);
	var _offset = 45;
	var _outline_width = 4;
	var _precision = 16;
} else {
	draw_set_font(f_pixel);
	var _offset = 8;
	var _outline_width = 1;
	var _precision = 8;
}
draw_set_color(c_white);

//draws helper text
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_text_outline(1, 1, "[arrow keys] move character", _outline_width, _precision);
var _following = (instance_exists(cam1.follow)) ? "following" : "not following";
draw_text_outline(1, _offset, "[space] " + _following, _outline_width, _precision);
draw_text_outline(1, _offset * 2, "[ALT] toggle hi-res GUI", _outline_width, _precision);
draw_text_outline(1, _offset * 3, "[LMB] move cam to pos (when not following)", _outline_width, _precision);
draw_text_outline(1, _offset * 4, "[RMB] Zoom amount: " + string(zoom_text), _outline_width, _precision);
var _constrained = (cam1.room_constrain) ? "camera constrained to room" : "camera not constrained to room";
draw_text_outline(1, _offset * 5, "[CTRL] " + _constrained, _outline_width, _precision);
draw_text_outline(1, _offset * 6, "[F] camera shake", _outline_width, _precision);
draw_text_outline(1, _offset * 7, "[P] camera paused: " + (cam1.get_paused() ? "ON" : "OFF"), _outline_width, _precision);
draw_text_outline(1, _offset * 8, "[Tab] camera speed " + string(cam1.spd), _outline_width, _precision);
draw_text_outline(1, _offset * 9, "[B] smooth_draw: " + (cam1.smooth_draw ? "ON" : "OFF"), _outline_width, _precision);
draw_text_outline(1, _offset * 10, "[1 & 2 & 3] to switch between example rooms", _outline_width, _precision);

//draw current resolution text
draw_set_halign(fa_right)
draw_text_outline(global.gui_w - 1, 0, "Game size: " + string(global.game_w) + " x " + string(global.game_h), _outline_width, _precision);
draw_text_outline(global.gui_w - 1, _offset, "Resolution: " + string(global.res_w) + " x " + string(global.res_h) + " [F1]", _outline_width, _precision);
draw_text_outline(global.gui_w - 1, _offset * 2, "GUI resolution: " + string(global.gui_w) + " x " + string(global.gui_h) + " [F2]", _outline_width, _precision);
draw_text_outline(global.gui_w - 1, _offset * 3, "Keep aspect ratio: " + (stanncam_get_keep_aspect_ratio() ? "ON" : "OFF") + " [F3]", _outline_width, _precision);

var _window_mode_text = "";
switch (global.window_mode) {
	case STANNCAM_WINDOW_MODE.WINDOWED:
		_window_mode_text = "windowed";
		break;
	case STANNCAM_WINDOW_MODE.FULLSCREEN:
		_window_mode_text = "fullscreen";
		break;
	case STANNCAM_WINDOW_MODE.BORDERLESS:
		_window_mode_text = "borderless";
		break;
}

draw_text_outline(global.gui_w - 1, _offset * 4, "window mode: " + _window_mode_text + " [F4]", _outline_width, _precision);
draw_text_outline(global.gui_w - 1, _offset * 5, "split-screen: " + (split_screen ? "ON" : "OFF") + " [F5]", _outline_width, _precision);

//point at player, when it's outside camera bounds
if(cam1.out_of_bounds(obj_player.x, obj_player.y, 8)){
	var _x = cam1.room_to_gui_x(obj_player.x);
	var _y = cam1.room_to_gui_y(obj_player.y);
	
	var _margin = (gui_hires) ? 50 : 20;
	
	var _gui_scale_x = stanncam_get_gui_scale_x();
	var _gui_scale_y = stanncam_get_gui_scale_y();
	
	_x = clamp(_x, _margin, cam1.width * _gui_scale_x -_margin);
	_y = clamp(_y, _margin, cam1.height * _gui_scale_y -_margin);
	
	var _x2 = cam1.room_to_gui_x(obj_player.x);
	var _y2 = cam1.room_to_gui_y(obj_player.y);
	var _dir = point_direction(_x, _y, _x2, _y2);

	if(gui_hires){
		draw_sprite_ext(spr_arrow, 0, _x, _y, 1, 1, _dir - 90, -1, 1);
	} else {
		draw_sprite_ext(spr_arrow_small, 0, _x, _y, 1, 1, _dir - 90, -1, 1);
	}
} else {
	//draws pointer over players head
	var _arrow_x = cam1.room_to_gui_x(obj_player.x);
	var _arrow_y = cam1.room_to_gui_y(obj_player.y);
	if(gui_hires){
		draw_sprite_ext(spr_arrow, 1, _arrow_x, _arrow_y - 64, 0.5, 0.5, 180, -1, 1);
	} else {
		draw_sprite_ext(spr_arrow_small, 1, _arrow_x, _arrow_y - 12, 1, 1, 180, -1, 1);
	}
}

//draw pointer on mouse location
if(pointer){
	var _arrow_x = cam1.room_to_gui_x(pointer_x);
	var _arrow_y = cam1.room_to_gui_y(pointer_y);
	if(gui_hires){
		draw_sprite_ext(spr_arrow, 0, _arrow_x, _arrow_y, 1, 1, 180, -1, 1);
	} else {
		draw_sprite_ext(spr_arrow_small, 0, _arrow_x, _arrow_y, 1, 1, 180, -1, 1);
	}
}

var _x = cam1.get_mouse_x();
var _y = cam1.get_mouse_y();
draw_set_color(c_red)
draw_circle(cam1.room_to_gui_x(_x),cam1.room_to_gui_y(_y),15,true);
draw_set_color(c_white)
