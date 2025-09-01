/// @description

//camera
stanncam_init(200, 200, 1920, 1080, 300, 300);

cam_3d = new stanncam_3d(global.game_w,global.game_h,true);

cam_2d = new stanncam(0, 0, global.game_w, global.game_h, true, false);

cam_2d.follow = obj_player;



mesh = load_obj("3d.obj");

mouse_x_last = mouse_x;
mouse_y_last = mouse_y;