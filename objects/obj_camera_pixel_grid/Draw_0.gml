/// @description
var dx = cam1.get_mouse_x();
var dy = cam1.get_mouse_y();



draw_set_color(c_red)
//var mx = (window_mouse_get_x() / stanncam_get_res_scale_x())-1;
//var my = (window_mouse_get_y() / stanncam_get_res_scale_y())-1;

draw_point(dx,dy);

draw_set_color(c_white)