-- ===================================================
-- Peek on Hover v0.1.0 (Server)
-- [X] TODO: Prints container contents to console when hovering
-- [ ] TODO: Change to server mod
-- [ ] TODO: Open UI of container size and display contents in it (no interaction allowed)
-- ===================================================

local GLOBAL = GLOBAL
local TheInput = GLOBAL.TheInput
local require = GLOBAL.require
local Widget = require "widgets/peekwidget"

-------------------------
-- Debug logger
local function Log(msg)
    print("[PEEK ON HOVER] " .. tostring(msg))
end

Log("Peek on Hover mod loaded...")
-------------------------



-----------------------
--- SERVER

-- item snapshot builder
local function BuildItemSnapshot(item)
    if not item then return nil end

    local data = {}

    -- Basic info
    data.prefab = item.prefab
    data.name = item.GetDisplayName and item:GetDisplayName() or nil

    -- Stackable (rocks, twigs, etc.)
    if item.components.stackable then
        data.stacksize = item.components.stackable:StackSize()
    end

    -- Tools, weapons, armor (durability)
    if item.components.finiteuses then
        data.durability = item.components.finiteuses:GetPercent()
    end

    if item.components.armor then
        data.armor = item.components.armor:GetPercent()
    end

    if item.components.fueled then
        data.fuel = item.components.fueled:GetPercent()
    end

    -- Perishables
    if item.components.perishable then
        data.freshness = item.components.perishable:GetPercent()
    end

    -- Food effects
    if item.components.edible then
        data.healthvalue = item.components.edible.healthvalue
        data.hungervalue = item.components.edible.hungervalue
        data.sanityvalue = item.components.edible.sanityvalue
        data.foodtype = item.components.edible.foodtype
    end

    -- Modded extras: tags
    if item.tags then
        data.tags = {}
        for _, tag in ipairs(item.tags) do
            table.insert(data.tags, tag)
        end
    end

    return data
end


-- Send container to client

local function ServerSendContainerContents(player, container)
    if not container or not container.components or not container.components.container then
        Log("Invalid container")
        return
    end

    local contents = container.components.container.slots
    local layout = container.components.container.widgetslotpos or {}    
    
    Log("Server: " .. (player and player.name or "unknown") .. " ALT-hovered " .. tostring(container.prefab))
    Log("Server: Layout has " .. tostring(#layout) .. " slots.")


    local slotdata = {}

    for slot, item in pairs(contents) do
        Log("- " .. (item and item.prefab or "nil"))
        if item then
            slotdata[slot] = BuildItemSnapshot(item)
        end
    end


    -- Sending container info to client
    SendModRPCToClient(
        MOD_RPC_CLIENT["peek_on_hover"]["ShowPeekUI"],
        player.userid,
        layout, slotdata
    )
    
end

AddModRPCHandler(
    "peek_on_hover", 
    "HoverContainer", 
    ServerSendContainerContents
)
-----------------------



-----------------------
--- CLIENT: Detect hovering event

-- States
local last_mouse_x, last_mouse_y = nil, nil
local last_hovered = nil
local peek_ui = nil


-- check if the entity is a container
local function IsContainer(entity)
    return entity and entity.components and entity.components.container ~= nil
end

local function OnUpdate()

    if not TheInput:IsKeyDown(GLOBAL.KEY_ALT) then
        last_hovered = nil
        return
    end

    
    local x, y = TheInput:GetScreenPosition()
    if x == last_mouse_x and y == last_mouse_y then
        return
    end

    last_mouse_x, last_mouse_y = x, y
    local hovered = TheInput:GetWorldEntityUnderMouse()

    if hovered == last_hovered or hovered == nil then
        return
    end

    last_hovered = hovered
    Log("Hovering over a container: " .. hovered.prefab)

    if not IsContainer(hovered) then
        return
    end

    if hovered and hovered.prefab then
        SendModRPCToServer(
            MOD_RPC["peek_on_hover"]["HoverContainer"], hovered
        )
    end

end

local function ClientHandleContainerContents(layout, slotdata)
    Log(player.name .. " received container contents from server.")
    Log("Layout: " .. layout and tostring(layout) or "nil!!!")

    -- create Peek Widget
    if peek_ui then 
        peek_ui:Kill() 
    end

    peek_ui = GLOBAL.ThePlayer.HUD:AddChild(PeekWidget(layout))
    peek_ui:SetPosition(0, -200, 0)

    -- fill slots
    peek_ui:Populate(slotdata)

end

AddClientModRPCHandler(
    "peek_on_hover", 
    "ShowPeekUI", 
    ClientHandleContainerContents
)

local function PeekOnHoverPostInit()
    Log("initializing...")
    local inst = GLOBAL.CreateEntity()
    inst:DoPeriodicTask(0, OnUpdate)
    Log("initialized...")
end


AddSimPostInit(
    PeekOnHoverPostInit
)