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

import = function(path, fenv, ...)
    local localPath = "src/" .. path
    local chunk = assert(loadfile(localPath, "t", fenv or _ENV))
    return chunk(...)
end

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
        ToolExorcismBook2 = { ElementChance = 0.5 },
        ToolShovel2 = { ElementChance = 0.5 },
        ToolPickaxe2 = { ElementChance = 0.5 },
        ToolFishingRod2 = { ElementChance = 0.5 },
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

    GetInteractedGodsThisRun = opts.GetInteractedGodsThisRun or function()
        return {}
    end
    IsGameStateEligible = opts.IsGameStateEligible or function()
        return true
    end
    TableLength = tableLength
end

local function applyOverrides(target, overrides)
    for key, value in pairs(overrides or {}) do
        target[key] = value
    end
end

local function makeRuntime(config, state)
    local values = {}
    applyOverrides(values, config)
    local sharedValues = {}

    return {
        data = {
            read = function(key)
                return values[key]
            end,
            cache = {
                currentRun = {
                    get = function()
                        return state
                    end,
                },
            },
        },
        shared = {
            set = function(key, value)
                sharedValues[key] = value
            end,
            read = function(key)
                return sharedValues[key]
            end,
        },
    }
end

local function makeHost(enabled)
    return {
        isEnabled = function()
            return enabled ~= false
        end,
    }
end

local function makeHookHost()
    local wraps = {}
    return {
        wraps = wraps,
        hooks = {
            wrap = function(name, callback)
                wraps[name] = callback
            end,
        },
    }
end

function MakeGodPoolPlan()
    local plan = {
        setManyOps = {},
        appendUniqueOps = {},
    }

    function plan:setMany(target, fields)
        table.insert(self.setManyOps, {
            target = target,
            fields = fields,
        })
        for key, value in pairs(fields) do
            target[key] = value
        end
    end

    function plan:appendUnique(target, key, value)
        table.insert(self.appendUniqueOps, {
            target = target,
            key = key,
            value = value,
        })
        local list = target[key]
        for _, existing in ipairs(list) do
            if existing == value then
                return
            end
        end
        table.insert(list, value)
    end

    return plan
end

function ResetGodPoolLogicHarness(opts)
    opts = opts or {}
    installBaseGlobals(opts)

    local data = dofile("src/mods/data.lua")
    local runStateCacheName = "RunState"
    local pool = import("mods/logic/pool.lua", nil, {
        godLookup = data.godLookup,
    })
    local runState = import("mods/logic/run_state.lua", nil, {
        runStateCacheName = runStateCacheName,
    })
    local hooks = import("mods/logic/hooks.lua", nil, {
        godList = data.godList,
        lootKeyLookup = data.lootKeyLookup,
        pool = pool,
        runState = runState,
    })
    local patches = import("mods/logic/patches.lua")
    local shared = import("mods/shared/god_availability.lua", nil, {
        godList = data.godList,
        pool = pool,
    })
    local config = {}
    applyOverrides(config, opts.config)

    local state = opts.runState or {
        EnabledGodsOverride = {},
        MaxGodsPerRunOverride = nil,
    }
    local runtime = makeRuntime(config, state)
    local host = makeHost(config.Enabled ~= false)
    local hookHost = makeHookHost()
    hooks.register(hookHost)

    return {
        data = data,
        pool = pool,
        runState = runState,
        hooks = hooks,
        hookHandlers = hookHost.wraps,
        patches = patches,
        shared = shared,
        config = config,
        host = host,
        runtime = runtime,
        state = state,
    }
end
