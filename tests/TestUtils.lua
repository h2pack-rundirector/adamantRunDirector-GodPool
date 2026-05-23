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

modutil = {
    once_loaded = {
        game = function() end,
    },
    mod = {
        Path = {
            Wrap = function(path, handler)
                registeredWraps[path] = handler
                local base = _G[path]
                _G[path] = function(...)
                    return handler(base, ...)
                end
            end,
        },
    },
}
rom.mods["SGG_Modding-ModUtil"] = modutil

import = function(path, fenv, ...)
    local chunk = assert(loadfile("../../adamant-ModpackLib/src/" .. path, "t", fenv or _ENV))
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

function ResetGodPoolHarness(opts)
    opts = opts or {}
    local pluginGuid = opts.pluginGuid or "adamant-RunDirector_GodPool:test"
    registeredWraps = {}
    installBaseGlobals(opts)

    local data = dofile("src/mods/data.lua")
    local logic = dofile("src/mods/logic.lua").bind(data)
    local cache = dofile("src/mods/cache.lua").bind({
        logic = logic,
        godList = data.godList,
    })
    local config = dofile("src/config.lua")
    applyOverrides(config, opts.config)

    local host, store = lib.createModule({
        pluginGuid = pluginGuid,
        config = config,
        modpack = "run-director",
        id = "GodPool",
        name = "God Pool",
        tooltip = "Control which gods enter the run, first-room hammer behavior, and pool support rules.",
        storage = data.buildStorage(),
        hashGroupPlan = data.buildHashGroupPlan(),
        onSettingsCommitted = function(host, settingsStore, commit)
            if opts.publishGodAvailability and commit.hadConfigChanges() then
                cache.writeGodAvailability(host, settingsStore)
            end
        end,
        drawTab = function() end,
        drawQuickContent = function() end,
    })
    host.mutation.patch(logic.buildPatchPlan)
    if opts.registerHooks then
        logic.registerHooks(host, store)
    end
    if opts.publishGodAvailability then
        cache.publishGodAvailability(host)
    end
    host.activate()
    if opts.publishGodAvailability then
        cache.writeGodAvailability(host, store)
    end
    local liveHost = lib.createFrameworkRuntime("adamant-ModpackFramework").modules.getLiveHost(pluginGuid)

    return {
        data = data,
        logic = logic,
        config = config,
        store = store,
        authorHost = host,
        liveHost = liveHost,
        wrappers = registeredWraps,
    }
end
