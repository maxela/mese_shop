mese_shop = {}
mese_shop.current_shop = {}
mese_shop.formspec = {
	customer = function(pos)
		local description = minetest.env:get_meta(pos):get_string("description")
		local list_name = "nodemeta:"..pos.x..','..pos.y..','..pos.z
		local formspec = "size[8,8.5]"..
		"label[0,0;Customer gives (pay here):]"..
		"list[current_player;customer_gives;0,0.5;3,2;]"..
		"label[5,0;Owner wants:]"..
		"list["..list_name..";owner_wants;5,0.5;3,2;]"..
		"label[0,3;Description:]"..
		"label[0,3.5;"..minetest.formspec_escape(description).."]"..
		"list[current_player;main;0,4.5;8,4;]"..
		"button_exit[3,1;2,1;activate;Activate]"
		return formspec
	end,
	owner = function(pos)
		local description = minetest.env:get_meta(pos):get_string("description")
		local duration = minetest.env:get_meta(pos):get_float("duration")
		if duration == nil then 
			duration = 1
		end
		local list_name = "nodemeta:"..pos.x..','..pos.y..','..pos.z
		local formspec = "size[8,8.5]"..
		"label[0,0;Customers gave:]"..
		"list["..list_name..";customers_gave;0,0.5;3,2;]"..
		"label[5,0;You want:]"..
		"list["..list_name..";owner_wants;5,0.5;3,2;]"..
-- 		"label[0,5;Owner, Use(E)+Place(RMB) for customer interface]"..
		"field[0.3,3.5;6.5,0.7;description;Description:;"..minetest.formspec_escape(description).."]"..
		"field[6.8,3.5;1.5,0.7;duration;Duration:;"..tostring(duration).."]"..
		"list[current_player;main;0,4.5;8,4;]"..
		"button[3,0.5;2,1;activate;Activate]"..
		"button_exit[3,1.5;2,1;exit;OK]"
		return formspec
	end,
}

mese_shop.check_privilege = function(listname,playername,meta)
	--[[if listname == "pl1" then
		if playername ~= meta:get_string("pl1") then
			return false
		elseif meta:get_int("pl1step") ~= 1 then
			return false
		end
	end
	if listname == "pl2" then
		if playername ~= meta:get_string("pl2") then
			return false
		elseif meta:get_int("pl2step") ~= 1 then
			return false
		end
	end]]
	return true
end


mese_shop.give_inventory = function(inv,list,playername)
	player = minetest.env:get_player_by_name(playername)
	if player then
		for k,v in ipairs(inv:get_list(list)) do
			player:get_inventory():add_item("main",v)
			inv:remove_item(list,v)
		end
	end
end

local init_mese_shop = function(pos, placer, itemstack)
	local owner = placer:get_player_name()
	local meta = minetest.env:get_meta(pos)
	meta:set_string("infotext", "Mese Shop (owned by "..owner..")")
	meta:set_string("owner",owner)
	meta:set_string("description","")
	meta:set_float("duration",1.0)
	local inv = meta:get_inventory()
	inv:set_size("customers_gave", 3*2)
	inv:set_size("owner_wants", 3*2)
end

local setup_use_mese_shop = function(pos, node, clicker, itemstack)
	clicker:get_inventory():set_size("customer_gives", 3*2)
	clicker:get_inventory():set_size("customer_gets", 3*2)
	mese_shop.current_shop[clicker:get_player_name()] = pos
	local meta = minetest.env:get_meta(pos)
	if clicker:get_player_name() == meta:get_string("owner") and not clicker:get_player_control().aux1 then
		minetest.show_formspec(clicker:get_player_name(),"mese_shop:mese_formspec",mese_shop.formspec.owner(pos))
	else
		minetest.show_formspec(clicker:get_player_name(),"mese_shop:meseshop_formspec",mese_shop.formspec.customer(pos))
	end
end

local inventory_move = function(pos, from_list, from_index, to_list, to_index, count, player)
	local meta = minetest.env:get_meta(pos)
	if player:get_player_name() ~= meta:get_string("owner") then return 0 end
	return count
end

local inventory_put_take = function(pos, listname, index, stack, player)
	local meta = minetest.env:get_meta(pos)
	if player:get_player_name() ~= meta:get_string("owner") then return 0 end
	return stack:get_count()
end

local dig_rules = function(pos, player)
	local inv = minetest.env:get_meta(pos):get_inventory()
	return inv:is_empty("customers_gave") and inv:is_empty("owner_wants")
end

