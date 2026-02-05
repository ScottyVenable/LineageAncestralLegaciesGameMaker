/// obj_pop - Create Event
///
/// Purpose:
///    Initializes all instance variables for a new pop.
///
/// Metadata:
///    Summary:         Sets up basic pop structure and generates detailed attributes.
///    Usage:           Automatically called when an obj_pop instance is created.
///    Version:        1.10 - May 22, 2025 (Updated life stage assignment logic and ensured metadata reflects current date)
///    Dependencies:    scr_item_definitions_init, scr_spawn_entity
//
// ============================================================================
// INJECTED VARIABLES (Initialized to undefined to prevent IDE errors)
// These are typically set by scr_spawn_entity immediately after creation.
// entity_data = undefined;
// entity_type_id = undefined;
// ============================================================================

// =========================================================================
// 1. CORE GAMEPLAY STATE & FLAGS
// =========================================================================
#region 1.1 Basic State & Selection
state = EntityState.IDLE;
selected = false;
depth = -y;
image_speed = 1;
sprite_index = spr_pop_man_idle; // Default sprite, can be overridden by entity_data
image_index = 0;
current_sprite = sprite_index;
is_mouse_hovering = false;

// REMOVED: Old hardcoded pop initialization:
// // Updated to use a specific Hominid species from global.EntityCategories
// // as EntityType.POP_HOMINID is obsolete.
// // This provides a default concrete entity type for obj_pop instances.
// // Consider making this configurable if obj_pop needs to represent different entity types at creation.
// pop = get_entity_data(global.EntityCategories.Hominids.Species.HOMO_HABILIS_EARLY);
// if (is_undefined(pop)) {
// 	show_error("Failed to initialize 'pop': Entity data is invalid.", true);
// }
#endregion

// =========================================================================
// 2. MOVEMENT & COMMAND RELATED
// =========================================================================
#region 2.1 Movement & Command Vars
// These will be properly initialized in initialize_from_data() after 'pop' is set.
speed = 1; // Default speed, will be overridden
direction = random(360);
travel_point_x = x;
travel_point_y = y;
has_arrived = true;
was_commanded = false;
order_id = 0;
is_waiting = false;
#endregion

// =========================================================================
// 3. BEHAVIOR TIMERS & VARIABLES
// =========================================================================
#region 3.1 Idle State Variables
idle_timer = 0;
idle_target_time = 0;
idle_min_sec = 2.0;
idle_max_sec = 4.0;
after_command_idle_time = 0.5;
#endregion

#region 3.2 Wander State Variables
wander_pts = 0;
wander_pts_target = 0;
min_wander_pts = 1;
max_wander_pts = 3;
wander_min_dist = 50;
wander_max_dist = 150;
#endregion

#region 3.3 Foraging State Variables
// target_bush = noone; // Commented out: Replaced by last_foraged_target_id for resumption logic
last_foraged_target_id = noone; // Stores the ID of the last bush this pop foraged from
last_foraged_slot_index = -1;   // Stores the slot index on the last_foraged_target_id
last_foraged_type_tag = "";     // Stores the type tag of the slot on the last_foraged_target_id
forage_timer = 0;
forage_rate = global.game_speed;
#endregion

#region 3.4 Interaction Variables
target_interaction_object_id = noone;
target_object_id = noone;
_slot_index = -1; 
_interaction_type_tag = "";
#endregion

// =========================================================================
// 4. GENERATE POP DETAILS (Name, Sex, Age, Stats, Traits etc.)
// =========================================================================
#region 4.1 Generate Details
// This section will be effectively handled within initialize_from_data()
// after 'pop' (entity_data) is properly assigned.
// The call to scr_generate_pop_details will be moved into initialize_from_data().
#endregion

// =========================================================================
// 5. INVENTORY (Initialize after details)
// =========================================================================
#region 5.1 Initialize Inventory
inventory_items = ds_list_create();

// These will be properly initialized in initialize_from_data()
max_inventory_capacity = 10; // Default capacity, will be overridden
hauling_threshold = 10;    // Default threshold, will be overridden

