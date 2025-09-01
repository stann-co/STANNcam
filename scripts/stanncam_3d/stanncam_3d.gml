// Feather disable all

/// @constructor stanncam_3d
/// @description creates a new 3d stanncam
/// @param {Real} [_width=global.game_w]
/// @param {Real} [_height=global.game_h]
/// @param {Bool} [_surface_extra_on=false] - use surface_extra in regular draw events
function stanncam_3d(_width=global.game_w, _height=global.game_h, _surface_extra_on=false, _smooth_draw=true) : __stanncam_base(_width, _height, _surface_extra_on) constructor{
	
	camera_set_begin_script(view_camera[cam_id],function(){
		stanncam_3d_draw(true);
	});
	
	debug_draw = true;
	
	fov = 45;
	
	spd = 4;
	
	cam_up = new stanncam_vec3(0,0,1)
	
	position_mat = matrix_build(0,0,0,0,0,0,1,1,1);
	scale_mat = matrix_build(0,0,0,0,0,0,1,1,1);
	rotation_mat = matrix_build(0,0,0,90,0,0,1,1,1);
	
	/// @function __step
	/// @description gets called every step
	/// @ignore
	static __step = function(){
		
		var viewmat = matrix_multiply(matrix_multiply(position_mat,scale_mat),rotation_mat);
		var projmat = matrix_build_projection_perspective_fov(fov,width/height,1,32000);
		
		camera_set_view_mat(__camera, viewmat);
		camera_set_proj_mat(__camera, projmat);
		camera_apply(__camera);
	}
	
	#region dynamic functions
		/// @function set_position
		/// @description sets camera position
		/// @ignore
		static set_position = function(_x,_y,_z){
			position = matrix_build(_x,_y,_z,0,0,0,1,1,1);
		}
		
		/// @function set_rotation
		/// @description sets camera rotation
		/// @ignore
		static set_rotation = function(_x,_y,_z){
			rotation = matrix_build(0,0,0,_x,_y,_z,1,1,1);
		}
		
		/// @function get_pitch
		/// @description get rotation x
		static get_pitch = function() {
		    var mat = rotation_mat;
		    // Extract pitch using atan2 (returns the angle in radians)
		    var pitch = arctan2(-mat[6], sqrt(mat[10] * mat[10] + mat[2] * mat[2]));

		    var cos_pitch = cos(pitch);
		    var sin_pitch = sin(pitch);

		    return [
		        1,        0,         0, 0,
		        0,        cos_pitch, -sin_pitch, 0,
		        0,        sin_pitch, cos_pitch, 0,
		        0,        0,         0, 1
		    ];
		}

		/// @function get_yaw
		/// @description get rotation y
		static get_yaw = function() {
		    var mat = rotation_mat;
		    // Extract yaw using atan2 (returns the angle in radians)
		    var yaw = arctan2(mat[2], mat[10]);

		    var cos_yaw = cos(yaw);
		    var sin_yaw = sin(yaw);

		    return [
		        cos_yaw,  0, sin_yaw, 0,
		        0,        1, 0,        0,
		        -sin_yaw, 0, cos_yaw, 0,
		        0,        0, 0,        1
		    ];
		}
		
		
		/// @function get_roll
		/// @description get rotation z
		/// @ignore
		static get_roll = function() {
		    var mat = rotation_mat;
		    // Extract roll using atan2 (returns the angle in radians)
		    var roll = arctan2(mat[4], mat[0]);
			
			var cos_roll = cos(roll);
		    var sin_roll = sin(roll);

		    return [
		        cos_roll, -sin_roll, 0, 0,
		        sin_roll, cos_roll,  0, 0,
		        0,        0,         1, 0,
		        0,        0,         0, 1
		    ];
		}
			
		/// @function get_right 
		/// @description gets right vector
		/// @ignore
		static get_right = function(){
			var mat = rotation_mat;
			return new stanncam_vec3(mat[0],mat[4],mat[8]).normalize();
		}
		
		/// @function get_forward
		/// @description gets forward vector
		/// @ignore
		static get_forward = function(){
			var mat = rotation_mat;
			return new stanncam_vec3(mat[2],mat[6],mat[10]).normalize();
		}
		
		/// @function get_up
		/// @description gets up vector
		/// @ignore
		static get_up = function(){
			var mat = rotation_mat;
			return new stanncam_vec3(mat[1],mat[5],mat[9]).normalize();
		}
		
		/// @function translate
		/// @description translate camera
		/// @ignore
		static translate = function(_x,_y,_z){
			var translation = matrix_build(_x,_y,_z,0,0,0,1,1,1);
			position_mat = matrix_multiply(position_mat,translation)
		}
		
		/// @function translate_relative
        /// @description translate camera relative to its rotation
        /// @ignore
        static translate_relative = function(_x, _y, _z) {
			var right = get_right();
			var forward = get_forward();
			var up = get_up();
			
			var tx = (right.x*_x + forward.x*_y + up.x*_z)*spd;
			var ty = (right.y*_x + forward.y*_y + up.y*_z)*spd;
			var tz = (right.z*_x + forward.z*_y + up.z*_z)*spd;
			
			var translation = [
				1,	0,	0,	0,
				0,	1,	0,	0,
				0,	0,	1,	0,
				tx,	ty,	tz,	1
			]
			position_mat = matrix_multiply(position_mat,translation)
        }
		
		/// @function rotate
		/// @description rotate camera
		/// @ignore
		static rotate = function(_pitch,_yaw){			

			var target = get_forward()
			var right = get_right();
			
			target = target.rotate_by_axis(cam_up,_yaw);
			target = target.rotate_by_axis(right,_pitch);
			
			rotation_mat = matrix_build_lookat(0,0,0,target.x,target.y,target.z,cam_up.x,cam_up.y,cam_up.z);
			
			//rotation_mat = matrix_multiply(rotation_mat,rotation);
		}
		

		
	#endregion
	
	#region draw functions
	
	/// @function __debug_draw
	/// @description draws debug information
	/// @ignore
	static __debug_draw = function(_x, _y, _scale_x, _scale_y){
		if(debug_draw){
			var gizmo_surf_ = surface_create(40,40)
			surface_set_target(gizmo_surf_);
				draw_clear_alpha(c_white,0)
			
				static gizmo = __gizmo_buffer();
				
				var world_matrix = matrix_get(matrix_world)
				matrix_set(matrix_world, matrix_multiply(rotation_mat,matrix_build(10,10,0,0,0,0,20,20,20)));
				shader_set(stanncam_sh_gizmo);
				vertex_submit(gizmo,pr_linelist,-1);
				shader_reset()
				matrix_set(matrix_world,world_matrix);
			surface_reset_target()			
			draw_surf(gizmo_surf_,_x,_y,_scale_x,_scale_y);
			surface_free(gizmo_surf_);			
		}
	}
	
	/// @function __gizmo_format
	/// @description vformat for a 3d gizmo
	/// @ignore
	static __gizmo_format = function(){
		vertex_format_begin()
		vertex_format_add_position_3d()
		vertex_format_add_color()		
		return vertex_format_end()
	}
	
	/// @function __gizmo_buffer
	/// @description vbuffer for a 3d gizmo
	/// @ignore
	static __gizmo_buffer = function(){
		static gizmo_format = __gizmo_format();
			
		var gizmo_ = vertex_create_buffer()
		vertex_begin(gizmo_,gizmo_format);
		vertex_position_3d(gizmo_,0,0,0);  vertex_color(gizmo_,c_red,1);
		vertex_position_3d(gizmo_,1,0,0);  vertex_color(gizmo_,c_red,1); //X
		vertex_position_3d(gizmo_,0,0,0);  vertex_color(gizmo_,c_green,1);
		vertex_position_3d(gizmo_,0,1,0);  vertex_color(gizmo_,c_green,1); //Y
		vertex_position_3d(gizmo_,0,0,0);  vertex_color(gizmo_,c_blue,1);
		vertex_position_3d(gizmo_,0,0,1);  vertex_color(gizmo_,c_blue,1); //Z
		vertex_end(gizmo_)
		return gizmo_;
	}
	#endregion
}

