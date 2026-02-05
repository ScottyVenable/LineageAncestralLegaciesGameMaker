// Script Name: scr_constants
// Purpose: Defines global enumerations (enums) and potentially other constants used throughout the game.
//          This script should be placed high in the asset tree or ensured to compile early so these
//          definitions are available when other scripts need them.
//
// Metadata:
//   Summary: Contains global game enums like EntityState, ItemType, PopNeeds, BuildingTypes, etc.
//   Usage: Exists in the project; its contents are globally accessible once compiled. Not called as a function.
//   Parameters: none (This script is not a function and does not accept parameters)
//   Returns: n/a (This script is not a function and does not return values)
//   Tags: [global][definitions][enums][constants]
//   Version: 1.5 — 2025-07-26 (Aligned with project template)
//   Dependencies: none (Enums defined here are self-contained)
//   Created: 2023-XX-XX (Assuming a creation date)
//   Modified: 2025-07-26 // Previously 2025-05-22
//
// ---

// This script does not define a function, so no JSDoc function block is needed here.
// It directly defines enums and constants at the global scope.

// =========================================================================
// 0. IMPORTS & CACHES (Not typically applicable for a pure constants script)
// =========================================================================
#region 0. IMPORTS & CACHES
// (Not applicable for a script that only defines global enums at the top level)
#endregion

// =========================================================================
// 1. VALIDATION & EARLY RETURNS (Not applicable for a constants script)
// =========================================================================
#region 1. VALIDATION & EARLY RETURNS
// (Not applicable for a script that only defines global enums)
#endregion

// =========================================================================
// 2. GLOBAL DEFINITIONS (ENUMS, MACROS, CONSTANTS)
// =========================================================================
#region 2. GLOBAL DEFINITIONS

#region 2.1 Pop Enums
enum EntityState {
	NONE,
	
    IDLE,
    COMMANDED,
    WANDERING,
    EATING,
    SLEEPING,   // Added
    WORKING,    // Added
    CRAFTING,   // Added
    BUILDING,   // Added
    HAULING,    // Added
    ATTACKING,
    FLEEING,
    SOCIALIZING,// Added
    WAITING,
    FORAGING
    // Add other pop states as needed
}
enum EntitySex {
	MALE,
	FEMALE
}
enum EntityNeed {
    HUNGER,
    THIRST,
    ENERGY,     // Or Rest/Sleep
    SAFETY,
    SHELTER,    // Related to safety/environment
    SOCIAL,
    RECREATION, // Or Fun/Entertainment
    COMFORT,    // Temperature, clothing etc.
    HEALTH      // General physical well-being
}

enum EntitySkill {
    FORAGING,
    FARMING,
    MINING,
    WOODCUTTING,
    CRAFTING_GENERAL,
    CRAFTING_WEAPONS,
    CRAFTING_TOOLS,
    CRAFTING_APPAREL,
    CONSTRUCTION,
    COOKING,
    MEDICINE,
    COMBAT_MELEE,
    COMBAT_RANGED,
    SOCIAL_CHARISMA, // For leadership, trading
    RESEARCHING,
    HAULING // Efficiency in carrying things
}

enum EntityRelationship {
    STRANGER,
    ACQUAINTANCE,
    FRIEND,
    GOOD_FRIEND,
    COMPANION, // Close, possibly romantic or deep platonic
    RIVAL,
    ENEMY,
    FAMILY_PARENT,
    FAMILY_SIBLING,
    FAMILY_CHILD,
    FAMILY_SPOUSE
}

// Define the PopLifeStage enum to represent different life stages of pops
enum PopLifeStage {
    TRIBAL, // Represents the tribal life stage
    AGRICULTURAL, // Placeholder for future life stages
    INDUSTRIAL // Placeholder for future life stages
}
#endregion

#region 2.2 Item Enums
enum ItemType {
    CONSUMABLE_FOOD,
    CONSUMABLE_DRINK,
    CONSUMABLE_MEDICINE,
    MATERIAL_STONE,
    MATERIAL_WOOD,
    MATERIAL_METAL,
    MATERIAL_FIBER, // For cloth, rope
    MATERIAL_FUEL,  // For fires, crafting stations
    EQUIPMENT_TOOL,
    EQUIPMENT_WEAPON_MELEE,
    EQUIPMENT_WEAPON_RANGED,
    EQUIPMENT_ARMOR_HEAD,
    EQUIPMENT_ARMOR_TORSO,
    EQUIPMENT_ARMOR_LEGS,
    FURNITURE,      // Placeable items
    BLUEPRINT,      // For learning new crafts/buildings
    QUEST,
	UNDEFINED,
    MISC
}

enum ItemQuality { // Could also be ItemTier
    CRUDE,
    POOR,
    COMMON,         // Or Standard, Normal
    GOOD,
    EXCELLENT,
    MASTERWORK,
    LEGENDARY       // Or Artifact
}

enum ItemTag { // For more flexible item categorization beyond ItemType
    EDIBLE,
    DRINKABLE,
    FLAMMABLE,
    CONSTRUCTION_MATERIAL,
    WEAPON_BLUNT,
    WEAPON_SLASHING,
    WEAPON_PIERCING,
    TOOL_GATHERING,
    TOOL_CRAFTING,
    CLOTHING_WARM,
    CLOTHING_COLD_RESISTANT,
    DECORATIVE
}
#endregion

