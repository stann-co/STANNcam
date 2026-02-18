// Feather disable all

#region Test stanncam constructor

function test_stanncam_constructor_checkDefaultValues() {
    var _ = new stanncam();
    assertEqual(_.x, 0);
    assertEqual(_.y, 0);
    assertEqual(_.width, global.game_w);
    assertEqual(_.height, global.game_h);
    assertFalse(_.surface_extra_on);
    assertFalse(_.smooth_draw);
}

function test_stanncam_constructor_createStanncamWithSpecifiedValues() {
    var _x = 100;
    var _y = 100;
    var _width = 800;
    var _height = 600;
    var _surface_extra_on = true;
    var _smooth_draw = false;
    var _ = new stanncam(_x, _y, _width, _height, _surface_extra_on, _smooth_draw);
    assertEqual(_.x, _x);
    assertEqual(_.y, _y);
    assertEqual(_.width, _width);
    assertEqual(_.height, _height);
    assertTrue(_.surface_extra_on);
    assertFalse(_.smooth_draw);
}

function test_stanncam_creatingMoreThan8Stanncams_shouldThrowAnError() {
    assertRaises(function() {
        repeat (8) {
            new stanncam();
        }
    });
}

function test_stanncam_creatingMoreThan8Stanncams_shouldThrowAnErrorMessage() {
    assertRaiseErrorValue(function() {
        repeat (8) {
            new stanncam();
        }
    }, "There can only be a maximum of 8 cameras.");
}

function test_stanncam_toString_shouldReturnAString() {
    var _ = parent.cam;
    assertEqual(typeof(_.toString()), "string");
}

#endregion
#region Test stanncam move

/// @ignore
function test_stanncam_moveWith0Duration_shouldBeAtNewMovePosition() {
    var _ = parent.cam;
    var _new_x = 100;
    var _new_y = 100;
    _.move(_new_x, _new_y, 0);
    assertEqual(_.x, _new_x);
    assertEqual(_.y, _new_y);
}

/// @ignore
function test_stanncam_moveWith1Duration_shouldBeAtTheSamePosition() {
    var _ = parent.cam;
    var _x_previous = _.x;
    var _y_previous = _.y;
    var _new_x = 100;
    var _new_y = 100;
    _.move(_new_x, _new_y, 1);
    assertEqual(_.x, _x_previous);
    assertEqual(_.y, _y_previous);
}

/// @ignore
function test_stanncam_moveWith1DurationAndInvokingStepOnce_shouldNotBeAtNewPosition() {
    var _ = parent.cam;
    var _new_x = 100;
    var _new_y = 100;
    _.move(_new_x, _new_y, 1);
    _.__step();
    assertEqual(_.x, _new_x);
    assertEqual(_.y, _new_y);
}

/// @ignore
function test_stanncam_moveWith1DurationAndInvokingStepTwice_shouldBeAtNewMovePosition() {
    var _ = parent.cam;
    var _new_x = 100;
    var _new_y = 100;
    _.move(_new_x, _new_y, 1);
    _.__step();
    _.__step();
    assertEqual(_.x, _new_x);
    assertEqual(_.y, _new_y);
}

/// @ignore
function test_stanncam_moveToSamePositionUntilNotMoving_shouldHaveTimeAndDurationEqual() {
    var _ = parent.cam;
    _.move(_.x, _.y, 5);
    // Keep track of time to prevent infinite loop
    var _start = current_time;
    var _end = _start + 10_000;
    while (current_time < _end) {
        if !_.__moving {
            break;
        }
        _.__step();
    }
    if current_time >= _end {
        show_debug_message($"TestCase {string_replace(string(_GMFUNCTION_), "gml_Script_", "")} timed out in {current_time - _start}ms");
    }
    assertEqual(_.__t, _.__duration);
}

/// @ignore
function test_stanncam_moveWith0DurationWhileFollowingObject_shouldBeAtPreviousPosition() {
    var _ = parent.cam;
    var _dummy = parent.dummy;
    _.move(_dummy.x, _dummy.y);
    var _x_previous = _.x;
    var _y_previous = _.y;
    _.follow = _dummy;
    _.move(1000, 1000);
    _.__step();
    assertEqual(_.x, _x_previous);
    assertEqual(_.y, _y_previous);
}

/// @ignore
function test_stanncam_moveWith1DurationWhileFollowingObject_shouldBeAtPreviousPosition() {
    var _ = parent.cam;
    var _dummy = parent.dummy;
    _.move(_dummy.x, _dummy.y);
    var _x_previous = _.x;
    var _y_previous = _.y;
    _.follow = _dummy;
    _.move(1000, 1000, 1);
    _.__step();
    assertEqual(_.x, _x_previous);
    assertEqual(_.y, _y_previous);
}

