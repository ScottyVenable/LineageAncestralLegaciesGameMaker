/// obj_controller - Event Global Right Released (Mouse_57)
///
/// Purpose:
///     Handles global right-click mouse input.
///     If a "Slot Provider" object is clicked within its expanded interaction area,
///     selected pops are commanded to interact. Otherwise, move commands are issued.
///
/// Metadata:
///    Version:        1.12 - [Current Date] (Corrected instance_count, variable_instance_get, and click detection logic)
///    Dependencies:   obj_pop, par_slot_provider, EntityState (enum),
///                     scr_interaction_slot_get_free, scr_interaction_slot_claim,
///                     scr_interaction_slot_get_world_pos, scr_interaction_slot_release,
///                     scr_formations (scr_formation_calculate_slots), global.current_formation_type,
///                     global.formation_spacing, global.order_counter

// =========================================================================
// 0. IMPORTS & CACHES
// =========================================================================
#region 0.1 Imports & Cached Locals
// (None needed at top level)
#endregion

// =========================================================================
// 1. INITIAL CHECKS & MOUSE POSITION
// =========================================================================
#region 1.1 Setup
var _event_mouse_x_room = device_mouse_x(0);
var _event_mouse_y_room = device_mouse_y(0);
var _clicked_interactive_object = noone;
#endregion

// =========================================================================
// 2. DETECT CLICKED INTERACTIVE OBJECT (SLOT PROVIDER - Using Interaction Padding)
// =========================================================================
#region 2.1 Detect Slot Provider (with Interaction Padding)
// Iterate through all instances of par_slot_provider to find the topmost one clicked
// within its expanded interaction area.

var _num_slot_providers = instance_number(par_slot_provider); // <<<<< CORRECTED: Use instance_number()

for (var i = 0; i < _num_slot_providers; i++) {
    var _inst_id = instance_find(par_slot_provider, i);
    
    // It's good practice to ensure the instance still exists, though instance_find should only return active ones.
    if (!instance_exists(_inst_id)) continue; 

    // Get the instance's scaled bounding box variables
    var _obj_bbox_left   = _inst_id.bbox_left;
    var _obj_bbox_top    = _inst_id.bbox_top;
    var _obj_bbox_right  = _inst_id.bbox_right;
    var _obj_bbox_bottom = _inst_id.bbox_bottom;

    // Get padding values. If the variable doesn't exist on the instance, default to 0.
    var _pad_x = 0;
    if (variable_instance_exists(_inst_id, "interaction_padding_x")) {
        _pad_x = _inst_id.interaction_padding_x;
    }
    var _pad_y = 0;
    if (variable_instance_exists(_inst_id, "interaction_padding_y")) {
        _pad_y = _inst_id.interaction_padding_y;
    }

    // Define the expanded interaction rectangle
    var _interact_left   = _obj_bbox_left   - _pad_x;
    var _interact_top    = _obj_bbox_top    - _pad_y;
    var _interact_right  = _obj_bbox_right  + _pad_x;
    var _interact_bottom = _obj_bbox_bottom + _pad_y;

    // Check if mouse is within this expanded interaction rectangle
    if (point_in_rectangle(_event_mouse_x_room, _event_mouse_y_room, 
                           _interact_left, _interact_top, _interact_right, _interact_bottom)) {
        
        // If multiple objects are clicked, pick the one "on top" (lowest depth value)
        if (_clicked_interactive_object == noone || _inst_id.depth < _clicked_interactive_object.depth) {
            _clicked_interactive_object = _inst_id;
        }
    }
}
// ds_list_destroy was for a previous ds_list approach, not needed with instance_number/find iteration.

// Further filter if needed (e.g., is it currently harvestable?)
if (instance_exists(_clicked_interactive_object)) {
    var _can_interact = true;
    // Example: If it's a bush, check if it's harvestable
    if (object_is_ancestor(_clicked_interactive_object.object_index, obj_redBerryBush)) {
        if (variable_instance_exists(_clicked_interactive_object, "is_harvestable") &&
            !_clicked_interactive_object.is_harvestable) {
            _can_interact = false;
        }
    }
    // Add other checks for other types of interactables if needed (e.g., has resources, needs repair, etc.)

    if (!_can_interact) {
        _clicked_interactive_object = noone; // Don't interact if conditions not met
    }
}
#endregion

