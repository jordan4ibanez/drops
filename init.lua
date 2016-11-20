--figure out a way to set .collect on item entities for falling and attached nodes

--This is worked to only work in survival mode
minetest.register_globalstep(function(dtime)
	--basic settings
	local age                   = 1 --how old an item has to be before collecting
	local radius_magnet         = 2.5 --radius of item magnet
	local radius_collect        = 0.2 --radius of collection
	local player_collect_height = 1.5 --added to their pos y value
	local collection_safety     = false --do this to prevent items from flying away on laggy servers
	local collect_by_default    = true --make item entities automatically collect in the item entity code  
													--versus setting it in the item drop code, setting true might interfere with
													--mods that use item entities (like pipeworks)
													
	local random_item_velocity  = true --this sets random item velocity if velocity is 0
	for _,player in ipairs(minetest.get_connected_players()) do
		if player:get_hp() > 0 then
			local pos = player:getpos()
			local inv = player:get_inventory()
			
			--collection
			
			for _,object in ipairs(minetest.env:get_objects_inside_radius({x=pos.x,y=pos.y + player_collect_height,z=pos.z}, radius_collect)) do
				if not object:is_player() and object:get_luaentity() and object:get_luaentity().name == "__builtin:item" then
					if object:get_luaentity().age > age then
						if inv and inv:room_for_item("main", ItemStack(object:get_luaentity().itemstring)) then
							
							if object:get_luaentity().itemstring ~= "" then
								inv:add_item("main", ItemStack(object:get_luaentity().itemstring))
								minetest.sound_play("item_drop_pickup", {
									pos = pos,
									max_hear_distance = 100,
									gain = 10.0,
								})
								object:get_luaentity().itemstring = ""
								object:remove()
							end
							
							
						end
					end
				end
			end
			
			
			--magnet
			for _,object in ipairs(minetest.env:get_objects_inside_radius({x=pos.x,y=pos.y + player_collect_height,z=pos.z}, radius_magnet)) do
				if not object:is_player() and object:get_luaentity() and object:get_luaentity().name == "__builtin:item" then
					if object:get_luaentity().age > age then
						if inv and inv:room_for_item("main", ItemStack(object:get_luaentity().itemstring)) then
										
							--modified simplemobs api
							
							local pos1 = pos
							--pos1.y = pos1.y+player_collect_height
							local pos2 = object:getpos()
							local vec = {x=pos1.x-pos2.x, y=(pos1.y+player_collect_height)-pos2.y, z=pos1.z-pos2.z}
							--vec.x = vec.x
							--vec.y = vec.y
							--vec.z = vec.z
							
							vec.x = pos2.x + (vec.x/3)
							vec.y = pos2.y + (vec.y/3)
							vec.z = pos2.z + (vec.z/3)
							object:moveto(vec)
							
							
							
							object:get_luaentity().physical_state = false
							object:get_luaentity().object:set_properties({
								physical = false
							})
							
							--fix eternally falling items
							--[[
							minetest.after(0, function(object)
								if object:get_luaentity() then
									object:setacceleration({x=0, y=-10, z=0})
									object:get_luaentity().physical_state = true
								end
								--object:get_luaentity():set_properties({physical = true})
							end, object)
							]]--
						end
					end
				end
			end
		end
	end
end)

if minetest.setting_getbool("creative_mode") == false then
	function minetest.handle_node_drops(pos, drops, digger)
		local inv
		if minetest.setting_getbool("creative_mode") and digger and digger:is_player() then
			inv = digger:get_inventory()
		end
		for _,item in ipairs(drops) do
			local count, name
			if type(item) == "string" then
				count = 1
				name = item
			else
				count = item:get_count()
				name = item:get_name()
			end
			if not inv or not inv:contains_item("main", ItemStack(name)) then
				for i=1,count do
					local obj = minetest.env:add_item(pos, name)
					if obj ~= nil then
						--obj:get_luaentity().timer = 
						obj:get_luaentity().collect = true
						local x = math.random(1, 5)
						if math.random(1,2) == 1 then
							x = -x
						end
						local z = math.random(1, 5)
						if math.random(1,2) == 1 then
							z = -z
						end
						obj:setvelocity({x=1/x, y=obj:getvelocity().y, z=1/z})
						obj:get_luaentity().age = 0.6
						-- FIXME this doesnt work for deactiveted objects
						if minetest.setting_get("remove_items") and tonumber(minetest.setting_get("remove_items")) then
							minetest.after(tonumber(minetest.setting_get("remove_items")), function(obj)
								obj:remove()
							end, obj)
						end
					end
				end
			end
		end
	end
end
--throw items using player's velocity
function minetest.item_drop(itemstack, dropper, pos)
	if dropper and dropper:is_player() then
		local v = dropper:get_look_dir()
		local p = {x=pos.x, y=pos.y+1.2, z=pos.z}

		local item = itemstack:to_string()
		local obj = core.add_item(p, item)
		if obj then
			v.x = v.x*4
			v.y = v.y*4 + 2
			v.z = v.z*4
			obj:setvelocity(v)
			--obj:get_luaentity().collect = true
			itemstack:clear()
			return itemstack
		end
	end
end

if minetest.setting_get("log_mods") then
	minetest.log("action", "item drop loaded")
end
