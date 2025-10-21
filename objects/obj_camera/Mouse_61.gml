var _zoom_amount = cam1.zoom_amount;
_zoom_amount += 0.01;
_zoom_amount = clamp(_zoom_amount, 0.1, 3);
cam1.zoom(_zoom_amount, 0);
obj_tv.tv.zoom(_zoom_amount, 0);
