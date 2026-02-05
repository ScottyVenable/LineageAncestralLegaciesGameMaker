/// obj_pop – Draw Event
///
/// Purpose:
///    Render the pop sprite. Displays colored name and state text if hovered
///    OR if this pop is the only one selected.
///    Draws selection highlight and command indicator.
///
/// Metadata:
///    Summary:         Draws pop and its UI elements, with name/state shown on hover or sole selection.
///    Usage:           obj_pop Draw Event
///    Parameters:    none
///    Returns:         void
///    Tags:            [rendering][ui][pop_feedback]
///    Version:         1.20 - 2024-05-19 // Scotty's Current Date - Name/State visible if solely selected
///    Dependencies:  EntityState enum, EntitySex enum, scr_get_state_name, global.selected_pops_list,
///                     fnt_pop_displayname, fnt_state, various c_ color constants,
///                     Instance variables: selected, state, image_xscale, image_yscale, x, y,
///                     is_mouse_hovering, pop_identifier_string, sex, travel_point_x, travel_point_y.

// ============================================================================
// 0. IMPORTS & CACHES
// ============================================================================
#region 0.1 Imports & Cached Locals
var _sprite_asset = sprite_index; 
var _base_sprite_w = sprite_get_width(_sprite_asset);
var _base_sprite_h = sprite_get_height(_sprite_asset);
var _scaled_sprite_w = _base_sprite_w * image_xscale;
var _scaled_sprite_h = _base_sprite_h * image_yscale;

var _x_pop      = x; 
var _y_pop      = y; 
var _state_current = state; 
var _time       = current_time; 
var _pop_sex    = variable_instance_exists(id, "sex") ? sex : undefined;

// Determine if name/state text should be visible
var _show_details_text = false;
if (is_mouse_hovering) { // Condition 1: Mouse is hovering
    _show_details_text = true;
} else if (selected) { // Condition 2: This pop is selected...
    if (variable_global_exists("selected_pops_list") && ds_exists(global.selected_pops_list, ds_type_list)) {
        if (ds_list_size(global.selected_pops_list) == 1) {
            // ...and it's the only one in the list (safety check, assuming list contains this pop's id)
            if (global.selected_pops_list[| 0] == id) {
                 _show_details_text = true;
            }
        }
    } else {
        // Fallback if global.selected_pops_list isn't set up yet, but pop.selected is true (single click selection maybe)
        // This part is a bit of a guess at how your single-selection might work without the list.
        // If you have another way to confirm it's the *only* selection, use that.
        // For now, we'll assume if the list isn't there, `selected` alone might mean single selection.
        // This can be refined once global.selected_pops_list is confirmed to be robust.
        // Consider if obj_controller.selected_pop == id as an alternative here for single selection tracking.
        // For safety, let's require the list for now for non-hover display.
        // _show_details_text = true; // Example if `selected` implies single without list.
    }
}
#endregion


// ============================================================================
// 1. DRAW BASE SPRITE
// ============================================================================
#region 1.1 Draw Self
draw_self();
#endregion


// ============================================================================
// 2. DRAW POP NAME (Colored by Sex, Above Pop, CONDITIONAL)
// ============================================================================
#region 2.1 Draw Pop Name
if (_show_details_text && variable_instance_exists(id, "pop_name")) {
    // Only display the pop's name above their head for clarity and a clean UI.
    // We use pop_name instead of pop_identifier_string to avoid showing debug info (instance/profile IDs).
    var _name_text = pop_name;
    
    var _text_x = _x_pop;
    var _name_y_offset_from_top = 8; 
    var _text_y = _y_pop - (_scaled_sprite_h * 0.5) - _name_y_offset_from_top; 

    draw_set_font(fnt_state); 
    draw_set_halign(fa_center);
    draw_set_valign(fa_bottom); 

    draw_set_color(c_black); 
    draw_text(_text_x + 1, _text_y + 1, _name_text);

    if (_pop_sex == EntitySex.MALE) {
        draw_set_color(c_orange); 
    } else if (_pop_sex == EntitySex.FEMALE) {
        draw_set_color(c_fuchsia); 
    } else {
        draw_set_color(c_white); 
    }
    
    draw_text(_text_x, _text_y, _name_text);
}
#endregion