// =========================================================================
// 3. COMMAND LOGIC
// =========================================================================
#region 3.1 Interaction Command (if an interactive object was clicked)
if (_clicked_interactive_object != noone) {
    var _target_object_for_this_command = _clicked_interactive_object; 
    var _pops_assigned_to_interaction = 0;
    var _successfully_assigned_pops = []; 
	
	#region Play Commanded Sound
	if (array_length(global.sfx_man_commanded_list) > 0) {
		var list_size = array_length(global.sfx_man_commanded_list);
		var random_index_in_list = irandom(list_size - 1); // irandom(max) gives 0 to max
    
		var sound_to_play = global.sfx_man_commanded_list[random_index_in_list];
    
		audio_play_sound(sound_to_play, 1, false); // Priority 1, not looping
	} else {
		show_debug_message("Warning: global.sfx_man_commanded_list is empty or not initialized.");
	}
	#endregion
			
    with (obj_pop) { 
        if (selected) {
            // If the pop is currently interacting, release its claimed interaction point (slot)
            if ((state == EntityState.FORAGING || state == EntityState.WORKING)
                && instance_exists(target_interaction_object_id)
                && target_interaction_slot_index != -1) {
                // --- NEW SYSTEM: Release by interaction point ID ---
                // Fix: Call the script directly, not as a variable of the object.
                var _old_point_id = scr_interaction_slot_get_by_pop(target_interaction_object_id, id); // Correct usage: script is global
                if (_old_point_id != noone) scr_interaction_slot_release(_old_point_id, id);
                // Reset interaction variables
                target_interaction_object_id = noone;
                target_interaction_slot_index = -1;
                target_interaction_type_tag = "";
                // Also clear last_foraged_target_id if it was the one being released
                if (variable_instance_exists(id, "last_foraged_target_id") && last_foraged_target_id == target_interaction_object_id) {
                    last_foraged_target_id = noone;
                    last_foraged_slot_index = -1;
                    last_foraged_type_tag = "";
                }
            }
            // --- NEW SYSTEM: Find and claim a free interaction point (slot) ---
            var _free_point_id = scr_interaction_slot_get_free(_target_object_for_this_command);
            if (_free_point_id != noone) {
                if (scr_interaction_slot_claim(_free_point_id, id)) {
                    // Get the world position and type tag from the point instance
                    var _slot_index = -1;
                    var _points = _target_object_for_this_command.interaction_slots_pop_ids;
                    for (var i = 0; i < array_length(_points); i++) {
                        if (_points[i] == _free_point_id) { _slot_index = i; break; }
                    }
                    var _slot_details = scr_interaction_slot_get_world_pos(_target_object_for_this_command, _slot_index);
                    if (_slot_details != undefined) {
                        // --- Assign all relevant target variables to the pop ---
                        target_interaction_object_id = _target_object_for_this_command;
                        target_interaction_slot_index = _slot_index; // Still used for legacy compatibility
                        target_interaction_type_tag = _slot_details[$ "type_tag"];
                        // Store the actual interaction point instance ID for robust slot management
                        target_interaction_point_id = _free_point_id; // (Optional: add this variable for clarity)
                        travel_point_x = _slot_details[$ "x"];
                        travel_point_y = _slot_details[$ "y"];
                        // Set state to FORAGING (or other, based on object type)
                        state = EntityState.FORAGING;
                        previous_state = EntityState.FORAGING;
                        // Update last_foraged_... for resume/idle logic
                        last_foraged_target_id = _target_object_for_this_command;
                        last_foraged_slot_index = _slot_index;
                        last_foraged_type_tag = _slot_details.type_tag;
                        if (state == EntityState.FORAGING) { forage_timer = 0; }
                        has_arrived = false; is_waiting = false;
                        array_push(_successfully_assigned_pops, id);
                    } else {
                        // If slot details couldn't be retrieved, release the point
                        scr_interaction_slot_release(_free_point_id, id);
                    }
                }
            }
        }
    } 
    // --- MULTI-POP INTERACTION LOGIC ---
    // 1. Gather all selected pops into a list
    var _selected_pops = [];
    with (obj_pop) {
        if (selected) array_push(_selected_pops, id);
    }
    // 2. Gather all free interaction points on the target object
    var _free_points = [];
    if (variable_instance_exists(_target_object_for_this_command, "interaction_slots_pop_ids")) {
        var _points = _target_object_for_this_command.interaction_slots_pop_ids;
        for (var i = 0; i < array_length(_points); i++) {
            var _point_id = _points[i];
            if (instance_exists(_point_id) && (object_get_parent(_point_id.object_index) == obj_interaction_point || _point_id.object_index == obj_interaction_point)) {
                if (_point_id.is_occupied_by_pop_id == noone) array_push(_free_points, _point_id);
            }
        }
    }
    // 3. Assign pops to free points (up to available slots)
    var _num_to_assign = min(array_length(_selected_pops), array_length(_free_points));
    // --- EDUCATIONAL NOTE: Only assign as many pops as there are free slots. Pops not assigned a slot are skipped ---
    for (var i = 0; i < _num_to_assign; i++) {
        var _pop_id = _selected_pops[i];
        var _point_id = _free_points[i];
        if (instance_exists(_pop_id) && instance_exists(_point_id)) {
            with (_pop_id) {
                // --- Only release/assign slot if this pop is being assigned a new slot ---
                // Release any previous slot (if any)
                if ((state == EntityState.FORAGING || state == EntityState.WORKING)
                    && instance_exists(target_interaction_object_id)
                    && target_interaction_slot_index != -1) {
                    var _old_point_id = scr_interaction_slot_get_by_pop(target_interaction_object_id, id);
                    if (_old_point_id != noone) scr_interaction_slot_release(_old_point_id, id);
                    target_interaction_object_id = noone;
                    target_interaction_slot_index = -1;
                    target_interaction_type_tag = "";
                    if (variable_instance_exists(id, "last_foraged_target_id") && last_foraged_target_id == target_interaction_object_id) {
                        last_foraged_target_id = noone;
                        last_foraged_slot_index = -1;
                        last_foraged_type_tag = "";
                    }
                }
                // Claim the new point
                if (scr_interaction_slot_claim(_point_id, id)) {
                    // Find the slot index for this point
                    var _slot_index = -1;
                    var _pts = _target_object_for_this_command.interaction_slots_pop_ids;
                    for (var j = 0; j < array_length(_pts); j++) {
                        if (_pts[j] == _point_id) { _slot_index = j; break; }
                    }
                    var _slot_details = scr_interaction_slot_get_world_pos(_target_object_for_this_command, _slot_index);
                    if (_slot_details != undefined) {
                        // --- Assign all relevant target variables to the pop ---
                        target_interaction_object_id = _target_object_for_this_command;
                        target_interaction_slot_index = _slot_index;
                        target_interaction_type_tag = _slot_details[$ "type_tag"];
                        target_interaction_point_id = _point_id;
                        travel_point_x = _slot_details[$ "x"];
                        travel_point_y = _slot_details[$ "y"];
                        state = EntityState.FORAGING;
                        previous_state = EntityState.FORAGING;
                        last_foraged_target_id = _target_object_for_this_command;
                        last_foraged_slot_index = _slot_index;
                        last_foraged_type_tag = _slot_details.type_tag;
                        forage_timer = 0;
                        has_arrived = false; is_waiting = false;
                        array_push(_successfully_assigned_pops, id);
                        // --- Unselect the pop so it is not processed again this event ---
                        selected = false; // This prevents double-processing and errors
                    } else {
                        // If slot details couldn't be retrieved, release the point
                        scr_interaction_slot_release(_point_id, id);
                    }
                }
            }
        }
    }
    // --- Pops that were not assigned a slot are skipped: no slot-release or assignment logic is run for them ---
    _pops_assigned_to_interaction = array_length(_successfully_assigned_pops);
    if (_pops_assigned_to_interaction > 0) { exit; }
}
#endregion

