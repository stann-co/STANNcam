//camera
resolutions = [
	{width:400,  height:400}, //1:1
	{width:500,  height:250}, //2:1
	{width:320,  height:180}, //16:9
	{width:640,  height:360},
	{width:1280, height:720},
	{width:1920, height:1080},
	{width:2560, height:1440},
];

gui_resolutions = [
	{width:320,  height:180}, //16:9
	{width:640,  height:360},
	{width:1280, height:720},
];

game_res = 4;
gui_res = 1;

stanncam_init(resolutions[2].width, resolutions[2].height, resolutions[game_res].width, resolutions[game_res].height, gui_resolutions[gui_res].width, gui_resolutions[gui_res].height);

cam1 = new stanncam(obj_player_sidescroller.x, obj_player_sidescroller.y, global.game_w, global.game_h);
cam1.follow = obj_player_sidescroller;
cam1.room_constrain = true;

cam1.debug_draw = true;

cam2 = cam1.clone();
cam2.follow = obj_player_sidescroller2;
cam2.set_size(global.game_w * 0.5, global.game_h, 0);

split_screen = false;

//pointer
zoom_text = cam1.zoom_amount;

speed_mode = 1;
zoom_mode = 1;

gui_hires = false;
gui_hires_scale = 6; //how much bigger the hires font is than the pixel one


lookahead = false;

draw_zones = false;

surface = -1;


parallax_bg = function(_cam){
	//the background is scaled up so it appears smooth when being parallaxed
	var _scalex = stanncam_get_res_scale_x();
	var _scaley = stanncam_get_res_scale_y();
	
	//the offset the camera is from the middle of the room
	var _offset_x = -_cam.get_x();
	var _pos_x = -200;
	var _pos_y = 0;
	
	draw_sprite_ext_tiled(spr_underwater_layer00, 0, _pos_x + (_offset_x * 0.0), _pos_y, 2, 1, _scalex, _scaley);
	draw_sprite_ext_tiled(spr_underwater_layer01, 0, _pos_x + (_offset_x * 0.2), _pos_y, 2, 1, _scalex, _scaley);
	draw_sprite_ext_tiled(spr_underwater_layer02, 0, _pos_x + (_offset_x * 0.4), _pos_y, 2, 1, _scalex, _scaley);
	draw_sprite_ext_tiled(spr_underwater_layer03, 0, _pos_x + (_offset_x * 0.6), _pos_y, 2, 1, _scalex, _scaley);
	draw_sprite_ext_tiled(spr_underwater_layer04, 0, _pos_x + (_offset_x * 0.8), _pos_y, 2, 1, _scalex, _scaley);
	draw_sprite_ext_tiled(spr_underwater_layer05, 0, _pos_x + (_offset_x * 1.0), _pos_y, 2, 1, _scalex, _scaley);
}

parallax_bg1 = function(){
	parallax_bg(cam1);
}

parallax_bg2 = function(){
	parallax_bg(cam2);
}
