/// scr_pop_foraging.gml (or scr_pop_interaction_work.gml)

/// Purpose:
///   Handles the behavior for a pop that is tasked with an interaction
///   at a specific slot on a target object (e.g., foraging from a bush).
///   Manages movement to the slot, performing the interaction using correct
///   directional sprites, releasing the slot, and then stepping a short distance
///   away before transitioning to a commanded move to that spot (which then leads to WAITING).
///

/// Metadata:
///     Summary:       Move to slot, perform work, release slot, step away, then commanded to wait.
///     Usage:         Called by scr_pop_behavior when state is PopState.FORAGING.
///     Usage:         Called by scr_pop_behavior when state is EntityState.FORAGING. // Updated enum
///     Dependencies:  scr_interaction_slot_get_world_pos, scr_interaction_slot_acquire,
///                    scr_update_walk_sprite, scr_inventory_struct_add, EntityState (enum), // Updated enum
///                    Instance variables: target_interaction_object_id, target_interaction_slot_index, etc.
/// @self obj_pop

function scr_pop_foraging() { // Consider renaming to scr_pop_perform_interaction() or scr_pop_work_at_slot()

    // =========================================================================
    // 0. VALIDATION: Ensure Target Object & Slot Info Are Valid
    // =========================================================================
    #region 0.1 Validate Interaction Target
    // --- UPDATED FOR INTERACTION POINT SYSTEM ---
    // Instead of checking interaction_slot_positions, we now check the interaction point instance directly.
    var _valid_slot = false;
    if (instance_exists(target_interaction_object_id) && target_interaction_slot_index != -1) {
        if (variable_instance_exists(target_interaction_object_id, "interaction_slots_pop_ids")) {
            var _points = target_interaction_object_id.interaction_slots_pop_ids;
            if (target_interaction_slot_index >= 0 && target_interaction_slot_index < array_length(_points)) {
                var _point_id = _points[target_interaction_slot_index];
                if (instance_exists(_point_id) && (object_get_parent(_point_id.object_index) == obj_interaction_point || _point_id.object_index == obj_interaction_point)) {
                    _valid_slot = true;
                }
            }
        }
    }
    if (!_valid_slot) {
        // If target is somehow invalid, try to release slot if pop thought it had one
        if (instance_exists(target_interaction_object_id) && target_interaction_slot_index != -1 &&
            variable_instance_exists(target_interaction_object_id, "interaction_slots_pop_ids")) {
            var _point_id = scr_interaction_slot_get_by_pop(target_interaction_object_id, id);
            if (_point_id != noone) scr_interaction_slot_release(_point_id, id);
        }
        // Reset pop's interaction variables and go to WAITING state
        target_interaction_object_id = noone;
        target_interaction_slot_index = -1;
        target_interaction_type_tag = "";
        state = PopState.WAITING;
        state = EntityState.WAITING; // Use new WAITING state
        is_waiting = true;
        depth = -y;
        has_arrived = true;
        // speed = pop.base_speed; // OLD: pop.base_speed is deprecated
        // Use walk_speed from stats, with a fallback if stats or walk_speed is not defined.
        var _walk_speed = (variable_instance_exists(id, "stats") && variable_struct_exists(stats, "walk_speed")) ? stats.walk_speed : 1; // Default to 1 if not found
        speed = _walk_speed;
        image_speed = 1.0;
        // sprite_index = spr_pop_man_idle; // OLD: Use spr_idle from stats or fallback
        // Use spr_idle from stats, falling back to spr_pop_man_idle if not defined or invalid.
        var _default_idle_sprite = spr_pop_man_idle; // Fallback sprite
        var _stat_idle_sprite = (variable_instance_exists(id, "stats") && variable_struct_exists(stats, "spr_idle")) ? stats.spr_idle : _default_idle_sprite;
        sprite_index = get_sprite_asset_safely(_stat_idle_sprite, _default_idle_sprite);
        show_debug_message($"Pop {pop_identifier_string} (ID: {id}) has invalid interaction target/slot (new system). Reverting to WAITING.");
        exit;
    }
    #endregion

    // Get target slot's current world position (in case target object moved)
    var _slot_details = scr_interaction_slot_get_world_pos(target_interaction_object_id, target_interaction_slot_index);
    if (_slot_details == undefined) {
        show_debug_message($"Pop {pop_identifier_string} (ID: {id}) could not retrieve slot details for target {target_interaction_object_id}, slot {target_interaction_slot_index}. Reverting to WAITING.");
        // Attempt to release slot even if details are bad, as pop *thinks* it has a slot
        if (instance_exists(target_interaction_object_id) && target_interaction_slot_index != -1) {
            // --- NEW SYSTEM: Release by interaction point ID ---
            var _point_id = scr_interaction_slot_get_by_pop(target_interaction_object_id, id);
            if (_point_id != noone) scr_interaction_slot_release(_point_id, id);
        }
        target_interaction_object_id = noone; target_interaction_slot_index = -1; target_interaction_type_tag = "";
        state = EntityState.WAITING; is_waiting = true; depth = -y; has_arrived = true; speed = 0; image_speed = 1.0; 
        // sprite_index = spr_pop_man_idle; // OLD: Use spr_idle from stats or fallback
        // Use spr_idle from stats, falling back to spr_pop_man_idle if not defined or invalid.
        var _default_idle_sprite_err = spr_pop_man_idle; // Fallback sprite
        var _stat_idle_sprite_err = (variable_instance_exists(id, "stats") && variable_struct_exists(stats, "spr_idle")) ? stats.spr_idle : _default_idle_sprite_err;
        sprite_index = get_sprite_asset_safely(_stat_idle_sprite_err, _default_idle_sprite_err);
        exit;
    }
    var _slot_target_x = _slot_details.x;
    var _slot_target_y = _slot_details.y;
    var _interaction_point_id = _slot_details.point_id;

    // =========================================================================
    // 1. MOVEMENT TO ASSIGNED SLOT (if not already there)
    // =========================================================================
    #region 1.1 Movement to Slot
    if (!has_arrived) { // 'has_arrived' means arrived at the interaction SLOT
        depth = target_interaction_object_id.depth - 1; // Pop appears in front of target while approaching
        
        if (point_distance(x, y, _slot_target_x, _slot_target_y) >= 2) { // Movement threshold
            direction = point_direction(x, y, _slot_target_x, _slot_target_y);
            // speed = pop.base_speed * 1.3; // Movement speed towards slot // OLD: pop.base_speed is not used
            // When moving to a forage/interaction target, use run_speed.
            // Ensure 'stats' and 'run_speed' exist to prevent errors, using a fallback if necessary.
            var _run_speed = (variable_instance_exists(id, "stats") && variable_struct_exists(stats, "run_speed")) 
                             ? stats.run_speed 
                             : 1.5; // Fallback run_speed if not found (e.g. 1.5x a default walk_speed of 1)
            speed = _run_speed; 
            image_speed = 1.5; // Walking animation speed
            scr_update_walk_sprite(); // Update walking animation
            exit; // Still moving to slot, exit script for this step
        } else {
            // Arrived at the slot
            x = _slot_target_x;
            y = _slot_target_y;
            speed = 0;
            has_arrived = true; // Now at the slot
            image_speed = 1.0;  // Reset animation speed, foraging anim will use its own or this base
            
            // Reset task-specific timer upon arrival at slot, based on interaction type
            if (target_interaction_type_tag == "forage_left" || target_interaction_type_tag == "forage_right") {
                forage_timer = 0;
                // When arriving at a slot for foraging, this is the current task.
                // So, update last_foraged_target_id, slot, and type tag.
                // This ensures that if the pop is interrupted while foraging (e.g., by hunger)
                // and then finishes that interruption, it knows which bush/slot it was at.
                last_foraged_target_id = target_interaction_object_id;
                last_foraged_slot_index = target_interaction_slot_index;
                last_foraged_type_tag = target_interaction_type_tag;
            }
            // else if (target_interaction_type_tag == "mine_rock") { mining_timer = 0; } // Example
            
            show_debug_message($"Pop {pop_identifier_string} (ID: {id}) arrived at slot {target_interaction_slot_index} for target {target_interaction_object_id}. Type: '{target_interaction_type_tag}'.");
        }
    }
    #endregion

    // If we've reached here, pop 'has_arrived' at the interaction slot and 'speed' is 0.
    // =========================================================================
    // 2. PERFORMING INTERACTION AT SLOT (Logic branches based on type_tag)
    // =========================================================================
    #region 2.1 Interaction Logic
    // Ensure pop is correctly positioned (already at slot) and facing the target object's center
     // Keep pop in front while working
    direction = point_direction(x, y, target_interaction_object_id.x, target_interaction_object_id.y);

    // --- Branch logic based on target_interaction_type_tag ---
    switch (target_interaction_type_tag) {
        case "forage_left": // SLOT is on the LEFT of the bush
            sprite_index = spr_man_foraging_right; // Pop FACES RIGHT (towards bush)
            // Foraging animation speed uses sprite's default if image_speed was reset to 1.0 on arrival.
            break; 
        case "forage_right": // SLOT is on THE RIGHT of the bush
            sprite_index = spr_pop_man_foraging_left;  // Pop FACES LEFT (towards bush)
            // Foraging animation speed uses sprite's default.
            break;
            
        // case "mine_rock_front": // Example for other tasks
        //     sprite_index = spr_man_mining_front; 
        //     // image_speed might be set if mining anim needs different speed from default
        //     break;
            
        default:
            // Unknown or generic interaction type tag
            // sprite_index = spr_pop_man_idle; // Fallback to idle animation // OLD: Use spr_idle from stats or fallback
            // Use spr_idle from stats, falling back to spr_pop_man_idle if not defined or invalid.
            var _default_idle_sprite_switch = spr_pop_man_idle; // Fallback sprite
            var _stat_idle_sprite_switch = (variable_instance_exists(id, "stats") && variable_struct_exists(stats, "spr_idle")) ? stats.spr_idle : _default_idle_sprite_switch;
            sprite_index = get_sprite_asset_safely(_stat_idle_sprite_switch, _default_idle_sprite_switch);
            image_speed = 0.2; // Example for a generic idle if no specific animation
            show_debug_message($"Pop {pop_identifier_string} (ID: {id}) at slot with unhandled tag: '{target_interaction_type_tag}'. Using fallback sprite.");
            break;
    }
    
    // --- Task-specific logic (e.g., Foraging progress) ---
    if (target_interaction_type_tag == "forage_left" || target_interaction_type_tag == "forage_right") {
        depth = target_interaction_object_id.depth - 1;
		forage_timer += 1;
        // Get forage_rate from stats, with a fallback if not defined.
        // This determines how many game steps it takes to complete one foraging "tick".
        var _current_forage_rate = (variable_instance_exists(id, "stats") && variable_struct_exists(stats, "forage_rate")) 
                                   ? stats.forage_rate 
                                   : 60; // Default to 60 steps (1 second at 60fps) if not found

        if (forage_timer >= _current_forage_rate) { // MODIFIED: Was 'forage_rate'
            forage_timer = 0; // Reset for next tick
            var _item_harvested_this_tick = false;
            var _target_is_depleted = false;

            // --- Modular Interaction with the target_interaction_object_id ---
            // This section now assumes the target object has:
            // - is_harvestable (boolean)
            // - resource_count (integer, e.g., how many berries/sticks are left)
            // - item_yield_enum (Item enum, e.g., Item.FOOD_RED_BERRY, Item.WOOD_STICK)
            // - yield_quantity_per_cycle (integer, e.g., 1, 2)
            // - spr_empty (sprite_index, sprite to show when depleted)
            // - forage_rate (integer, frames per yield cycle) - this should ideally be on the pop or interaction definition

            if (instance_exists(target_interaction_object_id) && 
                variable_instance_exists(target_interaction_object_id, "is_harvestable") &&
                target_interaction_object_id.is_harvestable &&
                variable_instance_exists(target_interaction_object_id, "resource_count") &&    // Check for generic resource_count
                variable_instance_exists(target_interaction_object_id, "item_yield_enum") && // Check for item type to yield
                variable_instance_exists(target_interaction_object_id, "yield_quantity_per_cycle")) { // Check for yield quantity

                if (target_interaction_object_id.resource_count > 0) {
                    // Determine how many items to actually gather this cycle
                    var _items_to_gather_this_cycle = min(target_interaction_object_id.yield_quantity_per_cycle, target_interaction_object_id.resource_count);
                    
                    target_interaction_object_id.resource_count -= _items_to_gather_this_cycle;
                    _item_harvested_this_tick = true;
					
					var _item_enum_to_add = target_interaction_object_id.item_yield_enum; // Get item type from target

					// 'self' here refers to the obj_pop instance running this script
					if (!variable_instance_exists(id, "inventory_items")) {
					    inventory_items = ds_list_create(); 
					    show_debug_message($"Warning: Pop {id} inventory_items not found, created new list.");
					}

					show_debug_message($"Pop {id} ({pop_name}) gathered {_items_to_gather_this_cycle} of item enum {_item_enum_to_add}. Attempting to add to inventory.");

					var _items_not_added = scr_inventory_add_item(self.inventory_items, _item_enum_to_add, _items_to_gather_this_cycle);

					if (_items_not_added > 0) {
					    show_debug_message($"Pop {id} inventory full or issue, {_items_not_added} of item enum {_item_enum_to_add} dropped/lost.");
					    // TODO: Implement logic for dropping items on the ground if inventory is full
					    // This could involve creating a temporary item drop object at the pop's location.
					}
					
                    if (target_interaction_object_id.resource_count <= 0) { // Check if depleted
                        target_interaction_object_id.is_harvestable = false;
                        if (variable_instance_exists(target_interaction_object_id, "spr_empty") && // Ensure spr_empty exists
                            sprite_exists(target_interaction_object_id.spr_empty)) { 
                             target_interaction_object_id.sprite_index = target_interaction_object_id.spr_empty;
                        }
                        _target_is_depleted = true;
                        show_debug_message($"Target {target_interaction_object_id} depleted. Resource count: {target_interaction_object_id.resource_count}");
                    }
                } else { // resource_count is 0 or less
                    _target_is_depleted = true;
                    target_interaction_object_id.is_harvestable = false; // Ensure flag is set
                    show_debug_message($"Target {target_interaction_object_id} already depleted before attempt. Resource count: {target_interaction_object_id.resource_count}");
                }
            } else { // Target doesn't exist, isn't harvestable, or lacks necessary variables
                _target_is_depleted = true; 
                show_debug_message($"Pop {pop_identifier_string} (ID: {id}) found target {target_interaction_object_id} invalid or missing required foraging variables (is_harvestable, resource_count, item_yield_enum, yield_quantity_per_cycle).");
                // If the target object itself is gone, we can't really do much with it.
                // If it exists but is missing variables, it's a setup error for that object.
            }

            // Check if task is complete (target depleted or became invalid)
            if (_target_is_depleted) {
                var _pop_id_str_depletion = pop_identifier_string + " (ID:" + string(id) + ")"; // For logging
                show_debug_message("Pop " + _pop_id_str_depletion + " foraging: target " + string(target_interaction_object_id) + " depleted or invalid.");

                // Determine the item type that was being foraged.
                // This is important for deciding if the pop should haul.
                var _item_type_being_foraged = undefined;
                if (instance_exists(target_interaction_object_id) && variable_instance_exists(target_interaction_object_id, "item_yield_enum")) {
                    _item_type_being_foraged = target_interaction_object_id.item_yield_enum;
                } else {
                    // If the target is gone or doesn't have the enum, we might not know what was being foraged.
                    show_debug_message("Pop " + _pop_id_str_depletion + ": Target " + string(target_interaction_object_id) + " is invalid or missing 'item_yield_enum'. Cannot determine specific item type for inventory check.");
                }
                
                var _has_foraged_items_in_inventory = false;
                // Only check inventory if we successfully identified the item type.
                if (_item_type_being_foraged != undefined && variable_instance_exists(id, "inventory_items") && ds_exists(inventory_items, ds_type_list)) {
                    for (var i = 0; i < ds_list_size(inventory_items); i++) {
                        var item_struct = inventory_items[| i];
                        if (is_struct(item_struct) && variable_struct_exists(item_struct, "item_id_enum") && variable_struct_exists(item_struct, "quantity")) {
                            if (item_struct.item_id_enum == _item_type_being_foraged && item_struct.quantity > 0) {
                                _has_foraged_items_in_inventory = true;
                                break;
                            }
                        }
                    }
                }

                // LEARNING POINT: When a task like foraging ends because the resource is gone,
                // the pop needs to decide what to do next. If it has collected items, it should
                // probably go store them (HAULING). If not, it should look for more resources or idle.

                if (_has_foraged_items_in_inventory) {
                    // Pop has items from the depleted source, so transition to HAULING
                    show_debug_message("Pop " + _pop_id_str_depletion + " has foraged items. Transitioning to HAULING.");

                    // Store context about the completed foraging task
                    self.previous_state = EntityState.FORAGING; 
                    // self.last_foraged_target_id = target_interaction_object_id; // Store the (now depleted) target
                    // Safer: ensure target_interaction_object_id still exists before assigning
                    self.last_foraged_target_id = instance_exists(target_interaction_object_id) ? target_interaction_object_id : noone;
                    self.last_foraged_slot_index = target_interaction_slot_index;
                    self.last_foraged_type_tag = target_interaction_type_tag;

                    // Release the slot from the depleted resource
                    // LEARNING POINT: It's crucial to pass the correct ID to the slot release function.
                    // We need to release the specific interaction_point_id, not the target_interaction_object_id (the bush/rock itself).
                    var _slot_release_idx_haul = asset_get_index("scr_interaction_slot_release");
                    if (_slot_release_idx_haul != -1 && script_exists(_slot_release_idx_haul)) {
                        // OLD: if (instance_exists(target_interaction_object_id)) { script_execute(_slot_release_idx_haul, target_interaction_object_id, id); }
                        // CORRECTED: Use _interaction_point_id, which was retrieved from _slot_details.
                        if (instance_exists(_interaction_point_id)) {
                            script_execute(_slot_release_idx_haul, _interaction_point_id, id);
                        } else {
                            show_debug_message("Pop " + _pop_id_str_depletion + " (to HAUL): Interaction point " + string(_interaction_point_id) + " no longer exists or was invalid. Cannot release slot formally.");
                        }
                    } else {
                        show_debug_message("ERROR: scr_interaction_slot_release script not found! Pop " + _pop_id_str_depletion + " (to HAUL) cannot release slot.");
                    }

                    // Clear current interaction targets as we are done with this specific interaction
                    target_interaction_object_id = noone; 
                    target_interaction_slot_index = -1; 
                    target_interaction_type_tag = "";
                    

                    state = EntityState.HAULING; // Use new HAULING state
                    has_arrived = false; // Pop needs to find and move to a gathering hut
                    // _hauling_state_initialized = false; // Ensure hauling state initializes correctly if it has such a flag

                } else {
                    // Target depleted AND pop has no items of that type, so step away and then resume/idle.
                    show_debug_message("Pop " + _pop_id_str_depletion + " has NO foraged items. Stepping away before resuming/idling.");

                    // Release the slot robustly
                    // LEARNING POINT: Same as above, ensure the correct ID (_interaction_point_id) is used.
                    var _slot_release_idx_step_away = asset_get_index("scr_interaction_slot_release");
                    if (_slot_release_idx_step_away != -1 && script_exists(_slot_release_idx_step_away)) {
                        // OLD: if (instance_exists(target_interaction_object_id)) { script_execute(_slot_release_idx_step_away, target_interaction_object_id, id); }
                        // CORRECTED: Use _interaction_point_id.
                        if (instance_exists(_interaction_point_id)) { 
                            script_execute(_slot_release_idx_step_away, _interaction_point_id, id);
                        } else {
                             show_debug_message("Pop " + _pop_id_str_depletion + " (to step away): Interaction point " + string(_interaction_point_id) + " no longer exists or was invalid. Cannot release slot formally.");
                        }
                    } else {
                        show_debug_message("ERROR: scr_interaction_slot_release script not found! Pop " + _pop_id_str_depletion + " (to step away) cannot release slot.");
                    }

                    // The pop was foraging, and the task ended because the resource was depleted.
                    // It should try to find a new foraging task after stepping away.
                    self.previous_state = EntityState.FORAGING;
                    // Clear the specific last target because it's gone and we don't have items from it.
                    // The resume script will then know to search for a *new* target.
                    self.last_foraged_target_id = noone; 
                    self.last_foraged_slot_index = -1;
                    self.last_foraged_type_tag = "";
                    
                    // Calculate a "step away" position
                    var _step_away_dist = irandom_range(30, 50);
                    var _new_travel_x = x; 
                    var _new_travel_y = y + _step_away_dist; // Step away downwards for simplicity

                    // Clean up foraging-specific target info from current task variables
                    target_interaction_object_id = noone; 
                    target_interaction_slot_index = -1; 
                    target_interaction_type_tag = "";
                    
                    // Set pop to move to this new "waiting spot"
                    travel_point_x = _new_travel_x;
                    travel_point_y = _new_travel_y;
                    
                    state = EntityState.COMMANDED; // Go to COMMANDED to execute the small move
                    is_waiting = false;         // Not waiting yet, it's moving
                    has_arrived = false;        // Needs to arrive at this new step-away spot
                    
                    show_debug_message("Pop " + _pop_id_str_depletion + " (foraging complete, no items, target depleted) setting previous_state=FORAGING, last_target_vars cleared. Stepping away to (" + string(floor(travel_point_x)) + "," + string(floor(travel_point_y)) + ") before resuming/idling.");
                }
                exit; // Exit script for this step, new state (HAULING or COMMANDED) will take over
            }
        }
    } 
    // else if (target_interaction_type_tag == "some_other_task") { /* Handle other tasks */ }
    #endregion

    // =========================================================================
    // 5. CHECK INVENTORY CAPACITY (Now the sole check for hauling)
    // =========================================================================
    #region 5.1 Check if Inventory Reaches Hauling Threshold
    // var hauling_threshold = pop.base_max_items_carried; // OLD: This variable is from the deprecated 'pop' struct.
    // The correct variable is 'stats.max_carrying_capacity', which is initialized in obj_pop's Create Event.
    // Ensure 'stats' and 'max_carrying_capacity' exist to prevent errors, using a fallback if necessary.
    // Also ensure 'id' (self) has a 'stats' struct first.
    var _max_capacity = 10; // Default fallback capacity
    if (variable_instance_exists(id, "stats")) {
        if (variable_struct_exists(stats, "max_carrying_capacity")) {
            _max_capacity = stats.max_carrying_capacity;
        } else {
            show_debug_message($"WARNING (scr_pop_foraging for {id}): stats.max_carrying_capacity not found. Using fallback: {_max_capacity}");
        }
    } else {
        show_debug_message($"WARNING (scr_pop_foraging for {id}): self.stats struct not found. Using fallback capacity: {_max_capacity}");
    }
    var hauling_threshold = _max_capacity; // Haul when at max capacity.

    var total_items_in_inventory = 0;
    // Ensure inventory_items list exists before trying to access it
    if (variable_instance_exists(id, "inventory_items") && ds_exists(inventory_items, ds_type_list)) {
        for (var i = 0; i < ds_list_size(inventory_items); i++) {
            var item_struct = inventory_items[| i];
            if (is_struct(item_struct) && variable_struct_exists(item_struct, "quantity")) {
                total_items_in_inventory += item_struct.quantity;
            }
        }
    }

    if (total_items_in_inventory >= hauling_threshold) {
        // This block executes if the pop's inventory has reached the threshold to start hauling.

        // 1. Store details of the current foraging task BEFORE releasing the slot or clearing target variables.
        // This information is crucial if the pop needs to resume a similar task later.
        self.previous_state = EntityState.FORAGING; // Record that the pop was foraging.
        self.last_foraged_target_id = target_interaction_object_id; // Store the ID of the object being foraged.
        self.last_foraged_slot_index = target_interaction_slot_index; // Store the specific slot index used.
        self.last_foraged_type_tag = target_interaction_type_tag;   // Store the type of interaction (e.g., "forage_left").
        
        // For debugging: create a concise identifier string for the pop.
        var _pop_id_str = pop_identifier_string + " (ID:" + string(id) + ")";

        // Log detailed information about the transition.
        // Note: Using string concatenation for compatibility, as GMS 2.3+ f-strings might not be desired here.
        show_debug_message("Pop " + _pop_id_str + " inventory (" + string(total_items_in_inventory) + "/" + string(hauling_threshold) + 
                           ") met hauling threshold. Last Foraged Target: " + 
                           (instance_exists(self.last_foraged_target_id) ? object_get_name(self.last_foraged_target_id.object_index) + "(" + string(self.last_foraged_target_id) + ")" : "noone") + 
                           ", Slot: " + string(self.last_foraged_slot_index) + ". Transitioning to HAULING.");

        // 2. Release the interaction slot the pop was using at the foraging target.
        // It's important to free up the slot so other pops can use it.
        if (instance_exists(target_interaction_object_id) && target_interaction_slot_index != -1) {
             var _scr_slot_release_idx = asset_get_index("scr_interaction_slot_release"); // Get the script asset for releasing slots.
             if (_scr_slot_release_idx != -1 && script_exists(_scr_slot_release_idx)) {
                // Execute the slot release script, passing the target object and the pop's ID.
                script_execute(_scr_slot_release_idx, target_interaction_object_id, id); 
             } else {
                // Log an error if the slot release script cannot be found.
                show_debug_message("ERROR: scr_interaction_slot_release script not found! Pop " + _pop_id_str + " cannot release slot before hauling.");
             }
        }

        // 3. Clean up foraging-specific variables from the pop's instance.
        // Since the pop is now hauling, it no longer has a foraging target.
        target_interaction_object_id = noone; // Clear the foraging target ID.
        target_interaction_slot_index = -1;   // Reset the slot index.
        target_interaction_type_tag = "";     // Clear the interaction type tag.
        has_arrived = false; // Reset 'has_arrived' as the pop will need to move for hauling.

        // 4. Set the pop's state to HAULING.
        // The main behavior script (scr_pop_behavior) will then call scr_pop_hauling in the next step.
        state = EntityState.HAULING;
        
        // Exit this script immediately since the state has changed.
        // Further logic in this script is for foraging, which is no longer relevant.
        exit; 
    }
    #endregion
}