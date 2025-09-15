--[[----------------------------------------------------------------------------

  LiteBag/Layouts.lua

  Copyright 2022 Mike Battersby

  Released under the terms of the GNU General Public License version 2 (GPLv2).
  See the file LICENSE.txt.

----------------------------------------------------------------------------]]--

local addonName, LB = ...

-- local function inDiffBag(a, b)
--     return a:GetBagID() ~= b:GetBagID()
-- end

LB.GridLayoutMixin = CreateFromMixins(GridLayoutMixin)

function LB.GridLayoutMixin:SetNewRowFunction(func)
    self.newRowFunction = func
end

function LB.GridLayoutMixin:IsNewRow(i)
    if self.newRowFunction and self.newRowFunction(i) then
        return true
    end
end

LB.CreateGridLayout = GenerateClosure(CreateAndInitFromMixin, LB.GridLayoutMixin)

function LB.GridLayout(frames, initialAnchor, layout)
    if #frames <= 0 then
        return
    end

    local width = layout.horizontalSpacing or frames[1]:GetWidth()
    local height = layout.verticalSpacing or frames[1]:GetHeight()
    local stride = layout.stride
    local paddingX = layout.paddingX
    local paddingY = layout.paddingY
    local direction = layout.direction

    local row, col = 1, 1

    for i, frame in ipairs(frames) do
        local clearAllPoints = true
        local customOffsetX, customOffsetY = layout:GetCustomOffset(row, col)
        local extraOffsetX = (col - 1) * (width + paddingX) * direction.x + customOffsetX
        local extraOffsetY = (row - 1) * (height + paddingY) * direction.y + customOffsetY
        if direction.isVertical then
            initialAnchor:SetPointWithExtraOffset(frame, clearAllPoints, extraOffsetY, extraOffsetX)
        else
            initialAnchor:SetPointWithExtraOffset(frame, clearAllPoints, extraOffsetX, extraOffsetY)
        end
        col = col + 1
        if col > stride or layout:IsNewRow(i) then
            row = row + 1
            col = 1
        end
    end
end

