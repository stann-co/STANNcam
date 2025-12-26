// Feather disable all

/// @constructor stanncam
/// @description creates a new stanncam
/// @param {Real} [_x=0] - X position
/// @param {Real} [_y=0] - Y position
/// @param {Real} [_width=global.game_w]
/// @param {Real} [_height=global.game_h]
/// @param {Bool} [_surface_extra_on=false] - use surface_extra in regular draw events
/// @param {Bool} [_smooth_draw=true] - use fractional camera position when drawing
function stanncam(_x=0, _y=0, _width=global.game_w, _height=global.game_h, _surface_extra_on=false, _smooth_draw=true) constructor{
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
	x = _x;
	y = _y;
	
	width = _width;
	height = _height;
	
	//offset the camera from whatever it's looking at
	offset_x = 0;
	offset_y = 0;
	
	follow = noone;
	
	//The extra surface is only neccesary if you are drawing the camera recursively in the room
	//Like a tv screen, where it can capture itself
	surface_extra_on = _surface_extra_on;
	
	//the first camera uses the application surface
	use_app_surface = cam_id == 0;
	
	spd = 10; //how fast the camera follows an instance
	spd_threshold = 50; //the minimum distance the camera is away, for the speed to be in full effect
	
	room_constrain = false; //if camera should be constrained to the room size
	
	//the camera bounding box, for the followed instance to leave before the camera starts moving
	bounds_w = 20;
	bounds_h = 20;
	bounds_dist_w = 0;
	bounds_dist_h = 0;
	
	//wether to use the fractional camera position when drawing the camera contents. Else it will be snapped to nearest integer
	smooth_draw = _smooth_draw;
	x_frac = 0;
	y_frac = 0;
	
	//which animation curve to use for moving/zooming the camera
	anim_curve = stanncam_ac_ease;
	anim_curve_zoom = stanncam_ac_ease;
	anim_curve_size = stanncam_ac_ease;
	anim_curve_offset = stanncam_ac_ease;
	
	surface = -1;
	surface_extra = -1;
	__surface_special = -1;
	
	debug_draw = false;
	
	__destroyed = false;
	
	//zone constrain
	__zone_constrain_amount = 0;
	__zone = noone;
	__zone_constrain_x = 0;
	__zone_constrain_y = 0;
	__zone_active = false;
	__zone_transition = 1;
	zone_constrain_speed = 0.1;

	paused = false;

	#region animation variables
	
	//moving
	__moving = false;
	__xStart = x;
	__yStart = y;
	__xTo = x;
	__yTo = y;
	__duration = 0;
	__t = 0;
	
	//width & height
	__size_change = false;
	__wStart = width;
	__hStart = height;
	__wTo = width;
	__hTo = height;
	__dimen_duration = 0;
	__dimen_t = 0;
	
	//offset
	__offset = false;
	__offset_xStart = 0;
	__offset_yStart = 0;
	__offset_xTo = 0;
	__offset_yTo = 0;
	__offset_duration = 0;
	__offset_t = 0;
	
	//zoom
	zoom_amount = 1;
	
	__zooming = false;
	zoom_x = 0;
	zoom_y = 0;
	__t_zoom = 0;
	__zoomStart = 0;
	__zoomTo = 0;
	__zoom_duration = 0;
	
	//screen shake
	__shake_length = 0;
	__shake_magnitude = 0;
	__shake_time = 0;
	__shake_x = 0;
	__shake_y = 0;
	
	__check_surface();
	__check_viewports();
	set_size(width, height);
	
	#endregion
	
#endregion

#region Step
	
	/// @function __step
	/// @description gets called every step
	/// @returns {Struct.stanncam}
	/// @ignore
	static __step = function(){

		//camera doesn't update if paused
		if(get_paused()){
			return;
		}

		#region moving
		if(instance_exists(follow)){
			
			//update destination
			__xTo = follow.x;
			__yTo = follow.y;
			
			var _x_dist = __xTo - x;
			var _y_dist = __yTo - y;
			
			bounds_dist_w = (max(bounds_w, abs(_x_dist)) - bounds_w) * sign(_x_dist);
			bounds_dist_h = (max(bounds_h, abs(_y_dist)) - bounds_h) * sign(_y_dist);
			
			bounds_dist_w = round(bounds_dist_w * 100) / 100; //rounds to 2 decimal places
			bounds_dist_h = round(bounds_dist_h * 100) / 100; //more decimal places may cause the position to fluctuate at certain points
			
			//update camera position
			if(abs(_x_dist) > bounds_w){
				var _spd = (bounds_dist_w / spd_threshold) * spd;
				if(smooth_draw) _spd = round(_spd);
				
				x += _spd;
			}
			
			if(abs(_y_dist) > bounds_h){
				var _spd = (bounds_dist_h / spd_threshold) * spd;
				if(smooth_draw) _spd = round(_spd);
				
				y += _spd;
			}
		
		} else if(__moving){
			__t++;
			
			//gradually moves camera into position based on duration
			x = stanncam_animcurve(__t, __xStart, __xTo, __duration, anim_curve);
			y = stanncam_animcurve(__t, __yStart, __yTo, __duration, anim_curve);
			
			if(__t >= __duration){
				__moving = false;
			}
		}
		#endregion
		
		#region zone constrain
		if(instance_exists(follow)){
			var new_zone = instance_position(follow.x, follow.y, obj_stanncam_zone);
			if(new_zone != noone){
				
				//if a zone is already active it will transition from one to the other
				if(__zone != new_zone && __zone_active) __zone_transition = 0;
				
				__zone_active = true;
				__zone = new_zone;
				
			} else {
				__zone_active = false;
			}
		}
		if(__zone_active){
			__zone_constrain_amount = lerp(__zone_constrain_amount, 1, zone_constrain_speed);
		} else {
			__zone_constrain_amount = lerp(__zone_constrain_amount, 0, zone_constrain_speed);
		}
		
		if(__zone_transition != 1){
			__zone_transition = lerp(__zone_transition, 1, zone_constrain_speed);
		}
		
		#endregion
		
		#region offset
		if(__offset){
			//gradually offsets camera based on duration
			offset_x = stanncam_animcurve(__offset_t, __offset_xStart, __offset_xTo, __offset_duration, anim_curve_offset);
			offset_y = stanncam_animcurve(__offset_t, __offset_yStart, __offset_yTo, __offset_duration, anim_curve_offset);
		
			__offset_t++;
			if(x == __offset_xTo && y == __offset_yTo) __offset = false;
		}
		#endregion
		
		#region screen-shake
		var _stanncam_shake_x = stanncam_shake(__shake_time, __shake_magnitude, __shake_length);
		var _stanncam_shake_y = stanncam_shake(__shake_time, __shake_magnitude, __shake_length);
		__shake_x = _stanncam_shake_x;
		__shake_y = _stanncam_shake_y;
		__shake_time++;
		#endregion
		
		#region zooming
			if(__zooming || __size_change){
				if(__size_change){
					//gradually resizes camera
					width = stanncam_animcurve(__dimen_t, __wStart, __wTo, __dimen_duration, anim_curve_size);
					height = stanncam_animcurve(__dimen_t, __hStart, __hTo, __dimen_duration, anim_curve_size);
					
					__dimen_t++;
					
					if(width == __wTo && height == __hTo) __size_change = false;
				}
				
				if(__zooming){
					//gradually zooms camera
					zoom_amount = stanncam_animcurve(__t_zoom, __zoomStart, __zoomTo, __zoom_duration, anim_curve_zoom);
					__t_zoom++;
					
					if(zoom_amount == __zoomTo) __zooming = false;
				}
			}
		#endregion
		
		__update_view_size();
		__update_view_pos();

		return self;
	}
#endregion
	
#region Dynamic functions
	
	/// @function clone
	/// @description returns a clone of the stanncam
	/// @returns {Struct.stanncam}
	/// @ignore
	static clone = function(){
		var _clone = new stanncam(x, y, width, height);
		_clone.surface_extra_on = surface_extra_on;
		_clone.offset_x = offset_x;
		_clone.offset_y = offset_y;
		_clone.spd = spd;
		_clone.spd_threshold = spd_threshold;
		_clone.room_constrain = room_constrain;
		_clone.bounds_w = bounds_w;
		_clone.bounds_h = bounds_h;
		_clone.follow = follow;
		_clone.smooth_draw = smooth_draw;
		_clone.anim_curve = anim_curve;
		_clone.anim_curve_zoom = anim_curve_zoom;
		_clone.anim_curve_offset = anim_curve_offset;
		_clone.anim_curve_size = anim_curve_size;
		_clone.paused = paused;
		
		return _clone;
	}
	
	/// @function move
	/// @description moves the camera to a position over a duration
	/// @param {Real} _x
	/// @param {Real} _y
	/// @param {Real} [_duration=0]
	/// @returns {Struct.stanncam}
	/// @ignore
	static move = function(_x, _y, _duration=0){
		if(_duration == 0 && !instance_exists(follow)){
			//view position is updated immediately
			x = _x;
			y = _y;
			__update_view_pos();
		} else {
			__moving = true;
			__t = 0;
			__xStart = x;
			__yStart = y;
			
			__xTo = _x;
			__yTo = _y;
			__duration = _duration;
		}

		return self;
	}
	
	/// @function set_size
	/// @description sets the camera dimensions
	/// @param {Real} _width
	/// @param {Real} _height
	/// @param {Real} [_duration=0]
	/// @returns {Struct.stanncam}
	/// @ignore
	static set_size = function(_width, _height, _duration=0){
		if(_duration == 0){ //if duration is 0 the view is updated immediately
			width = _width;
			height = _height;
			__update_view_size();
		} else {
			__size_change = true;
			__dimen_t = 0;
			__wStart = width;
			__hStart = height;
			
			__wTo = _width;
			__hTo = _height;
			__dimen_duration = _duration;
		}

		return self;
	}
	
	/// @function offset
	/// @description offsets the camera over a duration
	/// @param {Real} _offset_x
	/// @param {Real} _offset_y
	/// @param {Real} [_duration=0]
	/// @returns {Struct.stanncam}
	/// @ignore
	static offset = function(_offset_x, _offset_y, _duration=0){
		if(_duration == 0){ //if duration is 0 the view is updated immediately
			offset_x = _offset_x;
			offset_y = _offset_y;
			__update_view_pos();
		} else {
			__offset = true;
			__offset_t = 0;
			__offset_xStart = offset_x;
			__offset_yStart = offset_y;
			
			__offset_xTo = _offset_x;
			__offset_yTo = _offset_y;
			__offset_duration = _duration;
		}

		return self;
	}
	
	/// @function zoom
	/// @description zooms the camera over a duration
	/// @param {Real} _zoom
	/// @param {Real} [_duration=0]
	/// @returns {Struct.stanncam}
	/// @ignore
	static zoom = function(_zoom, _duration=0){
		if(_duration == 0){ //if duration is 0 the view is updated immediately
			zoom_amount = _zoom;
			
			//some rounding issues, so here we round to nearest second decimal place, IE 0.19999999 becomes 0.02, very edge case problem
			zoom_amount = round(zoom_amount * 100) / 100;

			zoom_x = ((width * zoom_amount) - width) * 0.5;
			zoom_y = ((height * zoom_amount) - height) * 0.5;
			
			if(!get_paused()){
				__update_view_size();
			}
		} else {
			__zooming = true;
			__t_zoom = 0;
			__zoomStart = zoom_amount;
			__zoomTo = _zoom;
			__zoom_duration = _duration;
		}

		return self;
	}
	
	/// @function get_zoom_x
	/// @description there's a difference in how zoom works with smooth_draw on/off if you need to use the zoom_amount while smooth_draw is off, you need to use this function
	/// @ignore
	static get_zoom_x = function(){
		if(smooth_draw) return zoom_amount;
		return surface_get_width(surface) / width;
	}
	
	/// @function get_zoom_y
	/// @description there's a difference in how zoom works with smooth_draw on/off if you need to use the zoom_amount while smooth_draw is off, you need to use this function
	/// @ignore
	static get_zoom_y = function(){
		if(smooth_draw) return zoom_amount;
		return surface_get_height(surface) / height;
	}
	
	/// @function shake_screen
	/// @description makes the camera shake
	/// @param {Real} _magnitude
	/// @param {Real} _duration - duration in frames
	/// @returns {Struct.stanncam}
	/// @ignore
	static shake_screen = function(_magnitude, _duration){
		__shake_magnitude = _magnitude;
		__shake_length = _duration;
		__shake_time = 0;
		return self;
	}
	
	/// @function set_speed
	/// @description changes the speed of the camera
	/// @param {Real} _spd - how fast the camera can move
	/// @param {Real} _threshold - minimum distance for the speed to have full effect
	/// @returns {Struct.stanncam}
	/// @ignore
	static set_speed = function(_spd, _threshold){
		spd = _spd;
		spd_threshold = _threshold;
		return self;
	}

	/// @function set_paused
	/// @description sets camera paused state
	/// @param {Bool} _paused
	/// @returns {Struct.stanncam}
	static set_paused = function(_paused){
		paused = _paused;
		return self;
	}

	/// @function get_paused
	/// @description gets camera's paused state
	/// @returns {Bool}
	static get_paused = function(){
		return paused;
	}

	/// @function toggle_paused
	/// @description toggles the camera's paused state
	/// @returns {Struct.stanncam}
	static toggle_paused = function(){
		set_paused(!get_paused());
		return self;
	}

	/// @function get_x
	/// @description get camera corner x position. if need the middle of the camera use x
	/// @returns {Real}
	/// @ignore
	static get_x = function(){
		return camera_get_view_x(__camera);
	}
	
	/// @function get_y
	/// @description get camera corner y position. if need the middle of the camera use y
	/// @returns {Real}
	/// @ignore
	static get_y = function(){
		return camera_get_view_y(__camera);
	}
	
	/// @function get_mouse_x
	/// @description gets the mouse x position within room relative to the camera
	/// @returns {Real}
	/// @ignore
	static get_mouse_x = function(){
		var _mouse_x = (((window_mouse_get_x() - stanncam_ratio_compensate_x()) / (__obj_stanncam_manager.__display_scale_x * width)) * width * get_zoom_x()) + get_x();
		if(smooth_draw) return _mouse_x;
		return _mouse_x - (_mouse_x mod get_zoom_x());
	}
	
	/// @function get_mouse_y
	/// @description gets the mouse y position within room relative to the camera
	/// @returns {Real}
	/// @ignore
	static get_mouse_y = function(){
		var _mouse_y = (((window_mouse_get_y() - stanncam_ratio_compensate_y()) / (__obj_stanncam_manager.__display_scale_y * height)) * height * get_zoom_y()) + get_y();
		if(smooth_draw) return _mouse_y;
		return _mouse_y - (_mouse_y mod get_zoom_y());
	}
	
	/// @function room_to_gui_x
	/// @description returns the room x position as the position on the gui relative to camera
	/// @param {Real} _x
	/// @returns {Real}
	/// @ignore
	static room_to_gui_x = function(_x){
		return ((_x - get_x() - x_frac) / get_zoom_x()) * stanncam_get_gui_scale_x();
	}
	
	/// @function room_to_gui_y
	/// @description returns the room y position as the position on the gui relative to camera
	/// @param {Real} _y
	/// @returns {Real}
	/// @ignore
	static room_to_gui_y = function(_y){
		return ((_y - get_y() - y_frac) / get_zoom_y()) * stanncam_get_gui_scale_y();
	}
	
	/// @function get_active_zone
	/// @description returns the active zone the followed instance is within, noone if outside, or no instance is followed
	/// @returns {Id.Instance|Noone}
	/// @ignore
	static get_active_zone = function(){
		if(__zone_active){
			return __zone;
		}
		return noone;
	}
	
	/// @function room_to_display_x
	/// @description returns the room x position as the position on the display relative to camera
	/// @param {Real} _x
	/// @returns {Real}
	function room_to_display_x(_x){
		return ((_x - get_x() - x_frac) / get_zoom_x()) * stanncam_get_res_scale_x();
	}
	
	/// @function room_to_display_y
	/// @description returns the room y position as the position on the display relative to camera
	/// @param {Real} _y
	/// @returns {Real}
	function room_to_display_y(_y){
		return ((_y - get_y() - y_frac) / get_zoom_y()) * stanncam_get_res_scale_y();
	}
	
	/// @function out_of_bounds
	/// @description returns if the position is outside of camera bounds
	/// @param {Real} _x
	/// @param {Real} _y
	/// @param {Real} [_margin=0]
	/// @returns {Bool}
	/// @ignore
	static out_of_bounds = function(_x, _y, _margin=0){
		var _cam_x = get_x();
		var _cam_y = get_y();
		var _col = //uses camera view bounding box
			(_x < (_cam_x + _margin)) ||
			(_y < (_cam_y + _margin)) ||
			(_x > ((_cam_x + (width * zoom_amount)) - _margin)) ||
			(_y > ((_cam_y + (height * zoom_amount)) - _margin))
		;

		return _col;
	}
	
	/// @function destroy
	/// @description marks the stanncam as destroyed
	/// @ignore
	static destroy = function(){
		camera_destroy(__camera);
		global.stanncams[cam_id] = -1;
		view_camera[cam_id] = -1;
		view_visible[cam_id] = false;
		--__obj_stanncam_manager.number_of_cams;
		follow = noone;
		if(surface_exists(surface)) surface_free(surface);
		if(surface_exists(surface_extra)) surface_free(surface_extra);
		if(surface_exists(__surface_special)) surface_free(__surface_special);
		__destroyed = true;
	}
	
	/// @function is_destroyed
	/// @returns {Bool}
	/// @ignore
	static is_destroyed = function(){
		return __destroyed;
	}
#endregion
	
#region Internal functions
	
	/// @function __check_viewports
	/// @description enables viewports and sets viewports size
	/// @returns {Struct.stanncam}
	/// @ignore
	static __check_viewports = function(){
		view_visible[cam_id] = true;
		view_camera[cam_id] = __camera;
		__check_surface();
		__update_view_size(true);
		return self;
	}
	
	/// @function __check_surface
	/// @description checks if surface & surface_extra exists and else creates it
	/// @returns {Struct.stanncam}
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

		return self;
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
	/// @returns {Struct.stanncam}
	/// @ignore
	static __update_view_size = function(_force=false){
		//if smooth_draw is off maintains pixel perfection even when zooming in and out
		//if on it is handled by the draw events
		if(smooth_draw){
			var _ceiled_zoom = ceil(zoom_amount); //ensures the new surface size is a whole number
			var _new_width = width * _ceiled_zoom  + 1; //smooth drawing needs the surface to be 1 pixel wider and taller to remove edge warping
			var _new_height = height * _ceiled_zoom + 1;
		} else {
			var _new_width = floor(width * zoom_amount);
			var _new_height = floor(height * zoom_amount);
			
			var _width_2px = _new_width mod 2;
			var _height_2px = _new_height mod 2;
			
			_new_width = _new_width - _width_2px;
			_new_height = _new_height - _height_2px;
		}
		//only runs if the size has changed (unless forced, used by __check_viewports to initialize)
		if(_force || surface_get_width(surface) != _new_width || surface_get_height(surface) != _new_height){
			__check_surface();
			surface_resize(surface,	_new_width, _new_height);
			camera_set_view_size(__camera, _new_width, _new_height);
		}

		return self;
	}

	/// @function __update_view_pos
	/// @description updates the view position
	/// @returns {Struct.stanncam}
	/// @ignore
	static __update_view_pos = function(){
		//update camera view
		var _new_x = x + offset_x - (width * 0.5) + __shake_x;
		var _new_y = y + offset_y - (height * 0.5) + __shake_y;
		
		if(!smooth_draw){// when smooth draw is off, the actual camera position gets rounded to whole numbers
			_new_x = round(_new_x);
			_new_y = round(_new_y);
		}
		
		//apply zoom offset
		_new_x -= zoom_x;
		_new_y -= zoom_y;
		
		if(smooth_draw){ //smooth drawing requires one extra pixel on the camera surface to remove edge warping, this is to fix the offset that occurs with that
			if(_new_x <= 0) _new_x -= 1;
			if(_new_y <= 0) _new_y -= 1;
		}

		//without smooth_draw zooming needs to be snapped a bit
		var _width_stepped = (width * zoom_amount);
		var _height_stepped = (height * zoom_amount);
		if(!smooth_draw){
			_width_stepped -= _width_stepped mod 2;
			_height_stepped -= _height_stepped mod 2;
		}

		//zone constricting
		if(__zone != noone){
			var _zone_constrain_x = 0;
			var _zone_constrain_y = 0;
			
			var _left, _right, _top, _bottom;
			
			if(__zone.left){
				_left = max(0, __zone.bbox_left - _new_x);
			}
			if(__zone.right){
				_right = -max(0, _new_x + _width_stepped - __zone.bbox_right);
			}
			if(__zone.top){
				_top = max(0, __zone.bbox_top - _new_y);
			}
			if(__zone.bottom){
				_bottom = -max(0, _new_y + _height_stepped - __zone.bbox_bottom);
			}
			
			//horizontal check
			if(__zone.sprite_width <= (_width_stepped) && __zone.left && __zone.right){
				//if the zones width is smaller than the camera and both left and right are constraining the cam will be pushed to its middle
				_zone_constrain_x = (__zone.x+__zone.sprite_width/2) - (_new_x+_width_stepped/2);
			} else {
				if(__zone.left) _zone_constrain_x += _left;
				if(__zone.right) _zone_constrain_x += _right;
			}
			
			//vertical check
			if(__zone.sprite_height <= (_height_stepped) && __zone.top && __zone.bottom){
				_zone_constrain_y = (__zone.y+__zone.sprite_height/2) - (_new_y+_height_stepped/2);
			} else {
				if(__zone.top)	_zone_constrain_y += _top;
				if(__zone.bottom) _zone_constrain_y += _bottom;
			}
			
			__zone_constrain_x = lerp(__zone_constrain_x, _zone_constrain_x, __zone_transition);
			__zone_constrain_y = lerp(__zone_constrain_y, _zone_constrain_y, __zone_transition);
		
			//constrains new camera position using constrain_amount
			_new_x += lerp(0, __zone_constrain_x, __zone_constrain_amount);
			_new_y += lerp(0, __zone_constrain_y, __zone_constrain_amount);
		}
		
		//Constrains camera to room
		if(room_constrain){
			__constrain_offset_x = (clamp(_new_x, 0, room_width - _width_stepped) - _new_x);
			__constrain_offset_y = (clamp(_new_y, 0, room_height - _height_stepped) - _new_y);
			
			_new_x += __constrain_offset_x;
			_new_y += __constrain_offset_y;
		} else {
			__constrain_offset_x = 0;
			__constrain_offset_y = 0;
		}
		
		if(smooth_draw){
			//seperates position into whole and fractional parts
			//when position is negative, fraction is too, and so this is to compensate for that
			
			if(_new_x > 0) x_frac = frac(_new_x);
			else x_frac = 1 + frac(_new_x);
					
			if(_new_y > 0) y_frac = frac(_new_y);
			else y_frac = 1 + frac(_new_y);
			
			_new_x = floor(abs(_new_x)) * sign(_new_x);
			_new_y = floor(abs(_new_y)) * sign(_new_y);
			
		}
		
		camera_set_view_pos(__camera, _new_x, _new_y);

		return self;
	}
#endregion

#region Drawing functions

	/// @function __debug_draw
	/// @description draws debug information
	/// @ignore
	static __debug_draw = function(){
		if(debug_draw){
			//draws camera bounding box
			if(instance_exists(follow)){
				surface_set_target(surface);
				
				var _pre_color = draw_get_color();
				
				var x_offset = -offset_x - __constrain_offset_x - (__zone_constrain_x * __zone_constrain_amount) + zoom_x;
				var y_offset = -offset_y - __constrain_offset_y - (__zone_constrain_y * __zone_constrain_amount) + zoom_y;
				
				var _x1 = (width * 0.5) - bounds_w + x_offset;
				var _x2 = (width * 0.5) + bounds_w + x_offset;
				var _y1 = (height * 0.5) - bounds_h + y_offset;
				var _y2 = (height * 0.5) + bounds_h + y_offset;
				draw_set_color(c_white);
				draw_rectangle(_x1, _y1, _x2, _y2, true);
				
				
				draw_set_color(c_red);
				
				//top
				if(bounds_dist_h != 0){
					if(bounds_dist_h < 0){
						//bottom
						draw_line(_x1, _y1, _x2, _y1);
					} else {
						draw_line(_x1, _y2, _x2, _y2);
					}
				}
				
				//left
				if(bounds_dist_w != 0){
					if(bounds_dist_w < 0){
						//right
						draw_line(_x1, _y1, _x1, _y2);
					} else {
						draw_line(_x2, _y1, _x2, _y2);
					}
				}
				
				draw_set_color(_pre_color);
				surface_reset_target();
			}
		}
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
		__debug_draw();
		draw_surf(surface, _x, _y, _scale_x, _scale_y, 0, 0, width, height);
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
		__debug_draw();
		draw_surf(surface, _x, _y, _scale_x, _scale_y, 0, 0, width, height, false);
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
		__debug_draw();
		draw_surf(surface, _x, _y, _scale_x, _scale_y, _left, _top, _width, _height);
	}
	
	/// @function draw_special
	/// @description pass in draw commands, and have them be scaled to match the stanncam
	/// @param {Function} _draw_func
	/// @param {Real} _x
	/// @param {Real} _y
	/// @param {Real} [_surf_width=width]
	/// @param {Real} [_surf_height=height]
	/// @param {Real} [_scale_x=1]
	/// @param {Real} [_scale_y=1]
	/// @ignore
	static draw_special = function(_draw_func, _x, _y, _surf_width=width, _surf_height=height, _scale_x=1, _scale_y=1){
		var _surf_width_scaled = floor(_surf_width * zoom_amount);
		var _surf_height_scaled = floor(_surf_height * zoom_amount);
		if(surface_exists(__surface_special)){
			if((surface_get_width(__surface_special) != _surf_width_scaled) || (surface_get_height(__surface_special) != _surf_height_scaled)){
				surface_free(__surface_special);
			}
		}
		if(!surface_exists(__surface_special)){
			__surface_special = surface_create(_surf_width_scaled, _surf_height_scaled);
		}
		
		surface_set_target(__surface_special);
		draw_clear_alpha(c_black, 0);
		_draw_func();
		surface_reset_target();
		
		draw_surf(__surface_special, _x, _y, _scale_x, _scale_y, 0, 0, _surf_width, _surf_height);
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

		if(smooth_draw){ //if smooth draw is off, the zoom amount becomes stepped to 0.02, and frac_x/y are 0
			_width *= zoom_amount;
			_height *= zoom_amount;
			_scale_x /= zoom_amount;
			_scale_y /= zoom_amount;
			
			draw_surface_part_ext(_surface, x_frac + _left, y_frac + _top, _width, _height, _x, _y, _display_scale_x * _scale_x, _display_scale_y * _scale_y, -1, 1);
		} else {
			var _width_stepped = _width * zoom_amount;
			var _height_stepped = _height * zoom_amount;
			
			_width_stepped -= _width_stepped mod 2;
			_height_stepped -= _height_stepped mod 2;
			
			_scale_x = _width / _width_stepped;
			_scale_y = _height / _height_stepped;

			draw_surface_part_ext(_surface, _left, _top, _width_stepped, _height_stepped, _x, _y, _display_scale_x * _scale_x, _display_scale_y * _scale_y, -1, 1);
		}
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
