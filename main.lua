local Arktwend = {}

Arktwend.STARTING_CELL = "Melee, Monastery"
Arktwend.STARTING_LOCATION = {
    -3112.08,
    2722.36,
    742.98
}
Arktwend.CHARGEN_STATUE = "20361-0"
Arktwend.CHARGEN_RING = "20360-0"
Arktwend.DEATH_TIME = 30


function Arktwend.OnPlayerEndCharGen(eventStatus, pid)
    --put the player in the right cell
    tes3mp.SetCell(pid, Arktwend.STARTING_CELL)
    tes3mp.SendCell(pid)

    tes3mp.SetPos(pid,
        Arktwend.STARTING_LOCATION[1],
        Arktwend.STARTING_LOCATION[2],
        Arktwend.STARTING_LOCATION[3]
    )
    tes3mp.SetRot(pid, 0, 0)
    tes3mp.SendPos(pid)
end

function Arktwend.OnServerPostInit(eventStatus)
    --remove the pesky message about game start being broken
    WorldInstance.data.customVariables.deliveredCaiusPackage = true

    --disabling default respawn
    --config.playersRespawn = false
end


function Arktwend.sendObjectState(pid, cellDescription, uniqueIndex, state)
    local splitIndex = uniqueIndex:split("-")

    tes3mp.SetObjectRefNum(splitIndex[1])
    tes3mp.SetObjectMpNum(splitIndex[2])
    tes3mp.SetObjectState(state)

    tes3mp.AddObject()
    tes3mp.SendObjectState(true, false)
end

function Arktwend.OnObjectActivate(eventStatus, pid, cellDescription, objects, players)
    for _, object in pairs(objects) do
        if object.uniqueIndex == Arktwend.CHARGEN_STATUE then
            local ring = LoadedCells[cellDescription].data.objectData[Arktwend.CHARGEN_RING]
            if ring ~= nil then
                if ring.state == false then
                    ring.state = true
                    Arktwend.sendObjectState(pid, cellDescription, Arktwend.CHARGEN_RING, true)
                    tes3mp.MessageBox(pid, -1, "Take the ring and put it on your finger.")
                end
            end
            return customEventHooks.makeEventStatus(false, false)
        end
    end
end

ArktwendResurrect = function(pid)
    --respawn the player in the same cell as they died
    tes3mp.Resurrect(pid, 5)
end

function Arktwend.OnPlayerDeath(eventStatus, pid)
    tes3mp.MessageBox(pid, -1, "You fall unconcious, but alive. You will wake up soon.")
    tes3mp.StartTimer(
        tes3mp.CreateTimerEx(
            "ArktwendResurrect",
            time.seconds(Arktwend.DEATH_TIME),
            "i",
            pid
        )
    )
    return customEventHooks.makeEventStatus(false, true)
end

customEventHooks.registerHandler("OnPlayerEndCharGen", Arktwend.OnPlayerEndCharGen)
customEventHooks.registerHandler("OnServerPostInit", Arktwend.OnServerPostInit)

customEventHooks.registerValidator("OnObjectActivate", Arktwend.OnObjectActivate)
customEventHooks.registerValidator("OnPlayerDeath", Arktwend.OnPlayerDeath)

return Arktwend