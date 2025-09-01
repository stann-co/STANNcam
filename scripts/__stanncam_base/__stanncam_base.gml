// Feather disable all

/// @constructor stanncam
/// @description creates a new stanncam
/// @param {Real} [_width=global.game_w]
/// @param {Real} [_height=global.game_h]
/// @param {Bool} [_surface_extra_on=false] - use surface_extra in regular draw events
function __stanncam_base(_width=global.game_w,_height=global.game_h, _surface_extra_on = false) constructor{
#region init
	//whenever a new cam is created number_of_cams gets incremented
	cam_id = __obj_stanncam_manager.number_of_cams;
	
	//checks if there's already 8 cameras
	if(cam_id == 8){
		show_error("There can only be a maximum of 8 cameras.", true);
	}

	__camera = camera_create();
	view_camera[cam_id] = __camera;
	
	++__obj_stanncam_manager.number_of_cams;
	
	global.stanncams[cam_id] = self;
#endregion

#region variables

	width = _width;
	height = _height;
	surface = -1;
	surface_extra = -1;
	__zone = noone;
	
	debug_draw = false;
	
	//The extra surface is only neccesary if you are drawing the camera recursively in the room
	//Like a tv screen, where it can capture itself
	surface_extra_on = _surface_extra_on;
	
	//the first camera uses the application surface
	use_app_surface = cam_id == 0;
	
	__check_viewports();
	__update_view_size(true);
	
#endregion

#region step

	/// @function __step
	/// @description gets called every step
	/// @ignore
	static __step = function(){
		
	}
	
#endregion

#region internal functions

	/// @function __check_viewports
	/// @description enables viewports and sets viewports size
	/// @ignore
	static __check_viewports = function(){
		view_visible[cam_id] = true;
		view_camera[cam_id] = __camera;
		__check_surface();
		__update_view_size(true);
	}
	
	/// @function __check_surface
	/// @description checks if surface & surface_extra exists and else creates it
	/// @ignore
	static __check_surface = function(){
		if(use_app_surface){
			surface = application_surface;
		} else {
			if (!surface_exists(surface)){
				surface = surface_create(width, height);
			}
		}
		
		if(surface_extra_on && !surface_exists(surface_extra)){
			surface_extra = surface_create(width, height);
		}
	}
	
	/// @function __predraw
	/// @description clears the surface
	/// @ignore
	static __predraw = function(){
		__check_surface();
		if(surface_extra_on){
			surface_copy(surface_extra, 0, 0, surface);
		}

		surface_set_target(surface);
		draw_clear_alpha(c_black, 0);
		surface_reset_target()
		view_set_surface_id(cam_id, surface);
	}
	
	/// @function __update_view_size
	/// @description updates the view size
	/// @param {Bool} [_force=false]
	/// @ignore
	static __update_view_size = function(_force=false){
		if(_force || surface_get_width(surface) != width || surface_get_height(surface) != height){
			__check_surface();
			surface_resize(surface,	width, height);
			camera_set_view_size(__camera, width, height);
		}
	}
	
#endregion

#region draw functions

	/// @function __debug_draw
	/// @description draws debug information
	/// @ignore
	static __debug_draw = function(_x, _y, _scale_x, _scale_y){
		//empty in base
	}

	/// @function draw
	/// @description draws stanncam
	/// @param {Real} _x
	/// @param {Real} _y
	/// @param {Real} [_scale_x=1]
	/// @param {Real} [_scale_y=1]
	/// @ignore
	static draw = function(_x, _y, _scale_x=1, _scale_y=1){
		__check_surface();
		draw_surf(surface, _x, _y, _scale_x, _scale_y, 0, 0, width, height);
		__debug_draw(_x, _y, _scale_x, _scale_y);
	}
	
	/// @function draw_no_compensate
	/// @description draws stanncam but without being offset by stanncam_ratio_compensate
	/// @param {Real} _x
	/// @param {Real} _y
	/// @param {Real} [_scale_x=1]
	/// @param {Real} [_scale_y=1]
	/// @ignore
	static draw_no_compensate = function(_x, _y, _scale_x=1, _scale_y=1){
		__check_surface();
		draw_surf(surface, _x, _y, _scale_x, _scale_y, 0, 0, width, height, false);
		__debug_draw(_x, _y, _scale_x, _scale_y);
	}
	
	/// @function draw_part
	/// @description draws part of stanncam camera view
	/// @param {Real} _x
	/// @param {Real} _y
	/// @param {Real} _left
	/// @param {Real} _top
	/// @param {Real} _width
	/// @param {Real} _height
	/// @param {Real} [_scale_x=1]
	/// @param {Real} [_scale_y=1]
	/// @ignore
	static draw_part = function(_x, _y, _left, _top, _width, _height, _scale_x=1, _scale_y=1){
		__check_surface();
		draw_surf(surface, _x, _y, _scale_x, _scale_y, _left, _top, _width, _height);
		__debug_draw(_x, _y, _scale_x, _scale_y);
	}
	
		/// @function draw_surf
	/// @description draws the supplied surface with the proper size and scaling
	/// @param {Id.Surface} _surface
	/// @param {Real} _x
	/// @param {Real} _y
	/// @param {Real} [_scale_x=1]
	/// @param {Real} [_scale_y=1]
	/// @param {Real} [_left=0]
	/// @param {Real} [_top=0]
	/// @param {Real} [_width=width]
	/// @param {Real} [_height=height]
	/// @param {Bool} [_ratio_compensate=true]
	/// @ignore
	static draw_surf = function(_surface, _x, _y, _scale_x=1, _scale_y=1, _left=0, _top=0, _width=width, _height=height, _ratio_compensate=true){
		if(!surface_exists(_surface)){
			return;
		}

		//offsets position to match with display resoultion
		_x *= stanncam_get_res_scale_x();
		_y *= stanncam_get_res_scale_y();
		
		if(_ratio_compensate){
			_x += stanncam_ratio_compensate_x();
			_y += stanncam_ratio_compensate_y();
		}

		var _display_scale_x = __obj_stanncam_manager.__display_scale_x;
		var _display_scale_y = __obj_stanncam_manager.__display_scale_y;
			
		draw_surface_part_ext(_surface, _left, _top, _width, _height, _x, _y, _display_scale_x * _scale_x, _display_scale_y * _scale_y, -1, 1);
	}

#endregion

	/**
	 * @function toString
	 * @returns {String}
	 */
	static toString = function(){
		return "<stanncam[" + string(cam_id) + "] (" + string(width) + ", " + string(height) + ")>";
	}

}