/// obj_controller – Create Event
///
/// Purpose:
///    Initializes core game controller variables, camera, selection system,
///    UI, global game settings (like formation type & notification vars),
///    and spawns the initial set of pops.
///
/// Metadata:
///    Summary:         Master setup for game systems, UI, and initial world state.
///    Usage:           obj_controller Create Event.
///    Tags:            [controller][init][global][ui][camera][spawn][formation][notification][selection]
///    Version:         1.8 - 2024-05-19 // Scotty's Current Date - Added overlay toggle logic
///    Dependencies:  scr_item_definitions_init, obj_UIPanel_Generic, obj_pop,
///                     Formation (enum from scr_constants.gml), room_speed

// ============================================================================
// 0. GLOBAL VARIABLES INITIALIZATION (Ensure before any pops are created)
// ============================================================================
#region 0.1 Initialize Global Variables
// Disable antialiasing for pixel-perfect rendering
gpu_set_texfilter(false);

// Ensure the first_load variable is initialized
// --- Ensure the game database is initialized before using global.GameData ---
if (!variable_global_exists("GameData") || !is_struct(global.GameData)) {
    scr_database_init();
}

if (!variable_global_exists("first_load")) {
    global.first_load = true; // Assume it's a new game if not set
}

// Initialize global life_stage variable
if (!variable_global_exists("life_stage")) {
    if (global.first_load) {
        global.life_stage = PopLifeStage.TRIBAL; // Set to TRIBAL for the first game load
        debug_log("Global life_stage set to TRIBAL on first load.", "obj_controller:Create", "green");
    } else {
        global.life_stage = undefined; // Placeholder for dynamic assignment later
        debug_log("Global life_stage will be determined dynamically.", "obj_controller:Create", "yellow");
    }
}

// Initialize hover detection distance for pops
if (!variable_global_exists("hover_detection_distance")) {
    global.hover_detection_distance = 50; // Default hover detection distance in pixels
}

// --- Ensure selected_pop is always defined to prevent runtime errors ---
selected_pop = noone; // This prevents 'not set before reading' errors when checking or using selected_pop

#endregion

// ============================================================================
// 1. DISPLAY & GUI SETUP
// ============================================================================
randomize();
#region 1.1 GUI Render Target
//display_set_gui_size(room_width, room_height);
scr_item_definitions_init(); // Assuming this defines items
#endregion

// ============================================================================
// 2. CORE INSTANCE VARIABLES (Selection, Camera, Click Tracking)
// ============================================================================
#region 2.1 Selection Variables (for GUI drag box & single selection tracking)
global.selected_pop   = noone; // Tracks a single primarily selected pop (optional if relying solely on list) // MODIFIED: Made global
sel_start_x         = 0;     // GUI X where drag selection box started
sel_start_y         = 0;     // GUI Y where drag selection box started
is_dragging         = false; // True when actively dragging a selection box
click_start_world_x = 0;     // World X where a click/drag input began
click_start_world_y = 0;     // World Y where a click/drag input began
ui_inspector_cleared = true; // Tracks if the inspector UI has been set to its "cleared" (N/A) state.

debug_log($"click_start_world_x initialized to: {click_start_world_x}", "obj_controller:Create", "cyan");
#endregion

// Regions 2.2 (Zoom Variables) and 2.3 (Camera Tracking Variables) are removed as camera logic is now in obj_camera_controller.

// ============================================================================
// 3. CAMERA SETUP (Initial camera configuration)
// ============================================================================
// Region 3.1 (Active Camera Setup) is removed. obj_camera_controller handles its own setup.

// Ensure obj_camera_controller instance exists
if (!instance_exists(obj_camera_controller)) {
    // Assuming "Instances" layer is appropriate. Adjust if you have a dedicated layer for controllers.
    var _controller_layer = "Instances"; 
    if (!layer_exists(_controller_layer)) {
        layer_create(0, _controller_layer); // Create layer if it doesn't exist, depth 0 or other suitable depth
        debug_log($"Dynamically created controller layer: '{_controller_layer}' for obj_camera_controller.", "obj_controller:Create", "cyan");
    }
    instance_create_layer(0, 0, _controller_layer, obj_camera_controller);
    debug_log("DEBUG (obj_controller): Created obj_camera_controller instance.", "obj_controller:Create", "green");
}

