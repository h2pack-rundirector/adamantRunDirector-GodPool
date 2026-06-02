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

local function init()
    import_as_fallback(rom.game)

    local data = import("mods/data.lua")
    local runStateCacheName = "RunState"
    local logic = import("mods/logic.lua", nil, {
        godList = data.godList,
        lootKeyLookup = data.lootKeyLookup,
        godLookup = data.godLookup,
        runStateCacheName = runStateCacheName,
    })
    local ui = import("mods/ui.lua")

    local module = lib.createModule({
        pluginGuid = PLUGIN_GUID,
        config = config,
        modpack = PACK_ID,
        id = MODULE_ID,
        name = "God Pool",
        tooltip = "Control which gods enter the run, first-room hammer behavior, and pool support rules.",
    })
    if not module then
        return
    end


    module.data.define(data.buildStorage())
    module.actions.define({
        resetAll = function(host, uiData)
            uiData.resetAll()
        end,
    })
    ui.attach(module)
    logic.defineCache(module)
    logic.attachShared(module)
    logic.attachActivation(module)
    logic.attachCommit(module)
    logic.attachMutation(module)
    logic.attachHooks(module)

    module.fallbackUi.attachGuiOnce(function(fallbackUi)
        rom.gui.add_imgui(fallbackUi.renderWindow)
        rom.gui.add_to_menu_bar(fallbackUi.addMenuBar)
    end)

    local ok = module.activate()
    if not ok then
        return
    end
end

local loader = reload.auto_single()

modutil.once_loaded.game(function()
    loader.load(nil, init)
end)
