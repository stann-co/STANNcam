// Feather disable all

/// @constructor stanncam
/// @description creates a new stanncam
/// @param {Real} [_x=0] - X position
/// @param {Real} [_y=0] - Y position
/// @param {Real} [_width=global.game_w]
/// @param {Real} [_height=global.game_h]
/// @param {Bool} [_surface_extra_on=false] - use surface_extra in regular draw events
/// @param {Bool} [_smooth_draw=false] - use fractional camera position when drawing
function stanncam(_x=0, _y=0, _width=global.game_w, _height=global.game_h, _surface_extra_on=false, _smooth_draw=false) constructor{
#region init
	//whenever a new cam is created number_of_cams gets incremented
	cam_id = __obj_stanncam_manager.number_of_cams;
	
	//checks if there's already 8 cameras
	if(cam_id == 8){
		show_error("There can only be a maximum of 8 cameras.", true);
	}
	
	__camera = camera_create();
	view_camera[cam_id] = __camera;
	
	global.stanncams[cam_id] = self;
	++__obj_stanncam_manager.number_of_cams;
#endregion

#region variables
	//the first camera uses the application surface
	use_app_surface = cam_id == 0
	
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
	
	spd = 1; //how fast the camera follows an instance from 0-1
	
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
	//last list added to array the active list of zones
	__zone_lists_max = 4;
	__zone_lists = [noone]; //noone means no list of zones, ie, not constrained
	
	//how much strength each list of zones have
	//previous ones gradually fall to 0 and then get removed
	__zone_lists_strength = [1];
	
	__constrain_offset_x = 0;
	__constrain_offset_y = 0;
	
	__constrain_frac_x = 0;
	__constrain_frac_y = 0;
	
	__constrain_spd = 0.1;
	
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
			
			bounds_dist_w = floor((bounds_dist_w / 0.01) + 0.99) * 0.01;
			bounds_dist_h = floor((bounds_dist_h / 0.01) + 0.99) * 0.01;
			
			//update camera position
			if(bounds_dist_w != 0){
				var _spd = (bounds_dist_w) * spd;
				x += _spd;
			}
			
			if(bounds_dist_h != 0){
				var _spd = (bounds_dist_h) * spd;
				y += _spd;
			}
		
		} else if(__moving){
			//gradually moves camera into position based on duration
			x = stanncam_animcurve(__t, __xStart, __xTo, __duration, anim_curve);
			y = stanncam_animcurve(__t, __yStart, __yTo, __duration, anim_curve);

			__t = min(__t + 1, __duration);
			
			if(__t >= __duration){
				__moving = false;
				x = __xTo;
				y = __yTo;
			}
		}
		#endregion
		
		#region zone constrain
		if(instance_exists(follow)){
			
			var _zone_list = ds_list_create();
			var _zone_count = instance_position_list(follow.x, follow.y, obj_stanncam_zone, _zone_list, false);
			if(_zone_count != 0){
				
				//adds included zones to list
				for (var j = 0; j < _zone_count; j++) {
					var _zone = _zone_list[| j];
					var _included_zones_count = array_length(_zone.included_zones);
					if(_included_zones_count > 0){
						
						for (var i = 0; i < _included_zones_count; i++) {
							var _included_zone = _zone.included_zones[i];
							
							//included zones are added, unless they're already within the list
							if (ds_list_find_index(_zone_list, _included_zone) == -1){
								ds_list_add(_zone_list, _included_zone);
							}
						}
					}
				}
			} else {
				ds_list_destroy(_zone_list);
				_zone_list = noone;
			}
			
			var _active_list = array_last(__zone_lists);
			
			var _active_list_compare = noone;
			if(ds_exists(_active_list, ds_type_list)){
				_active_list_compare = ds_list_write(_active_list);
			}
			
			var _zone_list_compare = noone;
			if(ds_exists(_zone_list, ds_type_list)){
				_zone_list_compare = ds_list_write(_zone_list);
			}
			
			//if entering a new list of zones, it gets added to the zone_lists array. and the previous ones fade out over time
			if(_active_list_compare != _zone_list_compare){
				array_push(__zone_lists_strength, 0);
				array_push(__zone_lists, _zone_list);

				//ensures that the zone lists array has a max size
				if(array_length(__zone_lists) > __zone_lists_max){
					array_shift(__zone_lists_strength);
					
					//if the index being removed is a DS list, destroy it to prevent leaks
					if(ds_exists(__zone_lists[0], ds_type_list)){
						ds_list_destroy(__zone_lists[0]);
					}
					array_shift(__zone_lists);
				}
			}
			
			var _len = array_length(__zone_lists_strength) - 1;
			for (var k = 0; k <= _len; k++) {
				if(k != _len){
					__zone_lists_strength[k] = lerp(__zone_lists_strength[k], 0, __constrain_spd);
				} else {
					__zone_lists_strength[k] = lerp(__zone_lists_strength[k], 1, __constrain_spd);
				}
				
				if(__zone_lists_strength[k] == 0){
					array_delete(__zone_lists_strength, k, 1);
					
					//if the index being removed is a DS list, destroy it to prevent leaks
					if(ds_exists(__zone_lists[k], ds_type_list)){
						ds_list_destroy(__zone_lists[k]);
					}
					array_delete(__zone_lists, k, 1);
					
					_len = array_length(__zone_lists_strength) - 1;
					k--;
				}
			}
		}
		
		#endregion
		
		#region offset
		if(__offset){
			//gradually offsets camera based on duration
			offset_x = stanncam_animcurve(__offset_t, __offset_xStart, __offset_xTo, __offset_duration, anim_curve_offset);
			offset_y = stanncam_animcurve(__offset_t, __offset_yStart, __offset_yTo, __offset_duration, anim_curve_offset);
			
			__offset_t = min(__offset_t + 1, __offset_duration);

			if(__offset_t >= __offset_duration){
				__offset = false;
				offset_x = __offset_xTo;
				offset_y = __offset_yTo;
			}
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
				
				__dimen_t = min(__dimen_t + 1, __dimen_duration);

				if(__dimen_t >= __dimen_duration){
					__size_change = false;
					width = __wTo;
					height = __hTo;
				}
			}
			
			if(__zooming){
				//gradually zooms camera
				zoom_amount = stanncam_animcurve(__t_zoom, __zoomStart, __zoomTo, __zoom_duration, anim_curve_zoom);
				
				__t_zoom = min(__t_zoom + 1, __zoom_duration);

				if(__t_zoom >= __zoom_duration) {
					__zooming = false;
					zoom_amount = __zoomTo;
				}
			}
		}
		#endregion
		
		__update_view_pos();
		__update_view_size();
	}
