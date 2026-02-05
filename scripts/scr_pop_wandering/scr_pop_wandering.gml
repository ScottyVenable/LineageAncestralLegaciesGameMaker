/// scr_pop_wandering.gml
///
/// Purpose:
///   Handles the "wandering" behavior state for a pop instance. In this state,
///   the pop will randomly choose a nearby point and move towards it. Once reached,
///   it will pause briefly and then select a new point. This creates an
///   organic, idle movement pattern.
///
/// Metadata:
///   Summary: Implements random wandering movement for a pop.
///   Usage: Called from obj_pop's state machine, typically in the Step Event when current_state is EntityState.WANDERING.
///   Parameters:
///     target_pop : instance_id — The pop instance that should execute the wandering behavior.
///   Returns: void (directly modifies the target_pop's properties like x, y, state_timer, etc.)
///   Tags: [behavior][pop][movement][ai]
///   Version: 1.1 — 2025-07-28 (Refactored to use entity_data)
///   Dependencies: EntityState enum, lengthdir_x, lengthdir_y, point_distance, irandom_range, choose
///   Created: (Assumed prior to 2023)
///   Modified: 2025-07-28

function scr_pop_wandering(target_pop) {
    // =========================================================================
    // 0. IMPORTS & CACHES
    // =========================================================================
    #region 0.1 Imports & Cached Locals
    var _pop = target_pop; // Reference to the pop instance for clarity and conciseness.
    
    // Game constants / settings that might be relevant
    var _room_speed = room_speed; // For time-based calculations (e.g., state_timer decrements per frame)
    var TILE_SIZE = 16; // Assuming a tile size of 16 pixels, common in many 2D games.
                        // This should ideally be a global constant or fetched from a game settings manager.
    #endregion

    // =========================================================================
    // 1. VALIDATION & EARLY RETURNS
    // =========================================================================
    #region 1.1 Parameter Validation
    if (!instance_exists(_pop)) {
        show_debug_message("ERROR: scr_pop_wandering() — Invalid target_pop instance provided.");
        return;
    }
    if (!variable_instance_exists(_pop, "current_state") || _pop.current_state != EntityState.WANDERING) {
        // This script should only run if the pop is actually in the WANDERING state.
        // If called otherwise, it might indicate a logic error in the state machine.
        // show_debug_message("INFO: scr_pop_wandering() — Pop " + string(_pop) + " is not in WANDERING state. current_state: " + string(_pop.current_state));
        return; 
    }
    // Ensure necessary data structures from entity_data are present
    if (!variable_instance_exists(_pop, "stats") || !is_struct(_pop.stats)) {
        show_debug_message("ERROR: scr_pop_wandering() - Pop " + string(_pop) + " is missing 'stats' struct.");
        return;
    }
    if (!variable_instance_exists(_pop, "behavior_settings") || !is_struct(_pop.behavior_settings)) {
        show_debug_message("ERROR: scr_pop_wandering() - Pop " + string(_pop) + " is missing 'behavior_settings' struct.");
        return;
    }
    #endregion

    // =========================================================================
    // 2. CONFIGURATION & CONSTANTS (from Pop's Data Profile)
    // =========================================================================
    #region 2.1 Behavior-Specific Parameters
    // These values define the characteristics of the wandering behavior.
    // Fetched from the pop's data profile (_pop.behavior_settings and _pop.stats)
    // to allow different pop types to wander differently.

    // Movement speed for wandering.
    // Uses base_move_speed from the pop's stats.
    var move_speed = _pop.stats.base_move_speed; 

    // Minimum and maximum distance (in pixels) the pop will travel to a wander point.
    // Converted from tiles using TILE_SIZE.
    var wander_min_dist_pixels = _pop.behavior_settings.wander_distance_min_tiles * TILE_SIZE;
    var wander_max_dist_pixels = _pop.behavior_settings.wander_distance_max_tiles * TILE_SIZE;

    // Minimum and maximum number of wander points to generate before potentially re-evaluating broader goals (if applicable).
    // For simple wandering, this might just influence how "committed" they are to a series of short wanders.
    var min_wander_pts = _pop.behavior_settings.wander_points_min; 
    var max_wander_pts = _pop.behavior_settings.wander_points_max; 

    // Duration (in seconds) the pop will pause at a wander point before choosing a new one.
    // Converted to game frames.
    var pause_duration_frames = _pop.behavior_settings.wander_pause_duration_secs * _room_speed;
    #endregion

    // =========================================================================
    // 3. INITIALIZATION & STATE SETUP (If entering state or choosing new point)
    // =========================================================================
    #region 3.1 Initialize/Update Wander Target
    // This section runs if the pop needs a new wander target:
    // - state_timer <= 0: Indicates the pop has reached its previous target or finished pausing.
    // - target_x/target_y == -1: Indicates the pop hasn't been assigned a target yet (e.g., first time entering wander state).

    if (_pop.state_timer <= 0 || _pop.target_x == -1 || _pop.target_y == -1) {
        // If previously moving (target_x != -1), it means the pop reached its destination.
        // Now, it should pause.
        if (_pop.target_x != -1 && _pop.target_y != -1 && !_pop.is_paused_at_wander_point) {
            _pop.is_paused_at_wander_point = true;
            _pop.state_timer = pause_duration_frames; // Set timer for pausing
            
            // Stop movement by clearing target (or could set speed to 0)
            // _pop.hspeed = 0; // Not using built-in hspeed/vspeed for this example
            // _pop.vspeed = 0;
            
            // Clear pathing variables if they were used
            if (variable_instance_exists(_pop, "path")) {
                if (path_exists(_pop.path)) {
                    path_delete(_pop.path);
                }
                _pop.path = noone;
            }
            // show_debug_message("Pop " + string(_pop) + " reached wander point. Pausing for " + string(pause_duration_frames / _room_speed) + "s.");
            return; // Exit script for this frame, will resume after pause.
        }

        // If pause is finished or it's the first target, choose a new wander point.
        _pop.is_paused_at_wander_point = false;

        // Determine a random direction and distance for the new wander point.
        var wander_dir = irandom_range(0, 359); // Full circle direction
        var wander_dist = irandom_range(wander_min_dist_pixels, wander_max_dist_pixels); // Random distance within configured range

        // Calculate the new target coordinates (target_x, target_y).
        // These are stored directly on the pop instance.
        _pop.target_x = _pop.x + lengthdir_x(wander_dist, wander_dir);
        _pop.target_y = _pop.y + lengthdir_y(wander_dist, wander_dir);
        
        // Basic boundary check: Prevent wandering too far off-screen or outside defined room limits.
        // This is a simple clamp to room boundaries. More sophisticated checks might involve pathfinding grids or defined "walkable areas."
        var buffer = TILE_SIZE; // Small buffer to prevent getting stuck at the very edge.
        _pop.target_x = clamp(_pop.target_x, buffer, room_width - buffer);
        _pop.target_y = clamp(_pop.target_y, buffer, room_height - buffer);

        // Set state_timer for how long the pop should attempt to reach this new point.
        // This acts as a timeout. If the pop gets stuck, it will eventually give up and pick a new point.
        // A generous timer based on distance and speed.
        var estimated_time_to_reach = (point_distance(_pop.x, _pop.y, _pop.target_x, _pop.target_y) / move_speed) * 1.5; // 50% buffer
        _pop.state_timer = max(estimated_time_to_reach, _room_speed * 2); // Minimum 2 seconds, or estimated time.

        // Optional: If using a pathfinding system, you would generate the path here.
        // For this example, we'll use direct movement (move_towards_point).
        // if (instance_exists(obj_pathfinding_grid)) {
        //     if (path_exists(_pop.path)) path_delete(_pop.path);
        //     _pop.path = path_add();
        //     if (!mp_grid_path(obj_pathfinding_grid.grid, _pop.path, _pop.x, _pop.y, _pop.target_x, _pop.target_y, false)) {
        //         // Path failed, maybe pick a new point or wait. For now, clear target.
        //         _pop.target_x = -1; _pop.target_y = -1; _pop.state_timer = _room_speed; // Wait 1s
        //     } else {
        //         path_start(_pop.path, move_speed, path_action_stop, false);
        //     }
        // }
        // show_debug_message("Pop " + string(_pop) + " new wander target: (" + string(_pop.target_x) + "," + string(_pop.target_y) + "). Time: " + string(_pop.state_timer / _room_speed) + "s.");
    }
    #endregion

    // =========================================================================
    // 4. CORE LOGIC (Movement & State Updates)
    // =========================================================================
    #region 4.1 Movement and State Timer Update
    
    // If paused, just count down the timer and do nothing else.
    if (_pop.is_paused_at_wander_point) {
        _pop.state_timer--;
        if (_pop.state_timer <= 0) {
            _pop.is_paused_at_wander_point = false; // Pause over, will pick new point next frame.
            // show_debug_message("Pop " + string(_pop) + " finished pausing.");
        }
        return; // Exit: currently paused.
    }

    // If a target is set, move towards it.
    if (_pop.target_x != -1 && _pop.target_y != -1) {
        var _dist_to_target = point_distance(_pop.x, _pop.y, _pop.target_x, _pop.target_y);

        // Check if the pop has reached its target.
        if (_dist_to_target < move_speed) { // Using move_speed as a threshold for arrival.
            _pop.x = _pop.target_x; // Snap to target to avoid overshooting.
            _pop.y = _pop.target_y;
            _pop.state_timer = 0; // Signal that target is reached, will trigger pause/new target logic next frame.
            // show_debug_message("Pop " + string(_pop) + " arrived at wander point (" + string(_pop.target_x) + "," + string(_pop.target_y) + ").");
        } else {
            // Move towards the target point using simple linear motion.
            // More advanced movement could use pathfinding (see commented section above) or steering behaviors.
            var _dir = point_direction(_pop.x, _pop.y, _pop.target_x, _pop.target_y);
            _pop.x += lengthdir_x(min(move_speed, _dist_to_target), _dir); // Move by speed, or less if very close
            _pop.y += lengthdir_y(min(move_speed, _dist_to_target), _dir);
            
            // Update sprite based on movement direction (optional, basic example)
            // This assumes you have sprites for different directions (e.g., spr_pop_walk_left, spr_pop_walk_right)
            // and logic to handle vertical movement sprites if needed.
            // A more robust system would handle animation and facing direction more comprehensively.
            if (variable_instance_exists(_pop, "spr_walk_right") && variable_instance_exists(_pop, "spr_walk_left")) {
                if (_pop.x > _pop.xprevious) { // Moving right
                    _pop.sprite_index = _pop.spr_walk_right;
                    _pop.image_xscale = 1;
                } else if (_pop.x < _pop.xprevious) { // Moving left
                    _pop.sprite_index = _pop.spr_walk_left; // Or use spr_walk_right and flip image_xscale
                    _pop.image_xscale = -1; // Assuming spr_walk_left is oriented right, then flip
                }
                // Add conditions for up/down movement if you have separate sprites for those.
            }
        }
    }

    // Decrement the state timer. If it runs out, the pop will choose a new wander point.
    if (_pop.state_timer > 0) {
        _pop.state_timer--;
    }
    #endregion

    // =========================================================================
    // 5. CLEANUP & RETURN (Handled by instance state or not applicable here)
    // =========================================================================
    // #region 5.1 Cleanup & Return Value
    // This script modifies the instance directly. No explicit return value needed.
    // Cleanup (like deleting paths) is handled when a new target is set or state changes.
    // #endregion

    // =========================================================================
    // 6. DEBUG/PROFILING (Optional)
    // =========================================================================
    // #region 6.1 Debug & Profile Hooks
    // if (global.debug_mode) {
    //     // Example: Draw a line to the current wander target
    //     if (instance_exists(_pop) && _pop.target_x != -1 && _pop.target_y != -1 && !_pop.is_paused_at_wander_point) {
    //         draw_set_color(c_green);
    //         draw_line(_pop.x, _pop.y, _pop.target_x, _pop.target_y);
    //         draw_circle(_pop.target_x, _pop.target_y, 4, false);
    //     }
    // }
    // #endregion
}
