
local settings = require("longod.CustomPortrait.config")
local validater = require("longod.CustomPortrait.validater")

local showPortrait = true
local textureWidth = 1
local textureHeight = 1

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
                tes3.messageBox("Error1") -- todo once
                return
            end
    
            local texture = niSourceTexture.createFromPath(path)
            if not validater.IsValidTextue(texture) then
                tes3.messageBox("Error2") -- todo once
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
                if node.borderRight or node.borderLeft then
                    if node.borderRight then
                        windowMinWidth = windowMinWidth + node.borderRight
                    end
                    if node.borderLeft then
                        windowMinWidth = windowMinWidth + node.borderLeft
                    end
                elseif node.borderAllSides then
                    windowMinWidth = windowMinWidth + node.borderAllSides * 2
                end
                
                node = node.parent
                while node ~= nil do
                    if node.parent then
                        if node.borderRight or node.borderLeft then
                            if node.borderRight then
                                windowMinWidth = windowMinWidth + node.borderRight
                            end
                            if node.borderLeft then
                                windowMinWidth = windowMinWidth + node.borderLeft
                            end
                        elseif node.borderAllSides then
                            windowMinWidth = windowMinWidth + node.borderAllSides * 2
                        end
                    end
                    if node.paddingRight or node.paddingLeft then
                        if node.paddingRight then
                            windowMinWidth = windowMinWidth + node.paddingRight
                        end
                        if node.paddingLeft then
                            windowMinWidth = windowMinWidth + node.paddingLeft
                        end
                    elseif node.paddingAllSides then
                        windowMinWidth = windowMinWidth + node.paddingAllSides * 2
                    end
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
