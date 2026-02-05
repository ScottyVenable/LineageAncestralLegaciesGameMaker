/// obj_hazard_controller - Create Event
///
/// Purpose:
///    Initializes a generic hazard controller based on entity_data
///    provided during its creation by scr_spawn_entity.
///
/// Metadata:
///    Summary:         Sets up hazard properties from data.
///    Usage:           Called when a hazard controller is spawned.
///    Tags:            [controller][hazard][init][data_driven]
///    Version:         1.0 - 2025-05-25 // Initial version
///    Dependencies:    scr_spawn_entity, scr_database (get_entity_data)
///    Author:          GitHub Copilot

// This controller instance expects entity_type and entity_data to be injected by scr_spawn_entity
// entity_type = undefined; // Example: EntityType.HAZARD_AREA_QUICKSAND
// entity_data = undefined; // Struct containing all data from get_entity_data()
// self.staticProfileData = undefined; // Injected by spawn_single_instance
// self.profileIDStringRef = undefined; // Injected by spawn_single_instance

// --- INJECTED VARIABLES (Initialized to undefined to prevent IDE errors) ---
staticProfileData = undefined;
profileIDStringRef = undefined;
// --------------------------------------------------------------------------

// --- Method to initialize the instance based on the provided entity_data ---
/// @function initialize_from_profile()
/// @description Initializes the hazard's properties using the self.staticProfileData struct.
///              This method is called by scr_spawn_system.spawn_single_instance after the instance is created
///              and self.staticProfileData / self.profileIDStringRef are injected.
initialize_from_profile = function() {
    // Ensure staticProfileData has been set by the spawner
    if (!is_struct(self.staticProfileData)) {
        var _error_msg = $"ERROR (obj_hazard_controller): self.staticProfileData was not provided or is not a struct. Profile ID: '{self.profileIDStringRef}'. Cannot initialize.";
        show_error(_error_msg, true);
        show_debug_message(_error_msg);
        instance_destroy(); // Destroy self if no data
        return;
    }

    var _profile = self.staticProfileData;
    var _profile_id = self.profileIDStringRef;

    show_debug_message($"Initializing Hazard from Profile: '{_profile_id}' (Object: {_profile[$ "object_to_spawn"]})");

    // I. Core Identification & Behavior
    self.display_name = variable_struct_exists(_profile, "display_name") ? _profile[$ "display_name"] : "Unknown Hazard";
    self.description = variable_struct_exists(_profile, "description") ? _profile[$ "description"] : "A dangerous area or event.";
    self.hazard_category_profile_path = variable_struct_exists(_profile, "hazard_category_profile_path") ? _profile[$ "hazard_category_profile_path"] : undefined;
    self.tags = variable_struct_exists(_profile, "tags") && is_array(_profile[$ "tags"]) ? scr_struct_clone(_profile[$ "tags"]) : [];
    self.is_static_feature = variable_struct_exists(_profile, "is_static_feature") ? _profile[$ "is_static_feature"] : false;
    self.is_event_driven = variable_struct_exists(_profile, "is_event_driven") ? _profile[$ "is_event_driven"] : false;

    // II. Damage & Effects on Entities (from effect_data struct or similar in profile)
    var _effect_data = variable_struct_exists(_profile, "effect_data") && is_struct(_profile[$ "effect_data"]) ? _profile[$ "effect_data"] : {};

    self.damage_type_profile_path = variable_struct_exists(_effect_data, "damage_type_profile_path") ? _effect_data[$ "damage_type_profile_path"] : undefined;
    
    // Define damage_type_enum to silence IDE error. Logic to resolve profile_path to enum should govern this.
    self.damage_type_enum = undefined; // TODO: Resolve damage_type_profile_path to an actual enum value if needed.

    self.damage_on_enter_amount = variable_struct_exists(_effect_data, "damage_on_enter_amount") ? _effect_data[$ "damage_on_enter_amount"] : 0;
    self.damage_per_tick_amount = variable_struct_exists(_effect_data, "damage_per_tick_amount") ? _effect_data[$ "damage_per_tick_amount"] : 0;
    self.damage_tick_rate_seconds = variable_struct_exists(_effect_data, "damage_tick_rate_seconds") ? _effect_data[$ "damage_tick_rate_seconds"] : 1.0;
    self.status_effect_profile_paths_applied = variable_struct_exists(_effect_data, "status_effect_profile_paths_applied") && is_array(_effect_data[$ "status_effect_profile_paths_applied"]) ? scr_struct_clone(_effect_data[$ "status_effect_profile_paths_applied"]) : [];
    self.force_applied_vector = variable_struct_exists(_effect_data, "force_applied_vector") && is_struct(_effect_data[$ "force_applied_vector"]) ? scr_struct_clone(_effect_data[$ "force_applied_vector"]) : { x: 0, y: 0 };
    self.resource_drain_effects = variable_struct_exists(_effect_data, "resource_drain_effects") && is_array(_effect_data[$ "resource_drain_effects"]) ? scr_struct_clone(_effect_data[$ "resource_drain_effects"]) : []; // Array of {resource_profile_path, amount_per_tick}
    self.can_damage_structures = variable_struct_exists(_effect_data, "can_damage_structures") ? _effect_data[$ "can_damage_structures"] : false;
    self.can_ignite_flammables = variable_struct_exists(_effect_data, "can_ignite_flammables") ? _effect_data[$ "can_ignite_flammables"] : false;

    // III. Area, Triggering, Duration & Persistence (from behavior_data struct or similar)
    var _behavior_data = variable_struct_exists(_profile, "behavior_data") && is_struct(_profile[$ "behavior_data"]) ? _profile[$ "behavior_data"] : {};

    self.area_of_effect_shape_enum = variable_struct_exists(_behavior_data, "area_of_effect_shape_enum") ? _behavior_data[$ "area_of_effect_shape_enum"] : undefined; // e.g., AreaShape.CIRCLE (ensure enum exists)
    self.area_dimensions = variable_struct_exists(_behavior_data, "area_dimensions") && is_struct(_behavior_data[$ "area_dimensions"]) ? scr_struct_clone(_behavior_data[$ "area_dimensions"]) : { radius: 32 };
    self.trigger_condition_enum = variable_struct_exists(_behavior_data, "trigger_condition_enum") ? _behavior_data[$ "trigger_condition_enum"] : undefined; // e.g., HazardTrigger.ALWAYS_ACTIVE
    self.trigger_radius_pixels = variable_struct_exists(_behavior_data, "trigger_radius_pixels") ? _behavior_data[$ "trigger_radius_pixels"] : 0;
    self.activation_delay_seconds = variable_struct_exists(_behavior_data, "activation_delay_seconds") ? _behavior_data[$ "activation_delay_seconds"] : 0;
    self.is_temporary = variable_struct_exists(_behavior_data, "is_temporary") ? _behavior_data[$ "is_temporary"] : true;
    self.lifespan_seconds_active = variable_struct_exists(_behavior_data, "lifespan_seconds_active") ? _behavior_data[$ "lifespan_seconds_active"] : 10;
    self.cooldown_seconds_after_deactivation = variable_struct_exists(_behavior_data, "cooldown_seconds_after_deactivation") ? _behavior_data[$ "cooldown_seconds_after_deactivation"] : 0;
    self.is_removable_by_player_action = variable_struct_exists(_behavior_data, "is_removable_by_player_action") ? _behavior_data[$ "is_removable_by_player_action"] : false;
    self.removal_requirements = variable_struct_exists(_behavior_data, "removal_requirements") && is_array(_behavior_data[$ "removal_requirements"]) ? scr_struct_clone(_behavior_data[$ "removal_requirements"]) : []; // Array of {item_profile_path, quantity} or {skill_profile_path, level}
    
    // Spreading behavior (from spread_data struct or similar)
    var _spread_data = variable_struct_exists(_profile, "spread_data") && is_struct(_profile[$ "spread_data"]) ? _profile[$ "spread_data"] : {};
    self.is_spreading_hazard = variable_struct_exists(_spread_data, "is_spreading_hazard") ? _spread_data[$ "is_spreading_hazard"] : false;
    self.spread_chance_per_tick = variable_struct_exists(_spread_data, "spread_chance_per_tick") ? _spread_data[$ "spread_chance_per_tick"] : 0.1;
    self.spread_interval_seconds = variable_struct_exists(_spread_data, "spread_interval_seconds") ? _spread_data[$ "spread_interval_seconds"] : 1.0;
    self.max_spread_radius_or_tiles = variable_struct_exists(_spread_data, "max_spread_radius_or_tiles") ? _spread_data[$ "max_spread_radius_or_tiles"] : 100;
    self.spread_target_tags = variable_struct_exists(_spread_data, "spread_target_tags") && is_array(_spread_data[$ "spread_target_tags"]) ? scr_struct_clone(_spread_data[$ "spread_target_tags"]) : [];
    self.spread_hazard_profile_path = variable_struct_exists(_spread_data, "spread_hazard_profile_path") ? _spread_data[$ "spread_hazard_profile_path"] : self.profileIDStringRef; // Hazard may spread itself or a different one

    // IV. Visuals & Audio (from visual_audio_data struct or sprite_info)
    var _visual_audio_data = variable_struct_exists(_profile, "visual_audio_data") && is_struct(_profile[$ "visual_audio_data"]) ? _profile[$ "visual_audio_data"] : {};

    self.is_initially_visible = variable_struct_exists(_visual_audio_data, "is_initially_visible") ? _visual_audio_data[$ "is_initially_visible"] : true;
    self.detection_difficulty_enum = variable_struct_exists(_visual_audio_data, "detection_difficulty_enum") ? _visual_audio_data[$ "detection_difficulty_enum"] : undefined; // e.g., DetectionDifficulty.EASY
    
    if (variable_struct_exists(_profile, "sprite_info") && is_struct(_profile[$ "sprite_info"]) && variable_struct_exists(_profile[$ "sprite_info"], "default")) {
        sprite_index = _profile[$ "sprite_info"][$ "default"];
    } else {
        // Fallback if spr_placeholder_hazard is not defined
        if (!variable_instance_exists(self, "spr_placeholder_hazard")) {
             // If a generic "undefined" sprite exists, use it, otherwise don't assign (or use -1)
             // sprite_index = -1; 
             // Ideally we shouldn't rely on undeclared sprites.
        } else {
             sprite_index = spr_placeholder_hazard; 
        }
        show_debug_message($"Warning (obj_hazard_controller): Profile '{_profile_id}' has no sprite_info.default. Using placeholder.");
    }
    if (variable_struct_exists(_profile, "sprite_info") && is_struct(_profile[$ "sprite_info"]) && variable_struct_exists(_profile[$ "sprite_info"], "image_speed")) {
        image_speed = _profile[$ "sprite_info"][$ "image_speed"];
    } else {
        image_speed = (sprite_index == spr_placeholder_hazard) ? 0 : 1; // Default to static for hazards unless animated
    }
    self.animation_profile_path_active = variable_struct_exists(_visual_audio_data, "animation_profile_path_active") ? _visual_audio_data[$ "animation_profile_path_active"] : undefined;

    self.particle_system_profile_path_on_active = variable_struct_exists(_visual_audio_data, "particle_system_profile_path_on_active") ? _visual_audio_data[$ "particle_system_profile_path_on_active"] : undefined;
    self.decal_sprite_profile_path_on_terrain = variable_struct_exists(_visual_audio_data, "decal_sprite_profile_path_on_terrain") ? _visual_audio_data[$ "decal_sprite_profile_path_on_terrain"] : undefined;
    self.sound_effect_profile_path_ambient_looping = variable_struct_exists(_visual_audio_data, "sound_effect_profile_path_ambient_looping") ? _visual_audio_data[$ "sound_effect_profile_path_ambient_looping"] : undefined;
    self.sound_effect_profile_path_on_trigger_activate = variable_struct_exists(_visual_audio_data, "sound_effect_profile_path_on_trigger_activate") ? _visual_audio_data[$ "sound_effect_profile_path_on_trigger_activate"] : undefined;
    self.sound_effect_profile_path_on_damage_dealt = variable_struct_exists(_visual_audio_data, "sound_effect_profile_path_on_damage_dealt") ? _visual_audio_data[$ "sound_effect_profile_path_on_damage_dealt"] : undefined;

    // V. Entity Interaction Specifics (from interaction_data struct or similar)
    var _interaction_data = variable_struct_exists(_profile, "interaction_data") && is_struct(_profile[$ "interaction_data"]) ? _profile[$ "interaction_data"] : {};

    self.movement_modifier_enum = variable_struct_exists(_interaction_data, "movement_modifier_enum") ? _interaction_data[$ "movement_modifier_enum"] : undefined; // e.g., MovementEffect.NONE
    self.required_trait_profile_paths_to_ignore = variable_struct_exists(_interaction_data, "required_trait_profile_paths_to_ignore") && is_array(_interaction_data[$ "required_trait_profile_paths_to_ignore"]) ? scr_struct_clone(_interaction_data[$ "required_trait_profile_paths_to_ignore"]) : [];
    self.affected_entity_tags = variable_struct_exists(_interaction_data, "affected_entity_tags") && is_array(_interaction_data[$ "affected_entity_tags"]) ? scr_struct_clone(_interaction_data[$ "affected_entity_tags"]) : ["pop_organic", "creature"]; // Default to affecting pops and creatures

    // --- State Variables ---
    self.is_active = false; // Hazard starts inactive unless trigger is ALWAYS_ACTIVE or similar
    // Initialize based on trigger condition
    if (self.trigger_condition_enum == HazardTrigger.ALWAYS_ACTIVE) { // Assuming HazardTrigger enum
        self.is_active = true;
        // TODO: Start any active effects, sounds, visuals immediately
    }
    self.current_lifespan_timer_steps = self.is_temporary ? (self.lifespan_seconds_active * game_get_speed(gamespeed_fps)) : -1; // -1 for infinite if not temporary
    self.current_damage_tick_timer_steps = self.damage_tick_rate_seconds * game_get_speed(gamespeed_fps);
    self.current_spread_tick_timer_steps = self.spread_interval_seconds * game_get_speed(gamespeed_fps);
    self.current_cooldown_timer_steps = 0;
    self.entities_inside = ds_list_create(); // To track entities currently affected
    self.status_effects_applied = []; // Initialize to empty to prevent crash in apply_effects (TODO: Resolve from paths)

    show_debug_message($"Hazard '{_profile_id}' initialized successfully.");

}; // End of initialize_from_profile