#region 3.2 Move Command Logic (Fallback)
var _selected_pops_list_for_move = [];
	#region Play Commanded Sound
	if (array_length(global.sfx_man_commanded_list) > 0) {
		var list_size = array_length(global.sfx_man_commanded_list);
		var random_index_in_list = irandom(list_size - 1); // irandom(max) gives 0 to max
    
		var sound_to_play = global.sfx_man_commanded_list[random_index_in_list];
    
		audio_play_sound(sound_to_play, 1, false); // Priority 1, not looping
	} else {
		show_debug_message("Warning: global.sfx_man_commanded_list is empty or not initialized.");
	}
	#endregion
	
with (obj_pop) {
    if (selected) {
        if ((state == EntityState.FORAGING || state == EntityState.WORKING) && 
            instance_exists(target_interaction_object_id) && 
            target_interaction_slot_index != -1) {
            // If the pop is currently interacting and is now commanded to move, release its slot.
            scr_interaction_slot_release(target_interaction_object_id, id);
            
            // Reset interaction variables.
            target_interaction_object_id = noone;
            target_interaction_slot_index = -1;
            target_interaction_type_tag = "";
            
            // Also, reset last_foraged_target_id if it was the one being released.
            // This is to ensure that if the pop becomes idle after the move,
            // it doesn't try to resume foraging at the slot it was just pulled from.
            if (variable_instance_exists(id, "last_foraged_target_id") && last_foraged_target_id == target_interaction_object_id) {
                last_foraged_target_id = noone;
                last_foraged_slot_index = -1;
                last_foraged_type_tag = "";
            }
        }
        array_push(_selected_pops_list_for_move, id);
    }
}
var _num_selected_for_move = array_length(_selected_pops_list_for_move);

