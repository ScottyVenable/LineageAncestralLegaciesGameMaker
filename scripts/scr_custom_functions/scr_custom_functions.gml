/// scr_custom_functions.gml
///
/// Purpose:
///   A collection of general-purpose utility functions accessible throughout the project.
///   These functions handle common tasks like item name conversion, deep cloning, etc.
///
/// Metadata:
///   Summary:       Custom utility functions for diverse project needs.
///   Usage:         Include this script once and call functions as needed.
///   Parameters:    Varies by function.
///   Returns:       Varies by function.
///   Tags:          [utility][functions][custom][general]
///   Version:       1.0 — 2025-05-22
///   Dependencies:  None
///   Created:       2025-05-22
///   Modified:      2025-05-22
///

// =========================================================================
// 1. DATA TYPE MANIPULATION
// =========================================================================
#region 1.1 ds_list_to_array
/// ---
/// ds_list_to_array(_list)
/// ---
/// Purpose:
///   Converts a GameMaker ds_list into a standard GML array.
///
/// Parameters:
///   _list : ds_list_id — The ID of the list to convert.
///
/// Returns:
///   Array — A standard GML array containing the list elements.
///
function ds_list_to_array(_list) {
    if (!ds_exists(_list, ds_type_list)) return [];
    var _arr = array_create(ds_list_size(_list));
    for (var i = 0; i < ds_list_size(_list); i++) {
        _arr[i] = _list[| i];
    }
    return _arr;
}
#endregion

// =========================================================================
// 2. ITEM & INVENTORY UTILITIES
// =========================================================================
#region 2.1 get_item_name_from_enum
/// ---
/// get_item_name_from_enum(_enum)
/// ---
/// Purpose:
///   Converts an item ID enum value into its corresponding human-readable string name.
///
/// Parameters:
///   _enum : enum.Item — The item's ID enum value.
///
/// Returns:
///   String — The item's name (e.g., "Wooden Log", "Stone Shard").
///
function get_item_name_from_enum(_enum) {
    if (!variable_global_exists("ItemData")) return "Unknown Item";
    // Assuming global.ItemData[? _enum][? "name"] structure
    if (ds_map_exists(global.ItemData, _enum)) {
        var _data = global.ItemData[? _enum];
        if (ds_exists(_data, ds_type_map) && ds_map_exists(_data, "name")) {
            return _data[? "name"];
        }
    }
    return "Item #" + string(_enum);
}
#endregion

// =========================================================================
// 3. MATH & COORDINATE UTILITIES
// =========================================================================
#region 3.1 wrap
/// ---
/// wrap(_val, _min, _max)
/// ---
/// Purpose:
///   Wraps a value within a circular range. Useful for rotations or looping indices.
///
/// Parameters:
///   _val : Real — The input value.
///   _min : Real — The lower bound.
///   _max : Real — The upper bound.
///
/// Returns:
///   Real — The wrapped value.
///
function wrap(_val, _min, _max) {
    var _range = _max - _min;
    while (_val < _min) _val += _range;
    while (_val >= _max) _val -= _range;
    return _val;
}
#endregion

// =========================================================================
// 4. MISC UTILITIES
// =========================================================================
#region 4.1 show_debug_message_once
/// ---
/// show_debug_message_once(_msg)
/// ---
/// Purpose:
///   Prints a debug message to the console only once per session per unique message.
///
/// Parameters:
///   _msg : string — The message to log.
///
function show_debug_message_once(_msg) {
    static _logged_messages = {};
    if (!variable_struct_exists(_logged_messages, _msg)) {
        _logged_messages[$ _msg] = true;
        show_debug_message(_msg);
    }
}
#endregion

// =========================================================================
// 5. CLEANUP & RETURN (N/A at script level)
// =========================================================================

// =========================================================================
// 6. DEBUG/PROFILING (Optional - N/A at script level)
// =========================================================================
