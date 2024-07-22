---@type Plugin
local plugin = ...
plugin.name = "37 Grab"
plugin.author = "KevysNotHeavy"
plugin.description = "Remakes grabbing based off of 37"

--PLEASE CALL hook.run("ReleaseGrab",human) WHEN TELPORTING PLAYERS!!!

----||SETTINGS||----

grabWorld = false --Can the player grab the level?
canClimb = false --Can the player use climbing?

dt = 1/62.5

----||HUMAN DATA||----
-- human.data.canGrab = true
-- human.data.canClimb = true
-- human.data.canGrabWorld = true

----||Hooks||----
-- hook.run("ReleaseGrab",human) - Makes the player let go every tick it is run (Reccomended to run in Physics Hook)
-- DO THIS WHEN TPING PLAYERS!!!!

----||CODE||----

---@param hum Human
---@param key number
function KeyPressed(hum,key)
    if bit32.band(hum.inputFlags,key) == key and bit32.band(hum.lastInputFlags,key) == key then
        return true
    else
        return false
    end
end

plugin:addHook("HumanDelete",function (human)
    ReleaseRight(human)
    ReleaseRight(human)
end)

plugin:addHook("ReleaseGrab",function (human)
    ReleaseLeft(human)
    ReleaseRight(human)
end)

plugin:addHook("HumanLimbInverseKinematics",function (human,A,B,pos,a,b,c,d,strength)
    local str = 1
    if human.data.grabbingLeft or human.data.grabbingRight then

        if A == enum.body.pelvis and B == enum.body.foot_left or B == enum.body.foot_right then
            strength.value = 2
        end

        --Standard Grabbing--
        local zOffset = math.clamp(math.abs(human.viewPitch/10),-.1,.1)

        if not human.data.climbing then
            local x,y,z = .1,.05-zOffset*1.1,-.55-zOffset
            if human.data.grabbingLeft then
                if A == enum.body.torso and B == enum.body.shoulder_left then
                    strength.value = str
                    pos:set(Vector(x,y,z))
                end
            end

            if human.data.grabbingRight then
                if A == enum.body.torso and B == enum.body.shoulder_right then
                    strength.value = str
                    pos:set(Vector(-x,y,z))
                end
            end

            human.data.leftHandOffset = 0
            human.data.rightHandOffset = .5
        else
            if human:getRigidBody(enum.body.hand_left).data.bound and human:getRigidBody(enum.body.hand_left).data.grabbingWorld or human:getRigidBody(enum.body.hand_right).data.bound and human:getRigidBody(enum.body.hand_right).data.grabbingWorld then
                human:getRigidBody(enum.body.head).vel = Vector(0,.05,0)

                if KeyPressed(human,enum.input.space) then
                    human:getRigidBody(enum.body.head).vel = human:getRigidBody(enum.body.head).rot:forwardUnit()/10+Vector(0,.09,0)
                end
            else
                human.data.leftHandOffset = 0
                human.data.rightHandOffset = .5
            end

            local vec = Vector(.1,human.data.leftHandOffset,-.5)
            if KeyPressed(human,enum.input.ctrl) then
                vec.z = -.6
            end
            if human.data.grabbingLeft then
                if A == enum.body.torso and B == enum.body.shoulder_left then
                    strength.value = str
                    pos:set(vec)
                end
            end

            local vec = Vector(-.1,human.data.rightHandOffset,-.5)
            if KeyPressed(human,enum.input.ctrl) then
                vec.z = -.6
            end
            if human.data.grabbingRight then
                if A == enum.body.torso and B == enum.body.shoulder_right then
                    strength.value = str
                    pos:set(vec)
                end
            end

            if human.data.rightHandOffset >= .5 then
                if not human:getRigidBody(enum.body.hand_right).data.bound then
                    GrabWorld(human:getRigidBody(enum.body.hand_right))
                end
            end

            if human.data.leftHandOffset >= .5 then
                if not human:getRigidBody(enum.body.hand_left).data.bound then
                    GrabWorld(human:getRigidBody(enum.body.hand_left))
                end
            end

            if KeyPressed(human,enum.input.shift) then
                if human:getRigidBody(enum.body.hand_right).data.bound then
                    if human.data.rightHandOffset > .2 then
                        human.data.rightHandOffset = human.data.rightHandOffset - dt/3.5
                    end

                    if human.data.rightHandOffset <= .2 then
                        if human:getRigidBody(enum.body.hand_left).data.bound then
                            ReleaseRight(human)
                        end
                    end
                else
                    if human.data.rightHandOffset < .5 then
                        human.data.rightHandOffset = human.data.rightHandOffset + dt/3.5
                    end
                end

                if human:getRigidBody(enum.body.hand_left).data.bound then
                    if human.data.leftHandOffset > .2 then
                        human.data.leftHandOffset = human.data.leftHandOffset - dt/3.5
                    end

                    if human.data.leftHandOffset <= .2 then
                        if human:getRigidBody(enum.body.hand_right).data.bound then
                            ReleaseLeft(human)
                        end
                    end
                else
                    if human.data.leftHandOffset < .5 then
                        human.data.leftHandOffset = human.data.leftHandOffset + dt/3.5
                    end
                end
            end
        end
    end
end)

