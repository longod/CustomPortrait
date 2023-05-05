---@class ModConfig
local modConfig = {}

local settings = require("longod.CustomPortrait.config")
local validater = require("longod.CustomPortrait.validater")

local indent = 12

---@param bool boolean
---@return string
local function GetYesNo(bool)
    ---@diagnostic disable-next-line: return-type-mismatch
    return bool and tes3.findGMST(tes3.gmst.sYes).value or tes3.findGMST(tes3.gmst.sNo).value
end

---@param parentBlock tes3uiElement
---@return tes3uiElement
local function CreateOuterContainer(parentBlock)
    local outerContainer = parentBlock:createBlock({ id = tes3ui.registerID("OuterContainer") })
    outerContainer.flowDirection = tes3.flowDirection.topToBottom
    outerContainer.widthProportional = 1.0
    outerContainer.autoHeight = true
    outerContainer.borderAllSides = 6
    outerContainer.borderBottom = 6
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
    innerContainer.paddingAllSides = 6
    innerContainer.paddingRight = indent
    return innerContainer
end

---@param element tes3uiElement
local function ContentsChanged(element)
    if element and element.widget and element.widget.contentsChanged then
        local widget = element.widget ---@cast widget tes3uiScrollPane
        widget:contentsChanged()
    end
end