// Initialize variables for resuming tasks, if not already present from a previous version
if (!variable_instance_exists(id, "previous_state")) {
    previous_state = undefined;
}
if (!variable_instance_exists(id, "last_foraged_target_id")) {
    last_foraged_target_id = noone;
}
if (!variable_instance_exists(id, "last_foraged_slot_index")) {
    last_foraged_slot_index = -1;
}
if (!variable_instance_exists(id, "last_foraged_type_tag")) {
    last_foraged_type_tag = "";
}

#endregion

// --- 0. Validate Injected Data ---
// Ensure entity_data has been set by the spawner (scr_spawn_entity)
if (!variable_instance_exists(self, "entity_data") || !is_struct(self.entity_data)) {
    var _error_msg = "FATAL (obj_pop Create): self.entity_data was not provided or is not a struct. Entity Type ID: " 
                   + (variable_instance_exists(self, "entity_type_id") ? string(self.entity_type_id) : "UNKNOWN") 
                   + ". Cannot initialize.";
    show_error(_error_msg, true);
    instance_destroy(); // Destroy self if no data
    exit; // Stop further execution of the Create event
}

// Assign self.entity_data to self.pop for compatibility with existing code that uses self.pop
// This ensures that scripts like scr_pop_wandering can access entity properties via self.pop.
self.pop = self.entity_data;

// Convenience alias for the injected data, used throughout this Create event.
var _data = self.entity_data;

// --- 1. Sex Assignment (Randomly chosen using EntitySex enum) ---
// Determines the biological sex of the pop, influencing sprites and potentially other attributes.
// Use EntitySex enum values instead of raw strings for consistency
self.sex = choose(EntitySex.MALE, EntitySex.FEMALE); // Randomly assign enum sex
show_debug_message($"INFO (obj_pop Create): Pop (ID: {self.entity_type_id}) assigned sex: {self.sex}.");

// --- 2. Sprite Initialization (Sex-Specific, from _data.sprite_info) ---
// Sets sprites based on assigned sex and data from _data.sprite_info.
// Includes safety checks for missing assets.

// Using the global helper function for safer sprite loading.
// The debug context string helps identify which pop instance encountered an issue.
var _debug_sprite_context = $"Pop ID: {self.entity_type_id}, Instance: {id}";

