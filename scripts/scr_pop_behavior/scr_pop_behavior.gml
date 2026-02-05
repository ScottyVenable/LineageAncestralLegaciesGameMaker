function scr_pop_behavior() {
    switch (state) {
        case EntityState.IDLE:
            scr_pop_idle();
            break;
        case EntityState.WANDERING:
            scr_pop_wandering(id);
            break;
        case EntityState.COMMANDED:
            scr_pop_commanded();
            break;
        case EntityState.WAITING:
            scr_pop_waiting();  // new handler
            break;
        case EntityState.FORAGING:   
            scr_pop_foraging();   
            break;  // ← new
		case EntityState.HAULING:
		    if (script_exists(scr_pop_hauling)) {
		        scr_pop_hauling(id);
		    } else {
		        show_debug_message_once($"ERROR: scr_pop_hauling script missing for pop {id}!");
		        state = EntityState.IDLE; // Fallback
		    }
		    break;
    }
}

// It uses the pop's current 'state' (an enum from EntityState)
// Ensure EntityState.IDLE is used if EntityState enum is being phased in.
