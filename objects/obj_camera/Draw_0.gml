/// @description
var _x = cam1.get_mouse_x(); 
var _y = cam1.get_mouse_y();
//
//draw_circle(_x,_y,10,true);


var left    = cam1.__view_to_room_x(0) +2;
var top     = cam1.__view_to_room_y(0) +2;
var right   = cam1.__view_to_room_x(cam1.width)  -2;
var bottom  = cam1.__view_to_room_y(cam1.height) -2;


draw_set_color(c_red)
draw_point(left,top)
draw_point(right,bottom)
draw_set_color(c_white)