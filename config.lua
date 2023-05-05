---@class Settings
local this = {}

---@class PortraitProfile
---@field enable boolean
---@field path string
---@field width integer
---@field height integer
---@field uncropWidth number

---@class Config
this.defaultConfig = {
    enable = true,
    fallbackGlobal = true,
    perCharacter = false,
    ---@type PortraitProfile
    global = {
        enable = true,
        path = "MWSE/mods/longod/CustomPortrait/portrait.dds",
        width = 256,
        height = 256,
        uncropWidth = 0.65,
    },
}
this.config = nil ---@type Config
this.configPath = "longod.CustomPortrait"

---@return Config
function this.Load()
    this.config = this.config or mwse.loadConfig(this.configPath, this.defaultConfig)
    mwse.log(this.config)
    return this.config
end

---@return Config
function this.Default()
    return table.deepcopy(this.defaultConfig)
end

---@return PortraitProfile?
function this.GetCharacterProfile(self)
    if not tes3.onMainMenu() and tes3.player and tes3.player.data then
        if tes3.player.data.customPortrait == nil then
            tes3.player.data.customPortrait = table.deepcopy(self.Load().global)
        end
        return tes3.player.data.customPortrait
    end
    return nil
end


---@return PortraitProfile?
function this.GetProfile(self)
    local config = self.Load()
    if config.enable then
        -- fixme
        if config.perCharacter and not tes3.onMainMenu() and tes3.player and tes3.player.data then
            return self:GetCharacterProfile()
        end
        if config.fallbackGlobal then
            return config.global
        end
    end
    return nil
end

return this
