cam1.draw(0, 0);
if(split_screen){
	cam2.draw(global.game_w * 0.5, 0);
}

var _x = cam1.get_mouse_x(); 
var _y = cam1.get_mouse_y();
draw_set_color(c_green)
//draw_circle(cam1.room_to_display_x(_x),cam1.room_to_display_y(_y),18,false);
draw_set_color(c_white)