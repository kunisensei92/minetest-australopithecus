--[[
Copyright (c) 2015, Robert 'Bobby' Zenz
All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

* Redistributions of source code must retain the above copyright notice, this
  list of conditions and the following disclaimer.

* Redistributions in binary form must reproduce the above copyright notice,
  this list of conditions and the following disclaimer in the documentation
  and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--]]


local nodebox_cache = nil

local function init_nodebox_cache()
	if nodebox_cache == nil then
		nodebox_cache = {}
		
		nodebox_cache.corners = {}
		nodebox_cache.corners.stepped = {}
		
		nodebox_cache.corners.corner = {
			type = "fixed",
			fixed = cornerutil.create_corner_nodebox(9)
		}
		
		for counter = 2, 9, 1 do
			nodebox_cache.corners.stepped[counter] = {
				type = "fixed",
				fixed = cornerutil.create_corner_nodebox(counter)
			}
		end
		
		nodebox_cache.stairs = {}
		nodebox_cache.stairs.stepped = {}
		nodebox_cache.stairs.stepped_inner = {}
		nodebox_cache.stairs.stepped_inner_flat = {}
		nodebox_cache.stairs.stepped_outer = {}
		nodebox_cache.stairs.stepped_outer_flat = {}
		
		for counter = 2, 9, 1 do
			nodebox_cache.stairs.stepped[counter] = {
				type = "fixed",
				fixed = ramputil.create_ramp_nodebox(counter)
			}
			nodebox_cache.stairs.stepped_inner[counter] = {
				type = "fixed",
				fixed = ramputil.create_inner_corner_nodebox(counter)
			}
			nodebox_cache.stairs.stepped_inner_flat[counter] = {
				type = "fixed",
				fixed = ramputil.create_inner_corner_flat_nodebox(counter)
			}
			nodebox_cache.stairs.stepped_outer[counter] = {
				type = "fixed",
				fixed = ramputil.create_outer_corner_nodebox(counter)
			}
			nodebox_cache.stairs.stepped_outer_flat[counter] = {
				type = "fixed",
				fixed = ramputil.create_outer_corner_flat_nodebox(counter)
			}
		end
		
		nodebox_cache.ramps = {}
		nodebox_cache.ramps.smooth = nodebox_cache.stairs.stepped[9]
		nodebox_cache.ramps.smooth_inner = nodebox_cache.stairs.stepped_inner[9]
		nodebox_cache.ramps.smooth_inner_flat = nodebox_cache.stairs.stepped_inner_flat[9]
		nodebox_cache.ramps.smooth_outer = nodebox_cache.stairs.stepped_outer[9]
		nodebox_cache.ramps.smooth_outer_flat = nodebox_cache.stairs.stepped_outer_flat[9]
	end
end

local function make_description(name)
	-- First char to upper.
	name = string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
	-- All other chars to upper.
	name = string.gsub(name, "_[a-z]", string.upper)
	-- Replace underscores.
	name = string.gsub(name, "_", " ")
	
	return name
end

local function register_node(definition)
	if definition.node_box ~= nil then
		definition.collision_box = definition.node_box
		definition.selection_box = definition.node_box
	end
	if definition.max_stack == nil then
		definition.stack_max = 64
	end
	
	local name = definition.name
	
	if not stringutil.startswith(name, "core:") then
		name = "core:" .. name
	end
	
	minetest.register_node(name, tableutil.clone(definition))
end

local function postfix_name(name, postfix)
	if name ~= nil and name ~= "" then
		return name .. "_" .. postfix
	end
	
	return postfix
end

local function postfix_dropnames(drops, postfix)
	if type(drops) == "string" then
		return postfix_name(drops, postfix)
	end
	
	drops = tableutil.clone(drops)
	
	for index, item in ipairs(drops.items) do
		item.items[1] = postfix_name(item.items[1], postfix)
	end
	
	return drops
end


local function register_conversion(group, source, target)
	ap.core.artisanry:register(group, "core:" .. target, {
		{ "core:" .. source }
	})
	ap.core.artisanry:register("Blocks", "core:" .. source, {
		{ "core:" .. target }
	})
end


