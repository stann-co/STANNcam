/// @description which sides to constrain
left = true;
top = true;
right = true;
bottom = true;

image_angle = (image_angle mod 360 + 360) mod 360;

if(image_angle mod 90 != 0){
	show_error(object_get_name(object_index) + ".image_angle must be a multiple of 90 degrees, got " + string(image_angle) + ".", true);
}

included_zones = [];

if(instance_exists(included_zone1)) array_push(included_zones,included_zone1);
if(instance_exists(included_zone2)) array_push(included_zones,included_zone2);
if(instance_exists(included_zone3)) array_push(included_zones,included_zone3);
if(instance_exists(included_zone4)) array_push(included_zones,included_zone4);