if (struct_exists(_data, "sprite_info")) {
    var _sprite_info = _data[$ "sprite_info"];
    var _fallback_sprite_asset = spr_pop_man_idle; // Default fallback if a specific placeholder isn't available

    // Idle Sprite
    var _idle_sprite_name_key = (self.sex == "male") ?
        (struct_exists(_sprite_info, "male_idle") ? _sprite_info[$ "male_idle"] : undefined) :
        (struct_exists(_sprite_info, "female_idle") ? _sprite_info[$ "female_idle"] : undefined);
    self.spr_idle = get_sprite_asset_safely(_idle_sprite_name_key, _fallback_sprite_asset, _debug_sprite_context);
    self.sprite_index = self.spr_idle; // Set current sprite to idle

    // Walk Sprite Prefix String
    self.spr_walk_prefix_string = (self.sex == "male") ?
        (struct_exists(_sprite_info, "male_walk_prefix") ? _sprite_info[$ "male_walk_prefix"] : undefined) :
        (struct_exists(_sprite_info, "female_walk_prefix") ? _sprite_info[$ "female_walk_prefix"] : undefined);
    // Note: spr_walk_prefix_string is a name prefix, not a direct asset. No get_sprite_asset_safely needed here.
    if (is_undefined(self.spr_walk_prefix_string)) {
         // Use type_tag for context if available, else fallback to "Pop"
         var _type_context = variable_struct_exists(_data, "type_tag") ? _data[$ "type_tag"] : "Pop";
         show_debug_message($"WARNING (obj_pop Create for {_type_context}): Walk sprite prefix string not found in sprite_info for sex '{self.sex}'. Movement animations may fail.");
    }

    // Portrait Sprite
    var _portrait_sprite_name_key = (self.sex == "male") ?
        (struct_exists(_sprite_info, "male_portrait") ? _sprite_info[$ "male_portrait"] : undefined) :
        (struct_exists(_sprite_info, "female_portrait") ? _sprite_info[$ "female_portrait"] : undefined);
    self.spr_portrait = get_sprite_asset_safely(_portrait_sprite_name_key, self.spr_idle, _debug_sprite_context); // Fallback to actual idle sprite if no portrait

    // Death Sprite (Example, add to sprite_info in database if needed)
    // var _death_sprite_name_key = (self.sex == "male") ?
    //     (struct_exists(_sprite_info, "male_death") ? _sprite_info.male_death : undefined) :
    //     (struct_exists(_sprite_info, "female_death") ? _sprite_info.female_death : undefined);
    // self.spr_death = get_sprite_asset_safely(_death_sprite_name_key, _fallback_sprite_asset, _debug_sprite_context);

} else {
    // Use type_tag for context if available, else fallback to "Pop"
    var _type_context = variable_struct_exists(_data, "type_tag") ? _data[$ "type_tag"] : "Pop";
    show_debug_message($"WARNING (obj_pop Create for {_type_context}): 'sprite_info' struct not found in profile. Sprites will use Create event defaults or be undefined.");
    self.spr_idle = spr_pop_man_idle; // Fallback to a default sprite
    self.sprite_index = self.spr_idle;
    self.spr_walk_prefix_string = undefined;
    self.spr_portrait = self.spr_idle; // Fallback portrait to idle
    // self.spr_death = undefined;
}
self.current_sprite = self.sprite_index;
self.current_state = EntityState.IDLE
self.image_index = 0;
self.image_speed = (is_undefined(self.sprite_index) || self.sprite_index == noone) ? 0 : 1;
// Base scale from profile, or default to 1 if not specified
self.image_xscale = struct_exists(_data, "base_scale") ? _data[$ "base_scale"] : 1;
self.image_yscale = struct_exists(_data, "base_scale") ? _data[$ "base_scale"] : 1;


// --- 3. Name Generation ---
// Generates a name for the pop. Assumes scr_generate_pop_name(profile_struct, sex_string) exists.
if (script_exists(asset_get_index("scr_name_generator"))) {
    // Pass the whole entity_data (aliased as _data) and the determined sex to the name generator
    self.pop_name = scr_name_generator(_data, self.sex);
    show_debug_message($"INFO (obj_pop Create): Pop name generated: {self.pop_name}");
} else {
    self.pop_name = "(Unnamed Pop)"; // Fallback name if script is missing
    show_debug_message("WARNING (obj_pop Create): scr_generate_pop_name script not found. Using fallback name.");
}
// pop_identifier_string is used for more detailed logging/identification
self.pop_identifier_string = self.pop_name + " [InstanceID:" + string(id) + ", ProfileID:" + string(self.entity_type_id) + "]";

// --- 4. Core Attributes & Stats (from _data.StatsBase and _data[$ "AbilityScoreRanges"]) ---
// Initialize base stats, abilities, health, speed, etc.

// --- 4.a Ability Scores ---
// Roll ability scores based on ranges in the profile
self.ability_scores = {}; // Initialize as an empty struct
if (variable_struct_exists(_data, "base_ability_scores")) {
    self.ability_scores = _data[$ "base_ability_scores"];
} else {
    if (struct_exists(_data, "AbilityScoreRanges")) {
        var _ranges = _data[$ "AbilityScoreRanges"];
        var _score_names = variable_struct_get_names(_ranges);
        for (var i = 0; i < array_length(_score_names); i++) {
            var _name = _score_names[i]; // e.g., "Strength"
            if (struct_exists(_ranges[$ _name], "min") && struct_exists(_ranges[$ _name], "max")) {
                self.ability_scores[$ _name] = irandom_range(_ranges[$ _name].min, _ranges[$ _name].max);
            } else {
                self.ability_scores[$ _name] = 10; // Default if range malformed
                show_debug_message($"WARNING (obj_pop Create for {self.pop_identifier_string}): Malformed range for ability '{_name}'. Defaulting to 10.");
            }
        }
    } else {
        show_debug_message($"WARNING (obj_pop Create for {self.pop_identifier_string}): 'AbilityScoreRanges' not in profile. Abilities not initialized from profile. Consider adding default scores.");
        // Example default scores if profile is missing this entirely:
        // self.ability_scores.Strength = 10; self.ability_scores.Dexterity = 10; // etc.
    }
}