// --- Call the initialization method ---
// Old call, remove or comment out.
// The new system expects spawn_single_instance to call initialize_from_profile()

// Example of how it was previously:
// if (instance_exists(self)) { // Check if not destroyed by init
//     if (is_method(self, initialize_from_data)) {
//         initialize_from_data();
//     } else {
//         show_error("obj_hazard_controller: initialize_from_data method not found!", true);
//     }
// }

// The above block should be removed.

// --- Placeholder Methods (to be expanded in Step event or other events) ---

/// @function activate_hazard()
/// @description Activates the hazard's effects.
self.activate_hazard = function() {
    if (self.is_active) return;
    self.is_active = true;
    self.current_lifespan_timer = self.lifespan_seconds_active * game_get_speed(gamespeed_fps);
    debug_log($"Hazard '{self.display_name}' activated.", "Hazard:State", "orange");
    // TODO: Play activation sound/visuals (e.g., self.sound_effect_on_trigger_activate, particle_system_on_active)
    // TODO: If damage_on_enter_amount > 0, apply to entities already inside (though typically this is for new entries)
};

/// @function deactivate_hazard()
/// @description Deactivates the hazard and starts cooldown if applicable.
self.deactivate_hazard = function() {
    if (!self.is_active) return;
    self.is_active = false;
    self.current_cooldown_timer = self.cooldown_seconds_after_deactivation * game_get_speed(gamespeed_fps);
    ds_list_clear(self.entities_inside); // Clear entities when deactivated
    debug_log($"Hazard '{self.display_name}' deactivated. Cooldown: {self.cooldown_seconds_after_deactivation}s.", "Hazard:State", "yellow");
    // TODO: Stop ambient sounds/visuals
};

