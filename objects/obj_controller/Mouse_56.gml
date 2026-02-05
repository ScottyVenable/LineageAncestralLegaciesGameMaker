/// obj_controller – Event Global Left Released
///
/// Purpose:
///    Handles global left-click release. Finalizes drag selection or performs single pop selection.
///    Updates selection states and the global selected pops list. Enhanced debugging.
///
/// Metadata:
///    Summary:        Finalizes selection (drag or single) and updates UI.
///    Usage:          obj_controller Event: Mouse > Global Mouse > Global Left Released
///    Tags:           [input][selection][drag_selection][ui_update][debug]
///    Version:        1.1 — 2024-05-19 // Scotty's Current Date - Enhanced debugging for click_start_world_x
///    Dependencies:   device_mouse_x_to_gui(), device_mouse_y_to_gui(), obj_pop,
///                    global.selected_pops_list, scr_selection_controller()

show_debug_message("========================================================");
show_debug_message("DEBUG GLR: Entered Global Left Released. self is: " + object_get_name(object_index) + " (ID: " + string(id) + ")");
if (variable_instance_exists(id, "click_start_world_x")) {
    show_debug_message($"DEBUG GLR: Initial click_start_world_x: {click_start_world_x}, exists: true");
} else {
    show_debug_message("DEBUG GLR: Initial click_start_world_x: UNDEFINED, exists: false");
}


// =========================================================================
// 0. IMPORTS & CACHES
// =========================================================================
#region 0.1 Imports & Cached Locals
var _gui_mx = device_mouse_x_to_gui(0);
var _gui_my = device_mouse_y_to_gui(0);
var _world_mx = device_mouse_x(0); 
var _world_my = device_mouse_y(0); 

var _drag_threshold = 5; 
#endregion

// =========================================================================
// 1. PREPARE FOR NEW SELECTION: DESELECT PREVIOUSLY SELECTED POPS
// =========================================================================
#region 1.1 Deselect All
show_debug_message("DEBUG GLR: Region 1.1 Before 'with (obj_pop)'. self is: " + object_get_name(object_index));
if (variable_instance_exists(id, "click_start_world_x")) { show_debug_message($"DEBUG GLR: Region 1.1 click_start_world_x: {click_start_world_x}"); }

// Deselect all pop instances visually
if (instance_exists(obj_pop)) {
    with (obj_pop) {
        selected = false; // Unconditionally deselect all pops first
    }
} else {
    show_debug_message("DEBUG GLR: Region 1.1 No obj_pop instances found to deselect.");
}

// Clear the global list of selected pops
if (ds_exists(global.selected_pops_list, ds_type_list)) {
    ds_list_clear(global.selected_pops_list);
}

// Reset the global variable that tracks a single selected pop for UI purposes
global.selected_pop = noone; 

show_debug_message("DEBUG GLR: Region 1.1 After deselecting all. self is: " + object_get_name(object_index));
if (variable_instance_exists(id, "click_start_world_x")) { show_debug_message($"DEBUG GLR: Region 1.1 click_start_world_x after deselection: {click_start_world_x}"); }
#endregion

// =========================================================================
// 2. PROCESS SELECTION (DRAG OR CLICK)
// =========================================================================
#region 2.1 Drag Selection Logic
show_debug_message("DEBUG GLR: Region 2.1 Before 'if (is_dragging)'. self is: " + object_get_name(object_index));
if (variable_instance_exists(id, "click_start_world_x")) { show_debug_message($"DEBUG GLR: Region 2.1 click_start_world_x: {click_start_world_x}"); }

