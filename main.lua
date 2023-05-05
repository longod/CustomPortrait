
local settings = require("longod.CustomPortrait.config")
local validater = require("longod.CustomPortrait.validater")

local showPortrait = true
local textureWidth = 1
local textureHeight = 1

---@param width integer
---@param n tes3uiElement
---@return integer
local function AddBorderWidth(width, n)
    if n.parent then
        if n.borderRight then
            width = width + n.borderRight
        elseif n.borderAllSides then
            width = width + n.borderAllSides
        end
        if n.borderLeft then
            width = width + n.borderLeft
        elseif n.borderAllSides then
            width = width + n.borderAllSides
        end
    end
    return width
end

---@param width integer
---@param n tes3uiElement
---@return integer
local function AddPaddingWidth(width, n)
    if n.paddingRight then
        width = width + n.paddingRight
    elseif n.paddingAllSides then
        width = width + n.paddingAllSides
    end
    if n.paddingLeft then
        width = width + n.paddingLeft
    elseif n.paddingAllSides then
        width = width + n.paddingAllSides
    end
    return width
end

---comment
---@param e tes3uiEventData
---@param image tes3uiElement
---@param sourceAspectRatio number 1:2=0.5
local function OnPreUpdate(e, image, sourceAspectRatio)
    if showPortrait then
        local profile = settings:GetProfile()
        if not profile then
            return
        end

        local path = profile.path

        if image.contentPath ~= path then
            if not validater.IsValidPath(path) then
                tes3.messageBox("[Custom Portrait] Invalid Path: " .. profile.path)
                showPortrait = false
                return
            end
    
            local texture = niSourceTexture.createFromPath(path)
            if not validater.IsValidTextue(texture) then
                tes3.messageBox("[Custom Portrait] Invalid Texture: " .. profile.path)
                showPortrait = false
                return
            end
    
            textureWidth = math.max(texture.width, 1)
            textureHeight = math.max(texture.height, 1)

            image.contentPath = path
        end

        local originalWidth = math.max(profile.width, 1)
        local originalHeight = math.max(profile.height, 1)
        local originalAspect = originalWidth / originalHeight
        local widthRatio = originalWidth / textureWidth
        local heightRatio = originalHeight / textureHeight
        local aspectRatio = widthRatio / heightRatio

        if sourceAspectRatio > originalAspect then
            -- fit width base
            local scale = image.width / textureWidth
            image.imageScaleX = scale
            image.imageScaleY = scale / aspectRatio
        else
            -- fit height base
            local scale = image.height / textureHeight
            image.imageScaleX = scale * aspectRatio
            image.imageScaleY = scale
        end

        image.minWidth = math.ceil(math.lerp(image.height * sourceAspectRatio, (image.height * originalAspect), profile.uncropWidth))
        image.scaleMode = false     -- must
    end
end

--- @param e uiActivatedEventData
local function OnUiActivated(e)
    local image = e.element:findChild("MenuInventory_CharacterImage")
    if image then
        local profile = settings:GetProfile()
        if not profile then
            return
        end
        showPortrait = profile.enable -- initial state

        -- local path = profile.path
        -- if not validater.IsValidPath(path) then
        --     tes3.messageBox("Error1")
        --     return
        -- end

        -- local texture = niSourceTexture.createFromPath(path)     -- how do i get if error
        -- if not validater.IsValidTextue(texture) then
        --     tes3.messageBox("Error2")
        --     return
        -- end

        -- local textureWidth = math.max(texture.width, 1)
        -- local textureHeight = math.max(texture.height, 1)
        -- local originalWidth = math.max(profile.width, 1)
        -- local originalHeight = math.max(profile.height, 1)
        -- local originalAspect = originalWidth / originalHeight
        -- local widthRatio = originalWidth / textureWidth
        -- local heightRatio = originalHeight / textureHeight
        -- local aspectRatio = widthRatio / heightRatio

        -- original character image aspect, it's almost 1:2
        -- fixed value avoid too small values
        local expectAspect = 0.5 -- image.width / image.height

        -- The character image is always resized, so resize them again before updating the inventry menu.
        e.element:register(tes3.uiEvent.preUpdate,
        ---@param ev tes3uiEventData
        function(ev)
            OnPreUpdate(ev, image, expectAspect)
        end)

        -- Then, minWwidth of the menu is set by width (before replaced) of the character image and the weight bar, so recalculate minWidth.
        e.element:register(tes3.uiEvent.update,
        ---@param ev tes3uiEventData
        function(ev)
            ev.source:forwardEvent(ev) -- it seems ok
            if showPortrait then

                -- min window width

                local windowMinWidth = math.max(image.minWidth, image.width)
                local node = image
                -- exclude padding
                windowMinWidth = AddBorderWidth(windowMinWidth, node)
                
                node = node.parent
                while node ~= nil do
                    windowMinWidth = AddPaddingWidth(windowMinWidth, node)
                    windowMinWidth = AddBorderWidth(windowMinWidth, node)
                    node = node.parent
                end
                -- not enough width, it seems double outer thick border frame do not contain property.
                windowMinWidth = windowMinWidth + (4 * 2) * 2
                image:getTopLevelMenu().minWidth = windowMinWidth
            end
        end)

        -- toggle portrait when armor rating clicked
        local ar = e.element:findChild("MenuInventory_ArmorRating")
        ar:register(tes3.uiEvent.mouseClick,
        function()
            showPortrait = not showPortrait
            if showPortrait then
                -- preUpdate
            else
                -- revert
                image.contentPath = nil
                image.scaleMode = true
                image.minWidth = nil
                image.imageScaleX = 0
                image.imageScaleY = 0
                tes3ui.updateInventoryCharacterImage()
            end
            image:getTopLevelMenu():updateLayout()
        end)

        e.element:updateLayout()
    end
end

local function OnModConfigReady()
    mwse.registerModConfig("Custom Portrait", require("longod.CustomPortrait.mcm"));
end

event.register(tes3.event.uiActivated, OnUiActivated, { filter = "MenuInventory" })
event.register(tes3.event.modConfigReady, OnModConfigReady)