---@param content tes3uiElement
---@param scrollBar tes3uiElement
---@param profile PortraitProfile
local function CreateProfileSettings(content, scrollBar, profile)
    local previewFrame = nil ---@type tes3uiElement
    local previewImage = nil ---@type tes3uiElement
    local function UpdatePreview()
        if not validater.IsValidPath(profile.path) then
            tes3.messageBox("error path")
            return
        end
        local texture = niSourceTexture.createFromPath(profile.path)
        if not validater.IsValidTextue(texture) then
            tes3.messageBox("error tex")
            return
        end
        
        -- local border = pane:createThinBorder()
        -- border.paddingAllSides = 4
        -- --border.width = config.height * 0.5 + 4*2
        -- -- border.height = config.height+ 4*2
        local border = previewFrame
        border.width = profile.height * 0.5 + 4 * 2 + math.max(profile.width - profile.height * 0.5, 0) * profile.uncropWidth

        -- border.autoWidth = true     -- TODO width is image size base
        -- border.autoHeight = true
        --local image = border:createImage({ path = config.path })
        -- image.autoWidth = true
        -- image.autoHeight = true
        local image  = previewImage
        image.contentPath = profile.path
        image.contentPath = profile.path
        image.imageScaleX = profile.width / texture.width
        image.imageScaleY = profile.height / texture.height
        image:getTopLevelMenu():updateLayout()
        ContentsChanged(scrollBar)
    end




    -- todo validater
    ---@param parentBlock tes3uiElement
    ---@param text string
    ---@return tes3uiElement
    ---@return tes3uiElement
    local function createInputField(parentBlock, text, placeholder)
        local border = parentBlock:createThinBorder()
        border.widthProportional = 1.0
        border.autoHeight = true
        border.flowDirection = tes3.flowDirection.leftToRight
        local inputField = border:createTextInput({ text = text, placeholderText = placeholder })
        inputField.widthProportional = 1.0
        inputField.autoHeight = true
        inputField.widget.lengthLimit = nil
        inputField.widget.eraseOnFirstKey = false
        inputField.borderLeft = 5
        inputField.borderBottom = 4
        inputField.borderTop = 2
        inputField.consumeMouseEvents = false
        inputField.wrapText = true
        return border, inputField
    end

    ---@param parentBlock tes3uiElement
    ---@return tes3uiElement
    ---@return tes3uiElement
    local function createInputButton(parentBlock) 
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
    local function registerAcquireTextInput(e, input)
        e:register(tes3.uiEvent.mouseClick, function()
            tes3ui.acquireTextInput(input)
        end)
        if e.children then
            for _, element in ipairs(e.children) do
                registerAcquireTextInput(element, input)
            end
        end
    end

    do
        local outer = CreateOuterContainer(content)
        local inner = CreateInnerContainer(outer)
        local button = inner:createButton({ text = GetYesNo(profile.enable) })
        button.borderRight = indent
        local label = inner:createLabel({ text = "Enable" })
        label.borderTop = 4
    end

    -- text input
    do
        local outer = CreateOuterContainer(content)
        local inner = CreateInnerContainer(outer)

        local label = inner:createLabel({ text = "Path"})
        label.autoWidth = true
        label.heightProportional = 1.0
        label.borderRight = indent

        local border, inputField = createInputField(inner, profile.path)

        local submit, revert = createInputButton(inner)
        border.borderRight = indent
        submit.borderRight = indent

        local right = CreateInnerContainer(outer)
        right.childAlignX = 1
        right.paddingLeft = indent * 8
        local desc = right:createLabel({ text = "here is description, texture path is data files relative, .dds, .tga or .bmp extension and width and height must be power of 2 e.g. 8, 16 ..." })
        desc.wrapText = true


        -- where is gone calette? | 

        registerAcquireTextInput(border, inputField)

        local function Accept()
            local text = inputField.text:trim()
            if validater.IsValidPath(text) then
                profile.path = text
                UpdatePreview()
            else
                -- todo error message
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
            if validater.IsValidPath(text) then
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
            if validater.IsValidPath(text) then
                inputField.color = tes3ui.getPalette(tes3.palette.normalOverColor)
            else
                inputField.color = tes3ui.getPalette(tes3.palette.negativeColor)
            end
            inputField:getTopLevelMenu():updateLayout()
        end)

        -- todo need copy and paste?
    end
    -- width height
    do
        


        local outer = CreateOuterContainer(content)
        local inner = CreateInnerContainer(outer)

        do
            local label = inner:createLabel({ text = "Width"})
            label.autoWidth = true
            label.heightProportional = 1.0
            label.borderRight = indent
            local border, inputField = createInputField(inner, tostring(profile.width))
            --border.widthProportional = 0.5
            border.borderRight = indent

            registerAcquireTextInput(border, inputField)

            local function Accept()
            	local number = tonumber(inputField.text:trim())
                if number ~= nil and number > 0 then
                    profile.width = number
                    UpdatePreview()
                else
                    -- todo error message
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
                Accept()
            end)
        end
        do
            local label = inner:createLabel({ text = "Height"})
            label.autoWidth = true
            label.heightProportional = 1.0
            label.borderRight = indent
            local border, inputField = createInputField(inner, tostring(profile.height))
            --border.widthProportional = 0.5
            border.borderRight = indent

            registerAcquireTextInput(border, inputField)

            local function Accept()
            	local number = tonumber(inputField.text:trim())
                if number ~= nil and number > 0 then
                    profile.height = number
                    UpdatePreview()
                else
                    -- todo error message
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
                Accept()
            end)
        end
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

        local label = inner:createLabel({ text = string.format("%.4f", profile.uncropWidth) })
        label.minWidth = 64
        label.maxWidth = 128
        label.autoWidth = true
        label.heightProportional= 1.0
        
        ---@param e tes3uiEventData
        local function OnValueChanged(e)
            local val = (slider.widget.current) / resolution
            label.text = string.format("%.2f", val)
            val = math.clamp(val, 0.0, 1.0)
            profile.uncropWidth = val
            UpdatePreview()
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
        inner.childAlignX = 1
    end

    do
        local outer = CreateOuterContainer(content)
        local inner = CreateInnerContainer(outer)

        do
            -- test button
            local button = inner:createButton({ id = tes3ui.registerID("TextField_TestButton"),
                text = "Show/Hide Preview" })
            button.borderAllSides = 0
            button.paddingAllSides = 2
            button:register(tes3.uiEvent.mouseClick, function(e)
                UpdatePreview()
            end)
        end
        do
            local right = inner:createBlock()
            right.widthProportional = 1.0
            right.autoHeight = true
            right.childAlignX = 1.0
            local button = right:createButton({ id = tes3ui.registerID("TextField_ResetButton"), text = "Reset Default" })
            button.borderAllSides = 0
            button.paddingAllSides = 2
            --button.heightProportional = 1.0
            button:register(tes3.uiEvent.mouseClick,
                ---@param e tes3uiEventData
                function(e)
                end)
        end
    end
    do
        local outer = CreateOuterContainer(content)
        local inner = CreateInnerContainer(outer)

        local texture = niSourceTexture.createFromPath(profile.path)

        -- todo fixed size

        -- todo validation
        
        local border = inner:createThinBorder()
        border.paddingAllSides = 4
        border.width = profile.height * 0.5 + 4 * 2 + math.max(profile.width - profile.height*0.5, 0) * profile.uncropWidth
        border.autoWidth = false 
        border.autoHeight = true
        local image = border:createImage()
        image.contentPath = profile.path
        image.imageScaleX = profile.width / texture.width
        image.imageScaleY = profile.height / texture.height

        previewFrame = border
        previewImage = image
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
            local outer = CreateOuterContainer(block)
            local inner = CreateInnerContainer(outer)
            local button = inner:createButton({ text = GetYesNo(config.enable) })
            button.borderRight = indent
            local label = inner:createLabel({ text = "Enable Mod" })
            label.borderTop = 4
        end

        do
            local outer = CreateOuterContainer(block)
            local inner = CreateInnerContainer(outer)
            local button = inner:createButton({ text = GetYesNo(config.fallbackGlobal) })
            button.borderRight = indent
            local label = inner:createLabel({ text = "Use Global Profile" })
            label.borderTop = 4
        end

        do
            local outer = CreateOuterContainer(block)
            local inner = CreateInnerContainer(outer)
            local button = inner:createButton({ text = GetYesNo(config.perCharacter) })
            button.borderRight = indent
            local label = inner:createLabel({ text = "Use Character Profile" })
            label.borderTop = 4
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
        CreateProfileSettings(block, pane, config.global)
    end


    -- per character profile...
    do
        local block = CreateOuterContainer(content)
        do
            local inner = CreateInnerContainer(block)
            local label = inner:createLabel({text="Character Profile"})
            label.borderRight = indent
            label.color = headerColor
            inner:createDivider().widthProportional = 1
        end

        if tes3.onMainMenu() then
            local inner = CreateInnerContainer(block)
            inner:createLabel({text = "Per Character Profile at in-game."})
        else
            local profile = settings:GetCharacterProfile()
            if profile then
                CreateProfileSettings(block, pane, profile)
            end
        end
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