/// @ignore
function test_stanncam_moveWithADurationThenMoveWith0DurationThenStep_shouldBeAtSecondPosition() {
    var _ = parent.cam;
    _.move(-100, -100, 5);
    _.__step();
    var _new_x = 100;
    var _new_y = 50;
    _.move(_new_x, _new_y, 0);
    _.__step();
    assertEqual(_.x, _new_x);
    assertEqual(_.y, _new_y);
}

#endregion
#region Test stanncam offset

/// @ignore
function test_stanncam_offsetWith0Duration_shouldBeAtNewOffsetAmount() {
    var _ = parent.cam;
    var _new_offset_x = 100;
    var _new_offset_y = 50;
    _.offset(_new_offset_x, _new_offset_y, 0);
    assertEqual(_.offset_x, _new_offset_x);
    assertEqual(_.offset_y, _new_offset_y);
}

/// @ignore
function test_stanncam_offsetWith1DurationAndNotStepping_shouldBeAtSameOffsetAmount() {
    var _ = parent.cam;
    var _new_offset_x = 100;
    var _new_offset_y = 50;
    _.offset(_new_offset_x, _new_offset_y, 1);
    assertEqual(_.offset_x, 0);
    assertEqual(_.offset_y, 0);
}

/// @ignore
function test_stanncam_offsetWith1DurationAndStepping_shouldBeAtNewOffsetAmount() {
    var _ = parent.cam;
    var _new_offset_x = 100;
    var _new_offset_y = 50;
    _.offset(_new_offset_x, _new_offset_y, 1);
    _.__step();
    assertEqual(_.offset_x, _new_offset_x);
    assertEqual(_.offset_y, _new_offset_y);
}

#endregion
#region Test stanncam destroy

/// @ignore
function test_stanncam_creatingAndDestroyingStanncamNumberOfStanncams_shouldBeEqual() {
    var _num_of_cameras_before_creation = __obj_stanncam_manager.number_of_cams;
    var _ = new stanncam();
    var _num_of_cameras_after_creation = __obj_stanncam_manager.number_of_cams;
    _.destroy();
    var _num_of_cameras_after_destruction = __obj_stanncam_manager.number_of_cams;
    assertEqual(_num_of_cameras_before_creation + 1, _num_of_cameras_after_creation);
    assertEqual(_num_of_cameras_before_creation, _num_of_cameras_after_destruction);
}

/// @ignore
function test_stanncam_surfaceExistsAfterDestroy_shouldBeFalse() {
    var _ = new stanncam();
    _.use_app_surface = false;
    _.__update_view_size();
    var _surf = _.surface;
    _.destroy();
    assertFalse(surface_exists(_surf));
}

/// @ignore
function test_stanncam_stanncamMarkedIsDestroyedAfterDestroy_shouldBeTrue() {
    var _ = new stanncam();
    _.destroy();
    assertTrue(_.is_destroyed());
}

/// @ignore
function test_stanncam_destroyedStanncamCameraIndex_shouldBeNegative1() {
    var _ = new stanncam();
    var _id = _.cam_id;
    _.destroy();
    assertEqual(global.stanncams[_id], -1);
}

#endregion
#region Test stanncam clone

/// @ignore
function test_stanncam_cloningStanncamCamId_shouldBeNotEqualToPreviousStanncam() {
    var _ = new stanncam();
    var _clone = _.clone();
    assertNotEqual(_.cam_id, _clone.cam_id);
}

/// @ignore
function test_stanncam_cloningStanncamMoveXAndY_shouldBeAtMovePosition() {
    var _ = new stanncam();
    var _new_x = 100;
    var _new_y = 50;
    var _duration = 4;
    _.move(_new_x, _new_y, _duration);
    for(var i = 0; i < _duration; i++) {
        if i == 2 {
            _ = _.clone();
        }
        _.__step();
    }
    assertEqual(_.x, _new_x);
    assertEqual(_.y, _new_y);
}

#endregion
#region Test stanncam cam_id

/// @ignore
function test_stanncam_newStanncamId_shouldBeEqualToTheNumberOfCameras() {
    var _ = new stanncam();
    var _num_of_cameras = __obj_stanncam_manager.number_of_cams;
    assertEqual(_.cam_id, _num_of_cameras - 1);
    _.destroy();
}

/// @ignore
function test_stanncam_creatingSecondStanncamCamId_shouldBe1() {
    var _ = new stanncam();
    assertEqual(_.cam_id, 1);
    _.destroy();
}

/// @ignore
function test_stanncam_newStanncamCamId_shouldBe0() {
    var _ = parent.cam;
    assertEqual(_.cam_id, 0);
}

#endregion
#region Test stanncam pause

