/// @function scr_stockpile_deposit_item(stockpile_inst, item_id_enum, quantity, item_data)
/// @description Handles depositing an item into a stockpile instance.
/// @param {Id.Instance} stockpile_inst The stockpile instance to deposit into.
/// @param {enum.Item}   item_id_enum   The enum of the item.
/// @param {real}        quantity       How many to deposit.
/// @param {struct}      item_data      The base data for the item.
/// @returns {bool} True if some or all were deposited.
function scr_stockpile_deposit_item(stockpile_inst, item_id_enum, quantity, item_data) {
    if (!instance_exists(stockpile_inst)) return false;

    // 1. Try instance-specific method
    if (variable_instance_exists(stockpile_inst, "deposit_resource")) {
        return stockpile_inst.deposit_resource(item_id_enum, quantity);
    }
    
    // 2. Fallback to direct inventory access if it exists
    if (variable_instance_exists(stockpile_inst, "inventory_items")) {
        // Assuming stockpile uses the same ds_list struct pattern
        if (script_exists(scr_inventory_add_item)) {
            var items_left = scr_inventory_add_item(stockpile_inst.inventory_items, item_id_enum, quantity);
            return (items_left < quantity); // True if at least one was added
        }
    }
    
    show_debug_message("WARNING: Stockpile " + string(stockpile_inst) + " has no known deposit method.");
    return false;
}
