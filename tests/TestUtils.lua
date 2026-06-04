public = {}
_PLUGIN = { guid = "test-god-pool" }

local function deepCopy(orig)
    if type(orig) ~= "table" then
        return orig
    end
    local copy = {}
    for key, value in pairs(orig) do
        copy[key] = deepCopy(value)
    end
    return copy
end

rom = {
    mods = {},
    game = {
        DeepCopyTable = deepCopy,
        SetupRunData = function() end,
    },
    ImGui = {},
    ImGuiCol = {
        Text = 1,
    },
    gui = {
        add_to_menu_bar = function() end,
        add_imgui = function() end,
    },
}

rom.mods["SGG_Modding-ENVY"] = {
    auto = function()
        return {}
    end,
}

rom.mods["SGG_Modding-Chalk"] = {
    auto = function()
        return { DebugMode = false }
    end,
    original = function(config)
        return config
    end,
}

local registeredWraps = {}

local modUtilApi = {
    Path = {
        Wrap = function(path, handler)
            registeredWraps[path] = handler
            local base = _G[path]
            _G[path] = function(...)
                return handler(base, ...)
            end
        end,
    },
}
modutil = {
    globals = _G,
    mod = modUtilApi,
    once_loaded = {
        game = function() end,
    },
}
modutil.globals.ModUtil = modUtilApi
ModUtil = modUtilApi
rom.mods["SGG_Modding-ModUtil"] = modutil

import = function(path, fenv, ...)
    local localPath = "src/" .. path
    local libPath = "../../adamant-ModpackLib/src/" .. path
    local file = io.open(localPath, "r")
    if file then
        file:close()
        local chunk = assert(loadfile(localPath, "t", fenv or _ENV))
        return chunk(...)
    end
    local chunk = assert(loadfile(libPath, "t", fenv or _ENV))
    return chunk(...)
end

dofile("../../adamant-ModpackLib/src/main.lua")
lib = public
rom.mods["adamant-ModpackLib"] = lib

local function tableLength(values)
    local count = 0
    for _ in pairs(values or {}) do
        count = count + 1
    end
    return count
end

local function installBaseGlobals(opts)
    opts = opts or {}

    CurrentRun = opts.CurrentRun
    rom.game.CurrentRun = CurrentRun
    WeaponShopItemData = deepCopy(opts.WeaponShopItemData or {
        ToolExorcismBook2 = { ElementChance = 0.25 },
        ToolShovel2 = { ElementChance = 0.25 },
        ToolPickaxe2 = { ElementChance = 0.25 },
        ToolFishingRod2 = { ElementChance = 0.25 },
    })
    NamedRequirementsData = deepCopy(opts.NamedRequirementsData or {
        SpellDropRequirements = {},
        HermesUpgradeRequirements = {},
        HammerLootRequirements = {},
    })
    LootData = deepCopy(opts.LootData or {
        AphroditeUpgrade = { GodLoot = true },
        ApolloUpgrade = { GodLoot = true },
        AresUpgrade = { GodLoot = true },
        DemeterUpgrade = { GodLoot = true },
        HephaestusUpgrade = { GodLoot = true },
        HeraUpgrade = { GodLoot = true },
        HestiaUpgrade = { GodLoot = true },
        PoseidonUpgrade = { GodLoot = true },
        ZeusUpgrade = { GodLoot = true },
        HermesUpgrade = { GodLoot = false },
        WeaponUpgrade = {},
    })

    GetEligibleLootNames = opts.GetEligibleLootNames or function()
        return {
            "ApolloUpgrade",
            "ZeusUpgrade",
            "HermesUpgrade",
        }
    end
    ReachedMaxGods = opts.ReachedMaxGods or function()
        return false
    end
    GiveLoot = opts.GiveLoot or function(args)
        return args
    end
    SpawnRoomReward = opts.SpawnRoomReward or function(_, args)
        return args
    end
    GetInteractedGodsThisRun = opts.GetInteractedGodsThisRun or function()
        return {}
    end
    TableLength = tableLength
end

local function applyOverrides(target, overrides)
    for key, value in pairs(overrides or {}) do
        target[key] = value
    end
end

local function getLiveStore(liveModule)
    local registry = AdamantModpackLib_Runtime and AdamantModpackLib_Runtime.registry
    local modules = registry and registry.modules
    local records = modules and modules.records
    local record = records and records[liveModule]
    return record and record.store or nil
end

function ResetGodPoolHarness(opts)
    opts = opts or {}
    local pluginGuid = opts.pluginGuid or "adamantRunDirector-GodPool:test"
    registeredWraps = {}
    installBaseGlobals(opts)

    local data = dofile("src/mods/data.lua")
    local runStateCacheName = "RunState"
    local logic = import("mods/logic.lua", nil, {
        godList = data.godList,
        lootKeyLookup = data.lootKeyLookup,
        godLookup = data.godLookup,
        runStateCacheName = runStateCacheName,
    })
    local config = dofile("src/config.lua")
    applyOverrides(config, opts.config)

    local module = lib.createModule({
        pluginGuid = pluginGuid,
        config = config,
        modpack = "run-director",
        id = "GodPool",
        name = "God Pool",
        tooltip = "Control which gods enter the run, first-room hammer behavior, and pool support rules.",
    })
    module.data.define(data.buildStorage())
    logic.defineCache(module)
    if opts.publishGodAvailability then
        logic.attachShared(module)
        logic.attachActivation(module)
        logic.attachCommit(module)
    end
    module.ui.tab(function() end)
    module.ui.quickContent(function() end)
    logic.attachMutation(module)
    if opts.registerHooks then
        logic.attachHooks(module)
    end
    module.activate()
    local liveModule = lib.createFrameworkRuntime("adamant-ModpackFramework").modules.getLiveModule(pluginGuid)
    local store = getLiveStore(liveModule)

    return {
        data = data,
        logic = logic,
        config = config,
        store = store,
        runtime = {
            data = store,
        },
        authorHost = module,
        liveModule = liveModule,
        wrappers = registeredWraps,
    }
end
