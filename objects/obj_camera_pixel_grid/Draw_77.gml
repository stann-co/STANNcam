cam1.draw(0, 0);

var _dx = cam1.room_to_display_x(cam1.get_mouse_x());
var _dy = cam1.room_to_display_y(cam1.get_mouse_y());
draw_circle(_dx, _dy, 10, false);
