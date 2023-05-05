---@class ModConfig
local modConfig = {}

local settings = require("longod.CustomPortrait.config")
local validater = require("longod.CustomPortrait.validater")

local indent = 16
local spacing = 4

---@param parentBlock tes3uiElement
---@return tes3uiElement
local function CreateOuterContainer(parentBlock)
    local outerContainer = parentBlock:createBlock({ id = tes3ui.registerID("OuterContainer") })
    outerContainer.flowDirection = tes3.flowDirection.topToBottom
    outerContainer.widthProportional = 1.0
    outerContainer.autoHeight = true
    outerContainer.borderAllSides = spacing
    outerContainer.borderLeft = indent
    return outerContainer
end

---@param parentBlock tes3uiElement
---@return tes3uiElement
local function CreateInnerContainer(parentBlock)
    local innerContainer = parentBlock:createBlock({ id = tes3ui.registerID("InnerContainer") })
    innerContainer.widthProportional = parentBlock.widthProportional
    innerContainer.autoWidth = parentBlock.autoWidth
    innerContainer.heightProportional = parentBlock.heightProportional
    innerContainer.autoHeight = parentBlock.autoHeight
    innerContainer.flowDirection = tes3.flowDirection.leftToRight
    -- innerContainer.paddingAllSides = 6
    innerContainer.paddingLeft = indent
    return innerContainer
end

---@param element tes3uiElement
local function ContentsChanged(element)
    if element and element.widget and element.widget.contentsChanged then
        local widget = element.widget ---@cast widget tes3uiScrollPane
        widget:contentsChanged()
    end
end

---@param parentBlock tes3uiElement
---@param text string
---@param bool boolean
---@param callback fun(e: tes3uiEventData) : boolean
---@return tes3uiElement
---@return tes3uiElement
---@return tes3uiElement
---@return tes3uiElement
local function CreateButton(parentBlock, text, bool, callback)

    ---@param bool boolean
    ---@return string
    local function GetYesNo(bool)
        ---@diagnostic disable-next-line: return-type-mismatch
        return bool and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value
    end

    local outer = CreateOuterContainer(parentBlock)
    local inner = CreateInnerContainer(outer)
    local button = inner:createButton({ id = tes3ui.registerID("Button"), text = GetYesNo(bool) })
    button.borderRight = indent
    local label = inner:createLabel({ text = text })
    label.borderTop = 4 -- fit withbutton
    button:register(tes3.uiEvent.mouseClick,
    ---@param e tes3uiEventData
    function(e)
        local result = callback(e)
        e.source.text = GetYesNo(result)
    end)
    return outer, inner, button, label
end

---@param parentBlock tes3uiElement
---@param text string
---@return tes3uiElement
---@return tes3uiElement
local function CreateDescription(parentBlock, text)
    local right = CreateInnerContainer(parentBlock)
    right.childAlignX = 1
    right.widthProportional = 1.0
    right.autoHeight = true
    right.paddingLeft = indent * 4
    local desc = right:createLabel({ text = text })
    desc.wrapText = true
    return right, desc
end

