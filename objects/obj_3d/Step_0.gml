/// @description

var forward = keyboard_check(ord("S")) - keyboard_check(ord("W"));
var right	= keyboard_check(ord("A")) - keyboard_check(ord("D"));
var up		= keyboard_check(vk_shift) - keyboard_check(vk_control);

if(forward != 0 || right != 0 || up != 0){
	//cam_3d.translate(right,up,forward);	
	cam_3d.translate_relative(right,forward,up)
}

if(mouse_check_button(mb_left)){
	var pitch = mouse_y - mouse_y_last
	var yaw   = mouse_x - mouse_x_last
	show_debug_message($"pitch {pitch} yaw {yaw}")
	
	cam_3d.rotate(-pitch,yaw);
}

mouse_x_last = mouse_x;
mouse_y_last = mouse_y;