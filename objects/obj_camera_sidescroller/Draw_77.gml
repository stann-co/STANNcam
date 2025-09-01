//background get's drawn behind, so when the game's aspect ratio doesn't match the windows, there's still some visuals
draw_sprite_tiled(spr_bg2, 0, 0, 0);

//fancy splitscreen rendering
var _width = global.res_w;
var _height = global.res_h;

//the parallax drawing is scaled down again
var _scalex = 1 / stanncam_get_res_scale_x();
var _scaley = 1 / stanncam_get_res_scale_y();

if(!split_screen){
	cam1.draw_special(parallax_bg1, 0, 0, _width, _height, _scalex, _scaley);
	cam1.draw(0, 0);
} else {
	//fancy splitscreen rendering
	cam1.draw_special(parallax_bg1, 0, 0, _width * 0.5, _height, _scalex, _scaley);
	cam1.draw(0, 0);
	
	cam2.draw_special(parallax_bg2, global.game_w * 0.5, 0, _width * 0.5, _height, _scalex, _scaley);
	cam2.draw(global.game_w * 0.5, 0);
}