--[[

LAYOUTS.default =
    function (self, Items, ncols)
        local grid = { }

        local w, h = ItemButtonTemplateInfo.width, ItemButtonTemplateInfo.height

        local xBreak = self:GetOption('xbreak') or 0
        local yBreak = self:GetOption('ybreak') or 0

        local row, col, maxCol, maxXGap = 0, 0, 0, 0

        local xGap, yGap, yGapCounter = 0, 0, 0

        for i = 1, self.size do
            if isReagentBagDivide(Items[i-1], Items[i]) then
                xGap, col, row = 0, 0, row + 1
                yGap, yGapCounter = yGap + h/3, 0
            elseif col > 0 and col % ncols == 0 then
                xGap, col, row, yGapCounter = 0, 0, row + 1, yGapCounter + 1
                if yBreak > 0 and yGapCounter % yBreak == 0 then
                    yGap = yGap + h/3
                end
            elseif xBreak > 0 and col > 0 and col % xBreak == 0 then
                xGap = xGap + w/3
                maxXGap = max(maxXGap, xGap)
            end

            local x = col*(w+BUTTON_X_GAP)+xGap
            local y = row*(h+BUTTON_Y_GAP)+yGap
            tinsert(grid, { x=x, y=y, b=Items[i] })

            maxCol = max(col, maxCol)
            col = col + 1
        end

        grid.ncols = maxCol+1
        grid.totalWidth  = (maxCol+1)*w + maxCol*BUTTON_X_GAP + maxXGap
        grid.totalHeight = (row+1)*h + row*BUTTON_Y_GAP + yGap

        return grid
    end

LAYOUTS.bag =
    function (self, Items, ncols)
        local grid = { }

        local w, h = Items[1]:GetSize()

        local row, col, yGap, maxCol = 0, 0, 0, 0

        for i = 1, self.size do
            local newBag = i > 1 and inDiffBag(Items[i-1], Items[i])
            if col > 1 then
                if newBag then
                    col = 0
                    row = row + 1
                    yGap = yGap + w/3
                elseif col % ncols == 0 then
                    col = 0
                    row = row + 1
                end
            end
            local x = col * (w+BUTTON_X_GAP)
            local y = row * (h+BUTTON_Y_GAP) + yGap
            tinsert(grid, { x=x, y=y, b=Items[i] })
            maxCol = max(col, maxCol)
            col = col + 1
        end

        grid.ncols = maxCol+1
        grid.totalWidth  = (maxCol+1) * w + maxCol * BUTTON_X_GAP
        grid.totalHeight = (row+1) * h + row * BUTTON_Y_GAP + yGap

        return grid
    end

local function GetLayoutNColsForWidth(self, width)
    local layout = self:GetOption('layout')
    if not layout or not LAYOUTS[layout] then layout = 'default' end

    local ncols
    local currentCols = self:GetOption('columns') or MIN_COLUMNS

    -- The BUTTONORDER doesn't matter for sizing so don't bother calling it.
    -- Search up or down from our current column size, for speed.

    if width < self:GetWidth() then
        ncols = MIN_COLUMNS
        for i = currentCols, MIN_COLUMNS, -1 do
            local layoutGrid = LAYOUTS[layout](self, self.Items, i)
            if layoutGrid.totalWidth + LEFT_OFFSET + RIGHT_OFFSET <= width then
                ncols = i
                break
            end
        end
    else
        ncols = self.size
        for i = currentCols+1, self.size+1, 1 do
            local layoutGrid = LAYOUTS[layout](self, self.Items, i)
            if layoutGrid.totalWidth + LEFT_OFFSET + RIGHT_OFFSET > width then
                ncols = i-1
                break
            end
        end
    end
    return ncols
end

local function GetLayoutGridForFrame(self)
    local ncols = self:GetOption('columns')
    local layout = self:GetOption('layout')
    local order = self:GetOption('order')

    if not layout or not LAYOUTS[layout] then layout = 'default' end
    if not order or not BUTTONORDERS[order] then order = 'default' end

    local Items = BUTTONORDERS[order](self)
    return LAYOUTS[layout](self, Items, ncols)
end

local function UpdateItemLayout(self)
    LB.FrameDebug(self, "UpdateItemLayout")
    local layoutGrid = GetLayoutGridForFrame(self)

    local adjustedBottomOffset = BOTTOM_OFFSET + self:CalculateExtraHeight()
    local adjustedTopOffset = self:CalculateTopOffset()


    local anchor = self:GetOption("anchor")

    local xM, yM, xOff, yOff

    if anchor == 'BOTTOMRIGHT' then
        xM, yM, xOff, yOff = -1,  1, -RIGHT_OFFSET,  adjustedBottomOffset
    elseif anchor == 'BOTTOMLEFT' then
        xM, yM, xOff, yOff =  1,  1,  LEFT_OFFSET,   adjustedBottomOffset
    elseif anchor == 'TOPRIGHT' then
        xM, yM, xOff, yOff = -1, -1, -RIGHT_OFFSET, -adjustedTopOffset
    else
        anchor = 'TOPLEFT'
        xM, yM, xOff, yOff =  1, -1,  LEFT_OFFSET,  -adjustedTopOffset
    end

    local n = 1

    for _, pos in ipairs(layoutGrid) do
        local x = xOff + xM * pos.x
        local y = yOff + yM * pos.y
        pos.b:ClearAllPoints()
        pos.b:SetPoint(anchor, self, x, y)
        pos.b:SetShown(true)
        n = n + 1
    end

    for i = 1, #self.bagButtons do
        local this = self.bagButtons[i]
        local last = self.bagButtons[i-1]
        this:ClearAllPoints()
        if not self:GetOption('bagButtons') then
            this:Hide()
        else
            if last then
                this:SetPoint("LEFT", last, "RIGHT", 0, 0)
            else
                this:SetPoint("TOPLEFT", self, "TOPLEFT", 32, -BAGBUTTON_OFFSET)
            end
            this:Show()
        end
    end

    self.width = layoutGrid.totalWidth + LEFT_OFFSET + RIGHT_OFFSET
    self.height = layoutGrid.totalHeight + adjustedTopOffset + adjustedBottomOffset
end
]]
