/// scr_pop_hauling.gml
///
/// Purpose:
///   Handles the "hauling" behavior state for a pop instance. In this state,
///   the pop attempts to find a resource to pick up, moves to it, collects it
///   (if it has capacity), then finds a designated drop-off point (e.g., a
///   stockpile or specific building) and moves to deposit the resource.
///
/// Metadata:
///   Summary: Manages pop behavior for picking up and hauling resources.
///   Usage: Called from obj_pop's state machine (Step Event) when current_state is EntityState.HAULING.
///   Parameters:
///     target_pop : instance_id — The pop instance executing the hauling behavior.
///   Returns: void (modifies target_pop directly)
///   Tags: [behavior][pop][resource][hauling][ai]
///   Version: 1.2 — 2025-07-28 (Refactored to use entity_data)
///   Dependencies: EntityState enum, scr_find_nearest_resource, scr_find_nearest_stockpile,
///                 instance_exists, point_distance, pathfinding (optional).
///   Created: (Assumed prior to 2023)
///   Modified: 2025-07-28
///

function scr_pop_hauling(target_pop) {
    // =========================================================================
    // 0. IMPORTS & CACHES
    // =========================================================================
    #region 0.1 Imports & Cached Locals
    var _pop = target_pop; // Reference to the pop instance
    var _room_speed = room_speed;
    // Replace direct access to global.TILE_SIZE with a safe check:
    var TILE_SIZE;
    if (variable_global_exists("TILE_SIZE")) {
        TILE_SIZE = global.TILE_SIZE; // Use the defined global tile size
    } else {
        show_debug_message("WARNING: global.TILE_SIZE not set. Using fallback TILE_SIZE = 32.");
        TILE_SIZE = 32; // Fallback tile size
    }
    // Debug: log the current hauling sub-state each step to trace behavior
    if (variable_instance_exists(_pop, "hauling_sub_state")) {
        show_debug_message("scr_pop_hauling: Pop " + string(_pop.id) + " sub_state = " + _pop.hauling_sub_state);
    }
    #endregion

    // =========================================================================
    // 1. VALIDATION & EARLY RETURNS
    // =========================================================================
    #region 1.1 Parameter Validation
    if (!instance_exists(_pop)) {
        show_debug_message("ERROR: scr_pop_hauling() — Invalid target_pop instance.");
        return;
    }
    if (!variable_instance_exists(_pop, "current_state") || _pop.current_state != EntityState.HAULING) {
        return;
    }
    if (!variable_instance_exists(_pop, "stats") || !is_struct(_pop.stats)) {
        show_debug_message("ERROR: scr_pop_hauling() - Pop " + string(_pop) + " is missing 'stats' struct.");
        scr_pop_resume_previous_or_idle();
        return;
    }
    if (!variable_instance_exists(_pop, "behavior_settings") || !is_struct(_pop.behavior_settings)) {
        show_debug_message("ERROR: scr_pop_hauling() - Pop " + string(_pop) + " is missing 'behavior_settings' struct.");
        scr_pop_resume_previous_or_idle();
        return;
    }
    // Ensure inventory_items ds_list exists
    if (!variable_instance_exists(_pop, "inventory_items") || !ds_exists(_pop.inventory_items, ds_type_list)) {
        show_debug_message("ERROR: scr_pop_hauling() - Pop " + string(_pop) + " is missing 'inventory_items' ds_list or it's not a list.");
        // Attempt to create it if missing, as a recovery measure.
        if (!variable_instance_exists(_pop, "inventory_items")) {
            _pop.inventory_items = ds_list_create();
            show_debug_message("INFO: scr_pop_hauling() - Created 'inventory_items' ds_list for Pop " + string(_pop));
        } else if (!ds_exists(_pop.inventory_items, ds_type_list)) {
            // It exists but is not a list, this is a more serious error.
             show_debug_message("CRITICAL ERROR: scr_pop_hauling() - Pop " + string(_pop) + " 'inventory_items' exists but is NOT a ds_list. Cannot proceed with hauling.");
            scr_pop_resume_previous_or_idle(); // Attempt to recover
            return;
        }
    }
    #endregion

    // =========================================================================
    // 2. CONFIGURATION & CONSTANTS (from Pop's Data Profile)
    // =========================================================================
    #region 2.1 Behavior-Specific Parameters
    var _base_walk_speed = 1.0; 
    if (variable_instance_exists(_pop, "stats")) {
        if (variable_struct_exists(_pop.stats, "walk_speed")) {
            _base_walk_speed = _pop.stats.walk_speed;
        } else {
            show_debug_message($"WARNING (scr_pop_hauling for Pop {_pop.id}): _pop.stats.walk_speed not found. Using fallback: {_base_walk_speed}");
        }
    } else {
        show_debug_message($"WARNING (scr_pop_hauling for Pop {_pop.id}): _pop.stats struct not found. Using fallback walk_speed: {_base_walk_speed}");
    }
    var move_speed = _base_walk_speed * 0.75;

    var carry_capacity_kg = 10; 
    if (variable_instance_exists(_pop, "stats")) {
        if (variable_struct_exists(_pop.stats, "carry_capacity_kg")) {
            carry_capacity_kg = _pop.stats.carry_capacity_kg;
        } else if (variable_struct_exists(_pop.stats, "max_carrying_capacity")) { // Fallback to max_carrying_capacity if carry_capacity_kg is missing
            carry_capacity_kg = _pop.stats.max_carrying_capacity;
            show_debug_message($"INFO (scr_pop_hauling for Pop {_pop.id}): _pop.stats.carry_capacity_kg not found. Using _pop.stats.max_carrying_capacity: {carry_capacity_kg}kg");
        } else {
            show_debug_message($"WARNING (scr_pop_hauling for Pop {_pop.id}): _pop.stats.carry_capacity_kg and max_carrying_capacity not found. Using fallback: {carry_capacity_kg}kg");
        }
    } else {
        show_debug_message($"WARNING (scr_pop_hauling for Pop {_pop.id}): _pop.stats struct not found. Using fallback carry_capacity_kg: {carry_capacity_kg}kg");
    }
    
    var hauling_fullness_threshold_percent = 75; 
    if (variable_instance_exists(_pop, "behavior_settings")) {
        if (variable_struct_exists(_pop.behavior_settings, "hauling_fullness_threshold_percent")) {
            hauling_fullness_threshold_percent = _pop.behavior_settings.hauling_fullness_threshold_percent;
        } else {
            show_debug_message($"WARNING (scr_pop_hauling for Pop {_pop.id}): _pop.behavior_settings.hauling_fullness_threshold_percent not found. Using fallback: {hauling_fullness_threshold_percent}%");
        }
    } else {
        show_debug_message($"WARNING (scr_pop_hauling for Pop {_pop.id}): _pop.behavior_settings struct not found. Using fallback hauling_fullness_threshold_percent: {hauling_fullness_threshold_percent}%");
    }

    var hauling_threshold_kg = carry_capacity_kg * (hauling_fullness_threshold_percent / 100);
    var interaction_distance = TILE_SIZE * 0.75; 
    if (variable_instance_exists(_pop, "behavior_settings")) {
        if (variable_struct_exists(_pop.behavior_settings, "interaction_distance_pixels")) {
            var _setting_dist = _pop.behavior_settings.interaction_distance_pixels;
            if (is_real(_setting_dist) && _setting_dist > 0) {
                interaction_distance = _setting_dist;
            } else {
                show_debug_message($"WARNING (scr_pop_hauling for Pop {_pop.id}): _pop.behavior_settings.interaction_distance_pixels is invalid ({_setting_dist}). Using fallback: {interaction_distance}");
            }
        } else {
            show_debug_message($"WARNING (scr_pop_hauling for Pop {_pop.id}): _pop.behavior_settings.interaction_distance_pixels not found. Using fallback: {interaction_distance}");
        }
    } else {
        show_debug_message($"WARNING (scr_pop_hauling for Pop {_pop.id}): _pop.behavior_settings struct not found. Using fallback interaction_distance: {interaction_distance}");
    }
    #endregion

    // =========================================================================
    // 3. STATE LOGIC (Sub-states: FIND_ITEM, MOVE_TO_ITEM, COLLECT_ITEM, FIND_DROPOFF, MOVE_TO_DROPOFF, DEPOSIT_ITEM)
    // =========================================================================
    if (!variable_instance_exists(_pop, "hauling_sub_state")) {
        _pop.hauling_sub_state = "FIND_ITEM";
        _pop.target_item_instance = noone;
        _pop.target_dropoff_instance = noone;
        _pop.state_timer = 0; 
    }

    // --- Calculate current inventory weight (using ds_list: inventory_items) ---
    var current_inventory_weight = 0;
    // Ensure inventory_items is valid before using ds_list_size
    if (variable_instance_exists(_pop, "inventory_items") && ds_exists(_pop.inventory_items, ds_type_list)) {
        for (var i = 0; i < ds_list_size(_pop.inventory_items); i++) {
            var item_stack_struct = _pop.inventory_items[| i];
            if (is_struct(item_stack_struct) && variable_struct_exists(item_stack_struct, "item_id_enum") && variable_struct_exists(item_stack_struct, "quantity")) {
                // get_item_data is expected to return a struct with item definition, including weight.
                var item_base_data = get_item_data(item_stack_struct.item_id_enum); 
                if (is_struct(item_base_data)) {
                    var _weight_key = "weight_kg"; // Primary key
                    if (!variable_struct_exists(item_base_data, _weight_key)) {
                        _weight_key = "weight_per_unit"; // Fallback key
                    }

                    if (variable_struct_exists(item_base_data, _weight_key)) {
                        current_inventory_weight += item_stack_struct.quantity * item_base_data[$ _weight_key];
                    } else {
                        // show_debug_message($"WARNING (scr_pop_hauling for Pop {_pop.id}): Item enum {item_stack_struct.item_id_enum} missing weight_kg or weight_per_unit in item_base_data.");
                    }
                } else {
                     // show_debug_message($"WARNING (scr_pop_hauling for Pop {_pop.id}): Could not get item_base_data for item enum {item_stack_struct.item_id_enum}.");
                }
            }
        }
    }
    _pop.current_inventory_weight_kg = current_inventory_weight; 

    // --- Hauling State Machine ---
    switch (_pop.hauling_sub_state) {
        case "FIND_ITEM":
            if (current_inventory_weight >= hauling_threshold_kg) {
                _pop.hauling_sub_state = "FIND_DROPOFF";
                _pop.target_item_instance = noone; 
                break; 
            }
            // Ensure scr_find_nearest_item_for_hauling exists before calling
            if (script_exists(scr_find_nearest_item_for_hauling)) {
                _pop.target_item_instance = scr_find_nearest_item_for_hauling(_pop.x, _pop.y, _pop, undefined); 
            } else {
                show_debug_message_once("ERROR: scr_find_nearest_item_for_hauling script missing!");
                _pop.target_item_instance = noone;
            }

            if (instance_exists(_pop.target_item_instance)) {
                _pop.hauling_sub_state = "MOVE_TO_ITEM";
            } else {
                scr_pop_resume_previous_or_idle(); 
            }
            break;

        case "MOVE_TO_ITEM":
            if (!instance_exists(_pop.target_item_instance)) {
                // Target item disappeared (e.g., picked up by someone else).
                // show_debug_message("Pop " + string(_pop) + " target item no longer exists. Returning to FIND_ITEM.");
                _pop.hauling_sub_state = "FIND_ITEM";
                // Clear sprite and speed as we are no longer moving
                _pop.speed = 0;
                // Use spr_idle from stats, falling back to spr_pop_man_idle if not defined or invalid.
                var _default_idle_sprite_target_gone = spr_pop_man_idle; // Fallback sprite
                var _stat_idle_sprite_target_gone = (variable_instance_exists(_pop, "stats") && variable_struct_exists(_pop.stats, "spr_idle")) ? _pop.stats.spr_idle : _default_idle_sprite_target_gone;
                _pop.sprite_index = get_sprite_asset_safely(_stat_idle_sprite_target_gone, _default_idle_sprite_target_gone);
                _pop.image_speed = 1.0;
                break;
            }

            var _dist_to_item = point_distance(_pop.x, _pop.y, _pop.target_item_instance.x, _pop.target_item_instance.y);

            if (_dist_to_item <= interaction_distance) {
                // Reached the item.
                _pop.hauling_sub_state = "COLLECT_ITEM";
            } else {
                // Move towards the item.
                var _dir = point_direction(_pop.x, _pop.y, _pop.target_item_instance.x, _pop.target_item_instance.y);
                // Ensure speed is applied correctly; direct modification of x/y is fine for simple movement.
                // Using min(move_speed, _dist_to_item) prevents overshooting in a single step.
                var move_dist = min(move_speed, _dist_to_item);
                _pop.x += lengthdir_x(move_dist, _dir);
                _pop.y += lengthdir_y(move_dist, _dir);
                
                if (_pop.x != _pop.xprevious || _pop.y != _pop.yprevious) { // Check if position actually changed
                     if (script_exists(scr_update_walk_sprite)) {
                        scr_update_walk_sprite(); 
                     } else {
                        // Fallback sprite logic if scr_update_walk_sprite is missing
                        if (_pop.x != _pop.xprevious) { _pop.image_xscale = sign(_pop.x - _pop.xprevious); }
                     }
                }
                _pop.image_speed = 1.0; 
            }
            break;

        case "COLLECT_ITEM":
            if (!instance_exists(_pop.target_item_instance)) {
                _pop.hauling_sub_state = "FIND_ITEM"; 
                // Clear sprite and speed as we are no longer interacting
                _pop.speed = 0;
                // Use spr_idle from stats, falling back to spr_pop_man_idle if not defined or invalid.
                var _default_idle_sprite_collect_gone = spr_pop_man_idle; // Fallback sprite
                var _stat_idle_sprite_collect_gone = (variable_instance_exists(_pop, "stats") && variable_struct_exists(_pop.stats, "spr_idle")) ? _pop.stats.spr_idle : _default_idle_sprite_collect_gone;
                _pop.sprite_index = get_sprite_asset_safely(_stat_idle_sprite_collect_gone, _default_idle_sprite_collect_gone);
                _pop.image_speed = 1.0;
                break;
            }

            // Item instance on ground should have: item_id_enum, quantity, item_data (struct with weight_kg)
            if (variable_instance_exists(_pop.target_item_instance, "item_id_enum") && // Expecting item_id_enum now
                variable_instance_exists(_pop.target_item_instance, "quantity") &&
                variable_instance_exists(_pop.target_item_instance, "item_data") && // item_data on the instance for its own properties
                is_struct(_pop.target_item_instance.item_data) &&
                variable_struct_exists(_pop.target_item_instance.item_data, "weight_kg")) {

                var item_to_collect = _pop.target_item_instance;
                // Calculate weight of the specific item instance being collected
                var weight_of_this_item_instance = item_to_collect.quantity * item_to_collect.item_data.weight_kg;

                if (current_inventory_weight + weight_of_this_item_instance <= carry_capacity_kg) {
                    // Corrected call to scr_inventory_add_item
                    // It expects: target_inventory_list (ds_list), item_to_add_enum, quantity_to_add
                    // item_to_collect.item_id_enum should be the enum value for the item.
                    var success = false;
                    if (script_exists(scr_inventory_add_item)) {
                         // scr_inventory_add_item returns items_remaining_to_add. Success is if 0 items remain.
                        var items_not_added = scr_inventory_add_item(_pop.inventory_items, item_to_collect.item_id_enum, item_to_collect.quantity);
                        success = (items_not_added == 0);
                    } else {
                        show_debug_message_once("ERROR: scr_inventory_add_item script missing!");
                    }
                                        
                    if (success) {
                        instance_destroy(item_to_collect); 
                        _pop.target_item_instance = noone;
                        // Recalculate current weight (will be done at the start of the next cycle of this script)
                        // For immediate decision making, update it here:
                        current_inventory_weight += weight_of_this_item_instance; // Add weight of collected item
                        _pop.current_inventory_weight_kg = current_inventory_weight; // Update the instance variable
                        
                        if (current_inventory_weight >= hauling_threshold_kg) {
                            _pop.hauling_sub_state = "FIND_DROPOFF";
                        } else {
                            _pop.hauling_sub_state = "FIND_ITEM"; 
                        }
                    } else {
                        _pop.hauling_sub_state = "FIND_ITEM";
                    }
                } else {
                    if (current_inventory_weight > 0) {
                        _pop.hauling_sub_state = "FIND_DROPOFF"; 
                    } else {
                        _pop.target_item_instance = noone; 
                        _pop.hauling_sub_state = "FIND_ITEM"; 
                    }
                }
            } else {
                _pop.hauling_sub_state = "FIND_ITEM";
            }
            break;

        case "FIND_DROPOFF":
            // Check inventory_items ds_list size for emptiness
            if (current_inventory_weight <= 0 && (ds_exists(_pop.inventory_items, ds_type_list) && ds_list_empty(_pop.inventory_items))) {
                _pop.hauling_sub_state = "FIND_ITEM";
                break;
            }

            // Ensure scr_find_nearest_stockpile exists
            if (script_exists(scr_find_nearest_stockpile)) {
                // Call without a filter so any flagged stockpile (e.g., gathering hut) is chosen
                _pop.target_dropoff_instance = scr_find_nearest_stockpile(_pop.x, _pop.y, _pop, undefined);
                show_debug_message("DEBUG (scr_pop_hauling): target_dropoff_instance = " + string(_pop.target_dropoff_instance));
            } else {
                show_debug_message_once("ERROR: scr_find_nearest_stockpile script missing!");
                _pop.target_dropoff_instance = noone;
            }

            if (instance_exists(_pop.target_dropoff_instance)) {
                _pop.hauling_sub_state = "MOVE_TO_DROPOFF";
            } else {
                scr_pop_resume_previous_or_idle();
            }
            break;

        case "MOVE_TO_DROPOFF":
            if (!instance_exists(_pop.target_dropoff_instance)) {
                // Target dropoff disappeared (e.g., destroyed).
                // show_debug_message("Pop " + string(_pop) + " target dropoff no longer exists. Returning to FIND_DROPOFF.");
                _pop.hauling_sub_state = "FIND_DROPOFF";
                // Clear sprite and speed
                _pop.speed = 0;
                // Use spr_idle from stats, falling back to spr_pop_man_idle if not defined or invalid.
                var _default_idle_sprite_dropoff_gone = spr_pop_man_idle; // Fallback sprite
                var _stat_idle_sprite_dropoff_gone = (variable_instance_exists(_pop, "stats") && variable_struct_exists(_pop.stats, "spr_idle")) ? _pop.stats.spr_idle : _default_idle_sprite_dropoff_gone;
                _pop.sprite_index = get_sprite_asset_safely(_stat_idle_sprite_dropoff_gone, _default_idle_sprite_dropoff_gone);
                _pop.image_speed = 1.0;
                break;
            }

            var _dist_to_dropoff = point_distance(_pop.x, _pop.y, _pop.target_dropoff_instance.x, _pop.target_dropoff_instance.y);

            if (_dist_to_dropoff <= interaction_distance) {
                _pop.hauling_sub_state = "DEPOSIT_ITEM";
            } else {
                var _dir = point_direction(_pop.x, _pop.y, _pop.target_dropoff_instance.x, _pop.target_dropoff_instance.y);
                var move_dist_dropoff = min(move_speed, _dist_to_dropoff);
                _pop.x += lengthdir_x(move_dist_dropoff, _dir);
                _pop.y += lengthdir_y(move_dist_dropoff, _dir);
                
                if (_pop.x != _pop.xprevious || _pop.y != _pop.yprevious) {
                     if (script_exists(scr_update_walk_sprite)) {
                        scr_update_walk_sprite();
                     } else {
                        if (_pop.x != _pop.xprevious) { _pop.image_xscale = sign(_pop.x - _pop.xprevious); }
                     }
                }
                _pop.image_speed = 1.0; 
            }
            break;

        case "DEPOSIT_ITEM":
            if (!instance_exists(_pop.target_dropoff_instance)) {
                _pop.hauling_sub_state = "FIND_DROPOFF"; 
                break;
            }
            
            var items_deposited_this_cycle = false;
            // Ensure inventory_items is valid and scr_stockpile_deposit_item & scr_inventory_remove_item_from_list exist
            if (ds_exists(_pop.inventory_items, ds_type_list) && 
                script_exists(scr_stockpile_deposit_item) &&
                script_exists(scr_inventory_remove_item_from_list) && // Check for the renamed/new remove script
                script_exists(get_item_data) && // Ensure get_item_data exists
                script_exists(scr_ui_showDropoffText) // Ensure UI script exists
                ) {

                // Iterate through pop's inventory_items (ds_list)
                for (var i = ds_list_size(_pop.inventory_items) - 1; i >= 0; i--) { // Iterate backwards for safe removal
                    var item_stack_struct = _pop.inventory_items[| i];
                    if (!is_struct(item_stack_struct) || 
                        !variable_struct_exists(item_stack_struct, "item_id_enum") || 
                        !variable_struct_exists(item_stack_struct, "quantity")) {
                        continue; // Skip malformed entries
                    }

                    var item_base_data_for_deposit = get_item_data(item_stack_struct.item_id_enum);
                    if (!is_struct(item_base_data_for_deposit)) {
                        // show_debug_message($"WARNING (scr_pop_hauling DEPOSIT): Could not get item_base_data for enum {item_stack_struct.item_id_enum}. Skipping deposit for this stack.");
                        continue; 
                    }
                    
                    // Call scr_stockpile_deposit_item with item_id_enum and fetched item_base_data
                    var deposited_successfully = scr_stockpile_deposit_item(
                        _pop.target_dropoff_instance, 
                        item_stack_struct.item_id_enum, 
                        item_stack_struct.quantity, 
                        item_base_data_for_deposit // Pass the full item data struct
                    );
                    
                    if (deposited_successfully) {
                        var _display_name = (variable_instance_exists(_pop, "pop_name")) ? _pop.pop_name : "Pop";
                        var _item_name = item_base_data_for_deposit[$ "display_name"];
                        if (is_undefined(_item_name)) _item_name = item_stack_struct.item_id_enum;

                        var _stockpile_name = instance_exists(_pop.target_dropoff_instance) ? object_get_name(_pop.target_dropoff_instance.object_index) : "stockpile";
                        var _message = $"{_display_name} deposited {item_stack_struct.quantity}x {_item_name} to {_stockpile_name}.";
                        scr_ui_showDropoffText(_message, 3); 

                        // Use scr_inventory_remove_item_from_list
                        scr_inventory_remove_item_from_list(_pop.inventory_items, item_stack_struct.item_id_enum, item_stack_struct.quantity); 
                        items_deposited_this_cycle = true;
                    } else {
                        // show_debug_message($"Pop {_pop.id} failed to deposit {item_stack_struct.item_id_enum}. Stockpile might be full or script failed.");
                    }
                }
            } else {
                 if (!script_exists(scr_stockpile_deposit_item)) show_debug_message_once("ERROR: scr_stockpile_deposit_item script missing!");
                 if (!script_exists(scr_inventory_remove_item_from_list)) show_debug_message_once("ERROR: scr_inventory_remove_item_from_list script missing!");
                 if (!script_exists(get_item_data)) show_debug_message_once("ERROR: get_item_data script missing!");
                 if (!script_exists(scr_ui_showDropoffText)) show_debug_message_once("ERROR: scr_ui_showDropoffText script missing!");
                 if (!ds_exists(_pop.inventory_items, ds_type_list)) show_debug_message_once($"ERROR: Pop {_pop.id} - inventory_items ds_list missing in DEPOSIT_ITEM!");
            }

            if (items_deposited_this_cycle) {
                // Recalculate weight (will also be done at the start of the script's next run)
                // Setting to 0 here is fine as it will be accurately recalculated.
                current_inventory_weight = 0; 
                _pop.current_inventory_weight_kg = current_inventory_weight;
            }
            
            _pop.hauling_sub_state = "FIND_ITEM";
            _pop.target_dropoff_instance = noone;
            break;

        default:
            _pop.hauling_sub_state = "FIND_ITEM";
            break;
    }
    #endregion

    // =========================================================================
    // 4. MOVEMENT & ANIMATION (Handled within sub-states for this behavior)
    // =========================================================================
    // ... existing comments ...
    // =========================================================================
    // 5. CLEANUP & RETURN (Handled by instance state or not applicable here)
    // =========================================================================
}