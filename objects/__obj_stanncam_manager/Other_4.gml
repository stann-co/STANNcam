view_enabled = true;
var _len = array_length(global.stanncams);
for (var i = 0; i < _len; ++i){
	var _cam = global.stanncams[i];
	if(_cam == -1) continue;
	_cam.__check_viewports();
	
	//if following something, snap the camera to it on room start
	if(instance_exists(_cam.follow)){
		_cam.move(_cam.follow.x, _cam.follow.y, 0);
	}
}

__stanncam_update_resolution();
