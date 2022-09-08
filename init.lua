
local max_radius = 10
local explosion_strength_treshold = 0.01

spherical_harmonic_detonator = {}

local function random_rotation()
	local r1 = math.random()
	local r2 = math.random()
	local yaw = r1 * (2 * math.pi)
	local pitch = math.asin(r2 * 2 - 1)

	-- rotation matrix (taken from wikipedia, with roll=0)
	local sy = math.sin(yaw)
	local cy = math.cos(yaw)
	local sp = math.sin(pitch)
	local cp = math.cos(pitch)
	local mat11 = cp * cy
	local mat12 = -sy
	local mat13 = sp * cy
	local mat21 = cp * sy
	local mat22 = cy
	local mat23 = sp * sy
	local mat31 = -sp
	--~ local mat32 = 0
	local mat33 = cp

	return function(v)
		return vector.new(
			v.x * mat11 + v.y * mat12 + v.z * mat13,
			v.x * mat21 + v.y * mat22 + v.z * mat23,
			v.x * mat31 +               v.z * mat33
		)
	end
end

function spherical_harmonic_detonator.boom(pos, _def)
	minetest.set_node(pos, {name = "tnt:boom"})
	minetest.remove_node(pos)
	minetest.sound_play("tnt_explode", {pos = pos, gain = 2.5}, true)

	local rot = random_rotation()

	local sh_koeff_0_0 = (math.random() - 0.5) * 2 + 3
	local sh_koeff_1m1 = (math.random() - 0.5) * 8
	local sh_koeff_1_0 = (math.random() - 0.5) * 8
	local sh_koeff_1_1 = (math.random() - 0.5) * 8
	local sh_koeff_2m2 = (math.random() - 0.5) * 2
	local sh_koeff_2m1 = (math.random() - 0.5) * 2
	local sh_koeff_2_0 = (math.random() - 0.5) * 2
	local sh_koeff_2_1 = (math.random() - 0.5) * 2
	local sh_koeff_2_2 = (math.random() - 0.5) * 2

	local explosion_strength = function(p)
		--~ return math.abs(p.x) < 1 and math.abs(p.z) < 1 and 1 or 0

		local r = math.sqrt(p.x * p.x + p.y * p.y + p.z * p.z)
		local rr = 1/r
		local rr2 = rr * rr
		local x = p.x * rr
		local y = p.y * rr
		local z = p.z * rr

		-- see https://en.wikipedia.org/wiki/Table_of_spherical_harmonics#Real_spherical_harmonics
		return rr2 * ( -- also weaken squared in distance
				  sh_koeff_0_0 * 0.28209479177387814
				+ sh_koeff_1m1 * 0.4886025119029199 * y * rr
				+ sh_koeff_1_0 * 0.4886025119029199 * z * rr
				+ sh_koeff_1_1 * 0.4886025119029199 * x * rr
				+ sh_koeff_2m2 * 1.0925484305920792 * x * y * rr2
				+ sh_koeff_2m1 * 1.0925484305920792 * y * z * rr2
				+ sh_koeff_2_0 * 0.31539156525252005 * (3*z*z - r*r) * rr2
				+ sh_koeff_2_1 * 1.0925484305920792 * x * z * rr2
				+ sh_koeff_2_2 * 0.5462742152960396 * (x*x - y*y) * rr2
			)
	end

	for x = -max_radius, max_radius do
	for z = -max_radius, max_radius do
	for y = -max_radius, max_radius do
		local relpos = vector.new(x, y, z)
		if explosion_strength(rot(relpos)) >= explosion_strength_treshold then
			minetest.remove_node(pos + relpos)
		end
	end
	end
	end
end

minetest.register_node("spherical_harmonic_detonator:detonator", {
	description = "Spherical Harmonic Detonator\nPunch with torch to ignite.",
	short_description = "Spherical Harmonic Detonator",
	groups = {dig_immediate = 2},
	drawtype = "normal",
	tiles = {"tnt_top.png", "tnt_bottom.png", "spherical_harmonic_detonator_side.png"},
	paramtype = "none",
	paramtype2 = "none",
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),

	on_punch = function(pos, _node, puncher, _pointed_thing)
		if not minetest.is_player(puncher)
				or puncher:get_wielded_item():get_name() ~= "default:torch" then
			return
		end
		minetest.swap_node(pos, {name = "spherical_harmonic_detonator:detonator_burning"})
		minetest.sound_play("tnt_ignite", {pos = pos}, true)
		minetest.get_node_timer(pos):start(2)
	end,

	on_blast = function(pos, _intensity)
		spherical_harmonic_detonator.boom(pos, {})
	end,
})

minetest.register_node("spherical_harmonic_detonator:detonator_burning", {
	description = "You hacker you!",
	groups = {not_in_creative_inventory = 1},
	light_source = 5,
	drawtype = "normal",
	tiles = {{name = "tnt_top_burning_animated.png", animation = {
			type = "vertical_frames", aspect_w = 16, aspect_h = 16, length = 1
		}}, "tnt_bottom.png", "spherical_harmonic_detonator_side.png"},
	paramtype = "light",
	paramtype2 = "none",
	is_ground_content = false,
	sounds = default.node_sound_wood_defaults(),
	drop = "",

	on_timer = function(pos, _elapsed)
		spherical_harmonic_detonator.boom(pos, {})
	end,

	on_blast = function(_pos, _intensity)
		-- stay
	end,
})
