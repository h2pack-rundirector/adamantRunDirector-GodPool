local deps = ...
local godList = deps.godList
local lootKeyLookup = deps.lootKeyLookup
local pool = deps.pool
local runState = deps.runState

local hooks = {}

local function isEligibleGodLoot(lootName)
    local lootData = LootData[lootName]
    return lootData and not lootData.DebugOnly and lootData.GodLoot and
        IsGameStateEligible(lootData, lootData.GameStateRequirements)
end

function hooks.register(module)
    module.hooks.wrap("GetEligibleLootNames", function(host, runtime, base, excludeLootNames)
        if not host.isEnabled() then return base(excludeLootNames) end

        local data = runtime.data
        local state = runState.get(runtime)
        if not state then return base(excludeLootNames) end
        state.MaxGodsPerRunOverride = state.MaxGodsPerRunOverride or data.read("MaxGodsPerRun")

        local eligible = base(excludeLootNames)
        local filtered = {}
        local overrides = state.EnabledGodsOverride or {}

        for _, lootName in ipairs(eligible) do
            if overrides[lootName] then
                table.insert(filtered, lootName)
            else
                local god = lootKeyLookup[lootName]
                if not god or pool.isGodEnabledInPool(god.key, data) then
                    table.insert(filtered, lootName)
                end
            end
        end

        if #filtered == 0 then
            local excludeSet = {}
            for _, lootName in ipairs(excludeLootNames or {}) do
                excludeSet[lootName] = true
            end
            for _, god in ipairs(godList) do
                if pool.isGodEnabledInPool(god.key, data) and not excludeSet[god.lootKey] and
                    isEligibleGodLoot(god.lootKey) then
                    table.insert(filtered, god.lootKey)
                end
            end
            for lootName, enabled in pairs(overrides) do
                if enabled and not excludeSet[lootName] then
                    table.insert(filtered, lootName)
                end
            end
        end

        return filtered
    end)

    module.hooks.wrap("ReachedMaxGods", function(host, runtime, base, excludedGods)
        if not host.isEnabled() then return base(excludedGods) end
        local data = runtime.data
        local state = runState.get(runtime)
        if not state then return base(excludedGods) end
        local maxGods = state.MaxGodsPerRunOverride or data.read("MaxGodsPerRun")
        local gods = {}
        for _, godName in pairs(excludedGods or {}) do gods[godName] = true end
        for _, godName in pairs(GetInteractedGodsThisRun() or {}) do gods[godName] = true end
        return TableLength(gods) >= maxGods
    end)

    module.hooks.wrap("GiveLoot", function(host, runtime, base, args)
        if not host.isEnabled() then return base(args) end
        local data = runtime.data
        local state = runState.get(runtime)
        if not state then return base(args) end

        local lootName = args.ForceLootName or args.Name
        if lootName and LootData[lootName] and LootData[lootName].GodLoot then
            local god = lootKeyLookup[lootName]
            local isDisabled = god and not pool.isGodEnabledInPool(god.key, data)
            if isDisabled and data.read("KeepsakeAddsGod") then
                if not state.EnabledGodsOverride[lootName] then
                    state.EnabledGodsOverride[lootName] = true
                    state.MaxGodsPerRunOverride = (state.MaxGodsPerRunOverride or data.read("MaxGodsPerRun")) + 1
                end
            end
        end

        return base(args)
    end)

    module.hooks.wrap("SpawnRoomReward", function(host, runtime, base, eventSource, args)
        if host.isEnabled() and runtime.data.read("PrioritizeHammerFirstRoomEnabled") and
        CurrentRun and CurrentRun.CurrentRoom and CurrentRun.CurrentRoom.BiomeStartRoom then
            args = args or {}
            if args.WaitUntilPickup then
                args.RewardOverride = "WeaponUpgrade"
                args.LootName = nil
            end
        end
        return base(eventSource, args)
    end)
end

return hooks