if (is_dragging) { // This instance variable 'is_dragging' was set in GLP
    // We will reset is_dragging to false at the end of this event, after processing.

    var _drag_dist_x = abs(_gui_mx - sel_start_x); // sel_start_x is instance var of obj_controller
    var _drag_dist_y = abs(_gui_my - sel_start_y); // sel_start_y is instance var of obj_controller

    show_debug_message("DEBUG GLR: Region 2.1 Inside 'if (is_dragging)'. self is: " + object_get_name(object_index));
    if (variable_instance_exists(id, "click_start_world_x")) { show_debug_message($"DEBUG GLR: Region 2.1 click_start_world_x: {click_start_world_x}"); }
    
    if (_drag_dist_x > _drag_threshold || _drag_dist_y > _drag_threshold) {
        // --- It was a DRAG BOX selection ---
        show_debug_message("DEBUG GLR: Region 2.1 Processing Drag Box.");
        // Ensure click_start_world_x/y are valid before using (these are instance variables of obj_controller)
        if (variable_instance_exists(id, "click_start_world_x") && variable_instance_exists(id, "click_start_world_y")) {
            var _world_sel_x1 = min(click_start_world_x, _world_mx);
            var _world_sel_y1 = min(click_start_world_y, _world_my);
            var _world_sel_x2 = max(click_start_world_x, _world_mx);
            var _world_sel_y2 = max(click_start_world_y, _world_my);
            
            show_debug_message($"DEBUG GLR: Drag box world coords: ({_world_sel_x1},{_world_sel_y1}) to ({_world_sel_x2},{_world_sel_y2})");

            with (obj_pop) {
                // Check if the pop's origin (x,y) is within the selection rectangle.
                // For more accuracy, you might want to check if any part of the pop's sprite/bounding box intersects.
                if (x >= _world_sel_x1 && x <= _world_sel_x2 && y >= _world_sel_y1 && y <= _world_sel_y2) {
                    selected = true; // Mark the pop as selected
                    ds_list_add(global.selected_pops_list, id); // Add its ID to the global list
                    show_debug_message($"DEBUG GLR: Pop {id} (at {x},{y}) added to selection by drag.");
                }
            }
        } else {
            show_debug_message("CRITICAL DEBUG GLR: Region 2.1 click_start_world_x/y NOT DEFINED just before drag box min/max calculations!");
        }
    } else {
        // --- It was a CLICK (drag distance was too small) ---
        show_debug_message("DEBUG GLR: Region 2.1 Processing as Single Click (short drag).");
        if (variable_instance_exists(id, "click_start_world_x") && variable_instance_exists(id, "click_start_world_y")) {
            // Use the initial world coordinates of the click
            var _clicked_pop = instance_position(click_start_world_x, click_start_world_y, obj_pop);
            if (instance_exists(_clicked_pop)) {
                _clicked_pop.selected = true; // Mark the pop as selected
                ds_list_add(global.selected_pops_list, _clicked_pop.id); // Add its ID to the global list
                show_debug_message($"DEBUG GLR: Pop {_clicked_pop.id} selected by click (short drag).");
            } else {
                show_debug_message("DEBUG GLR: Click (short drag) on empty space. No pop selected.");
            }
        } else {
            show_debug_message("CRITICAL DEBUG GLR: Region 2.1 click_start_world_x/y NOT DEFINED for single click check!");
        }
    }
} else {
    // If is_dragging is false, it means the mouse press might have been consumed by UI or another system,
    // or it's a scenario not intended for pop selection (e.g., if GLP didn't set is_dragging).
    show_debug_message("DEBUG GLR: Region 2.1 'is_dragging' was false. No pop selection processing in this block.");
}
#endregion

// =========================================================================
// 3. DETERMINE SINGLE SELECTED POP & UPDATE UI
// =========================================================================
#region 3.1 Determine Single Selected Pop for UI
// After processing drag or click, update global.selected_pop based on the list.
if (ds_exists(global.selected_pops_list, ds_type_list)) {
    var _num_selected = ds_list_size(global.selected_pops_list);
    if (_num_selected == 1) {
        global.selected_pop = global.selected_pops_list[| 0]; // Get the ID of the single selected pop
        show_debug_message($"DEBUG GLR: Single pop {global.selected_pop} finalized for UI update.");
    } else {
        global.selected_pop = noone; // Multiple or no pops selected, so no single pop for the UI
        if (_num_selected > 1) {
            show_debug_message($"DEBUG GLR: {_num_selected} pops selected. UI will show N/A for single pop details.");
        } else { // _num_selected == 0
            show_debug_message("DEBUG GLR: No pops selected after processing. UI will show N/A.");
        }
    }
} else {
    // This case should ideally not be reached if global.selected_pops_list is always initialized.
    global.selected_pop = noone; 
    show_debug_message("CRITICAL DEBUG GLR: global.selected_pops_list does not exist! Cannot determine single selected pop.");
}
#endregion

#region 3.2 Call Selection Controller Script
// Call the script to update UI elements like the inspector panel text fields
if (script_exists(scr_selection_controller)) {
    scr_selection_controller(global.selected_pop); // Pass the single selected pop (or noone)
} else {
    // Log error only once if the script is missing (flag should be initialized in Create event)
    if (variable_global_exists("logged_missing_selection_script") && !global.logged_missing_selection_script) {
        show_debug_message("ERROR (obj_controller GLR): scr_selection_controller script not found! UI will not update.");
        global.logged_missing_selection_script = true; // Prevent spamming this message
    }
}
#endregion

// =========================================================================
// 4. CLEANUP
// =========================================================================
#region 4.1 Reset Drag State
is_dragging = false; // Reset dragging state for the next mouse press
show_debug_message("DEBUG GLR: is_dragging reset to false.");
#endregion


if (ds_exists(global.selected_pops_list, ds_type_list)) {
    show_debug_message($"DEBUG GLR: Selection finalized. {ds_list_size(global.selected_pops_list)} pops selected.");
}
show_debug_message("========================================================");