local function register_corners(definition)
	if nodebox_cache == nil then
		init_nodebox_cache()
	end
	
	for counter = 2, 9, 1 do
		local corner_name = definition.name .. "_corner_" .. counter
		local corner_definition = tableutil.merge(definition, {
			description = definition.description .. " (Corner with " .. counter .. " steps)",
			drawtype = "nodebox",
			drop = postfix_dropnames(definition.drop, "corner_" .. counter),
			name = corner_name,
			node_box = nodebox_cache.corners.stepped[counter],
			paramtype = "light",
			paramtype2 = "facedir"
		})
		
		register_node(corner_definition)
		register_conversion("Corners", definition.name, corner_name)
	end
	
	-- Corner
	local corner_smooth_name = definition.name .. "_corner_smooth"
	local corner_smooth_definition = tableutil.merge(definition, {
		description = definition.description .. " (Smooth Corner)",
		drawtype = "mesh",
		drop = postfix_dropnames(definition.drop, "corner_smooth"),
		mesh = "corner.obj",
		name = corner_smooth_name,
		node_box = nodebox_cache.corners.corner,
		paramtype = "light",
		paramtype2 = "facedir"
	})
	
	register_node(corner_smooth_definition)
	register_conversion("Corners", definition.name, corner_smooth_name)
end

local function register_plates(definition)
	for thickness = 1, 9, 1 do
		local plate_name = definition.name .. "_plate_" .. thickness
		local plate_definition = tableutil.merge(definition, {
			description = definition.description .. " (Plate, " .. thickness .. "/10)",
			drawtype = "nodebox",
			drop = "core:" .. plate_name,
			name = plate_name,
			node_box = {
				type = "wallmounted",
				wall_bottom = {
					-0.5, -0.5, -0.5,
					0.5, thickness * 0.1 - 0.5, 0.5
				},
				wall_side = {
					-0.5, -0.5, -0.5,
					thickness * 0.1 - 0.5, 0.5, 0.5
				},
				wall_top = {
					-0.5, 0.5 - thickness * 0.1, -0.5,
					0.5, 0.5, 0.5
				}
			},
			paramtype = "light",
			paramtype2 = "wallmounted"
		})
		
		register_node(plate_definition)
		
		register_conversion("Plates", definition.name, plate_name .. " " .. math.floor(10 / thickness))
	end
end

local function register_ramps(definition)
	if nodebox_cache == nil then
		init_nodebox_cache()
	end
	
	-- Ramp
	local ramp_name = definition.name .. "_ramp"
	local ramp_definition = tableutil.merge(definition, {
		description = definition.description .. " (Ramp)",
		drawtype = "mesh",
		drop = postfix_dropnames(definition.drop, "ramp"),
		mesh = "ramp.obj",
		name = ramp_name,
		node_box = nodebox_cache.ramps.smooth,
		paramtype = "light",
		paramtype2 = "facedir",
		after_place_node = facedirutil.create_after_node_placed_upsidedown_handler()
	})
	
	register_node(ramp_definition)
	register_conversion("Ramps", definition.name, ramp_name)
	
	-- Inner corner
	local ramp_inner_corner_name = definition.name .. "_ramp_inner_corner"
	local ramp_inner_corner_definition = tableutil.merge(ramp_definition, {
		description = definition.description .. " (Ramp inner corner)",
		drawtype = "mesh",
		drop = postfix_dropnames(definition.drop, "ramp_inner_corner"),
		mesh = "inner_corner_ramp.obj",
		name = ramp_inner_corner_name,
		node_box = nodebox_cache.ramps.smooth_inner,
		after_place_node = facedirutil.create_after_node_placed_upsidedown_handler(true)
	})
	
	register_node(ramp_inner_corner_definition)
	register_conversion("Ramps", definition.name, ramp_inner_corner_name)
	
	-- Outer corner
	local ramp_outer_corner_name = definition.name .. "_ramp_outer_corner"
	local ramp_outer_corner_definition = tableutil.merge(ramp_definition, {
		description = definition.description .. " (Ramp outer corner)",
		drawtype = "mesh",
		drop = postfix_dropnames(definition.drop, "ramp_outer_corner"),
		mesh = "outer_corner_ramp.obj",
		name = ramp_outer_corner_name,
		node_box = nodebox_cache.ramps.smooth_outer,
		after_place_node = facedirutil.create_after_node_placed_upsidedown_handler(true)
	})
	
	register_node(ramp_outer_corner_definition)
	register_conversion("Ramps", definition.name, ramp_outer_corner_name)
	
	-- Inner corner flat
	local ramp_inner_corner_flat_name = definition.name .. "_ramp_inner_corner_flat"
	local ramp_inner_corner_flat_definition = tableutil.merge(ramp_definition, {
		description = definition.description .. " (Ramp flat inner corner)",
		drawtype = "mesh",
		drop = postfix_dropnames(definition.drop, "ramp_inner_corner_flat"),
		mesh = "inner_corner_ramp_flat.obj",
		name = ramp_inner_corner_flat_name,
		node_box = nodebox_cache.ramps.smooth_inner_flat,
		after_place_node = facedirutil.create_after_node_placed_upsidedown_handler(true)
	})
	
	register_node(ramp_inner_corner_flat_definition)
	register_conversion("Ramps", definition.name, ramp_inner_corner_flat_name)
	
	-- Outer corner flat
	local ramp_outer_corner_flat_name = definition.name .. "_ramp_outer_corner_flat"
	local ramp_outer_corner_flat_definition = tableutil.merge(ramp_definition, {
		description = definition.description .. " (Ramp flat outer corner)",
		drawtype = "mesh",
		drop = postfix_dropnames(definition.drop, "ramp_outer_corner_flat"),
		mesh = "outer_corner_ramp_flat.obj",
		name = ramp_outer_corner_flat_name,
		node_box = nodebox_cache.ramps.smooth_outer_flat,
		after_place_node = facedirutil.create_after_node_placed_upsidedown_handler(true)
	})
	
	register_node(ramp_outer_corner_flat_definition)
	register_conversion("Ramps", definition.name, ramp_outer_corner_flat_name)