// ============================================================================
// 4. GLOBAL GAME STATE & UI
// ============================================================================
#region 4.1 Gameplay Globals
global.musicplaying			= false
global.order_counter        = 0;
global.initial_pop_count    = 5; // Example
global.pop_count            = global.initial_pop_count
global.selected_pops_list   = ds_list_create(); // Create the global list for selected pops ONCE here.
// Initialize game_speed using the game's configured FPS (steps per second)
// This is a reliable way to handle game speed for time-based calculations.
global.game_speed			= game_get_speed(gamespeed_fps); 

global.lineage_food_stock       = 100; // Example starting food
global.lineage_wood_stock       = 50;  // Example starting wood
global.lineage_stone_stock      = 30;  // Example starting stone
global.lineage_metal_stock		= 0
global.lineage_housing_capacity = 5;   // How many pops can be housed

// Pop count will be dynamic: instance_number(obj_pop)
global.game_day                 = 1;
global.game_time_display_string = "Morning"; // Or a numerical time
#endregion

#region 4.2 Formation System Globals
global.current_formation_type   = FormationType.GRID; // Ensure Formation enum exists
global.formation_spacing        = 48;
// Formation Notification Globals
global.formation_notification_text  = "";
global.formation_notification_alpha = 0;
global.formation_notification_timer = 0;
global.formation_notification_stay_time = 1.5 * global.game_speed; 
global.formation_notification_fade_time = 0.5 * global.game_speed; 
#endregion

#region 4.3 UI Globals & Initialization
global.mouse_event_consumed_by_ui = false;
global.show_overlays = false; // Initialize overlay toggle state
global.logged_missing_selection_script = false; // Initialize flag for missing selection script log


#endregion

// ============================================================================
// 4.A ENTITY STATE SYSTEM INITIALIZATION
// ============================================================================
#region 4.A.1 Initialize Entity State Definitions
// This section is now handled by obj_entity_state_controller's Create Event.
// Ensure an instance of obj_entity_state_controller exists in the room, preferably created before obj_controller
// or early in the room's instance creation order, so global.EntityStateDefinitions is available.

if (!instance_exists(obj_entity_state_controller)) {
    // Attempt to create it if it's missing, though ideally it should be placed in the room manually.
    var _controller_layer = "Instances"; // Or a dedicated system layer
    if (!layer_exists(_controller_layer)) {
        layer_create(0, _controller_layer); 
        debug_log($"Dynamically created controller layer: '{_controller_layer}' for obj_entity_state_controller.", "obj_controller:Create", "cyan");
    }
    instance_create_layer(0, 0, _controller_layer, obj_entity_state_controller);
    debug_log("WARNING (obj_controller): obj_entity_state_controller was not found, created dynamically. Ensure it's in the room for proper initialization order.", "obj_controller:Create", "yellow");
} else {
    debug_log("INFO (obj_controller): obj_entity_state_controller found. Entity state definitions should be initialized by it.", "obj_controller:Create", "green");
}
#endregion

// ============================================================================
// 4.B PRE-SPAWN DATA INITIALIZATION (e.g. Name data for pops)
// ============================================================================
#region 4.B.1 Load Name Data
// Load pop name data from external JSON loaded into global.GameData.name_data
// Robust check to ensure global.GameData and global.GameData.name_data exist and are structs,
// and then safely access sub-properties.
if (variable_global_exists("GameData") && is_struct(global.GameData) &&
    variable_struct_exists(global.GameData, "name_data") && is_struct(global.GameData.name_data)) {

    // Safely access name components using variable_struct_get to avoid IDE undeclared variable errors on struct properties
    global.male_prefixes = variable_struct_exists(global.GameData.name_data, "male_prefixes") 
                           ? global.GameData.name_data.male_prefixes 
                           : [];

    global.male_suffixes = variable_struct_exists(global.GameData.name_data, "male_suffixes") 
                           ? global.GameData.name_data.male_suffixes 
                           : [];

    global.female_prefixes = variable_struct_exists(global.GameData.name_data, "female_prefixes") 
                             ? global.GameData.name_data.female_prefixes 
                             : [];

    global.female_suffixes = variable_struct_exists(global.GameData.name_data, "female_suffixes") 
                             ? global.GameData.name_data.female_suffixes 
                             : [];

    // Debug logging for empty lists
    if (array_length(global.male_prefixes) == 0) debug_log("WARNING: male_prefixes list is empty.", "obj_controller:Create", "yellow");
    if (array_length(global.male_suffixes) == 0) debug_log("WARNING: male_suffixes list is empty.", "obj_controller:Create", "yellow");
    if (array_length(global.female_prefixes) == 0) debug_log("WARNING: female_prefixes list is empty.", "obj_controller:Create", "yellow");
    if (array_length(global.female_suffixes) == 0) debug_log("WARNING: female_suffixes list is empty.", "obj_controller:Create", "yellow");

    
    // Check if any names were actually loaded
    if (array_length(global.male_prefixes) == 0 && array_length(global.female_prefixes) == 0) {
        debug_log("INFO: No name components (prefixes/suffixes) were loaded from global.GameData.name_data. Pop names might be blank if text file loading also fails.", "obj_controller:Create", "yellow");
    }

} else {
    // This case handles if global.GameData.name_data itself is missing or not a struct.
    debug_log("ERROR: global.GameData.name_data is not a valid struct or does not exist. Pop names will rely on text file fallbacks or be blank.", "obj_controller:Create", "red");
    global.male_prefixes   = [];
    global.male_suffixes   = [];
    global.female_prefixes = [];
    global.female_suffixes = [];
}