if (_num_selected_for_move > 0) {
    global.order_counter++; 

    if (_num_selected_for_move > 1 && global.current_formation_type != FormationType.NONE) {
        // Educational: Always use the enum name (FormationType.NONE) for clarity and to avoid bugs.
        // This ensures the code is robust if the enum values ever change.
        var _formation_slots = scr_calculate_formation_positions(
            global.current_formation_type,
            _num_selected_for_move,
            _event_mouse_x_room,
            _event_mouse_y_room,
            { spacing: global.formation_spacing }
        );
        if (array_length(_formation_slots) == _num_selected_for_move) {
            for (var i = 0; i < _num_selected_for_move; i++) {
                var _pop_id = _selected_pops_list_for_move[i]; 
                var _slot = _formation_slots[i]; 
                if (instance_exists(_pop_id)) { 
                    with (_pop_id) {
                        travel_point_x = _slot[$ "x"]; travel_point_y = _slot[$ "y"];
                        has_arrived = false; state = EntityState.COMMANDED;
                        order_id = global.order_counter; is_waiting = false;
                    }
                }
            }
        } else { 
            show_debug_message("ERROR (Controller GRR): Mismatch in formation slots. Defaulting to single point move for group.");
            for (var i = 0; i < _num_selected_for_move; i++) { 
                var _pop_id = _selected_pops_list_for_move[i];
                if (instance_exists(_pop_id)) { 
                    with (_pop_id) {
                        travel_point_x = _event_mouse_x_room; travel_point_y = _event_mouse_y_room;
                        has_arrived = false; state = EntityState.COMMANDED;
                        order_id = global.order_counter; is_waiting = false;
                    }
                }
            }
        }
    } else {
        for (var i = 0; i < _num_selected_for_move; i++) {
            var _pop_id = _selected_pops_list_for_move[i];
            if (instance_exists(_pop_id)) { 
                with (_pop_id) {
                    travel_point_x = _event_mouse_x_room; travel_point_y = _event_mouse_y_room;
                    has_arrived = false; state = EntityState.COMMANDED;
                    order_id = global.order_counter; is_waiting = false;
                }
            }
        }
    }
}
#endregion

// =========================================================================
// 4. CLEANUP & RETURN
// =========================================================================
#region 4.1 Cleanup
// (No changes needed here)
#endregion