-- ===================================================
-- Peek on Hover v0.0.5
-- TODO: Prints container contents to console when hovering
-- ===================================================



local GLOBAL = GLOBAL
local TheInput = GLOBAL.TheInput

-- Debug logger
local function Log(msg)
    print("[PEEK ON HOVER] " .. tostring(msg))
end

Log("Peek on Hover mod loaded...")


-- States
local last_mouse_x, last_mouse_y = nil, nil
local last_hovered = nil

-- Speak out hovered entity prefab name
local function SpeakHovered(player, entity)

    if entity and entity.prefab then

        -- player speak out entity prefab name
        if player and player.components and player.components.talker then
            player.components.talker:Say("[SpeakHovered]: " .. entity.prefab)
        end
    end

end

-- check if the hovered entity is a container
local function IsContainer(entity)
    return entity and entity.components and entity.components.container ~= nil
end


-- showing the covered container contents
-- to be called only of the hovered entity is a container.
local function ShowContainerContents(container)
    if not container or not container.components or not container.components.container then
        return
    end

    local contents = container.components.container.slots or {}
    Log("contents table id:" .. tostring(contents) .. " contains: " .. #contents .. " filled slots.")

    for slot, item in pairs(contents) do
            Log("Slot " .. slot .. ": " .. (item.prefab or "unknown prefab") .. " x" .. (item.components.stackable and item.components.stackable:StackSize() or 1))
    end
end

-- light weight version of update check
local function OnUpdate(inst)

    -- If alt key is not held down, and last hovered entity is set, reset and do nothing.
    if not TheInput:IsKeyDown(GLOBAL.KEY_ALT) then
        if last_hovered then
            last_hovered = nil
            last_mouse_x, last_mouse_y = nil, nil
        end
        return
    end

    
    local x, y = TheInput:GetScreenPosition()

    -- return if mouse did not move
    if x == last_mouse_x and y == last_mouse_y then
        return
    end

    last_mouse_x, last_mouse_y = x, y

    local hovered = TheInput:GetWorldEntityUnderMouse()

    -- return if hovered entity did not change
    if hovered == last_hovered then
        return
    end

    last_hovered = hovered

    if hovered == nil then
        return
    end

    Log("Hovering over: " .. tostring(hovered and hovered.prefab or "unknown prefab"))

    if not IsContainer(hovered) then
        return
    end

    Log("Hovering over a container: " .. hovered.prefab)
    SpeakHovered(GLOBAL.ThePlayer, hovered)
    ShowContainerContents(hovered)


end

local function PeekOnHoverPostInit()
    Log("initializing...")
    -- Add the update function to the inst
    local inst = GLOBAL.CreateEntity()
    inst:DoPeriodicTask(0, OnUpdate) -- 0 = every frame
    Log("initialized...")
end



--[[
    "When the game finishes setting up the world, run my code of..."
]]
AddSimPostInit(
    PeekOnHoverPostInit
)