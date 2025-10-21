//camera
stanncam_init(320, 180, 1280, 720, 640, 360);
cam1 = new stanncam(obj_player.x, obj_player.y, global.game_w, global.game_h, 0, 0);
cam1.follow = obj_player;

cam1.bounds_w = 10;
cam1.bounds_h = 10;

cam2 = undefined;

split_screen = false;

//pointer
pointer = false;
pointer_x = 0;
pointer_y = 0;

zoom_mode = 0;
zoom_text = cam1.zoom_amount;

speed_mode = 1;

game_res = 2;
gui_hires = false;
gui_res = 1;
gui_hires_scale = 6; //how much bigger the hires font is than the pixel one

resolutions = [
	{w:400, h:400}, //1:1
	{w:500, h:250}, //2:1
	{w:320, h:180}, //16:9
	{w:640, h:360},
	{w:1280, h:720},
	{w:1920, h:1080},
	{w:2560, h:1440}
];

gui_resolutions = [
	{w:320, h:180}, //16:9
	{w:640, h:360},
	{w:1280, h:720}
];

stanncam_debug_set_draw_zones(true);