local Widget = require "widgets/widget"
local Image = require "widgets/image"
local Text = require "widgets/text"

-- PeekWidget: shows a non-interactive container UI
local PeekWidget = Class(Widget, function(self, layout)
    Widget._ctor(self, "PeekWidget")

    -- Optional semi-transparent background
    self.bg = self:AddChild(Image("images/hud.xml", "craftingslot_bg.tex"))
    self.bg:SetScale(2.2, 2.2)
    self.bg:SetTint(1, 1, 1, 0.5)

    self.slots = {}
    self.layout = layout

    -- Build slot positions
    for i, pos in ipairs(layout) do
        local slot = {}

        -- Slot background
        slot.bg = self:AddChild(Image("images/hud.xml", "inventory_bg.tex"))
        slot.bg:SetPosition(pos.x, pos.y, 0)
        slot.bg:SetScale(1.2)

        -- Empty references for later
        slot.icon = nil
        slot.stacktext = nil
        slot.overlay = nil

        self.slots[i] = slot
    end
end)

function PeekWidget:Populate(slotdata)
    for i, slot in ipairs(self.slots) do
        -- Clear previous visuals
        if slot.icon then slot.icon:Kill() slot.icon = nil end
        if slot.stacktext then slot.stacktext:Kill() slot.stacktext = nil end
        if slot.overlay then slot.overlay:Kill() slot.overlay = nil end

        -- Slot data for this index
        local data = slotdata[i]
        if data and data.prefab then
            -------------------------------------------------
            -- ICON (item picture)
            -------------------------------------------------
            local atlas = "images/inventoryimages/"..data.prefab..".xml"
            local tex = data.prefab..".tex"

            -- fallback for unknown items
            if not softresolvefilepath(atlas) then
                atlas = "images/inventoryimages.xml"
                tex = "unknown.tex"
            end

            slot.icon = self:AddChild(Image(atlas, tex))
            slot.icon:SetPosition(slot.bg:GetPosition())
            slot.icon:SetScale(1.1)

            -------------------------------------------------
            -- STACK SIZE
            -------------------------------------------------
            if data.stacksize and data.stacksize > 1 then
                slot.stacktext = self:AddChild(Text(DEFAULTFONT, 26))
                slot.stacktext:SetPosition(slot.bg:GetPosition() + Vector3(16, -16, 0))
                slot.stacktext:SetString(tostring(data.stacksize))
                slot.stacktext:SetColour(1, 1, 1, 1)
            end

            -------------------------------------------------
            -- STATUS BAR (freshness/durability)
            -------------------------------------------------
            local percent = data.freshness or data.durability or data.armor or data.fuel
            if percent then
                slot.overlay = self:AddChild(Image("images/hud.xml", "inventory_bg.tex"))
                slot.overlay:SetPosition(slot.bg:GetPosition() + Vector3(0, -25, 0))
                slot.overlay:SetScale(percent, 0.1)  -- width scales with % (thin bar)
                if data.freshness then
                    slot.overlay:SetTint(0, 1, 0, 1) -- green
                elseif data.durability or data.armor then
                    slot.overlay:SetTint(1, 1, 0, 1) -- yellow
                elseif data.fuel then
                    slot.overlay:SetTint(0, 0.5, 1, 1) -- blue
                end
            end
        end
    end
end

return PeekWidget