function ClimbUp(hand,otherHand,offset,human,left)
    if hand.data.bound then
        if offset > .2 then
            offset = offset - dt/3
        end
        
        if offset <= .2 then
            if otherHand.data.bound then
                if not left then
                    ReleaseRight(human)
                else
                    ReleaseLeft(human)
                end
            end
        end
    else
        if offset < .5 then
            offset = offset + dt/3
        end
    end
end

function GrabLeft(human)
    human.data.grabbingLeft = true
    human:getRigidBody(enum.body.hand_left).data.grabbing = true
end


function GrabRight(human)
    human.data.grabbingRight = true
    human:getRigidBody(enum.body.hand_right).data.grabbing = true
end

function ReleaseLeft(human)
    human.data.grabbingLeft = false
    human:getRigidBody(enum.body.hand_left).data.grabbing = false
    if human:getRigidBody(enum.body.hand_left).data.bound then
        human:getRigidBody(enum.body.hand_left).data.grabbingWorld = false
        human:getRigidBody(enum.body.hand_left).data.bound:remove()
        human:getRigidBody(enum.body.hand_left).data.bound = nil
    end
end

function ReleaseRight(human)
    human.data.grabbingRight = false
    human:getRigidBody(enum.body.hand_right).data.grabbing = false
    if human:getRigidBody(enum.body.hand_right).data.bound then
        human:getRigidBody(enum.body.hand_right).data.grabbingWorld = false
        human:getRigidBody(enum.body.hand_right).data.bound:remove()
        human:getRigidBody(enum.body.hand_right).data.bound = nil
    end
end

plugin:addHook("Logic",function ()
    for _,human in ipairs(humans.getAll()) do
        if not human.data.grabInit then
            human:getRigidBody(enum.body.hand_left).data.hand = true
            human:getRigidBody(enum.body.hand_right).data.hand = true
            human.data.grabbingLeft = false
            human.data.grabbingRight = false
            human.data.grabInit = true

            human.data.canGrab = true
            human.data.canClimb = true
            human.data.canGrabWorld = true

            human.data.climbing = false

            human.data.leftHandOffset = 0
            human.data.rightHandOffset = 0
        end

        if KeyPressed(human,enum.input.ctrl) and KeyPressed(human,enum.input.shift) and KeyPressed(human,enum.input.e) then
            if not human.data.togglingClimb and human.data.canClimb and canClimb then
                human.data.togglingClimb = true
                human.data.climbing = not human.data.climbing

                if human.data.climbing then
                    messagePlayerWrap(human.player,"Climbing Enabled")
                    messagePlayerWrap(human.player,"-            [E] Grab Wall                -")
                    messagePlayerWrap(human.player,"-            [Shift] Climb                  -")
                    messagePlayerWrap(human.player,"-  [Look+Space] Mantle Edge  -")
                else
                    messagePlayerWrap(human.player,"Climbing Disabled")
                end
            end
        else
            human.data.togglingClimb = false
        end

        if not human.data.canClimb and not canClimb then
            human.data.climbing = false
        end

        if KeyPressed(human,enum.input.e) and human.isAlive then
            local grabLeft = true
            local grabRight = true

            local slot0 = human:getInventorySlot(0).primaryItem
            if slot0 then
                grabRight = false
                if slot0.type.numHands == 2 then
                    grabLeft = false
                end
            end

            local slot1 = human:getInventorySlot(1).primaryItem
            if slot1 then
                grabLeft = false
            end

            if grabLeft then
                if human.data.climbing or human.data.canGrab then
                    GrabLeft(human)
                end
            else
                ReleaseLeft(human)
            end
                
            if grabRight then
                if human.data.climbing or human.data.canGrab then
                    GrabRight(human)
                end
            else
                ReleaseRight(human)
            end
        else
            ReleaseLeft(human)
            ReleaseRight(human)
        end

        if grabWorld and human.data.canGrabWorld then
            GrabWorld(human:getRigidBody(enum.body.hand_left))
            GrabWorld(human:getRigidBody(enum.body.hand_right))
        end
    end
end)

---@param hand RigidBody
function GrabWorld(hand)
    local grace = .1

    if hand.data.grabbing then
        local upOffset = hand.rot:upUnit()*grace
        local leftRightOffset = hand.rot:rightUnit()*grace
        local fwdBackOffset = hand.rot:forwardUnit()*grace
        

        local castUpDown = physics.lineIntersectLevel(hand.pos+upOffset,hand.pos-upOffset,false).hit
        local castLeftRight = physics.lineIntersectLevel(hand.pos+leftRightOffset,hand.pos-leftRightOffset,false).hit
        local castFwdBack = physics.lineIntersectLevel(hand.pos+fwdBackOffset,hand.pos-fwdBackOffset,false).hit
        if not hand.data.bound and (castUpDown or castLeftRight or castFwdBack) then
            hand.data.bound = hand:bondToLevel(Vector(),hand.pos)
            hand.data.grabbingWorld = true
        end
    end
end

plugin:addHook("CollideBodies",function (A,B)
    local hand
    local body

    if A.data.hand then
        hand = A
        if not B.data.hand then
            body = B
        end
    elseif B.data.hand then
        hand = B
        if not A.data.hand then
            body = A
        end
    end

    if body and hand then
        if not hand.data.bound and hand.data.grabbing then
            local offset = (hand.pos - body.pos) * body.rot
            hand.data.bound = hand:bondTo(body,Vector(),offset)
        end
    end
end)