local Widget = require "widgets/widget"
local Image = require "widgets/image"

-- PeekWidget will take widgetslotpos from container.components.container.widgetslotpos
-- and draw empty placeholder slots at the same positions.

local PeekWidget = Class(Widget, function(self, widgetslotpos)
    Widget._ctor(self, "PeekWidget")

    -- Background panel (ugly black rectangle for now)
    self.bg = self:AddChild(Image("images/global.xml", "square.tex"))
    self.bg:SetTint(0, 0, 0, 0.5)        -- semi-transparent black
    self.bg:SetSize(400, 400)            -- oversized background; will tweak later

    self.slots = {}

    if widgetslotpos and #widgetslotpos > 0 then
        -- Determine bounding box for all slot positions to center background nicely
        local min_x, max_x = 9999, -9999
        local min_y, max_y = 9999, -9999

        for _, pos in ipairs(widgetslotpos) do
            if pos.x < min_x then min_x = pos.x end
            if pos.x > max_x then max_x = pos.x end
            if pos.y < min_y then min_y = pos.y end
            if pos.y > max_y then max_y = pos.y end
        end

        local width = (max_x - min_x) + 80   -- add padding around slots
        local height = (max_y - min_y) + 80
        self.bg:SetSize(width, height)

        -- Add slot placeholders
        for _, pos in ipairs(widgetslotpos) do
            local slot = self:AddChild(Image("images/global.xml", "square.tex"))
            slot:SetSize(64, 64)                -- placeholder slot size
            slot:SetPosition(pos.x, pos.y, 0)   -- use the container’s real slot position
            slot:SetTint(1, 1, 1, 0.25)         -- light gray transparent
            table.insert(self.slots, slot)
        end
    else
        -- No layout found (fallback)
        print("[PEEK ON HOVER] WARNING: widgetslotpos missing, drawing one big gray box.")
        local slot = self:AddChild(Image("images/global.xml", "square.tex"))
        slot:SetSize(64, 64)
        slot:SetTint(1, 0, 0, 0.5)  -- red so you notice it’s wrong
        table.insert(self.slots, slot)
    end
end)

return PeekWidget
