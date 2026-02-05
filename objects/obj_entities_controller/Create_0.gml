/// obj_creature_ai_controller - Create Event
///
/// Purpose:
///    Initializes a generic creature AI controller based on self.entity_data
///    provided during its creation by scr_spawn_entity.
///
/// Metadata:
///    Summary:         Sets up creature properties from data.
///    Usage:           Called when a creature AI controller is spawned.
///    Tags:            [controller][creature][ai][init][data_driven]
///    Version:         1.1 - 2025-05-26 // Refactored to use self.entity_data directly
///    Dependencies:    scr_spawn_entity, scr_database, PopState enum, scr_struct_clone
///    Author:          GitHub Copilot

// This controller instance expects self.entity_type_id and self.entity_data to be injected by scr_spawn_entity.
// These variables are used directly in this Create event for initialization.

// --- Core State & AI Variables ---
target_entity = noone;      // Current target for AI behaviors (e.g., enemy, resource)
current_behavior_state = undefined; // Stores the current AI state (e.g., PopState.IDLE, PopState.WANDERING)
path = undefined;           // Path for mp_grid_path
path_position = 0;          // Current position along the path
move_target_x = x;          // Target x for movement
move_target_y = y;          // Target y for movement

// =========================================================================
// INITIALIZATION FROM ENTITY DATA (Passed by scr_spawn_entity)
// =========================================================================

// --- 0. Validate Injected Data ---
// Ensure entity_data has been set by the spawner (scr_spawn_entity)
if (!variable_instance_exists(self, "entity_data") || !is_struct(self.entity_data)) {
    var _error_msg = "FATAL (obj_creature_ai_controller Create): self.entity_data was not provided or is not a struct. Entity Type ID: " 
                   + (variable_instance_exists(self, "entity_type_id") ? string(self.entity_type_id) : "UNKNOWN") 
                   + ". Cannot initialize.";
    show_error(_error_msg, true);
    instance_destroy(); // Destroy self if no data
    exit; // Stop further execution of the Create event
}

// Convenience aliases for the injected data
var _data = self.entity_data; 
var _entity_id_string = variable_instance_exists(self, "entity_type_id") ? string(self.entity_type_id) : "UNKNOWN_ID"; // For logging
var _display_name_for_log = variable_struct_exists(_data, "type_tag") ? _data.type_tag : "Unnamed Creature"; // For logging

show_debug_message($"INFO (obj_creature_ai_controller Create): Initializing Creature AI '{_display_name_for_log}' (ID: {_entity_id_string}) from self.entity_data.");

// --- Helper function to safely get a sprite asset index ---
// Defined here to keep it local to this initialization logic.
function _get_sprite_asset(sprite_asset_name_from_data, fallback_asset = spr_placeholder_creature) {
    // sprite_asset_name_from_data is expected to be a string like "spr_wolf_idle"
    // It can also be undefined or an empty string if the profile doesn't specify it.
    if (is_string(sprite_asset_name_from_data) && string_length(sprite_asset_name_from_data) > 0) {
        if (asset_exists(sprite_asset_name_from_data)) {
            var _asset_index = asset_get_index(sprite_asset_name_from_data);
            if (asset_get_type(_asset_index) == asset_sprite) {
                return _asset_index; // Successfully found and it's a sprite
            } else {
                show_debug_message($"WARNING (obj_creature_ai_controller Create for '{_display_name_for_log}'): Asset '{sprite_asset_name_from_data}' found but is NOT a sprite. Using fallback '{string(fallback_asset)}'.");
                return fallback_asset;
            }
        } else {
            show_debug_message($"WARNING (obj_creature_ai_controller Create for '{_display_name_for_log}'): Sprite asset name '{sprite_asset_name_from_data}' NOT FOUND. Using fallback '{string(fallback_asset)}'.");
            return fallback_asset;
        }
    }
    return fallback_asset;
};