---@param content tes3uiElement
---@param scrollBar tes3uiElement
---@param profile PortraitProfile
---@param isGlobal boolean
local function CreateProfileSettings(content, scrollBar, profile, isGlobal)
    local previewFrame = nil ---@type tes3uiElement
    local previewImage = nil ---@type tes3uiElement

    ---@param updateLayout boolean
    local function UpdatePreview(updateLayout)
        if not validater.IsValidPath(profile.path) then
            tes3.messageBox("[Custom Portrait] Invalid Path: " .. profile.path)
            return
        end
        local texture = niSourceTexture.createFromPath(profile.path)
        if not validater.IsValidTextue(texture) then
            tes3.messageBox("[Custom Portrait] Invalid Texture: " .. profile.path)
            return
        end

        local width = profile.width > 0 and profile.width or texture.width
        local height = profile.height > 0 and profile.height or texture.height
        
        local border = previewFrame
        local padding = 4
        local aspect = 0.5
        border.borderLeft = 4 -- fit others
        border.paddingAllSides = padding
        border.autoWidth = false 
        border.autoHeight = false
        local h = math.clamp(height, 128, 256) -- display limit
        local scale = (h/height)
        border.height = h + padding * 2
        border.width = (math.lerp(h * aspect, width * scale, profile.uncropWidth )) + padding * 2
        local image  = previewImage
        image.contentPath = profile.path
        image.imageScaleX = (width  / texture.width) * scale
        image.imageScaleY = (height / texture.height) * scale

        if updateLayout then
            image:getTopLevelMenu():updateLayout()
            ContentsChanged(scrollBar)
        end
    end

    ---@param parentBlock tes3uiElement
    ---@param text string
    ---@param numeric boolean?
    ---@param validate fun(text:string): any
    ---@return tes3uiElement
    ---@return tes3uiElement
    local function CreateInputField(parentBlock, text, numeric, validate)
        local border = parentBlock:createThinBorder()
        border.widthProportional = 1.0
        border.autoHeight = true
        border.flowDirection = tes3.flowDirection.leftToRight
        local inputField = border:createTextInput({ text = text:trim(), numeric = numeric })
        inputField.widthProportional = 1.0
        inputField.autoHeight = true
        inputField.widget.lengthLimit = nil
        inputField.widget.eraseOnFirstKey = false
        inputField.borderLeft = 5
        inputField.borderBottom = 4
        inputField.borderTop = 2
        inputField.consumeMouseEvents = false
        inputField.wrapText = true
        if not validate or validate(inputField.text) ~= nil then
            inputField.color = tes3ui.getPalette(tes3.palette.normalOverColor)
        else
            inputField.color = tes3ui.getPalette(tes3.palette.negativeColor)
        end
        return border, inputField
    end

    ---@param parentBlock tes3uiElement
    ---@return tes3uiElement
    ---@return tes3uiElement
    local function CreateInputButton(parentBlock) 
        local submit = parentBlock:createButton({ id = tes3ui.registerID("TextField_SubmitButton"),
        text = mwse.mcm.i18n("Submit") })
        submit.borderAllSides = 0
        submit.paddingAllSides = 2
        submit.heightProportional = 1.0
        local revert = parentBlock:createButton({ id = tes3ui.registerID("TextField_RevertButton"), text = "Revert" })
        revert.borderAllSides = 0
        revert.paddingAllSides = 2
        revert.heightProportional = 1.0
        return submit, revert
    end

    ---@param e tes3uiElement
    ---@param input tes3uiElement
    local function RegisterAcquireTextInput(e, input)
        e:register(tes3.uiEvent.mouseClick, function()
            tes3ui.acquireTextInput(input)
        end)
        if e.children then
            for _, element in ipairs(e.children) do
                RegisterAcquireTextInput(element, input)
            end
        end
    end

    do
        local _, inner = CreateButton(content, "Enable", profile.enable,
        function()
            profile.enable = not profile.enable
            return profile.enable
        end)
        local _, desc = CreateDescription(inner, "placeholder")
        desc.borderTop = 4
    end

    -- text input
    do
        local outer = CreateOuterContainer(content)
        local inner = CreateInnerContainer(outer)

        local label = inner:createLabel({ text = "Path"})
        label.autoWidth = true
        label.heightProportional = 1.0
        label.borderRight = indent

        ---@param text string
        ---@return boolean
        local function Validate(text)
            return validater.IsValidPath(text)
        end

        local border, inputField = CreateInputField(inner, profile.path, false, Validate)

        local submit, revert = CreateInputButton(inner)
        border.borderRight = indent
        submit.borderRight = indent

        CreateDescription(outer, "placeholder")

        RegisterAcquireTextInput(border, inputField)

        local function Accept()
            local text = inputField.text:trim()
            if Validate(text) then
                profile.path = text
                UpdatePreview(true)
            else
                tes3.messageBox("Invalid Path: " .. profile.path)
            end
        end

        inputField:register(tes3.uiEvent.keyEnter,
        ---@param e tes3uiEventData
        function(e)
            Accept()
        end)
        inputField:register(tes3.uiEvent.keyPress,
        ---@param e tes3uiEventData
        function(e)
            e.source:forwardEvent(e)

            local text = inputField.text:trim()
            if Validate(text) then
                inputField.color = tes3ui.getPalette(tes3.palette.normalOverColor)
            else
                inputField.color = tes3ui.getPalette(tes3.palette.negativeColor)
            end
            inputField:getTopLevelMenu():updateLayout()
        end)

        submit:register(tes3.uiEvent.mouseClick,
        ---@param e tes3uiEventData
        function(e)
            Accept()
        end)
        revert:register(tes3.uiEvent.mouseClick,
        ---@param e tes3uiEventData
        function(e)
            -- todo better before saved path than submiited path
            inputField.text = profile.path
            local text = inputField.text:trim()
            if Validate(text) then
                inputField.color = tes3ui.getPalette(tes3.palette.normalOverColor)
            else
                inputField.color = tes3ui.getPalette(tes3.palette.negativeColor)
            end
            inputField:getTopLevelMenu():updateLayout()
        end)

    end

    -- width height
    do
        local outer = CreateOuterContainer(content)
        local inner = CreateInnerContainer(outer)

        ---@param text string
        ---@return any
        local function Validate(text)
            local number = tonumber(text)
            if number ~= nil and number >= 0 then
                return number
            end
            return nil
        end

        do
            local label = inner:createLabel({ text = "Width"})
            label.autoWidth = true
            label.heightProportional = 1.0
            label.borderRight = indent
            local border, inputField = CreateInputField(inner, tostring(profile.width), true, Validate)
            border.borderRight = indent

            RegisterAcquireTextInput(border, inputField)

            local function Accept()
            	local number = Validate(inputField.text:trim())
                if number ~= nil then
                    profile.width = math.floor(number)
                    inputField.color = tes3ui.getPalette(tes3.palette.normalOverColor)
                    UpdatePreview(true)
                else
                    inputField.color = tes3ui.getPalette(tes3.palette.negativeColor)
                end
                inputField:getTopLevelMenu():updateLayout()
            end
            inputField:register(tes3.uiEvent.keyEnter,
            ---@param e tes3uiEventData
            function(e)
                Accept()
            end)
            inputField:register(tes3.uiEvent.keyPress,
            ---@param e tes3uiEventData
            function(e)
                e.source:forwardEvent(e)
                Accept()
            end)
        end
        do
            local label = inner:createLabel({ text = "Height"})
            label.autoWidth = true
            label.heightProportional = 1.0
            label.borderRight = indent
            local border, inputField = CreateInputField(inner, tostring(profile.height), true, Validate)
            --border.borderRight = indent

            RegisterAcquireTextInput(border, inputField)

            local function Accept()
            	local number = Validate(inputField.text:trim())
                if number ~= nil then
                    profile.height = math.floor(number)
                    inputField.color = tes3ui.getPalette(tes3.palette.normalOverColor)
                    UpdatePreview(true)
                else
                    inputField.color = tes3ui.getPalette(tes3.palette.negativeColor)
                end
                inputField:getTopLevelMenu():updateLayout()
            end
            inputField:register(tes3.uiEvent.keyEnter,
            ---@param e tes3uiEventData
            function(e)
                Accept()
            end)
            inputField:register(tes3.uiEvent.keyPress,
            ---@param e tes3uiEventData
            function(e)
                e.source:forwardEvent(e)
                Accept()
            end)
        end

        CreateDescription(outer,
        "Specifies the size of the original image. "..
        "This can be used to compensate for changes in aspect ratio caused by a texture to the power of two. "..
        "When 0, the texture size is treated as a ratio. " ..
        "The aspect ratio of the rendered character image is 1:2.")

    end

    -- crop
    do
        local outer = CreateOuterContainer(content)
        local inner = CreateInnerContainer(outer)

        local label = inner:createLabel({ text = "Crop Width"})
        label.autoWidth = true
        label.heightProportional = 1.0
        label.borderRight = indent

        local resolution = 1024
        
        local slider = inner:createSlider({ current = profile.uncropWidth * resolution, step = 1, jump = 16, max = resolution})
        slider.widthProportional = 1.0
        slider.heightProportional = 1.0
        slider.borderRight = indent
        slider.borderTop = 4

        local right = inner:createBlock()
        right.width = 64
        right.autoHeight = true
        right.childAlignX = 1.0

        local label = right:createLabel({ text = string.format("%.3f", profile.uncropWidth) })
        label.autoWidth = true
        label.heightProportional= 1.0

        CreateDescription(outer, "placeholder")
        
        ---@param e tes3uiEventData
        local function OnValueChanged(e)
            local val = (slider.widget.current) / resolution
            label.text = string.format("%.3f", val)
            val = math.clamp(val, 0.0, 1.0)
            profile.uncropWidth = val
            UpdatePreview(true)
        end
    
        for _, child in ipairs(slider.children) do
            child:register(tes3.uiElementType.mouseClick, OnValueChanged) -- click, drag
            child:register(tes3.uiEvent.mouseRelease, OnValueChanged) -- drag
            for _, gchild in ipairs(child.children) do
                gchild:register(tes3.uiEvent.mouseClick, OnValueChanged) -- click, drag
                gchild:register(tes3.uiEvent.mouseRelease, OnValueChanged) -- drag
            end
        end
    
        -- need to update only value test?
        slider:register(tes3.uiEvent.partScrollBarChanged, OnValueChanged)
    end

    do
        local outer = CreateOuterContainer(content)
        local inner = CreateInnerContainer(outer)

        do
            -- test button
            local button = inner:createButton({ id = tes3ui.registerID("TextField_TestButton"),
                text = "Hide Preview" })
            button:register(tes3.uiEvent.mouseClick, function(e)
                previewFrame.visible = not previewFrame.visible
                button.text = previewFrame.visible and "Hide Preview" or "Show Preview"
                previewFrame:getTopLevelMenu():updateLayout()
                ContentsChanged(scrollBar)
            end)
        end
        --[[
        do
            local right = inner:createBlock()
            right.widthProportional = 1.0
            right.autoHeight = true
            right.childAlignX = 1.0
            local button = right:createButton({ id = tes3ui.registerID("TextField_ResetButton"), text = "Reset to Default" })
            button:register(tes3.uiEvent.mouseClick,
                ---@param e tes3uiEventData
                function(e)
                    
                end)
        end
        ]]--
    end
    -- preview
    do
        local outer = CreateOuterContainer(content)
        local inner = CreateInnerContainer(outer)
        local border = inner:createThinBorder()
        local image = border:createImage()
        previewFrame = border
        previewImage = image
        UpdatePreview(false)
    end