// --- 4.b Core Stats (Speed, Perception) ---
self.stats = {}; // Initialize a struct to hold all stats for clarity

// Base speeds from profile
if (struct_exists(_data, "StatsBase") && struct_exists(_data[$ "StatsBase"], "Movement")) {
    self.stats.walk_speed = struct_exists(_data[$ "StatsBase"][$ "Movement"], "walk_speed") ? _data[$ "StatsBase"][$ "Movement"][$ "walk_speed"] : 1.0;
    self.stats.run_speed = struct_exists(_data[$ "StatsBase"][$ "Movement"], "run_speed") ? _data[$ "StatsBase"][$ "Movement"][$ "run_speed"] : 1.5;
    self.speed = self.stats.walk_speed;
} else {
    show_debug_message($"WARNING (obj_pop Create for {self.pop_identifier_string}): No 'StatsBase.Movement' in profile. Using fallback speeds.");
    self.stats.walk_speed = 1.0;
    self.stats.run_speed = 1.5;
    self.speed = self.stats.walk_speed;
}

// Perception Radius
if (struct_exists(_data, "StatsBase") && struct_exists(_data[$ "StatsBase"], "Perception")) {
    self.stats.perception_radius_pixels = struct_exists(_data[$ "StatsBase"][$ "Perception"], "base_radius") ? _data[$ "StatsBase"][$ "Perception"][$ "base_radius"] : 100;
    if (self.stats.perception_radius_pixels <= 0) {
        self.stats.perception_radius_pixels = 100;
        show_debug_message($"WARNING (obj_pop Create for {self.pop_identifier_string}): Invalid Perception radius. Defaulting to 100.");
    }
} else {
    show_debug_message($"WARNING (obj_pop Create for {self.pop_identifier_string}): No 'StatsBase.Perception' in profile. Using fallback perception: 100.");
    self.stats.perception_radius_pixels = 100;
}


// --- 4.c Derived Stats (Health, Carrying Capacity) ---
// Health
var _base_max_health = 50; // Default base health
if (struct_exists(_data, "StatsBase") && struct_exists(_data[$ "StatsBase"], "Health") && struct_exists(_data[$ "StatsBase"][$ "Health"], "base_max")) {
    _base_max_health = _data[$ "StatsBase"][$ "Health"][$ "base_max"];
}
var _constitution_score = struct_exists(self.ability_scores, "Constitution") ? self.ability_scores[$ "Constitution"] : 10;
// Example formula: Max Health = Base + (Constitution Score - 10) * 5 (adjust multiplier as needed)
self.stats.max_health = _base_max_health + (_constitution_score - 10) * 5;
self.stats.current_health = self.stats.max_health; // Start with full health

// Carrying Capacity
var _base_carrying_capacity = 0;
var _strength_multiplier_for_capacity = 2;
if (struct_exists(_data, "StatsBase") && struct_exists(_data[$ "StatsBase"], "carrying_capacity_formula")) {
    var _formula = _data[$ "StatsBase"][$ "carrying_capacity_formula"];
    if (struct_exists(_formula, "base_value")) _base_carrying_capacity = _formula[$ "base_value"];
    if (struct_exists(_formula, "strength_multiplier")) _strength_multiplier_for_capacity = _formula[$ "strength_multiplier"];
}
var _strength_score = struct_exists(self.ability_scores, "Strength") ? self.ability_scores[$ "Strength"] : 10;
self.stats.max_carrying_capacity = _base_carrying_capacity + (_strength_score * _strength_multiplier_for_capacity);


