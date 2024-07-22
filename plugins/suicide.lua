---@type Plugin
local plugin = ...
plugin.name = "Suicide"
plugin.author = "KevysNotHeavy"
plugin.description = "KYS"

plugin.commands["/suicide"] = {

    info = "Kills the player using the command.",
  
    call = function(ply)
        if ply.data.suicideCooldown <= 0 then
          ply.human.bloodLevel = 0
          ply.data.suicideCooldown = 10
        else
            messagePlayerWrap(ply,"Cooldown ("..math.floor(ply.data.suicideCooldown).."s) left...")
        end
    end,
  }

plugin:addHook("Logic",function ()
      for _,ply in ipairs(players.getAll()) do
            if not ply.data.suicideInit then
                  ply.data.suicideCooldown = 0
                  ply.data.suicideInit = true
            end
            
            if ply.human then
                  if bit32.band(ply.human.inputFlags,enum.input.del) == enum.input.del then
                        if not ply.data.suicideKilled then
                              if ply.data.suicideCooldown <= 0 then
                                    ply.human.bloodLevel = 0
                                    ply.data.suicideCooldown = 10
                              else
                                    messagePlayerWrap(ply,"Cooldown ("..math.floor(ply.data.suicideCooldown).."s) left...")
                              end
                              ply.data.suicideKilled = true
                        end
                  else
                        ply.data.suicideKilled = false
                  end
            end

            if ply.data.suicideCooldown > 0 then
                  ply.data.suicideCooldown = ply.data.suicideCooldown - 1/62
            end
      end
end)