/// @ignore
function test_stanncam_getPausedOnNewStanncam_shouldBeFalse() {
    var _ = parent.cam;
    assertFalse(_.get_paused());
}

/// @ignore
function test_stanncam_setPausedToTrue_shouldBeTrue() {
    var _ = parent.cam;
    _.set_paused(true);
    assertTrue(_.paused);
}

/// @ignore
function test_stanncam_setPausedToFalse_shouldBeFalse() {
    var _ = parent.cam;
    _.set_paused(false);
    assertFalse(_.paused);
}

/// @ignore
function test_stanncam_setPausedToFalseAfterTrue_shouldBeFalse() {
    var _ = parent.cam;
    _.set_paused(true);
    _.set_paused(false);
    assertFalse(_.paused);
}

/// @ignore
function test_stanncam_togglePausedOnNewStanncam_shouldBeTrue() {
    var _ = parent.cam;
    _.toggle_paused();
    assertTrue(_.paused);
}

#endregion
#region Test stanncam __update_view_size

/// @ignore
function test_stanncamUpdateViewSize_invokeUpdateViewSize_shouldCreateSurface() {
    var _ = parent.cam;
    _.use_app_surface = false;
    _.__update_view_size();
    assertTrue(surface_exists(_.surface), "Expected stanncam.surface to exist.");
}

/// @ignore
function test_stanncamUpdateViewSize_invokeUpdateViewSizeWithSmoothDraw_shouldCreateSurfaceUsingWidthAndHeightPlus1Pixel() {
    var _ = parent.cam;
	_.smooth_draw = true
    _.use_app_surface = false;
    _.__update_view_size();
    assertEqual(_.width + 1, surface_get_width(_.surface));
    assertEqual(_.height + 1, surface_get_height(_.surface));
}

/// @ignore
function test_stanncamUpdateViewSize_invokeUpdateViewSizeWithoutSmoothDraw_shouldCreateSurfaceUsingWidthAndHeight() {
    var _ = parent.cam;
    _.use_app_surface = false;
    _.__update_view_size();
    assertEqual(_.width, surface_get_width(_.surface));
    assertEqual(_.height, surface_get_height(_.surface));
}

/// @ignore
function test_stanncamUpdateViewSize_updateZoomToHalf_shouldNotResizeSurface() {
    var _ = parent.cam;
    _.use_app_surface = false;
    _.__update_view_size();
    var _width = surface_get_width(_.surface);
    var _height = surface_get_height(_.surface);
    var _zoom_amount = 0.5;
    _.zoom(_zoom_amount);
    _.__update_view_size();
    assertEqual(_width, surface_get_width(_.surface));
    assertEqual(_height, surface_get_height(_.surface));
}

/// @ignore
function test_stanncamUpdateViewSize_invokeUpdateViewSizeZoomAmount_shouldBeEqualTo1() {
    var _ = parent.cam;
    _.use_app_surface = false;
    _.__update_view_size();
    assertEqual(_.zoom_amount, 1, "Expected a stanncam with no zoom modifications to have a zoom_amount of 1, actual " + string(_.zoom_amount) + ".");
}

/// @ignore
function test_stanncamUpdateViewSize_updateZoomToHalf_shouldUpdateZoomAmountToHalf() {
    var _ = parent.cam;
    _.use_app_surface = false;
    var _zoom_amount = 0.5;
    _.zoom(_zoom_amount);
    _.__update_view_size();
    assertEqual(_.zoom_amount, _zoom_amount);
}

/// @ignore
function test_stanncamUpdateViewSize_updateZoomToDouble_shouldUpdateZoomAmountToDouble() {
    var _ = parent.cam;
    _.use_app_surface = false;
    var _zoom_amount = 2;
    _.zoom(_zoom_amount);
    _.__update_view_size();
    assertEqual(_.zoom_amount, _zoom_amount);
}

#endregion
#region Test stanncam zoom

/// @ignore
function test_stanncamZoom_whenZoomingOnInstance_shouldUpdateXAndYPositionsToInstance() {
    var _ = parent.cam;
    var _dummy = parent.dummy;
    _.bounds_w = 0;
    _.bounds_h = 0;
    _.follow = _dummy;
    _.room_constrain = false;
    _.zoom(0.25);
    repeat (1000) {
        _.__step();
    }
    assertEqual(_.x, _dummy.x);
    assertEqual(_.y, _dummy.y);
}

#endregion
#region Test stanncam draw

/// @ignore
function test_stanncam_draw_shouldNotThrowError() {
    var __ = {};
    var _ = parent.cam;
    with (__) {
        cam = _;
        test = function() {
            self.cam.draw(0, 0);
        };
    }
    assertDoesNotThrow(__.test);
}

#endregion