// --- 5. Skills Initialization ---
// Sets initial skill aptitudes based on the pop's profile.
self.skills_data = {}; // Initialize as an empty struct for skill data (levels, xp, aptitudes)
if (struct_exists(_data, "base_skill_aptitudes")) {
    var _aptitudes_profile = _data[$ "base_skill_aptitudes"]; // e.g., { global.GameData.Skills.Type.FORAGING: 4 }
    var _skill_enum_keys_as_strings = variable_struct_get_names(_aptitudes_profile);

    for (var i = 0; i < array_length(_skill_enum_keys_as_strings); i++) {
        var _skill_name_key = _skill_enum_keys_as_strings[i];
        var _aptitude_value = _aptitudes_profile[$ _skill_name_key];

        // Ensure the skill is valid in our global definitions
        // (Assuming we have a way to validate, else just trust the data)
        var _skill_enum_val = real(_skill_name_key); // Convert string key to number for use as enum

        // Store skill data using the numeric enum value as the key for self.skills_data
        self.skills_data[$ _skill_enum_val] = {
            aptitude: _aptitude_value,       // Innate learning speed/potential from profile
            level: 1,                        // Starting level
            experience: 0,                   // Current XP in this level
            progress_to_next_level: 0,       // For UI or calculations
            skill_id_enum: _skill_enum_val   // Store the enum for easy reference
        };
        // show_debug_message($"DEBUG (obj_pop Create): Initialized skill enum {_skill_enum_val} (Key: '{_skill_key_str}') with aptitude: {_aptitude_value}");
    }
} else {
    show_debug_message($"WARNING (obj_pop Create for {self.pop_identifier_string}): 'base_skill_aptitudes' not in profile. Skills not initialized from profile.");
}


// --- 6. Traits Initialization ---
// Assigns innate traits from the profile and applies their initial effects.
self.traits_list = ds_list_create(); // Initialize a list to store trait profile structs
if (struct_exists(_data, "innate_trait_profile_paths") && is_array(_data[$ "innate_trait_profile_paths"])) {
    var _trait_id_enum_array = _data[$ "innate_trait_profile_paths"]; // e.g., [ID.TRAIT_KEEN_EYES, ID.TRAIT_STRONG_BACK]
    for (var i = 0; i < array_length(_trait_id_enum_array); i++) {
        var _trait_id_enum = _trait_id_enum_array[i]; // This is an enum value from ID, e.g., ID.TRAIT_KEEN_EYES
        var _trait_profile_data = GetProfileFromID(_trait_id_enum); // Use the global helper

        if (!is_undefined(_trait_profile_data)) {
            ds_list_add(self.traits_list, _trait_profile_data); // Store the actual trait profile struct
            // Defensive: Always check for undefined or missing data when loading from profiles or mods.
            // This prevents runtime errors and helps with modding support.
            // TODO: Apply initial effects of the trait here.
            // This might involve calling a function like `apply_trait_effects(self, _trait_profile_data);`
            show_debug_message($"INFO (obj_pop Create for {self.pop_identifier_string}): Added innate trait '{_trait_profile_data.display_name_key}'.");
        } else {
            show_debug_message($"WARNING (obj_pop Create for {self.pop_identifier_string}): Innate trait ID enum '{_trait_id_enum}' not found via GetProfileFromID. Trait not added.");
        }
    }
} else {
     show_debug_message($"INFO (obj_pop Create for {self.pop_identifier_string}): No 'innate_trait_profile_paths' array in profile or array is empty. No innate traits assigned from profile.");
}


// --- 7. Inventory Initialization (from _data if specified, or defaults) ---
// self.inventory_items = ds_list_create(); // Already created in section 5.1

// Max capacity from profile or default
if (struct_exists(self.stats, "max_carrying_capacity")) { // This is now calculated in 4.c
    self.max_inventory_capacity = self.stats.max_carrying_capacity;
} else {
     self.max_inventory_capacity = 10; // Fallback if not calculated
     show_debug_message($"WARNING (obj_pop Create for {self.pop_identifier_string}): 'max_carrying_capacity' not in self.stats. Using fallback inventory capacity: {self.max_inventory_capacity}.");
}

