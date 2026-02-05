/// obj_controller – Event Global Left Pressed
///
/// Purpose:
///    Handles global left-click mouse input. Initiates drag selection.
///    Records click position for potential single click handling on release.
///
/// Metadata:
///    Summary:        Initiates drag selection or marks start of a potential single click.
///    Usage:          obj_controller Event: Mouse > Global Mouse > Global Left Pressed
///    Parameters:     none
///    Returns:        void
///    Tags:           [input][selection][drag_selection]
///    Version:        1.1 — 2024-05-19 // Scotty's Current Date - Focus on initiating drag/click
///    Dependencies:   device_mouse_x_to_gui(), device_mouse_y_to_gui()

// =========================================================================
// 0. IMPORTS & CACHES
// =========================================================================
#region 0.1 Imports & Cached Locals
var _gui_mx = device_mouse_x_to_gui(0);
var _gui_my = device_mouse_y_to_gui(0);

// Store the world position of the click as well, for checking instance_position later
// This assumes your camera setup correctly translates GUI to world.
// If using view_get_xport/yport and view_wport/hport for scaling, adjust accordingly.
// For simplicity, if camera is 1:1 with GUI and no complex port scaling:
var _world_mx = device_mouse_x(0); 
var _world_my = device_mouse_y(0);
#endregion

// =========================================================================
// 1. CHECK IF CLICK IS ON UI (Prevent game world interaction if UI handles it)
// =========================================================================
#region 1.1 UI Click Consumption
// This should ideally be set by UI elements themselves in their own mouse press events
// if (global.mouse_event_consumed_by_ui) {
//     is_dragging = false; // Don't start a game world drag
//     exit; // Exit this script if UI consumed the click
// }
// For now, assume UI consumption is handled elsewhere or not yet critical.
#endregion

// =========================================================================
// 2. INITIATE DRAG SELECTION / PREPARE FOR SINGLE CLICK
// =========================================================================
#region 2.1 Start Drag Box
is_dragging = true;     // Assume a drag until proven otherwise (e.g., very short drag in Released event)
sel_start_x = _gui_mx;  // GUI coordinates for drawing the selection box
sel_start_y = _gui_my;

// Store initial world coordinates for precise instance checking later
// (You might already have these as other variables for camera or movement)
click_start_world_x = _world_mx; 
click_start_world_y = _world_my;


show_debug_message($"DEBUG (obj_controller GLP): Drag/Click initiated at GUI({sel_start_x}, {sel_start_y}), World({click_start_world_x},{click_start_world_y}). is_dragging = {is_dragging}");
show_debug_message($"DEBUG GLP: click_start_world_x set to: {click_start_world_x} (was _world_mx: {_world_mx})");
#endregion

// No actual selection or deselection happens here yet. That's for Global Left Released.