// Initialize text-based name loading (this is a separate system from name_data.json)
// This was previously called by obj_gameStart, but it makes sense to have it here
// if obj_controller is responsible for pop name components.
// Ensure this doesn't conflict with obj_gameStart's call if it still exists there.
// load_name_data(); // Consider if this call is duplicated or best placed here.
// For now, assuming obj_gameStart handles this initial call.
#endregion

// ============================================================================
// 4.C GLOBAL VARIABLES INITIALIZATION
// ============================================================================
#region 4.C.1 Initialize Global Variables
// Ensure the first_load variable is initialized
if (!variable_global_exists("first_load")) {
    global.first_load = true; // Assume it's a new game if not set
}

// Initialize global life_stage variable
if (!variable_global_exists("life_stage")) {
    if (global.first_load) {
        global.life_stage = PopLifeStage.TRIBAL; // Set to TRIBAL for the first game load
        debug_log("Global life_stage set to TRIBAL on first load.", "obj_controller:Create", "green");
    } else {
        global.life_stage = undefined; // Placeholder for dynamic assignment later
        debug_log("Global life_stage will be determined dynamically.", "obj_controller:Create", "yellow");
    }
}
#endregion

// ============================================================================
// 5. SET THE GAME START
// ============================================================================
#region 5.1 Spawn Initial Pops
var _pop_spawn_layer = "Pops"; // Ensure this layer exists or is created with appropriate depth (e.g., below UILayer)
if (!layer_exists(_pop_spawn_layer)) { 
    layer_create(0, _pop_spawn_layer); // Create layer if it doesn't exist (depth 0 is common for instances)
    debug_log($"Dynamically created Pop Spawn layer: '{_pop_spawn_layer}' at depth 0.", "obj_controller:Create", "cyan");
}