end

local function register_stairs(definition)
	if nodebox_cache.stairs == nil then
		init_nodebox_cache()
	end
	
	for counter = 2, 9, 1 do
		-- Stair
		local stair_name = definition.name .. "_stair_" .. counter
		local stair_definition = tableutil.merge(definition, {
			description = definition.description .. " (Stair with " .. counter .. " steps)",
			drawtype = "nodebox",
			drop = postfix_dropnames(definition.drop, "stair_" .. counter),
			name = stair_name,
			node_box = nodebox_cache.stairs.stepped[counter],
			paramtype = "light",
			paramtype2 = "facedir",
			after_place_node = facedirutil.create_after_node_placed_upsidedown_handler()
		})
		
		register_node(stair_definition)
		register_conversion("Stairs", definition.name, stair_name)
		
		-- Inner corner
		local inner_corner_name = definition.name .. "_stair_inner_corner_" .. counter
		local inner_corner_definition = tableutil.merge(stair_definition, {
			description = definition.description .. " (Stair inner corner with " .. counter .. " steps)",
			drop = postfix_dropnames(definition.drop, "stair_inner_corner_" .. counter),
			name = inner_corner_name,
			node_box = nodebox_cache.stairs.stepped_inner[counter],
			after_place_node = facedirutil.create_after_node_placed_upsidedown_handler()
		})
		
		register_node(inner_corner_definition)
		register_conversion("Stairs", definition.name, inner_corner_name)
		
		-- Inner corner flat
		local inner_corner_flat_name = definition.name .. "_stair_inner_corner_flat_" .. counter
		local inner_corner_flat_definition = tableutil.merge(stair_definition, {
			description = definition.description .. " (Stair flat inner corner with " .. counter .. " steps)",
			drop = postfix_dropnames(definition.drop, "stair_inner_corner_flat_" .. counter),
			name = inner_corner_flat_name,
			node_box = nodebox_cache.stairs.stepped_inner_flat[counter],
			after_place_node = facedirutil.create_after_node_placed_upsidedown_handler()
		})
		
		register_node(inner_corner_flat_definition)
		register_conversion("Stairs", definition.name, inner_corner_flat_name)
		
		-- Outer corner
		local outer_corner_name = definition.name .. "_stair_outer_corner_" .. counter
		local outer_corner_definition = tableutil.merge(stair_definition, {
			description = definition.description .. " (Stair outer corner with " .. counter .. " steps)",
			drop = postfix_dropnames(definition.drop, "stair_outer_corner_" .. counter),
			name = outer_corner_name,
			node_box = nodebox_cache.stairs.stepped_outer[counter],
			after_place_node = facedirutil.create_after_node_placed_upsidedown_handler()
		})
		
		register_node(outer_corner_definition)
		register_conversion("Stairs", definition.name, outer_corner_name)
		
		-- Outer corner flat
		local outer_corner_flat_name = definition.name .. "_stair_outer_corner_flat_" .. counter
		local outer_corner_flat_definition = tableutil.merge(stair_definition, {
			description = definition.description .. " (Stair flat outer corner with " .. counter .. " steps)",
			drop = postfix_dropnames(definition.drop, "stair_outer_corner_flat_" .. counter),
			name = outer_corner_flat_name,
			node_box = nodebox_cache.stairs.stepped_outer_flat[counter],
			after_place_node = facedirutil.create_after_node_placed_upsidedown_handler()
		})
		
		register_node(outer_corner_flat_definition)
		register_conversion("Stairs", definition.name, outer_corner_flat_name)
	end
