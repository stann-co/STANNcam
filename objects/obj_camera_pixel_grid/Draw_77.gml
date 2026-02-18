cam1.draw(0, 0);

var dx = cam1.room_to_display_x(cam1.get_mouse_x());
var dy = cam1.room_to_display_y(cam1.get_mouse_y());
draw_circle(dx, dy, 10, false);
