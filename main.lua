local Arktwend = {}

Arktwend.STARTING_CELL = "Melee, Monastery"
Arktwend.STARTING_LOCATION = {
    -3112.08,
    2722.36,
    742.98
}
Arktwend.CHARGEN_STATUE = "20361-0"
--Arktwend.CHARGEN_RING = "20360-0"
Arktwend.CHARGEN_RING = "ringdeskaisers"
Arktwend.DEATH_TIME = 30
Arktwend.CHURCH_CELL = "Melee, Monastery Church"
Arktwend.FURSEAL_CELL = "Melee, Fur Seal Tavern"
Arktwend.RING_SLOT = 12


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

function Arktwend.OnPlayerCellChange(eventStatus, pid, prev, curr)
    --fix players getting spawned into the ceiling
    if prev == Arktwend.CHURCH_CELL and curr == Arktwend.FURSEAL_CELL then
        tes3mp.SetPos(pid,
            6.08,
            -138.45,
            -63
        )
        tes3mp.SetRot(pid, 0, 0)
        tes3mp.SendPos(pid)
    end
end


function Arktwend.sendObjectState(pid, cellDescription, uniqueIndex, state)
    local splitIndex = uniqueIndex:split("-")

    tes3mp.SetObjectRefNum(splitIndex[1])
    tes3mp.SetObjectMpNum(splitIndex[2])
    tes3mp.SetObjectState(state)

    tes3mp.AddObject()
    tes3mp.SendObjectState(true, false)
end

function Arktwend.addKaisersRing(pid)
    tes3mp.ClearInventoryChanges(pid)
    tes3mp.SetInventoryChangesAction(pid, enumerations.inventory.ADD)
    tes3mp.AddItemChange(pid, Arktwend.CHARGEN_RING, 1, -1, -1, "")
    tes3mp.SendInventoryChanges(pid)
end

function Arktwend.equipKaisersRing(pid)
    tes3mp.EquipItem(
        pid,
        Arktwend.RING_SLOT,
        Arktwend.CHARGEN_RING,
        1,
        -1,
        -1
    )
    tes3mp.SendEquipment(pid)
end

function Arktwend.OnObjectActivate(eventStatus, pid, cellDescription, objects, players)
    for _, object in pairs(objects) do
        if object.uniqueIndex == Arktwend.CHARGEN_STATUE then
            local inventory = Players[pid].data.inventory

            if not inventoryHelper.containsItem(inventory, Arktwend.CHARGEN_RING, -1, -1, "") then
                inventoryHelper.addItem(inventory, Arktwend.CHARGEN_RING, 1, -1, -1, "")
                Arktwend.addKaisersRing(pid)
                tes3mp.MessageBox(pid, -1, "Put the ring on your finger.")
            else
                tes3mp.MessageBox(pid, -1, "You already have the ring.")
            end

            return customEventHooks.makeEventStatus(false, false)
        end
    end
end

function Arktwend.OnPlayerInventory(eventStatus, pid)
    local action = tes3mp.GetInventoryChangesAction(pid)
    local itemChangesCount = tes3mp.GetInventoryChangesSize(pid)

    if action == enumerations.inventory.REMOVE then
        for index = 0, itemChangesCount - 1 do
            local itemRefId = tes3mp.GetInventoryItemRefId(pid, index)

            if itemRefId == Arktwend.CHARGEN_RING then
                Arktwend.equipKaisersRing(pid)
                return customEventHooks.makeEventStatus(false, false)
            end
        end
    end
end

function Arktwend.OnObjectPlace(eventStatus, pid, cellDescription, objects)
    for _, object in pairs(objects) do
        if object.refId == Arktwend.CHARGEN_RING then
            return customEventHooks.makeEventStatus(false, false)
        end
    end
end

function Arktwend.OnContainer(eventStatus, pid, cellDescription, containers)
    tes3mp.ReadReceivedObjectList()
    tes3mp.CopyReceivedObjectListToStore()

    local packetOrigin = tes3mp.GetObjectListOrigin()
    local action = tes3mp.GetObjectListAction()

    if action == enumerations.container.ADD then
        for containerIndex = 0, tes3mp.GetObjectListSize() - 1 do
            local uniqueIndex = tes3mp.GetObjectRefNum(containerIndex) .. "-" .. tes3mp.GetObjectMpNum(containerIndex)

            for itemIndex = 0, tes3mp.GetContainerChangesSize(containerIndex) - 1 do
                local itemRefId = tes3mp.GetContainerItemRefId(containerIndex, itemIndex)

                if itemRefId == Arktwend.CHARGEN_RING then
                    LoadedCells[cellDescription]:LoadContainers(
                        pid,
                        LoadedCells[cellDescription].data.objectData,
                        {uniqueIndex}
                    )
                    return customEventHooks.makeEventStatus(false, false)
                end
            end
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
    return customEventHooks.makeEventStatus(false, nil)
end

customEventHooks.registerHandler("OnPlayerEndCharGen", Arktwend.OnPlayerEndCharGen)
customEventHooks.registerHandler("OnServerPostInit", Arktwend.OnServerPostInit)
customEventHooks.registerHandler("OnPlayerCellChange", Arktwend.OnPlayerCellChange)

customEventHooks.registerValidator("OnObjectActivate", Arktwend.OnObjectActivate)
customEventHooks.registerValidator("OnPlayerInventory", Arktwend.OnPlayerInventory)
customEventHooks.registerValidator("OnObjectPlace", Arktwend.OnObjectPlace)
customEventHooks.registerValidator("OnContainer", Arktwend.OnContainer)
customEventHooks.registerValidator("OnPlayerDeath", Arktwend.OnPlayerDeath)

return Arktwend