---@type Plugin
local plugin = ...

plugin:addHook("Logic",function ()
    for _,hum in ipairs(humans.getAll()) do
        hum.stamina = 123
    end
end)