// Hauling threshold (can be a fraction of max_inventory_capacity or a fixed value from profile)
// For now, let's make it 100% of capacity, or a default if capacity is very low.
self.hauling_threshold = max(5, self.max_inventory_capacity); // Haul when full, or at least 5 if capacity is tiny.
// TODO: Consider making hauling_threshold configurable in the entity profile.

// --- 8. Behavior Settings Initialization (from _data[$ "behavior_settings"]) ---
// Note: Work preferences might need to be initialized if the AI system relies on them.
if (struct_exists(_data, "ai_behavior_profile")) {
    self.ai_profile = _data[$ "ai_behavior_profile"];
} else {
    self.ai_profile = "default_pop";
}
self.behavior_settings = {}; // Initialize struct to hold behavior settings

if (struct_exists(_data, "behavior_settings")) {
    var _bs = _data[$ "behavior_settings"]; // Alias to the profile's behavior settings

    // Idle State Variables
    self.behavior_settings.idle_min_seconds = struct_exists(_bs, "idle_min_seconds") ? _bs[$ "idle_min_seconds"] : 2.0;
    self.behavior_settings.idle_max_seconds = struct_exists(_bs, "idle_max_seconds") ? _bs[$ "idle_max_seconds"] : 4.0;
    self.behavior_settings.after_command_idle_seconds = struct_exists(_bs, "after_command_idle_seconds") ? _bs[$ "after_command_idle_seconds"] : 0.5;

    // Wander State Variables
    self.behavior_settings.wander_min_points = struct_exists(_bs, "wander_min_points") ? _bs[$ "wander_min_points"] : 1;
    self.behavior_settings.wander_max_points = struct_exists(_bs, "wander_max_points") ? _bs[$ "wander_max_points"] : 3;
    self.behavior_settings.wander_min_distance_pixels = struct_exists(_bs, "wander_min_distance_pixels") ? _bs[$ "wander_min_distance_pixels"] : 50;
    self.behavior_settings.wander_max_distance_pixels = struct_exists(_bs, "wander_max_distance_pixels") ? _bs[$ "wander_max_distance_pixels"] : 150;

    // Foraging State Variables (Example - add to profile if needed)
    // self.behavior_settings.forage_duration_seconds = struct_exists(_bs, "forage_duration_seconds") ? _bs.forage_duration_seconds : 10;
    // self.forage_rate = global.game_speed; // This seems more like a global setting or derived from skill

} else {
    show_debug_message($"WARNING (obj_pop Create for {self.pop_identifier_string}): 'behavior_settings' not found in profile. Using hardcoded defaults for behavior timers/variables.");
    // Fallback to hardcoded defaults if behavior_settings struct is missing in profile
    self.behavior_settings.idle_min_seconds = 2.0;
    self.behavior_settings.idle_max_seconds = 4.0;
    self.behavior_settings.after_command_idle_seconds = 0.5;
    self.behavior_settings.wander_min_points = 1;
    self.behavior_settings.wander_max_points = 3;
    self.behavior_settings.wander_min_distance_pixels = 50;
    self.behavior_settings.wander_max_distance_pixels = 150;
    // self.forage_rate = global.game_speed;
}

// Apply these settings to the instance variables that the state machine uses
// Idle
idle_min_sec = self.behavior_settings.idle_min_seconds;
idle_max_sec = self.behavior_settings.idle_max_seconds;
after_command_idle_time = self.behavior_settings.after_command_idle_seconds;
// Wander
min_wander_pts = self.behavior_settings.wander_min_points;
max_wander_pts = self.behavior_settings.wander_max_points;
wander_min_dist = self.behavior_settings.wander_min_distance_pixels;
wander_max_dist = self.behavior_settings.wander_max_distance_pixels;
// Forage (if forage_rate is to be set from profile, do it here)
// forage_rate = ...;


