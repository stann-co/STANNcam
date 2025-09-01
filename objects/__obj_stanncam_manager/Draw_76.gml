var _len = array_length(global.stanncams);
for (var i = 0; i < _len; ++i){
	if(global.stanncams[i] == -1) continue;
	global.stanncams[i].__predraw();	
}
