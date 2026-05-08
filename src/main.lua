local mods = rom.mods
mods['SGG_Modding-ENVY'].auto()

---@diagnostic disable: lowercase-global
rom = rom
_PLUGIN = _PLUGIN
game = rom.game
modutil = mods['SGG_Modding-ModUtil']
local chalk = mods['SGG_Modding-Chalk']
local reload = mods['SGG_Modding-ReLoad']
---@module "adamant-ModpackLib"
---@type AdamantModpackLib
lib = mods['adamant-ModpackLib']

local config = chalk.auto('config.lua')

local PACK_ID = "run-director"
local MODULE_ID = "GodPool"
local PLUGIN_GUID = _PLUGIN.guid
---@class RunDirectorGodPoolInternal
---@field store ManagedStore|nil
---@field host AuthorHost|nil
---@field standaloneUi StandaloneRuntime|nil
---@field RegisterHooks fun()|nil
---@field RegisterIntegrations fun(host: AuthorHost)|nil
---@field DrawTab fun(imgui: table, session: AuthorSession)|nil
---@field DrawQuickContent fun(imgui: table, session: AuthorSession)|nil
---@field IsGodEnabledInPool fun(godKey: string): boolean|nil
RunDirectorGodPool_Internal = RunDirectorGodPool_Internal or {}
---@type RunDirectorGodPoolInternal
local internal = RunDirectorGodPool_Internal

internal.standaloneUi = nil

local function registerGui()
    rom.gui.add_imgui(function()
        if internal.standaloneUi and internal.standaloneUi.renderWindow then
            internal.standaloneUi.renderWindow()
        end
    end)

    rom.gui.add_to_menu_bar(function()
        if internal.standaloneUi and internal.standaloneUi.addMenuBar then
            internal.standaloneUi.addMenuBar()
        end
    end)
end

local function init()
    import_as_fallback(rom.game)
    import("mods/data.lua")
    import("mods/logic.lua")
    import("mods/integrations.lua")
    import("mods/ui.lua")

    internal.host, internal.store = lib.createModule({
        owner = internal,
        pluginGuid = PLUGIN_GUID,
        config = config,
        definition = {
            modpack = PACK_ID,
            id = MODULE_ID,
            name = "God Pool",
            tooltip = "Control which gods enter the run, first-room hammer behavior, and pool support rules.",
            storage = internal.BuildStorage(),
            hashGroupPlan = internal.BuildHashGroupPlan and internal.BuildHashGroupPlan() or nil,
        },
        registerPatchMutation = internal.BuildPatchPlan,
        registerHooks = internal.RegisterHooks,
        registerIntegrations = internal.RegisterIntegrations,
        drawTab = internal.DrawTab,
        drawQuickContent = internal.DrawQuickContent,
    })
    internal.standaloneUi = lib.standaloneHost(PLUGIN_GUID)
end

local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(registerGui, init)
end)