end


local function register_bricks(definition)
	local name = postfix_name(definition.name, "bricks")
	
	ap.core.artisanry:register("Blocks", "core:" .. postfix_name(definition.name, "cobble"), {
		{ "core:" .. name }
	})
	
	definition = tableutil.merge(definition, {
		description = definition.description .. " Bricks",
		drop = {
			items = {
				{
					items = { "core:" .. name },
					tools = { "~hammer" }
				},
				{
					items = { "core:" .. postfix_name(definition.name, "rubble") },
					tools = { "~pickaxe" }
				}
			}
		},
		name = name,
		tiles = {
			name .. ".png"
		}
	})
	
	register_node(definition)
	
	register_corners(definition)
	register_plates(definition)
	register_ramps(definition)
	register_stairs(definition)
end

local function register_cobble(definition)
	local name = postfix_name(definition.name, "cobble")
	
	ap.core.artisanry:register("Blocks", "core:" .. postfix_name(definition.name, "rubble"), {
		{ "core:" .. name }
	})
	
	definition = tableutil.merge(definition, {
		description = definition.description .. " Cobble",
		drop = {
			items = {
				{
					items = { "core:" .. name },
					tools = { "~hammer" }
				},
				{
					items = { "core:" .. postfix_name(definition.name, "rubble") },
					tools = { "~pickaxe" }
				}
			}
		},
		name = name,
		tiles = {
			name .. ".png"
		}
	})
	
	register_node(definition)
	
	register_corners(definition)
	register_plates(definition)
	register_ramps(definition)
	register_stairs(definition)
end

local function register_rubble(definition)
	local rubble_name = postfix_name(definition.name, "rubble")
	
	definition = tableutil.merge(definition, {
		description = definition.description .. " Rubble",
		drop = "core:" .. rubble_name,
		name = rubble_name,
		tiles = {
			rubble_name .. ".png"
		}
	})
	
	register_node(definition)
	
	register_corners(definition)
	register_plates(definition)
	register_ramps(definition)
	register_stairs(definition)
end


ap.core.helpers.register_dirt = function(name, prototype)
	name = postfix_name(name, "dirt")
	
	local definition = {
		description = make_description(name),
		diggable = true,
		drop = "core:" .. name,
		groups = {
			dirt = DigSpeed.NORMAL,
			oddly_breakable_by_hand = 2
		},
		name = name,
		tiles = {
			name .. ".png"
		}
	}
	
	if prototype ~= nil then
		definition = tableutil.merge(definition, prototype)
	end
	
	register_node(definition)
	
	register_corners(definition)
	register_plates(definition)
	register_ramps(definition)
	register_stairs(definition)
end

ap.core.helpers.register_fluid = function(name, alpha, viscosity, type)
	if type == nil then
		ap.core.helpers.register_fluid(name, alpha, viscosity, "source")
		ap.core.helpers.register_fluid(name, alpha, viscosity, "flowing")
		return
	end
	
	local typed_name = name .. "_" .. type
	local texture = typed_name ..".png"
	local texture_animated = typed_name .. "_animated.png"
	
	local liquid_type = "liquid"
	if type == "flowing" then
		liquid_type = "flowingliquid"
	end
	
	local definition = {
		alpha = alpha,
		buildable_to = true,
		description = name .. " (" .. type .. ")",
		diggable = false,
		drawtype = liquid_type,
		drowning = 1,
		groups = {
			water = 3,
			liquid = 3
		},
		inventory_image = minetest.inventorycube(texture),
		liquidtype = type,
		liquid_alternative_flowing = "core:" .. name .. "_flowing",
		liquid_alternative_source = "core:" .. name .. "_source",
		liquid_viscosity = viscosity,
		name = typed_name,
		paramtype = "light",
		pointable = false,
		post_effect_color = {
			a = 64,
			r = 100,
			g = 100,
			b = 200
		},
		special_tiles = {
			{
				name = texture_animated,
				animation = {
					aspect_h = 32,
					aspect_w = 32,
					length = 3.0,
					type = "vertical_frames"
				},
				backface_culling = false
			}
		},
		tiles = {
			{
				name = texture_animated,
				animation = {
					aspect_h = 32,
					aspect_w = 32,
					length = 3.0,
					type = "vertical_frames"
				}
			}
		},
		walkable = false
	}
	
	register_node(definition)
end