// Check if the spawn entity script exists
if (script_exists(scr_spawn_entity)) {
    // Entity data is fetched using GetProfileFromID, which resolves the ID enum
    // to the correct path within the global.GameData structure.
    // This ensures consistency with how other parts of the game might access entity profiles.
    var _initial_pop_entity_type = ID.POP_GEN1; // Use the ID enum for the initial pop type.
    
    // Get the entity data profile by resolving the ID.
    // GetProfileFromID is defined in scr_database.gml and maps enums to actual data paths.
    var _pop_entity_data = GetProfileFromID(_initial_pop_entity_type); 

    if (_pop_entity_data == undefined) {
        // Updated error message to reflect that an ID enum is used.
        show_error("ERROR: EntityType ID '" + string(_initial_pop_entity_type) + "' (resolved to undefined by GetProfileFromID) is not defined or accessible in the entity database. Cannot spawn initial pops!", true);
    } else {
        // Find the game start object to determine spawn location
        // Ensure obj_gameStart exists and is placed in the room.
        var _game_start_obj = instance_find(obj_gameStart, 0); // Typically there's only one
        if (!instance_exists(_game_start_obj)) {
            show_error("ERROR: obj_gameStart instance not found in the room. Cannot determine spawn location for initial pops.", true);
            return; // Exit if no spawn point
        }

        var _spawn_center_x = _game_start_obj.x;
        var _spawn_center_y = _game_start_obj.y;
        var _spawn_radius = 300; // Radius around the spawn point
        var _spawn_attempts_max_per_pop = 15; // Max attempts to find a free spot for one pop
        var _spawned_count = 0;

        debug_log($"Attempting to spawn {global.initial_pop_count} pops of type '{entity_type_to_string(_initial_pop_entity_type)}' around ({_spawn_center_x}, {_spawn_center_y}).", "obj_controller:Create", "cyan");

        for (var i = 0; i < global.initial_pop_count; i++) {
            var _attempt = 0; 
            var _spawn_x, _spawn_y; 
            var _valid_spot_found = false;
            var _controller_to_check = obj_pop; // Default to checking against obj_pop if specific controller isn't easily determined here.
                                                // This could be refined if scr_spawn_entity returned the controller type or if we had a utility.

            do {
                _attempt++;
                var _angle = random(360); 
                var _dist  = random(_spawn_radius);
                _spawn_x = _spawn_center_x + lengthdir_x(_dist, _angle);
                _spawn_y = _spawn_center_y + lengthdir_y(_dist, _angle);
                _spawn_x = clamp(_spawn_x, 32, room_width - 32); 
                _spawn_y = clamp(_spawn_y, 32, room_height - 32);
                
                // Check for collisions with existing pops (or their controllers)
                // For now, we assume initial pops are obj_pop. If other controllers are used for initial spawns,
                // this collision check might need to be more dynamic.
                if (!place_meeting(_spawn_x, _spawn_y, _controller_to_check)) { 
                    _valid_spot_found = true; 
                }
            } until (_valid_spot_found || _attempt >= _spawn_attempts_max_per_pop);
            
            if (_valid_spot_found) {
                // Use scr_spawn_entity to create the pop
                var _new_pop_instance = scr_spawn_entity(_initial_pop_entity_type, _spawn_x, _spawn_y, _pop_spawn_layer);
                
                if (instance_exists(_new_pop_instance)) {
                    _spawned_count++;
                    // debug_log($"Successfully spawned pop {i+1} (Instance ID: {_new_pop_instance}) at ({_spawn_x}, {_spawn_y}).", "obj_controller:Create", "green");
                } else {
                    debug_log($"Warning: scr_spawn_entity did not return a valid instance for pop {i+1}.", "obj_controller:Create", "yellow");
                }
            } else { 
                debug_log($"Warning: Could not find valid spawn spot for pop {i+1} after {_spawn_attempts_max_per_pop} attempts.", "obj_controller:Create", "yellow");
            }
        }
        debug_log($"Total initial pops spawned via scr_spawn_entity: {_spawned_count}/{global.initial_pop_count}.", "obj_controller:Create", "green");
    }
} else { 
    debug_log("ERROR: scr_spawn_entity script does not exist. Cannot spawn initial pops using the new system.", "obj_controller:Create", "red");
    // Fallback or alternative spawning logic could be placed here if necessary
    // For now, we'll just log the error.
}
#endregion

#region 5.2 Initialize & Play Sounds/Music
if (global.musicplaying == true){
	audio_play_sound(music1, 1, true)
}
#endregion

#region 5.3 Set UI Text Elements
// Get the ID of the layer where UI elements are placed.
text_layer_id = layer_get_id("UI"); 