#region 2.3 Building & Zone Enums
enum BuildingCategory {
    HOUSING,
    PRODUCTION_PRIMARY,   // Resource gathering spots like mines, lumber camps
    PRODUCTION_SECONDARY, // Crafting stations like smithy, tailor
    STORAGE,
    DEFENSE,
    INFRASTRUCTURE, // Roads, bridges
    COMMUNITY,      // Meeting spots, recreation
    AGRICULTURE     // Farms, hydroponics
}

enum StructureType { // More specific than category
    // Housing
    HUT_PRIMITIVE,
    HOUSE_SMALL,
    BARRACKS,
    // Production Primary
    FORAGING_POST,
    LUMBER_CAMP,
    MINE_SHAFT,
    QUARRY,
    FISHING_SPOT,
    // Production Secondary
    WORKBENCH_GENERAL,
    CAMPFIRE_COOKING,
    SMELTER,
    SMITHY,
    TAILOR_STATION,
    RESEARCH_BENCH,
    // Storage
    STORAGE_PILE_WOOD,
    STORAGE_PILE_STONE,
    GRANARY,
    WAREHOUSE_SMALL,
    // Defense
    WALL_WOODEN,
    WALL_STONE,
    WATCHTOWER,
    TRAP_SPIKE,
    // Infrastructure
    PATH_DIRT,
    BRIDGE_WOODEN,
    // Community
    FIRE_PIT_COMMUNAL,
    GATHERING_HALL,
    // Agriculture
    FARM_PLOT_SMALL,
    HYDROPONICS_BASIN
}
#endregion

#region 2.4 Resource Enums
enum BiomeType {
    FOREST_TEMPERATE,
    FOREST_BOREAL,
    PLAINS,
    GRASSLAND,
    MOUNTAIN_ROCKY,
    MOUNTAIN_SNOWY,
    SWAMP,
    DESERT_ARID,
    TUNDRA,
    RIVER,
    LAKE,
    OCEAN_COAST
}

enum Season {
    SPRING,
    SUMMER,
    AUTUMN,
    WINTER
}

enum WeatherType {
    CLEAR_SKY,
    PARTLY_CLOUDY,
    OVERCAST,
    LIGHT_RAIN,
    HEAVY_RAIN,
    THUNDERSTORM,
    LIGHT_SNOW,
    HEAVY_SNOW,
    BLIZZARD,
    FOG,
    HAIL,
    DUST_STORM // If applicable
}

enum TimeOfDay { // Could be used for lighting, pop schedules
    DAWN,
    MORNING,
    MIDDAY,
    AFTERNOON,
    DUSK,
    NIGHT,
    MIDNIGHT
}
#endregion

#region 2.5 UI & Interaction Enums
enum TaskPriority {
    NONE,       // Not set or not a task
    VERY_LOW,
    LOW,
    NORMAL,
    HIGH,
    URGENT,
    CRITICAL    // System critical, must be done
}

// Enum to define different ways entities can be arranged when spawned in groups.
// Used by scr_spawn_system and scr_formations.
enum FormationType {
    NONE,                       // No specific formation, entities might spawn at the same point or randomly within a radius.
    GRID,                       // Entities arranged in a grid.
    LINE_HORIZONTAL,            // Entities in a horizontal line.
    LINE_VERTICAL,              // Entities in a vertical line.
    CIRCLE,                     // Entities arranged in a circle around a central point.
    RANDOM_WITHIN_RADIUS,       // Entities spawned randomly within a specified radius from a central point.
    SINGLE_POINT,
    CLUSTERED,
    PACK_SCATTER,
    SCATTER,
    STAGGERED_LINE_HORIZONTAL
    
    
    // Add other formation types as needed, e.g.:
    // STAGGERED_GRID,
    // V_FORMATION,
}

enum AlertLevel { // For colony/settlement wide alerts
    NONE,       // All clear
    CAUTION,    // Potential threat, be aware
    LOW_THREAT, // Minor threat detected (e.g., small predator)
    MEDIUM_THREAT, // Significant threat (e.g., raiders sighted)
    HIGH_THREAT,  // Imminent danger (e.g., attack underway)
    EVACUATE    // Extreme danger, non-combatants to safety
}

enum FactionStanding { // How other factions view the player's faction
    HOSTILE_AT_WAR,
    HOSTILE_AGGRESSIVE,
    NEUTRAL_WARY,
    NEUTRAL,
    NEUTRAL_FRIENDLY_LEANING,
    FRIENDLY_ALLY,
    FRIENDLY_LOYAL_ALLY
}
#endregion

// Add any additional game state or system-related enums here
enum HazardTrigger {
    ALWAYS_ACTIVE,
    ON_TOUCH,
    ON_PROXIMITY,
    ON_TIMER,
    ON_SIGNAL
}

enum AreaShape {
    CIRCLE,
    SQUARE,
    RECTANGLE,
    CONE
}

enum DetectionDifficulty {
    TRIVIAL,
    EASY,
    NORMAL,
    HARD,
    IMPOSSIBLE,
    NONE
}

enum MovementEffect {
    NONE,
    SLOW,
    STUN,
    SNARE,
    KNOCKBACK,
    PULL
}
#endregion

#region 2.7 Other Constants & Macros (If any)
// Example: #macro TILE_SIZE 32
// Example: #macro GAME_VERSION "0.1.0-alpha"
#endregion

#endregion // End of 2. GLOBAL DEFINITIONS

// =========================================================================
// X. CLEANUP (Not applicable for a constants script)
// =========================================================================
// (No cleanup actions needed for a script that only defines constants)