ap.core.helpers.register_grass = function(name, group_addition, definition_override)
	name = postfix_name(name, "grass")
	
	local top_side = name .. ".png"
	local side_side = textureutil.tileable("dirt.png^" .. name .. "_side_overlay.png", true, false)
	
	local definition = {
		description = make_description(name),
		diggable = true,
		drop = "core:dirt",
		groups = {
			becomes_dirt = NodeGroup.DUMMY,
			dirt = DigSpeed.NORMAL,
			oddly_breakable_by_hand = 2,
			spread_minimum_light = 9,
			spreads_on_dirt = DigSpeed.NORMAL
		},
		name = name,
		tiles = {
			top_side, "dirt.png",
			side_side, side_side,
			side_side, side_side
		}
	}
	
	if group_addition ~= nil then
		definition.groups = tableutil.merge(definition.groups, group_addition)
	end
	
	if definition_override ~= nil then
		definition = tableutil.merge(definition, definition_override)
	end
	
	register_node(definition)
end

ap.core.helpers.register_gravel = function(name, prototype)
	name = postfix_name(name, "gravel")
	
	local definition = {
		description = make_description(name),
		diggable = true,
		drop = "core:" .. name,
		groups = {
			gravel = DigSpeed.NORMAL,
			oddly_breakable_by_hand = 2
		},
		name = name,
		tiles = {
			name .. ".png"
		}
	}
	
	if prototype ~= nil then
		definition = tableutil.merge(definition, prototype)
	end
	
	register_node(definition)
	
	register_corners(definition)
	register_plates(definition)
	register_ramps(definition)
end

ap.core.helpers.register_ice = function(name, prototype)
	name = postfix_name(name, "ice")
	
	local definition = {
		description = make_description(name),
		diggable = true,
		drop = {
			items = {
				{
					items = { "core:" .. name .. "_bricks" },
					tools = { "~hammer" }
				},
				{
					items = { "core:" .. name .. "_rubble" },
					tools = { "~pickaxe" }
				}
			}
		},
		groups = {
			ice = DigSpeed.NORMAL,
		},
		name = name,
		tiles = {
			name .. ".png"
		}
	}
	
	if prototype ~= nil then
		definition = tableutil.merge(definition, prototype)
	end
	
	register_node(definition)
	
	register_corners(definition)
	register_plates(definition)
	register_ramps(definition)
	register_stairs(definition)
	
	register_bricks(definition)
	register_cobble(definition)
	register_rubble(definition)
end

ap.core.helpers.register_rock = function(name, prototype)
	name = postfix_name(name, "rock")
	
	local definition = {
		description = make_description(name),
		diggable = true,
		drop = {
			items = {
				{
					items = { "core:" .. name .. "_bricks" },
					tools = { "~hammer" }
				},
				{
					items = { "core:" .. name .. "_rubble" },
					tools = { "~pickaxe" }
				}
			}
		},
		groups = {
			rock = DigSpeed.NORMAL,
		},
		name = name,
		tiles = {
			name .. ".png"
		}
	}
	
	definition = tableutil.merge(definition, prototype)
	
	register_node(definition)
	
	register_plates(definition)
	register_ramps(definition)
	register_stairs(definition)
	
	register_bricks(definition)
	register_cobble(definition)
	register_rubble(definition)
end

ap.core.helpers.register_sand = function(name, prototype)
	name = postfix_name(name, "sand")
	
	local definition = {
		description = make_description(name),
		diggable = true,
		drop = "core:" .. name,
		groups = {
			sand = DigSpeed.NORMAL,
			oddly_breakable_by_hand = 2
		},
		name = name,
		tiles = {
			name .. ".png"
		}
	}
	
	register_node(definition)
	
	register_corners(definition)
	register_ramps(definition)
end

ap.core.helpers.register_snow = function(name, prototype)
	name = postfix_name(name, "snow")
	
	local definition = {
		description = make_description(name),
		diggable = true,
		drop = "core:" .. name,
		groups = {
			snow = DigSpeed.NORMAL,
			oddly_breakable_by_hand = 2
		},
		name = name,
		tiles = {
			name .. ".png"
		}
	}
	
	definition = tableutil.merge(definition, prototype)
	
	register_node(definition)
	
	register_corners(definition)
	register_plates(definition)
	register_ramps(definition)
	register_stairs(definition)
end

ap.core.helpers.register_stone = function(name, prototype)
	name = postfix_name(name, "stone")
	
	local definition = {
		description = make_description(name),
		diggable = true,
		drop = "core:" .. name,
		groups = {
			stone = DigSpeed.NORMAL
		},
		name = name,
		tiles = {
			name .. ".png"
		}
	}
	
	definition = tableutil.merge(definition, prototype)
	
	register_node(definition)
	
	register_corners(definition)
	register_plates(definition)
	register_ramps(definition)
	register_stairs(definition)
end

