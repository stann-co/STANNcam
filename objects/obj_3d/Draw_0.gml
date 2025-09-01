/// @description

gpu_set_ztestenable(true);
gpu_set_zwriteenable(true);

matrix_set(matrix_world,matrix_build(100,100,50,0,0,0,100,100,100));
shader_set(sh_3d)
vertex_submit(mesh,pr_trianglelist,-1);
shader_reset()

matrix_set(matrix_world,matrix_build_identity());

gpu_set_ztestenable(false);
gpu_set_zwriteenable(false);