#endregion
	
#region Dynamic functions
	
	/// @function clone
	/// @description returns a clone of the stanncam
	/// @returns {Struct.stanncam}
	static clone = function(){
		var _clone = new stanncam(x, y, width, height);
		_clone.offset_x = offset_x;
		_clone.offset_y = offset_y;
		_clone.follow = follow;
		_clone.surface_extra_on = surface_extra_on;
		_clone.spd = spd;
		_clone.room_constrain = room_constrain;
		_clone.bounds_w = bounds_w;
		_clone.bounds_h = bounds_h;
		_clone.smooth_draw = smooth_draw;
		_clone.anim_curve = anim_curve;
		_clone.anim_curve_zoom = anim_curve_zoom;
		_clone.anim_curve_size = anim_curve_size;
		_clone.anim_curve_offset = anim_curve_offset;
		_clone.debug_draw = debug_draw;
		_clone.paused = paused;
		
		_clone.__moving = __moving
		_clone.__xStart = __xStart
		_clone.__yStart = __yStart
		_clone.__xTo = __xTo
		_clone.__yTo = __yTo
		_clone.__duration = __duration
		_clone.__t = __t
		
		_clone.__size_change = __size_change
		_clone.__wStart = __wStart
		_clone.__hStart = __hStart
		_clone.__wTo = __wTo
		_clone.__hTo = __hTo
		_clone.__dimen_duration = __dimen_duration
		_clone.__dimen_t = __dimen_t
		
		_clone.__offset = __offset
		_clone.__offset_xStart = __offset_xStart;
		_clone.__offset_yStart = __offset_yStart;
		_clone.__offset_xTo = __offset_xTo;
		_clone.__offset_yTo = __offset_yTo;
		_clone.__offset_duration = __offset_duration;
		_clone.__offset_t = __offset_t;
		
		_clone.zoom_amount = zoom_amount
		
		_clone.__zooming = __zooming
		_clone.__t_zoom = __t_zoom
		_clone.__zoomStart = __zoomStart
		_clone.__zoomTo = __zoomTo
		_clone.__zoom_duration = __zoom_duration
		
		return _clone;
	}
	
	/// @function move
	/// @description moves the camera to a position over a duration
	/// @param {Real} _x
	/// @param {Real} _y
	/// @param {Real} [_duration=0]
	static move = function(_x, _y, _duration=0){
		if(_duration == 0 && follow == noone){
			//view position is updated immediately
			x = _x;
			y = _y;
            __moving = false;
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
	}
	
	/// @function set_size
	/// @description sets the camera dimensions
	/// @param {Real} _width
	/// @param {Real} _height
	/// @param {Real} [_duration=0]
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
	}
	
	/// @function offset
	/// @description offsets the camera over a duration
	/// @param {Real} _offset_x
	/// @param {Real} _offset_y
	/// @param {Real} [_duration=0]
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
	}
	
	/// @function zoom
	/// @description zooms the camera over a duration
	/// @param {Real} _zoom
	/// @param {Real} [_duration=0]
	static zoom = function(_zoom, _duration=0){
		if(_duration == 0){ //if duration is 0 the view is updated immediately
			zoom_amount = _zoom;
			
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
	}
	
	/// @function shake_screen
	/// @description makes the camera shake
	/// @param {Real} _magnitude
	/// @param {Real} _duration - duration in frames
	static shake_screen = function(_magnitude, _duration){
		__shake_magnitude = _magnitude;
		__shake_length = _duration;
		__shake_time = 0;
	}
	
	/// @function set_speed
	/// @description changes the speed of the camera
	/// @param {Real} _spd - how fast the camera follows from 0-1
	static set_speed = function(_spd){
		spd = _spd;
	}
	
	/// @function set_paused
	/// @description sets camera paused state
	/// @param {Bool} _paused
	static set_paused = function(_paused){
		paused = _paused;
	}
	
	/// @function get_paused
	/// @description gets camera's paused state
	/// @returns {Bool}
	static get_paused = function(){
		return paused;
	}
	
	/// @function toggle_paused
	/// @description toggles the camera's paused state
	static toggle_paused = function(){
		set_paused(!get_paused());
	}
	
	/// @function get_x
	/// @description get camera corner x position
	/// @returns {Real}
	static get_x = function(){
		var _x = camera_get_view_x(__camera);
		return _x + (width / 2) * ceil(zoom_amount - 1);
	}
	
	/// @function get_y
	/// @description get camera corner y position
	/// @returns {Real}
	static get_y = function(){
		var _y = camera_get_view_y(__camera);
		return _y + (height / 2) * ceil(zoom_amount - 1);
	}
	
	/// @function get_mouse_x
	/// @description gets the mouse x position within room relative to the camera
	/// @returns {Real}
	static get_mouse_x = function(){
		var _mouse_x = view_to_room_x((window_mouse_get_x() - stanncam_ratio_compensate_x()) / stanncam_get_res_scale_x());
		_mouse_x += __constrain_frac_x + __constrain_offset_x;
		return _mouse_x;
	}
	
	/// @function get_mouse_y
	/// @description gets the mouse y position within room relative to the camera
	/// @returns {Real}
	static get_mouse_y = function(){
		var _mouse_y = view_to_room_y((window_mouse_get_y() - stanncam_ratio_compensate_y()) / stanncam_get_res_scale_y());
		_mouse_y += __constrain_frac_y + __constrain_offset_y;
		return _mouse_y;
	}
	
	/// @function room_to_gui_x
	/// @description returns the room x position as the position on the gui relative to camera
	/// @param {Real} _x
	/// @returns {Real}
	static room_to_gui_x = function(_x){
		var _gui_x = _x - __constrain_offset_x - __constrain_frac_x;
		_gui_x = room_to_view_x(_gui_x) * stanncam_get_gui_scale_x() - 1;
		return _gui_x;
	}
	
	/// @function room_to_gui_y
	/// @description returns the room y position as the position on the gui relative to camera
	/// @param {Real} _y
	/// @returns {Real}
	static room_to_gui_y = function(_y){
		var _gui_y = _y - __constrain_offset_y - __constrain_frac_y;
		_gui_y = room_to_view_y(_gui_y) * stanncam_get_gui_scale_y() - 1;
		return _gui_y;
	}
	
	/// @function get_active_zone
	/// @description returns list of active zones the followed instance is within, noone if outside, or no instance is followed
	/// @returns {Id.Instance|Noone}
	static get_active_zone = function(){
		if(follow == noone) return noone;
		
		var _active_zones = array_last(__zone_lists);
		if(_active_zones != noone){
			return _active_zones;
		}
		return noone;
	}
	
	/// @function room_to_display_x
	/// @description returns the room x position as the position on the display relative to camera
	/// @param {Real} _x
	/// @returns {Real}
	function room_to_display_x(_x){
		var _display_x = _x - __constrain_offset_x - __constrain_frac_x;
		return room_to_view_x(_display_x) * stanncam_get_res_scale_x() + stanncam_ratio_compensate_x() - 1;
	}
	
	/// @function room_to_display_y
	/// @description returns the room y position as the position on the display relative to camera
	/// @param {Real} _y
	/// @returns {Real}
	function room_to_display_y(_y){
		var _display_y = _y - __constrain_offset_y - __constrain_frac_y;
		return room_to_view_y(_display_y) * stanncam_get_res_scale_y() + stanncam_ratio_compensate_y() - 1;
	}
	
	/// @function out_of_bounds
	/// @description returns if the position is outside of camera bounds
	/// @param {Real} _x
	/// @param {Real} _y
	/// @param {Real} [_margin=0]
	/// @returns {Bool}
	static out_of_bounds = function(_x, _y, _margin=0){
		_x = room_to_view_x(_x);
		_y = room_to_view_y(_y);
		
		var _col = //uses camera view bounding box
			(_x < (_margin)) ||
			(_y < (_margin)) ||
			(_x > (width - _margin)) ||
			(_y > (height - _margin))
		;
		
		return _col;
	}
	
	/// @function destroy
	/// @description marks the stanncam as destroyed
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
	static is_destroyed = function(){
		return __destroyed;
	}

	/// @function room_to_view_x
	/// @description room position to camera view
	/// @param {Real} [_x]
	static room_to_view_x = function(_x){
		var _zoom = __get_zoom();
		var _zoom_offset = (width * (1 - _zoom)) / 2;
		
		_x -= _zoom_offset + (x - width / 2) - 1;
		_x /= _zoom;
		
		return _x;
	}
	
	/// @function view_to_room_x
	/// @description camera view to room position
	/// @param {Real} [_x]
	static view_to_room_x = function(_x){
		var _zoom = __get_zoom();
		var _zoom_offset = (width * (1 - _zoom)) / 2;
		
		_x *= _zoom;
		_x += _zoom_offset + (x - width / 2) - 1;
		
		return _x;
	}
	
	/// @function room_to_view_y
	/// @description room position to camera view
	/// @param {Real} [_y]
	static room_to_view_y = function(_y){
		var _zoom = __get_zoom();
		var _zoom_offset = (height * (1 - _zoom)) / 2;
		
		_y -= _zoom_offset + (y - height / 2) - 1;
		_y /= _zoom;
		
		return _y;
	}
	
	/// @function view_to_room_y
	/// @description camera view to room position
	/// @param {Real} [_y]
	static view_to_room_y = function(_y){
		var _zoom = __get_zoom();
		var _zoom_offset = (height * (1 - _zoom)) / 2;
		
		_y *= _zoom;
		_y += _zoom_offset + (y - height / 2) - 1;
		
		return _y;
	}
#endregion
	
#region Internal functions
	
	/// @function __get_zoom
	/// @description gets zoom value, snapped if smooth draw is off
	/// @ignore
	static __get_zoom = function(){
		if(smooth_draw) return zoom_amount;
		else return floor((zoom_amount / 0.02) + 0.999) * 0.02;
	}
	
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

		surface_set_target(surface);
		draw_clear_alpha(c_black, 0);
		surface_reset_target();
		view_set_surface_id(cam_id, surface);
	}
	
	/// @function __postdraw
	/// @description postdraw drawing
	/// @ignore
	static __postdraw = function(){
		if(surface_extra_on){
			var _left = 0;
			var _top = 0;
			
			var _zoom_whole = ceil(zoom_amount - 1);
			_left -= (width / 2) * _zoom_whole;
			_top -= (height / 2) * _zoom_whole;
			
			surface_copy(surface_extra, _left, _left, surface);
		}
	}
	
	/// @function __update_view_size
	/// @description updates the view size
	/// @param {Bool} [_force=false]
	/// @ignore
	static __update_view_size = function(_force=false){
		//if zooming out the surface is scaled up
		var _zoom = ceil(zoom_amount);
		var _new_width = width * _zoom;
		var _new_height = height * _zoom;
		
		if(smooth_draw){ //smooth drawing needs the surface to be 1 pixel wider and taller to remove edge warping
			_new_width += 1;
			_new_height += 1;
		}
		
		//only runs if the size has changed (unless forced, used by __check_viewports to initialize)
		if(_force || surface_get_width(surface) != _new_width || surface_get_height(surface) != _new_height){
			__check_surface();
			surface_resize(surface,	_new_width, _new_height);
			camera_set_view_size(__camera, _new_width, _new_height);
		}
	}
	
	/// @function __update_view_pos
	/// @description updates the view position
	/// @ignore
	static __update_view_pos = function(){
		//update camera view
		var _new_x = x + offset_x - (width / 2) + __shake_x;
		var _new_y = y + offset_y - (height / 2) + __shake_y;
		
		var _zoom_whole = ceil(zoom_amount - 1);
		_new_x -= (width / 2) * _zoom_whole;
		_new_y -= (height / 2) * _zoom_whole;
		
		//round to nearest 0.01 decimal
		_new_x = floor(_new_x / 0.01 + 0.99) * 0.01;
		_new_y = floor(_new_y / 0.01 + 0.99) * 0.01;
		
		x_frac = frac(_new_x);
		y_frac = frac(_new_y);
		if(x_frac < 0) {
			x_frac++;
		}
		if(y_frac < 0){
			y_frac++;
		}
		
		_new_x = floor(_new_x);
		_new_y = floor(_new_y);
		
		#region constraining
		
		var _constrain_offset_x = array_create(array_length(__zone_lists), 0);
		var _constrain_offset_y = array_create(array_length(__zone_lists), 0);
		
		var _view_left    = view_to_room_x(0) + 1;
		var _view_right   = view_to_room_x(width) + 1;
		var _view_top     = view_to_room_y(0) + 1;
		var _view_bottom  = view_to_room_y(height) + 1;
		
		_view_left += offset_x;
		_view_right += offset_x;
		_view_top += offset_y;
		_view_bottom += offset_y;
		
		//zone constricting
		for (var l = 0; l < array_length(__zone_lists); l++) {
			
			if(__zone_lists[l] != noone){
				
				var _zone_left   = undefined;
				var _zone_right  = undefined;
				var _zone_top    = undefined;
				var _zone_bottom = undefined;
				
				//needs to loop through every zone & room bounds, to find narrowest relative to camera position
				// eg zone.right zone.left ect
				
				for (var z = 0; z < ds_list_size(__zone_lists[l]); z++) {
					var _zone = __zone_lists[l][| z];
					
					if(_zone.left ){ // if dist from the zone edge to the center is shorter than previous it takes over
						if(_zone_left == undefined || _zone.bbox_left < _zone_left){
							_zone_left = _zone.bbox_left;
						}
					}
					if(_zone.right){
						if(_zone_right == undefined || _zone.bbox_right > _zone_right){
							_zone_right = _zone.bbox_right;
						}
					}
					if(_zone.top){
						if(_zone_top == undefined || _zone.bbox_top < _zone_top){
							_zone_top = _zone.bbox_top;
						}
					}
					if(_zone.bottom){
						if(_zone_bottom == undefined || _zone.bbox_bottom > _zone_bottom){
							_zone_bottom = _zone.bbox_bottom;
						}
					}
				}
				
				//Constrains camera to zones/room bounds
				
				#region horizontal constraint
				var _zone_center_h = false;
				if(_zone_left != undefined && _zone_right != undefined){
					//if width of zone is narrower than width of camera, constrain to center
					var _zone_width = (_zone_right - _zone_left);
					if((_view_right - _view_left) > _zone_width){
						var _middle = ((_zone_left + _zone_right) / 2) - 1;
						_constrain_offset_x[l] = _middle - x - offset_x;
						_zone_center_h = true;
					}
				}
				
				if(!_zone_center_h && (_zone_left != undefined || _zone_right != undefined)){
					if(_zone_left != undefined){ //left zone
						_constrain_offset_x[l] -= min(_view_left - _zone_left, 0);
					}
					
					if(_zone_right != undefined){ //right zone
						_constrain_offset_x[l] -= max(_view_right - _zone_right, 0);
					}
				}
				
				#endregion
				
				#region vertical constraint
				var _zone_center_v = false;
				if(_zone_top != undefined && _zone_bottom != undefined){
					//if height of zone is narrower than height of camera, constrain to center
					var _zone_height = (_zone_bottom - _zone_top);
					if((_view_bottom - _view_top) > _zone_height){
						var _middle = ((_zone_top + _zone_bottom) / 2) - 1;
						_constrain_offset_y[l] = _middle - y - offset_y;
						_zone_center_v = true;
					}
				}
				
				if(!_zone_center_v && (_zone_top != undefined || _zone_bottom != undefined)){
					if(_zone_top != undefined){ //top zone
						_constrain_offset_y[l] -= min(_view_top - _zone_top, 0);
					}
					
					if(_zone_bottom != undefined){ //bottom zone
						_constrain_offset_y[l] -= max(_view_bottom - _zone_bottom , 0);
					}
				}
				#endregion
			}
		}
		
		__constrain_offset_x = 0;
		__constrain_offset_y = 0;
		
		for (var i = 0; i < array_length(__zone_lists_strength); i++) {
			__constrain_offset_x += _constrain_offset_x[i] * __zone_lists_strength[i];
			__constrain_offset_y += _constrain_offset_y[i] * __zone_lists_strength[i];
		}
		
		if(room_constrain){
			//Horizontal
			if((_view_right - _view_left) < room_width) {
				__constrain_offset_x = clamp(__constrain_offset_x, -_view_left, room_width - 1 - _view_right);
			} else {
				__constrain_offset_x = (room_width - (_view_right + _view_left)) / 2;
			}
			
			//Vertical
			if((_view_bottom - _view_top) < room_height) {
				__constrain_offset_y = clamp(__constrain_offset_y, -_view_top, room_height - 1 - _view_bottom);
			} else {
				__constrain_offset_y = (room_height - (_view_bottom + _view_top)) / 2;
			}
		}
		
		#region fractional constraint
		
		__constrain_frac_x = frac(__constrain_offset_x);
		if(__constrain_offset_x > 0){
			__constrain_offset_x = floor(__constrain_offset_x);
		} else if (__constrain_offset_x < 0) {
			__constrain_offset_x = ceil(__constrain_offset_x);
		}
		
		__constrain_frac_y = frac(__constrain_offset_y);
		if(__constrain_offset_y > 0){
			__constrain_offset_y = floor(__constrain_offset_y);
		} else if (__constrain_offset_y < 0){
			__constrain_offset_y = ceil(__constrain_offset_y);
		}
		
		#endregion
		
		_new_x += __constrain_offset_x;
		_new_y += __constrain_offset_y;
		
		#endregion
		
		//when smooth draw is off, the fractions are applied directly on the camera and not in draw step
		if(!smooth_draw){
			_new_x+=x_frac + __constrain_frac_x;
			_new_y+=y_frac + __constrain_frac_y;
		}
		
		camera_set_view_pos(__camera, _new_x, _new_y);
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
				
				var _x_offset = -offset_x - __constrain_offset_x;
				var _y_offset = -offset_y - __constrain_offset_y;
				
				var _zoom_whole = ceil(zoom_amount - 1);
				_x_offset += (width / 2) * _zoom_whole;
				_y_offset += (height / 2) * _zoom_whole;
				
				var _x1 = (width / 2) - bounds_w + _x_offset;
				var _x2 = (width / 2) + bounds_w + _x_offset;
				var _y1 = (height / 2) - bounds_h + _y_offset;
				var _y2 = (height / 2) + bounds_h + _y_offset;
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
	/// @param {Real} [_scale_x=1]
	/// @param {Real} [_scale_y=1]
	/// @param {Real} [_surf_width=width]
	/// @param {Real} [_surf_height=height]
	static draw_special = function(_draw_func, _x, _y, _scale_x=1, _scale_y=1, _surf_width=width, _surf_height=height){
		
		var _zoom = ceil(zoom_amount);
		var _surf_width_scaled = _surf_width * _zoom;
		var _surf_height_scaled = _surf_height * _zoom;
		
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
		
		var _zoom_whole = ceil(__get_zoom() - 1);
		var _draw_offset_x = (_surf_width / 2) * _zoom_whole;
		var _draw_offset_y = (_surf_height / 2) * _zoom_whole;
		
		//offsets drawing
		var _prev_matrix = matrix_get(matrix_world);
		var _offset_matrix = matrix_build(_draw_offset_x, _draw_offset_y, 0, 0, 0, 0, 1, 1, 1);
		matrix_set(matrix_world, matrix_multiply(_prev_matrix, _offset_matrix));
		_draw_func();
		//resets world matrix
		matrix_set(matrix_world, _prev_matrix);
		
		surface_reset_target();
		
		var _x_frac = 0;
		var _y_frac = 0;
		
		if(smooth_draw){
			_x_frac = x_frac + __constrain_frac_x;
			_y_frac = y_frac + __constrain_frac_y;
		}
		
		draw_surf(__surface_special, _x, _y, _scale_x, _scale_y, -_x_frac, -_y_frac, _surf_width, _surf_height);
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
		
		var _x_frac = 0;
		var _y_frac = 0;
		
		if(smooth_draw){
			_x_frac = x_frac + __constrain_frac_x;
			_y_frac = y_frac + __constrain_frac_y;
		}
		
		var _zoom = __get_zoom();
		_left += (_width * (1 - _zoom)) / 2;
		_top += (_height * (1 - _zoom)) / 2;
		
		var _zoom_whole = ceil(_zoom - 1);
		_left += (_width / 2) * _zoom_whole;
		_top += (_height / 2) * _zoom_whole;
		
		_width *= _zoom;
		_height *= _zoom;
		_scale_x /= _zoom;
		_scale_y /= _zoom;
		
		draw_surface_part_ext(_surface, _left + _x_frac, _top + _y_frac, _width, _height, _x, _y, _display_scale_x * _scale_x, _display_scale_y * _scale_y, -1, 1);
	}
#endregion

	/// @function toString
	/// @returns {String}
	static toString = function(){
		return "<stanncam[" + string(cam_id) + "] (" + string(width) + ", " + string(height) + ")>";
	}

}
