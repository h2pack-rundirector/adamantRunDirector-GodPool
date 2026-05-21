local logic = {}

local godList
local lootKeyLookup
local godLookup

local function ReadStore(store, alias)
    return store.get(alias):read()
end

local function GetRunState(host)
    if not host then return nil end
    return host.cache.currentRun.get("run", function()
        return {
            EnabledGodsOverride = {},
            MaxGodsPerRunOverride = nil,
        }
    end)
end

logic.GetRunState = GetRunState

function logic.isGodEnabledInPool(godKey, store)
    local god = godLookup[godKey]
    if not god then return true end
    if not store then return true end
    return ReadStore(store, god.alias) ~= false
end

local PREVENT_EARLY_REQUIREMENT = {
    Path = { "CurrentRun", "LootTypeHistory" },
    CountOf = {
        "AphroditeUpgrade", "ApolloUpgrade", "DemeterUpgrade",
        "HephaestusUpgrade", "HestiaUpgrade", "HeraUpgrade",
        "PoseidonUpgrade", "ZeusUpgrade", "AresUpgrade",
    },
    Comparison = ">=",
    Value = 1,
}

local PREVENT_EARLY_REQUIREMENT_KEYS = {
    "SpellDropRequirements",
    "HermesUpgradeRequirements",
    "HammerLootRequirements",
}

function logic.buildPatchPlan(plan, _, store)
    if ReadStore(store, "BoostElementGathering") then
        plan:setMany(WeaponShopItemData.ToolExorcismBook2, { ElementChance = 1.0 })
        plan:setMany(WeaponShopItemData.ToolShovel2, { ElementChance = 1.0 })
        plan:setMany(WeaponShopItemData.ToolPickaxe2, { ElementChance = 1.0 })
        plan:setMany(WeaponShopItemData.ToolFishingRod2, { ElementChance = 1.0 })
    end

    if ReadStore(store, "PreventEarlySeleneHermes") then
        for _, key in ipairs(PREVENT_EARLY_REQUIREMENT_KEYS) do
            plan:appendUnique(NamedRequirementsData, key, PREVENT_EARLY_REQUIREMENT)
        end
    end
end

function logic.registerHooks(host, store)
    host.hooks.wrap("GetEligibleLootNames", function(base, excludeLootNames)
        if not host.isEnabled() then return base(excludeLootNames) end

        local state = GetRunState(host)
        if not state then return base(excludeLootNames) end
        state.MaxGodsPerRunOverride = state.MaxGodsPerRunOverride or ReadStore(store, "MaxGodsPerRun")

        local eligible = base(excludeLootNames)
        local filtered = {}
        local overrides = state.EnabledGodsOverride or {}

        for _, lootName in ipairs(eligible) do
            if overrides[lootName] then
                table.insert(filtered, lootName)
            else
                local god = lootKeyLookup[lootName]
                if not god or logic.isGodEnabledInPool(god.key, store) then
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
                if logic.isGodEnabledInPool(god.key, store) and not excludeSet[god.lootKey] then
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

    host.hooks.wrap("ReachedMaxGods", function(base, excludedGods)
        if not host.isEnabled() then return base(excludedGods) end
        local state = GetRunState(host)
        if not state then return base(excludedGods) end
        local maxGods = state.MaxGodsPerRunOverride or ReadStore(store, "MaxGodsPerRun")
        local gods = {}
        for _, godName in pairs(excludedGods or {}) do gods[godName] = true end
        for _, godName in pairs(GetInteractedGodsThisRun() or {}) do gods[godName] = true end
        return TableLength(gods) >= maxGods
    end)

    host.hooks.wrap("GiveLoot", function(base, args)
        if not host.isEnabled() then return base(args) end
        local state = GetRunState(host)
        if not state then return base(args) end

        local lootName = args.ForceLootName or args.Name
        if lootName and LootData[lootName] and LootData[lootName].GodLoot then
            local god = lootKeyLookup[lootName]
            local isDisabled = god and not logic.isGodEnabledInPool(god.key, store)
            if isDisabled and ReadStore(store, "KeepsakeAddsGod") then
                if not state.EnabledGodsOverride[lootName] then
                    state.EnabledGodsOverride[lootName] = true
                    state.MaxGodsPerRunOverride = (state.MaxGodsPerRunOverride or ReadStore(store, "MaxGodsPerRun")) + 1
                end
            end
        end

        return base(args)
    end)

    host.hooks.wrap("SpawnRoomReward", function(base, eventSource, args)
        if host.isEnabled() and ReadStore(store, "PrioritizeHammerFirstRoomEnabled") and
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

function logic.bind(data)
    godList = data.godList
    lootKeyLookup = data.lootKeyLookup
    godLookup = data.godLookup
    return logic
end

return logic