// ============================================================================
// 3. DRAW STATE TEXT (Below Pop, CONDITIONAL)
// ============================================================================
#region 3.0 Condition to Show State Text
if (_show_details_text) { // Use the new combined condition
#endregion

    #region 3.1 Configure Text Style for State
    draw_set_font(fnt_state); 
    draw_set_halign(fa_center);
    draw_set_valign(fa_top);    
    #endregion

    #region 3.2 Color by State
    switch (_state_current) {
        case EntityState.IDLE:     draw_set_color(c_white);    break;
        case EntityState.COMMANDED: draw_set_color(c_blue);     break; 
        case EntityState.FORAGING:  draw_set_color(c_lime);     break;
        case EntityState.FLEEING:   draw_set_color(c_yellow);   break;
        case EntityState.ATTACKING: draw_set_color(c_red);      break;
        case EntityState.WANDERING: draw_set_color(c_silver);   break;
        case EntityState.EATING:    draw_set_color(c_orange);   break;
        case EntityState.SLEEPING:  draw_set_color(c_purple);   break;
        case EntityState.WORKING:   draw_set_color(c_olive);    break;
        case EntityState.CRAFTING:  draw_set_color(c_maroon);   break;
        case EntityState.BUILDING:  draw_set_color(c_teal);     break;
        case EntityState.HAULING:   draw_set_color(c_dkgray);   break;
        case EntityState.SOCIALIZING: draw_set_color(c_fuchsia); break;
        case EntityState.WAITING:   draw_set_color(c_gray);     break;
        default:                draw_set_color(c_gray);     break;
    }
    #endregion

    #region 3.3 Render State Text with Bobbing (Below Pop)
    var _offset    = sin(_time / 200) * 1; 
    var _state_txt = scr_get_state_name(_state_current); 
    var _state_y_offset_from_bottom = 4; 
    var _text_y_state = _y_pop + (_scaled_sprite_h * 0.5) + _state_y_offset_from_bottom + _offset; 
    
    // Shadow for state text (optional, but good for consistency if name has it)
    var _current_text_color = draw_get_color(); // Store the state color
    draw_set_color(c_black);
    draw_text( _x_pop + 1, _text_y_state + 1, _state_txt );
    draw_set_color(_current_text_color); // Restore state color
    // End Shadow
    
    draw_text( _x_pop, _text_y_state, _state_txt );
    #endregion

#region 3.4 End Condition for State Text
} // Closing brace for 'if (_show_details_text)'
#endregion


// ============================================================================
// 4. DRAW SELECTION HIGHLIGHT (Thicker)
// ============================================================================
#region 4.1 Selection Circle
if (selected) { 
    draw_set_color(global.POP_SELECTION_PROPERTIES.COLOR); 

	var _base_selection_radius_x = _base_sprite_w * 0.35;
    var _base_selection_radius_y = _base_sprite_w * 0.15; // This being different from X makes it an ellipse
    
	
	var _scaled_selection_radius_x = _base_selection_radius_x * image_xscale;
    var _scaled_selection_radius_y = _base_selection_radius_y * image_xscale; // Should this be image_yscale for true ellipse scaling?
                                                                            // Or keep image_xscale if you want a specific shape.
    var _ellipse_center_y = _y_pop + (_scaled_sprite_h * 0.5) - _scaled_selection_radius_y; 
    var _thickness = global.POP_SELECTION_PROPERTIES.THICKNESS; 
    for (var i = 0; i < _thickness; i++) {
        draw_ellipse(
            _x_pop - _scaled_selection_radius_x - i, _ellipse_center_y - _scaled_selection_radius_y - i,
            _x_pop + _scaled_selection_radius_x + i, _ellipse_center_y + _scaled_selection_radius_y + i,
            true); 
    }
}
#endregion


// ============================================================================
// 5. DRAW COMMAND TARGET INDICATOR
// ============================================================================
#region 5.1 Command Target Indicator
if (_state_current == EntityState.COMMANDED && 
    variable_instance_exists(id, "travel_point_x") && is_real(travel_point_x) && 
    variable_instance_exists(id, "travel_point_y") && is_real(travel_point_y) && 
    (floor(x) != floor(travel_point_x) || floor(y) != floor(travel_point_y))) { 

    draw_set_alpha(global.POP_DESTINATION_MARKER_PROPERTIES.ALPHA);
    draw_set_color(global.POP_DESTINATION_MARKER_PROPERTIES.COLOR); 
    var _marker_size = global.POP_DESTINATION_MARKER_PROPERTIES.SIZE; // Use the size from global.POP_SELECTION_PROPERTIES
    draw_line_width(travel_point_x - _marker_size, travel_point_y - _marker_size, 
                    travel_point_x + _marker_size, travel_point_y + _marker_size, 2);
    draw_line_width(travel_point_x + _marker_size, travel_point_y - _marker_size, 
                    travel_point_x - _marker_size, travel_point_y + _marker_size, 2);
    draw_set_alpha(global.POP_DESTINATION_MARKER_PROPERTIES.ALPHA);
}
#endregion

// ============================================================================
// ================= OVERLAY: Sight Lines & Radii =====================
if (global.show_overlays) {
    // Draw pop's sight radius (for learning: helps visualize perception)
    var sight_radius = 150; // Example value, or use pop.base_perception_radius if available
    draw_set_color(c_aqua);
    draw_set_alpha(0.25);
    draw_circle(x, y, sight_radius, false);
    draw_set_alpha(1);
    // Optionally, draw a line to the current target (foraging, hauling, etc.)
    if (variable_instance_exists(id, "target_object_id") && target_object_id != noone && instance_exists(target_object_id)) {
        draw_set_color(c_yellow);
        draw_line(x, y, target_object_id.x, target_object_id.y);
    }
}


// ============================================================================
// X. FINAL RESET (Good practice for all draw events)
// ============================================================================
#region X.1 Reset Draw Settings
draw_set_font(-1);          
draw_set_color(c_white);    
draw_set_alpha(1.0);        
draw_set_halign(fa_left);   
draw_set_valign(fa_top);    
#endregion