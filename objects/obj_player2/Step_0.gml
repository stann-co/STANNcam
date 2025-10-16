hspd = (keyboard_check_direct(ord("D")) - keyboard_check_direct(ord("A"))) * spd;
vspd = (keyboard_check_direct(ord("S")) - keyboard_check_direct(ord("W"))) * spd;

x += hspd;
y += vspd;

x = clamp(x, 0, room_width);
y = clamp(y, 0, room_height);