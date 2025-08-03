-- ===================================================
-- Peek on Hover v0.2.0 (Server)
-- [X] TODO: Prints container contents to console when hovering
-- [X] TODO: Change to server mod
-- [ ] TODO: Fix sending valid container layout and table to client
-- [ ] TODO: Open UI of container size and display contents in it (no interaction allowed)
-- ===================================================


local GLOBAL = GLOBAL
local TheInput = GLOBAL.TheInput
local require = GLOBAL.require
local PeekWidget = require "widgets/peekwidget"

-------------------------------------------------------
-- Debug Logger
-------------------------------------------------------
local function Log(msg)
    print("[PEEK ON HOVER] " .. tostring(msg))
end

Log("Peek on Hover mod loaded...")

-- -------------------------------------------------------
-- -- Item Snapshot Builder (server safe)
-- -------------------------------------------------------
-- local function BuildItemSnapshot(item)
--     if not item then return nil end

--     local data = {}

--     -- Basic info
--     data.prefab = item.prefab
--     data.name = item.GetDisplayName and item:GetDisplayName() or nil

--     -- Stackable
--     if item.components.stackable then
--         data.stacksize = item.components.stackable:StackSize()
--     end

--     -- Durability-like
--     if item.components.finiteuses then
--         data.durability = item.components.finiteuses:GetPercent()
--     end
--     if item.components.armor then
--         data.armor = item.components.armor:GetPercent()
--     end
--     if item.components.fueled then
--         data.fuel = item.components.fueled:GetPercent()
--     end

--     -- Perishables
--     if item.components.perishable then
--         data.freshness = item.components.perishable:GetPercent()
--     end

--     -- Edible info
--     if item.components.edible then
--         data.healthvalue = item.components.edible.healthvalue
--         data.hungervalue = item.components.edible.hungervalue
--         data.sanityvalue = item.components.edible.sanityvalue
--         data.foodtype = item.components.edible.foodtype
--     end

--     -- Tags (only strings, safe)
--     if item.tags then
--         data.tags = {}
--         for _, tag in ipairs(item.tags) do
--             table.insert(data.tags, tag)
--         end
--     end

--     return data
-- end

-------------------------------------------------------
-- SERVER: Send container contents & layout to client
-------------------------------------------------------

local function ServerSendContainerContents(player, container)
    if player == nil then
        Log("Server: player is nil, cannot send container contents.")
        return
    end
    Log("Server: player=" .. tostring(player) ..
        "\nplayerID=" .. tostring(player.userid) ..
        "\nplayerName=" .. (player.name or "unknown"))


    -- check if container is valid -----
    if not container then
        Log("Server: container is nil, nothing sent.")
        return
    end

    if not container.prefab then
        Log("Server: container prefab is nil, nothing sent.")
        return
    end

    if not container.components then
        Log("Server: container has no components, nothing sent.")
        return
    end

    if not container.components.container then
        Log("Server: container has no 'container' component, nothing sent.")
        return
    end
    -------------------------------------------------------
    

    local comp = container.components.container
    Log("Server: " .. (player and player.name or "unknown") ..
        "\n\t ALT-hovered " .. tostring(container) 
        ..
        "\n\t | NumSlots: " .. tostring(comp:GetNumSlots()) ..
        "\n\t | NumItems: " .. tostring(comp:GetNumItems())
    )

    -- log container information

    

    local items_in_container = comp:GetAllItems()
    Log("Server: containerID=" .. tostring(container) ..
        "\nContainer:GetNumSlots=" .. tostring(comp:GetNumSlots()) ..
        "\nContainer:GetAllItems=collected_items=" .. tostring(items_in_container)
    )

    Log("Server: container contains: \n")
    for i, item in ipairs(items_in_container) do
        Log("  " .. tostring(i) .. ": " .. tostring(item.prefab) ..
            " (stack: " .. tostring(item.components.stackable and item.components.stackable:StackSize() or 1) .. ")")
    end



    -- Build slot data
    local slotdata = {}
    for slot, item in pairs(comp.slots) do
        if item then
            -- slotdata[slot] = BuildItemSnapshot(item)
            slotdata[slot] = item.name or "unknown"
        end
    end

    Log("Server: Sending container layout & slot data to client...")

    -- Send layout + slotdata to client
    SendModRPCToClient(
        CLIENT_MOD_RPC["peek_on_hover"]["ShowPeekUI"],
        player.userid,
        layout,
        slotdata
    )
end

-- Register server RPC handler
AddModRPCHandler("peek_on_hover", "HoverContainer", ServerSendContainerContents)

-------------------------------------------------------
-- CLIENT: Handle RPC from server
-------------------------------------------------------
local peek_ui = nil

local function ClientHandleContainerContents(layout, slotdata)
    Log("Client: Received Peek UI data from server")

    -- Kill old UI if exists
    if peek_ui then
        peek_ui:Kill()
        peek_ui = nil
    end

    -- Create new PeekWidget
    peek_ui = GLOBAL.ThePlayer.HUD:AddChild(PeekWidget(layout))
    peek_ui:SetPosition(0, -200, 0)

    -- Populate widget with server slot data
    peek_ui:Populate(slotdata)
end

-- Register client RPC handler
AddClientModRPCHandler("peek_on_hover", "ShowPeekUI", ClientHandleContainerContents)

-------------------------------------------------------
-- CLIENT: Detect ALT-hover & tell server
-------------------------------------------------------
local last_mouse_x, last_mouse_y = nil, nil
local last_hovered = nil

local function IsContainer(entity)
    return entity and entity.replica and entity.replica.container ~= nil
end

local function OnUpdate()
    -- Only react when ALT is held
    if not TheInput:IsKeyDown(GLOBAL.KEY_ALT) then
        last_hovered = nil
        return
    end

    -- Only update when mouse moves
    local x, y = TheInput:GetScreenPosition()
    if x == last_mouse_x and y == last_mouse_y then
        return
    end

    last_mouse_x, last_mouse_y = x, y
    local hovered = TheInput:GetWorldEntityUnderMouse()

    -- Skip if same hovered entity
    if hovered == last_hovered or hovered == nil then
        return
    end

    last_hovered = hovered

    -- If entity is a container, request info from server
    if IsContainer(hovered) then
        Log("Client: ALT-hovering " .. hovered.prefab .. " → asking server.")
        SendModRPCToServer(
            MOD_RPC["peek_on_hover"]["HoverContainer"],
            hovered
        )
    end
end

-------------------------------------------------------
-- INIT
-------------------------------------------------------
AddSimPostInit(function()
    Log("Peek on Hover initialized.")
    local inst = GLOBAL.CreateEntity()
    inst:DoPeriodicTask(0, OnUpdate)
end)