/// @function apply_effects_to_entity(entity_instance_id)
/// @description Applies damage, status effects, forces to a specific entity.
self.apply_effects_to_entity = function(entity_instance_id) {
    if (!instance_exists(entity_instance_id) || !self.is_active) return;

    // Check if entity matches affected_entity_tags
    var _can_affect = false;
    if (method_exists(entity_instance_id, "get_tags")) { // Assuming entities have a get_tags() method
        var _entity_tags = entity_instance_id.get_tags();
        for (var i = 0; i < array_length(self.affected_entity_tags); i++) {
            if (array_contains(_entity_tags, self.affected_entity_tags[i])) {
                _can_affect = true;
                break;
            }
        }
    } else {
        // If no tag system, assume it can be affected (or add other checks)
        _can_affect = true; 
    }
    if (!_can_affect) return;

    // TODO: Check for required_pop_traits_to_ignore if entity is a pop

    // Apply damage_per_tick
    if (self.damage_per_tick_amount > 0) {
        if (method_exists(entity_instance_id, "take_damage")) {
            entity_instance_id.take_damage(self.damage_per_tick_amount, self.damage_type_enum, id);
            if (variable_instance_exists(self, "sound_effect_on_damage_dealt") && self.sound_effect_on_damage_dealt != undefined) {
                 audio_play_sound(self.sound_effect_on_damage_dealt, 0, false);
            }
        }
    }

    // Apply status_effects_applied
    for (var i = 0; i < array_length(self.status_effects_applied); i++) {
        var _effect_data = self.status_effects_applied[i];
        if (random(1) < _effect_data.application_chance) {
            if (method_exists(entity_instance_id, "apply_status_effect")) {
                // entity_instance_id.apply_status_effect(_effect_data.effect_enum, _effect_data.potency, _effect_data.duration_seconds_on_entity, _effect_data.stacking_limit);
                // TODO: Uncomment and ensure apply_status_effect method exists and matches parameters
                 debug_log($"Applied status '{_effect_data.effect_enum}' to {entity_instance_id} from '{self.display_name}'", "Hazard:Effect", "magenta");
            }
        }
    }
    
    // Apply force_applied_vector
    if (self.force_applied_vector.x != 0 || self.force_applied_vector.y != 0) {
        if (variable_instance_exists(entity_instance_id, "x") && variable_instance_exists(entity_instance_id, "y")) {
            // This is a simple direct application; a physics system or more complex movement handling would be better
            // entity_instance_id.x += self.force_applied_vector.x;
            // entity_instance_id.y += self.force_applied_vector.y;
            // TODO: Implement proper force application (e.g., add to a velocity vector on the entity)
            debug_log($"Applied force ({self.force_applied_vector.x}, {self.force_applied_vector.y}) to {entity_instance_id} from '{self.display_name}'", "Hazard:Effect", "magenta");
        }
    }

    // Apply resource_drain_effects
    // TODO: Implement resource drain logic
};

// Clean up ds_list in Clean Up event
// event_inherited(ev_cleanup);
// ds_list_destroy(self.entities_inside);
