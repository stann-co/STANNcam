///@function load_obj(filepath)
function load_obj(filepath){
	var buffer = buffer_load(filepath);
	var content_String = buffer_read(buffer,buffer_text);
	buffer_delete(buffer);
	
	static vf = __make_vertex_format();
	
	static px = buffer_create(10000, buffer_grow, 4);
	static py = buffer_create(10000, buffer_grow, 4);
	static pz = buffer_create(10000, buffer_grow, 4);
	static cr = buffer_create(10000, buffer_grow, 4);
	static cg = buffer_create(10000, buffer_grow, 4);
	static cb = buffer_create(10000, buffer_grow, 4);
	static nx = buffer_create(10000, buffer_grow, 4);
	static ny = buffer_create(10000, buffer_grow, 4);
	static nz = buffer_create(10000, buffer_grow, 4);
	
	buffer_seek(px, buffer_seek_start, 4);
	buffer_seek(py, buffer_seek_start, 4);
	buffer_seek(pz, buffer_seek_start, 4);
	buffer_seek(cr, buffer_seek_start, 4);
	buffer_seek(cg, buffer_seek_start, 4);
	buffer_seek(cb, buffer_seek_start, 4);
	buffer_seek(nx, buffer_seek_start, 4);
	buffer_seek(ny, buffer_seek_start, 4);
	buffer_seek(nz, buffer_seek_start, 4);
	
	var lines = string_split(content_String,"\n");
	
	var vb = vertex_create_buffer();
	vertex_begin(vb,vf);
	
	var i = 0;
	repeat (array_length(lines)) {
	    var this_line = lines[i++];
	    if (this_line == "") continue;
	    
	    var tokens = string_split(this_line, " ");
	    
		switch (tokens[0]) {
	    case "v":
	        buffer_write(px, buffer_f32, real(tokens[1])); //position
	        buffer_write(py, buffer_f32, real(tokens[3]));
	        buffer_write(pz, buffer_f32, real(tokens[2]));
			buffer_write(cr, buffer_f32, real(tokens[4])); //color
	        buffer_write(cg, buffer_f32, real(tokens[5]));
	        buffer_write(cb, buffer_f32, real(tokens[6]));
	        break;
	    case "vn":
	        buffer_write(nx, buffer_f32, real(tokens[1]));
	        buffer_write(ny, buffer_f32, real(tokens[3]));
	        buffer_write(nz, buffer_f32, real(tokens[2]));
	        break;
	    case "f":
			var o = 1;
			repeat(3){
				var slots = string_split(tokens[o++],"/");
				var pos_x = buffer_peek(px,real(slots[0])*4,buffer_f32);
				var pos_y = buffer_peek(py,real(slots[0])*4,buffer_f32);
				var pos_z = buffer_peek(pz,real(slots[0])*4,buffer_f32);
														 
				var col_r = buffer_peek(cr,real(slots[0])*4,buffer_f32);
				var col_g = buffer_peek(cg,real(slots[0])*4,buffer_f32);
				var col_b = buffer_peek(cb,real(slots[0])*4,buffer_f32);
														 
				var nor_x = buffer_peek(nx,real(slots[2])*4,buffer_f32);
				var nor_y = buffer_peek(ny,real(slots[2])*4,buffer_f32);
				var nor_z = buffer_peek(nz,real(slots[2])*4,buffer_f32);
				
				vertex_position_3d(vb, pos_x, pos_y, pos_z);
				vertex_normal(vb, nor_x, nor_y, nor_z);
				var color = make_color_rgb(col_r*255,col_g*255,col_b*255);
				vertex_color(vb,color,1);
	        }
	    }	
	}
	vertex_end(vb);
	vertex_freeze(vb);
	
	return vb
}

function __make_vertex_format(){
		vertex_format_begin()
		vertex_format_add_position_3d()
		vertex_format_add_normal()
		vertex_format_add_color()
		return vertex_format_end()
}