// --- 9. Final Cleanup & Logging ---
// Remove the old initialize_from_profile method as its logic is now integrated above.
// The method itself is defined below the main Create event code, so it will be naturally overridden
// if this instance type (obj_pop) is inherited from. For a direct obj_pop, it's now unused.
// To explicitly remove it if it were a variable holding a function:
// if (variable_instance_exists(self, "initialize_from_profile")) {
//     initialize_from_profile = undefined; // Or use variable_instance_remove
// }

show_debug_message($"DEBUG (obj_pop Create for {self.pop_identifier_string}): Initialization from entity_data complete. State: {state}, Pos: ({x},{y}), Depth: {depth}.");
show_debug_message($"DEBUG STATS for {self.pop_identifier_string}: Speed: {self.speed}, MaxHealth: {self.stats.max_health}, Perception: {self.stats.perception_radius_pixels}, MaxCarry: {self.stats.max_carrying_capacity}");
var _skill_names_debug = "";
if (struct_exists(self, "skills_data")) {
    var _s_keys = variable_struct_get_names(self.skills_data);
    for(var _i = 0; _i < array_length(_s_keys); _i++) {
        var _key = _s_keys[_i];
        _skill_names_debug += $"SkillEnum({self.skills_data[$ _key].skill_id_enum}):Lvl{self.skills_data[$ _key].level}(Apt:{self.skills_data[$ _key].aptitude}); ";
    }
}
show_debug_message($"DEBUG SKILLS for {self.pop_identifier_string}: {_skill_names_debug}");

var _trait_names_debug = "";
if (ds_exists(self.traits_list, ds_type_list)) {
    for(var _i = 0; _i < ds_list_size(self.traits_list); _i++) {
        var _trait_data = self.traits_list[| _i];
        _trait_names_debug += $"{_trait_data[$ "display_name_key"]}; ";
    }
}
show_debug_message($"DEBUG TRAITS for {self.pop_identifier_string}: {_trait_names_debug}");

// Ensure the old initialize_from_profile method is no longer callable or defined for this instance.
// This prevents accidental calls if some legacy code path tries to invoke it.
// One way is to set it to undefined if it was assigned as a method variable.
// However, since it's a function defined in the object's event, simply not calling it
// and ensuring all its logic is moved here is sufficient.
// For clarity and to prevent any potential for it to be called if obj_pop were part of an inheritance chain
// where a parent might call it, we can explicitly nullify it if it exists on self.

// Check if the instance variable 'initialize_from_profile' exists on this instance.
// This is an alternative to using method_get() if it's causing issues.
// The original 'initialize_from_profile' is defined as a function assigned to an instance variable
// later in this Create Event. If that definition exists, this check will find the variable.
if (variable_instance_exists(self, "initialize_from_profile")) {
    // Educational Note: We've found that an instance variable named 'initialize_from_profile' exists.
    // We will now overwrite it with a new function that logs a deprecation message.
    // This ensures that if any code (perhaps legacy or from an unexpected call order)
    // tries to invoke 'self.initialize_from_profile()', it will execute our warning
    // instead of the old, now-deprecated, initialization logic.
    // For added safety in other scenarios, one might also check 'is_method(self.initialize_from_profile)'
    // before overwriting, but given the context (deprecating a known function definition),
    // directly overwriting the existing variable is the primary goal here.
    self.initialize_from_profile = function() {
        show_debug_message("DEPRECATED (obj_pop): 'initialize_from_profile' was called, but all initialization logic has been moved directly into the Create Event. This method call can be removed from where it's being invoked.");
    }
    // Log that we've performed this override for easier debugging.
    // self.pop_identifier_string should be defined earlier in this Create Event.
    if (variable_instance_exists(self, "pop_identifier_string")) {
        show_debug_message($"INFO (obj_pop Create for {self.pop_identifier_string}): Found and overrode deprecated 'initialize_from_profile' variable with a warning function.");
    } else {
        show_debug_message("INFO (obj_pop Create): Found and overrode deprecated 'initialize_from_profile' variable with a warning function (pop_identifier_string not yet available for this message).");
    }
}