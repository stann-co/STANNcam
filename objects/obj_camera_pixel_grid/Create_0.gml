//camera
stanncam_init(100, 100, 1920, 1080, 300, 300);
cam1 = new stanncam(room_width / 2, room_height / 2, global.game_w, global.game_h, false, false);

zoom_mode = 0;
zoom_text = cam1.zoom_amount;

game_res = 0;

resolutions = [
	{w:400, h:400}, //1:1
	{w:500, h:250}, //2:1
	{w:320, h:180}, //16:9
	{w:1000, h:1000}, //1:1
	{w:1280, h:720},
];


hspd = 0;
vspd = 0;

acceleration_spd = 0.02;
deacceleration_spd = 0.1;
max_spd = 3;
