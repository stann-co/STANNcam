//draw circle over cursor pos

var _dx = cam1.get_mouse_x();
var _dy = cam1.get_mouse_y();
var _size = 10;

_dx = cam1.room_to_gui_x(_dx);
_dy = cam1.room_to_gui_y(_dy);

draw_line(_dx - _size, _dy, _dx + _size, _dy);
draw_line(_dx, _dy - _size, _dx, _dy + _size);

var _outline_width = 1;
var _precision = 8;
var _offset = 10;

//draws helper text
draw_set_halign(fa_left);
draw_set_valign(fa_top);
draw_text_outline(1, 0, "[RMB] Zoom amount: " + string(zoom_text), _outline_width, _precision);
draw_text_outline(1, _offset * 1, "[F] camera shake", _outline_width, _precision);
draw_text_outline(1, _offset * 2, "[P] camera paused: " + (cam1.get_paused() ? "ON" : "OFF"), _outline_width, _precision);
draw_text_outline(1, _offset * 3, "[B] smooth camera: " + (cam1.smooth_draw ? "ON" : "OFF"), _outline_width, _precision);
draw_text_outline(1, _offset * 4, "[1 & 2 & 3] to switch", _outline_width, _precision);
draw_text_outline(1, _offset * 5, "between example rooms", _outline_width, _precision);

//draw current camera position
draw_set_halign(fa_right);
draw_text_outline(-1, 0, $"x:{cam1.get_x()} y:{cam1.get_y()} ", _outline_width, _precision);
draw_text_outline(-1, _offset * 1, $"x_frac:{cam1.x_frac} y_frac:{cam1.y_frac} ", _outline_width, _precision);

//draw current resolution text
draw_set_halign(fa_right);
draw_text_outline(global.gui_w - 1, 0, "Game size: " + string(global.game_w) + " x " + string(global.game_h), _outline_width, _precision);
draw_text_outline(global.gui_w - 1, _offset * 1, "Resolution: " + string(global.res_w) + " x " + string(global.res_h) + " [F1]", _outline_width, _precision);
draw_text_outline(global.gui_w - 1, _offset * 2, "Keep aspect ratio: " + string(stanncam_get_keep_aspect_ratio()) + " [F3]", _outline_width, _precision);
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

draw_text_outline(global.gui_w - 1, _offset * 3, "window mode: " + _window_mode_text + " [F4]", _outline_width, _precision);

var _mx = cam1.room_to_gui_x(cam1.get_mouse_x());
var _my = cam1.room_to_gui_y(cam1.get_mouse_y());
draw_set_halign(fa_left);
draw_text(_mx, _my, $"{_mx} {_my}");