end

---@param container tes3uiElement
function modConfig.onCreate(container)

    local pane = container:createVerticalScrollPane()
    pane.widthProportional = 1.0
    pane.heightProportional = 1.0
    local content = pane:getContentElement()
    local headerColor = tes3ui.getPalette(tes3.palette.headerColor)

    local config = settings.Load()

    local characterProfileBlock ---@type tes3uiElement

    
    ---comment
    ---@param element tes3uiElement
    ---@param visible boolean
    local function SetVisibility(element, visible)
        if element then
            element.visible = visible
            if element.children then
                for _, child in ipairs(element.children) do
                    SetVisibility(child, visible)
                end
            end
        end
    end
    
    do
        local block = CreateOuterContainer(content)
        do
            local inner = CreateInnerContainer(block)
            local label = inner:createLabel({text="Common Settings"})
            label.borderRight = indent
            label.color = headerColor
            inner:createDivider().widthProportional = 1
        end

        do
            CreateButton(block, "Enable Mod", config.enable,
            function()
                config.enable = not config.enable
                return config.enable
            end)
        end
        do
            local _, inner = CreateButton(block, "Use Character Profile", config.useCharacterProfile,
            function()
                config.useCharacterProfile = not config.useCharacterProfile
                SetVisibility(characterProfileBlock, config.useCharacterProfile)
                container:updateLayout()
                ContentsChanged(pane)
                return config.useCharacterProfile
            end)
            local _, desc = CreateDescription(inner, "placeholder")
            desc.borderTop = 4
        end
    end
    
    do
        local block = CreateOuterContainer(content)
        do
            local inner = CreateInnerContainer(block)
            local label = inner:createLabel({text="Global Profile"})
            label.borderRight = indent
            label.color = headerColor
            inner:createDivider().widthProportional = 1
        end
        CreateProfileSettings(block, pane, config.global, true)
    end


    -- per character profile...
    do
        local block = CreateOuterContainer(content)
        characterProfileBlock = block
        do
            local inner = CreateInnerContainer(block)
            local label = inner:createLabel({text="Character Profile"})
            label.borderRight = indent
            label.color = headerColor
            inner:createDivider().widthProportional = 1
        end

        if tes3.onMainMenu() then
            local inner = CreateInnerContainer(block)
            inner:createLabel({text = "Character Profile at in-game."})
        else
            local profile = settings:GetCharacterProfile()
            if profile then
                CreateProfileSettings(block, pane, profile, false)
            end
        end
        SetVisibility(characterProfileBlock, config.useCharacterProfile)
    end

    container:updateLayout()
    ContentsChanged(pane)
end

---@param container tes3uiElement
function modConfig.onClose(container)
    mwse.saveConfig(settings.configPath, settings.Load())
    -- todo feedback in game if needed
end

return modConfig