if (text_layer_id == -1) {
    // Log an error if the UI layer isn't found.
    debug_log("ERROR: UI layer named 'UI' not found! Text elements cannot be initialized.", "obj_controller:Create:UI", "red");
} else {
    // Initialize the global struct to store references to UI text elements.
    // This is crucial for scr_selection_controller to update the correct fields.
    global.ui_text_elements = {}; 
    debug_log("DEBUG: Initialized global.ui_text_elements struct.", "obj_controller:Create:UI", "cyan");

    // Get all elements on the UI layer.
    var _elements_on_layer = layer_get_all_elements(text_layer_id);
    var _found_pop_name = false, _found_pop_sex = false, _found_pop_age = false; // Flags for debugging

    for (var i = 0; i < array_length(_elements_on_layer); i++) {
        var _element_id = _elements_on_layer[i];
        // We are interested only in text elements.
        if (layer_get_element_type(_element_id) == layerelementtype_text) {
            var _initial_text = layer_text_get_text(_element_id); // Get the placeholder text

            // Identify Pop Inspector Panel Text Elements by their placeholder text.
            // These placeholders must exactly match what you've set in the Room Editor.
            if (string_pos("POP_NAME_PLACEHOLDER", _initial_text) > 0) {
                global.ui_text_elements.pop_name_display = _element_id;
                layer_text_text(_element_id, "N/A"); // Set initial display to N/A
                _found_pop_name = true;
                debug_log($"Assigned Pop Name Display text element (ID: {_element_id}) based on placeholder.", "obj_controller:Create:UI", "green");
            } else if (string_pos("POP_SEX_PLACEHOLDER", _initial_text) > 0) {
                global.ui_text_elements.pop_sex_display = _element_id;
                layer_text_text(_element_id, "N/A"); // Set initial display to N/A
                _found_pop_sex = true;
                debug_log($"Assigned Pop Sex Display text element (ID: {_element_id}) based on placeholder.", "obj_controller:Create:UI", "green");
            } else if (string_pos("POP_AGE_PLACEHOLDER", _initial_text) > 0) {
                global.ui_text_elements.pop_age_display = _element_id;
                layer_text_text(_element_id, "N/A"); // Set initial display to N/A
                _found_pop_age = true;
                debug_log($"Assigned Pop Age Display text element (ID: {_element_id}) based on placeholder.", "obj_controller:Create:UI", "green");
            }
            // ... (any other general UI text elements like F0, W1, S2, M3 would be here) ...
            else if (string_pos("F0", _initial_text) > 0) { 
                global.ui_text_elements.food = _element_id;
                layer_text_text(global.ui_text_elements.food, string(global.lineage_food_stock));
                debug_log($"Assigned food text element (ID: {_element_id}).", "obj_controller:Create:UI", "green");
            } else if (string_pos("W1", _initial_text) > 0) {
                global.ui_text_elements.wood = _element_id;
                layer_text_text(global.ui_text_elements.wood, string(global.lineage_wood_stock));
                debug_log($"Assigned wood text element (ID: {_element_id}).", "obj_controller:Create:UI", "green");
            } else if (string_pos("S2", _initial_text) > 0) {
                global.ui_text_elements.stone = _element_id;
                layer_text_text(global.ui_text_elements.stone, string(global.lineage_stone_stock));
                debug_log($"Assigned stone text element (ID: {_element_id}).", "obj_controller:Create:UI", "green");
            } else if (string_pos("M3", _initial_text) > 0) {
                global.ui_text_elements.metal = _element_id;
                layer_text_text(global.ui_text_elements.metal, string(global.lineage_metal_stock));
                debug_log($"Assigned metal text element (ID: {_element_id}).", "obj_controller:Create:UI", "green");
            }
        }
    }
    // Debugging: Check if all expected inspector elements were found
    if (!_found_pop_name) { debug_log("WARNING: POP_NAME_PLACEHOLDER text element not found on UI layer.", "obj_controller:Create:UI", "yellow"); }
    if (!_found_pop_sex) { debug_log("WARNING: POP_SEX_PLACEHOLDER text element not found on UI layer.", "obj_controller:Create:UI", "yellow"); }
    if (!_found_pop_age) { debug_log("WARNING: POP_AGE_PLACEHOLDER text element not found on UI layer.", "obj_controller:Create:UI", "yellow"); }
}
#endregion
// ============================================================================
// 6. DEBUGGING & LOGGING
// ============================================================================
#region 6.1 Initial Log
// Moved to the end for better organization
if (!variable_global_exists("first_load")) {
    global.first_load = true; // Assume it's a new game if not set
}

if (global.first_load) {
    debug_log("First load detected. Setting initial pop life stage to TRIBAL.", "obj_controller:Create", "green");
    global.pop_life_stage = PopLifeStage.TRIBAL; // Set the initial life stage for pops
} else {
    debug_log("Not the first load. Pop life stage will be determined dynamically.", "obj_controller:Create", "yellow");
}

if (!variable_global_exists("life_stage")) {
    if (global.first_load) {
        global.life_stage = PopLifeStage.TRIBAL; // Set to TRIBAL for the first game load
        debug_log("Global life_stage set to TRIBAL on first load.", "obj_controller:Create", "green");
    } else {
        global.life_stage = undefined; // Placeholder for dynamic assignment later
        debug_log("Global life_stage will be determined dynamically.", "obj_controller:Create", "yellow");
    }
}

// Log initialization success
debug_log("obj_controller initialized successfully.", "obj_controller:Create", "blue");
debug_log($"Music playing set to: {global.musicplaying}", "obj_controller:Create", "blue");
#endregion



// NOTE: To ensure obj_controller runs before obj_gameStart, place obj_controller ABOVE obj_gameStart in the Room Editor's instance order.
// This ensures all controller variables and systems are initialized before game start logic runs.
