// Inherit the parent event
event_inherited();

left = function(){
	return keyboard_check_direct(ord("A"));
}
right = function(){
	return keyboard_check_direct(ord("D"));
}
jump = function(){
	return keyboard_check_pressed(ord("W"));
}