minetest.register_node("mese_shop:mese_shop_off", {
	description = "Mese Shop",
	paramtype2 = "facedir",
	tiles = {"meseshop_top.png",
	                "meseshop_top.png",
			"meseshop_side.png",
			"meseshop_side.png",
			"meseshop_side.png",
			"meseshop_front.png"},
	inventory_image = "meseshop_front.png",
	groups = {choppy=2,oddly_breakable_by_hand=2},
	sounds = default.node_sound_wood_defaults(),
	mesecons = {receptor = {
		state = mesecon.state.off,
		rules = mesecon.rules.alldirs
	}},
	after_place_node = init_meseshop,
	on_rightclick = setup_use_meseshop,
	allow_metadata_inventory_move = inventory_move,
	allow_metadata_inventory_put = inventory_put_take,
	allow_metadata_inventory_take = inventory_put_take,
	can_dig = dig_rules
})

minetest.register_node("mese_shop:mese_shop_on", {
	description = "Mesecon Shop",
	paramtype2 = "facedir",
	tiles = {"meseshop_top.png",
	                "meseshop_top.png",
			"meseshop_side.png",
			"meseshop_side.png",
			"meseshop_side.png",
			"meseshop_front_on.png"},
	groups = {choppy=2,oddly_breakable_by_hand=2,not_in_creative_inventory=1},
	drop = 'mese_shop:mese_shop_off',
	light_source = default.LIGHT_MAX-7,
	sunlight_propagates = true,
	sounds = default.node_sound_wood_defaults(),
	mesecons = {receptor = {
		state = mesecon.state.on,
		rules = mesecon.rules.alldirs
	}},
	after_place_node = init_mese_shop,
	on_rightclick = setup_use_mese_shop,
	allow_metadata_inventory_move = inventory_move,
	allow_metadata_inventory_put = inventory_put_take,
	allow_metadata_inventory_take = inventory_put_take,
	can_dig = dig_rules
})

mesecon.mese_shop_turnon = function (pos)
	local node = minetest.get_node(pos)
	local duration = minetest.env:get_meta(pos):get_float("duration")
	minetest.swap_node(pos, {name = "mese_shop:mese_shop_on", param2=node.param2})
	mesecon.receptor_on(pos, mesecon.rules.alldirs)
	minetest.sound_play("mesecons_button_push", {pos=pos})
	minetest.after(duration, mesecon.mese_shop_turnoff, pos)
end

mesecon.mese_shop_turnoff = function (pos)
	local node = minetest.get_node(pos)
	if node.name=="mese_shop:mese_shop_on" then --has not been dug
		minetest.swap_node(pos, {name = "mese_shop:mese_shop_off", param2=node.param2})
		minetest.sound_play("mesecons_button_pop", {pos=pos})
		mesecon.receptor_off(pos, mesecon.rules.alldirs)
	end
end


minetest.register_on_player_receive_fields(function(sender, formname, fields)
	if formname == "mese_shop:mese_shop_formspec" then
		local name = sender:get_player_name()
		local pos = mese_shop.current_shop[name]
		local meta = minetest.env:get_meta(pos)
		if fields.exit ~= nil and fields.exit ~= "" then
			meta:set_string("description",fields.description)
			meta:set_float("duration",fields.duration)
		end
		if fields.activate ~= nil and fields.activate ~= "" then
			if meta:get_string("owner") == name then
				meta:set_string("description",fields.description)
				meta:set_float("duration",fields.duration)
				mesecon.mese_shop_turnon(pos)
			else
				local minv = meta:get_inventory()
				local pinv = sender:get_inventory()
				local invlist_tostring = function(invlist)
					local out = {}
					for i, item in pairs(invlist) do
						out[i] = item:to_string()
					end
					return out
				end
				local wants = minv:get_list("owner_wants")
				if wants == nil then return end -- do not crash the server
				-- Check if we can activate
				local can_activate = true
				for i, item in pairs(wants) do
					if not pinv:contains_item("customer_gives",item) then
						can_activate = false
					end
				end
				if can_activate then
					for i, item in pairs(wants) do
						pinv:remove_item("customer_gives",item)
						minv:add_item("customers_gave",item)
					end
					mesecon.mese_shop_turnon(pos)
					minetest.chat_send_player(name,"Activated!")
				else
					minetest.chat_send_player(name,"Activation can not be done, check if you put all items!")
				end
			end
		end
	end
end)

minetest.register_craft({
	output = 'mese_shop:mese_shop_off',
	recipe = {
		{'group:mesecon_conductor_craftable'},
		{'currency:shop'}
	}
})
