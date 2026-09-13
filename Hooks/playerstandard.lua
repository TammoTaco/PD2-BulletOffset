--Hola, thanks for looking at my code! Always nice to have another Lua wizard judging my craft.
local mvec_set = mvector3.set
local mvec_set_static = mvector3.set_static
local mvec_add = mvector3.add
local mvec_sub = mvector3.subtract
local mvec_rotate_with = mvector3.rotate_with

local mrot_set_zero = mrotation.set_zero
local mrot_multiply = mrotation.multiply
local mrot_invert = mrotation.invert

local offset = Vector3()
local local_offset = Vector3()
local inv_rot = Rotation()
local result_pos = Vector3()

local akimbo_alternate = false

--Get position
local orig_get_fire_weapon_position = PlayerStandard.get_fire_weapon_position
function PlayerStandard:get_fire_weapon_position()
	local equipped_unit = self._equipped_unit

	if alive(equipped_unit) and equipped_unit:base() and equipped_unit:base().fire_object then
		local fire_obj = equipped_unit:base():fire_object()

		if alive(fire_obj) then
			local cam_pos = self._ext_camera:position()
			local cam_rot = self._ext_camera:rotation()
			local muzzle_pos = fire_obj:position()

			-- Worldspace offset (muzzle relative to the camera) 
			mvec_set(offset, muzzle_pos)
			mvec_sub(offset, cam_pos)

			-- Rotate offset into camera space, x is sideways, y is forward and z is vertical
			mrot_set_zero(inv_rot)
			mrot_multiply(inv_rot, cam_rot)
			mrot_invert(inv_rot)

			mvec_set(local_offset, offset)
			mvec_rotate_with(local_offset, inv_rot)

			local sideways = local_offset.x

			-- Akimbo stuff, alternate between mirrored offsets to emulate both guns alternating fire
			if equipped_unit:base():is_category("akimbo") then
				if equipped_unit:base():start_shooting_allowed() then --start_shooting_allowed tells you if a gun will actually fire, had to look deep for this gem
					akimbo_alternate = not akimbo_alternate
				end

				if akimbo_alternate then
					sideways = -sideways --We only have to mirror side offset
				end
			end

			-- Forward offset is bad, it can cause shots to go through objects if too close
			mvec_set_static(local_offset, sideways, 0, local_offset.z)

			-- Rotate the offset back to world space and lock it to the camera
			mvec_rotate_with(local_offset, cam_rot)

			mvec_set(result_pos, local_offset)
			mvec_add(result_pos, cam_pos)

			return result_pos
		end
	end

	return orig_get_fire_weapon_position(self)
end

--Gotta also have direction
local orig_get_fire_weapon_direction = PlayerStandard.get_fire_weapon_direction 
function PlayerStandard:get_fire_weapon_direction()
	local equipped_unit = self._equipped_unit

	if alive(equipped_unit) and equipped_unit:base() and equipped_unit:base().fire_object then
		local fire_obj = equipped_unit:base():fire_object()

		if alive(fire_obj) then
			return fire_obj:rotation():y()
		end
	end

	return orig_get_fire_weapon_direction(self)
end