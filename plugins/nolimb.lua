---@type Plugin
local plugin = ...
plugin.name = "No Limb Damage"
plugin.author = "KevysNotHeavy"
plugin.description = "Disables Damage on all humans limbs besides torso and head"

plugin:addHook("Logic",function ()
    for _,hum in ipairs(humans.getAll()) do
        hum.leftArmHP = 100
        hum.rightArmHP = 100
        hum.leftLegHP = 100
        hum.rightLegHP = 100
        hum.isBleeding = false
    end
end)

plugin:addHook("HumanLimbInverseKinematics", function(man)
	man.damage = 0
end)