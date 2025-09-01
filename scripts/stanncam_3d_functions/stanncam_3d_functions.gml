/// @constructor stanncam_vec3
/// @description vector3 constructor for ease of use
function stanncam_vec3(_x,_y,_z) constructor {
	x = _x;
	y = _y;
	z = _z;	
	
	/// @function subtract
	/// @description subtracts vector
	/// @return subtracted vector
	/// @ignore
	static subtract = function(_vec){
		return new stanncam_vec3(x-_vec.x,y-_vec.y,z-_vec.z);
	}
	
	/// @function add
	/// @description add vector
	/// @return added vector
	/// @ignore
	static add = function(_vec){
		return new stanncam_vec3(x+_vec.x,y+_vec.y,z+_vec.z);
	}
	
	/// @function divide
	/// @description divides vector
	/// @return divided vector
	/// @ignore
	static divide = function(_vec){
		return new stanncam_vec3(x/_vec.x,y/_vec.y,z/_vec.z);
	}
	
	/// @function multiply
	/// @description multiply vector
	/// @return multiplied vector
	/// @ignore
	static multiply = function(_vec){
		return new stanncam_vec3(x*_vec.x,y*_vec.y,z*_vec.z);
	}
	
	/// @function scale
	/// @description scale vector
	/// @return scaled vector
	/// @ignore
	static scale = function(_scale){
		return new stanncam_vec3(x*_scale,y*_scale,z*_scale);
	}
	
	/// @function normalize
	/// @description Normalize 3D vector (make its length equal to 1)
	/// @return The normalized vector [x, y, z]
	/// @ignore
	static normalize = function() {
		// Calculate the length (magnitude) of the vector
		var length = sqrt(x * x + y * y + z * z);

		// Avoid division by zero
		if (length == 0) {
		    return new stanncam_vec3(0,0,0);
		}
		
		// Divide each component by the length
		return new stanncam_vec3( x / length, y / length, z / length);
	}
	
	/// @function cross
	/// @description cross product between 2 vectors
	/// @return cross product
	/// @ignore
	static cross = function(_v){
		return new stanncam_vec3(y * _v.z - z * _v.y,z * _v.x - x * _v.z,x * _v.y - y * _v.x);
	}
	
	/// @function length
	/// @description length of vector
	/// @return scalar length
	/// @ignore
	static length = function(){
		return sqrt(sqr(x) + sqr(y) + sqr(z));
	}
	
	/// @function transform
	/// @description transforms vector using matrix
	/// @return transformed vector
	/// @ignore
	static transform = function (mat) {
	    var vertex = matrix_transform_vertex(mat,x,y,z);
	    return new stanncam_vec3(vertex[0],vertex[1],vertex[2]);
	}
	
	/// @function rotate_by_axis
	/// @description rotates vector around axis by angle
	/// @return rotated vector
	/// @ignore
	static rotate_by_axis = function(axis, angle) {
		axis = axis.normalize();

	    // Precompute terms to save redundant calculations
	    var cos_theta = dcos(angle);
	    var sin_theta = dsin(angle);
	    var one_minus_cos = 1 - cos_theta;

	    // Axis components
	    var x_ = axis.x;
	    var y_ = axis.y;
	    var z_ = axis.z;

	    // Compute terms for the matrix
	    var m_xx = x_ * x_;
	    var m_xy = x_ * y_;
	    var m_xz = x_ * z_;
	    var m_yy = y_ * y_;
	    var m_yz = y_ * z_;
	    var m_zz = z_ * z_;

	    // Construct the 4x4 rotation matrix in column-major format
	    var m00 = cos_theta + one_minus_cos * m_xx;
	    var m01 = (1 - cos_theta) * m_xy + z_ * sin_theta;
	    var m02 = (1 - cos_theta) * m_xz - y_ * sin_theta;
	    var m10 = (1 - cos_theta) * m_xy - z_ * sin_theta;
	    var m11 = cos_theta + one_minus_cos * m_yy;
	    var m12 = (1 - cos_theta) * m_yz + x_ * sin_theta;
	    var m20 = (1 - cos_theta) * m_xz + y_ * sin_theta;
	    var m21 = (1 - cos_theta) * m_yz - x_ * sin_theta;
	    var m22 = cos_theta + one_minus_cos * m_zz;

	    // Build the 4x4 rotation matrix
	    var rotation_matrix = [
	        m00, m01, m02, 0,
	        m10, m11, m12, 0,
	        m20, m21, m22, 0,
	        0, 0, 0, 1
	    ];

	    // Apply the rotation matrix to the vector using transform
	    return transform(rotation_matrix);
	}
}

/// @function stanncam_3d_draw
/// @param _on bool
/// @description sets ztest & zwrite
function stanncam_3d_draw(_on){
	gpu_set_ztestenable( _on);
	gpu_set_zwriteenable(_on);
}

//// Function to create a rotation matrix from pitch, yaw, and roll
//function _stanncam_build_rotation_matrix(pitch, yaw, roll) {
//	var c_pitch = cos(pitch);
//	var s_pitch = sin(pitch);
//	var c_yaw	= cos(yaw);
//	var s_yaw	= sin(yaw);
//	var c_roll	= cos(roll);
//	var s_roll	= sin(roll);

//	// Pitch rotation matrix (around X-axis)
//	var pitch_matrix = [
//		[1, 0, 0],
//		[0, c_pitch, -s_pitch],
//		[0, s_pitch, c_pitch]
//	];

//	// Yaw rotation matrix (around Y-axis)
//	var yaw_matrix = [
//		[c_yaw, 0, s_yaw],
//		[0, 1, 0],
//		[-s_yaw, 0, c_yaw]
//	];

//	// Roll rotation matrix (around Z-axis)
//	var roll_matrix = [
//		[c_roll, -s_roll, 0],
//		[s_roll, c_roll, 0],
//		[0, 0, 1]
//	];

//	// Combine the matrices: first roll, then yaw, then pitch
//	var result_matrix = matrix_multiply(pitch_matrix, yaw_matrix);
//	result_matrix = matrix_multiply(result_matrix, roll_matrix);

//	return result_matrix;
//}