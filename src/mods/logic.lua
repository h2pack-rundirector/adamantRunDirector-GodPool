local internal = RunDirectorGodPool_Internal
local godList = internal.godList
local lootKeyLookup = internal.lootKeyLookup
local godLookup = internal.godLookup

function internal.GetRunState()
    if not CurrentRun then return nil end
    if not CurrentRun.RunDirector_GodPool_State then
        CurrentRun.RunDirector_GodPool_State = {
            EnabledGodsOverride = {},
            MaxGodsPerRunOverride = nil,
        }
    end
    return CurrentRun.RunDirector_GodPool_State
end

function internal.IsGodEnabledInPool(godKey, store)
    local god = godLookup[godKey]
    if not god then return true end
    if not store then return true end
    return store.read(god.alias) ~= false
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

function internal.BuildPatchPlan(plan, ...)
    local _, store = ...
    if store.read("BoostElementGathering") then
        plan:setMany(WeaponShopItemData.ToolExorcismBook2, { ElementChance = 1.0 })
        plan:setMany(WeaponShopItemData.ToolShovel2, { ElementChance = 1.0 })
        plan:setMany(WeaponShopItemData.ToolPickaxe2, { ElementChance = 1.0 })
        plan:setMany(WeaponShopItemData.ToolFishingRod2, { ElementChance = 1.0 })
    end

    if store.read("PreventEarlySeleneHermes") then
        for _, key in ipairs(PREVENT_EARLY_REQUIREMENT_KEYS) do
            plan:appendUnique(NamedRequirementsData, key, PREVENT_EARLY_REQUIREMENT)
        end
    end
end

function internal.RegisterHooks(host, store)
    lib.hooks.Wrap(internal, "GetEligibleLootNames", function(base, excludeLootNames)
        if not host.isEnabled() then return base(excludeLootNames) end

        local state = internal.GetRunState()
        if not state then return base(excludeLootNames) end
        state.MaxGodsPerRunOverride = state.MaxGodsPerRunOverride or store.read("MaxGodsPerRun")

        local eligible = base(excludeLootNames)
        local filtered = {}
        local overrides = state.EnabledGodsOverride or {}

        for _, lootName in ipairs(eligible) do
            if overrides[lootName] then
                table.insert(filtered, lootName)
            else
                local god = lootKeyLookup[lootName]
                if not god or internal.IsGodEnabledInPool(god.key, store) then
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
                if internal.IsGodEnabledInPool(god.key, store) and not excludeSet[god.lootKey] then
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

    lib.hooks.Wrap(internal, "ReachedMaxGods", function(base, excludedGods)
        if not host.isEnabled() then return base(excludedGods) end
        local state = internal.GetRunState()
        if not state then return base(excludedGods) end
        local maxGods = state.MaxGodsPerRunOverride or store.read("MaxGodsPerRun")
        local gods = {}
        for _, godName in pairs(excludedGods or {}) do gods[godName] = true end
        for _, godName in pairs(GetInteractedGodsThisRun() or {}) do gods[godName] = true end
        return TableLength(gods) >= maxGods
    end)

    lib.hooks.Wrap(internal, "GiveLoot", function(base, args)
        if not host.isEnabled() then return base(args) end
        local state = internal.GetRunState()
        if not state then return base(args) end

        local lootName = args.ForceLootName or args.Name
        if lootName and LootData[lootName] and LootData[lootName].GodLoot then
            local god = lootKeyLookup[lootName]
            local isDisabled = god and not internal.IsGodEnabledInPool(god.key, store)
            if isDisabled and store.read("KeepsakeAddsGod") then
                if not state.EnabledGodsOverride[lootName] then
                    state.EnabledGodsOverride[lootName] = true
                    state.MaxGodsPerRunOverride = (state.MaxGodsPerRunOverride or store.read("MaxGodsPerRun")) + 1
                end
            end
        end

        return base(args)
    end)

    lib.hooks.Wrap(internal, "SpawnRoomReward", function(base, eventSource, args)
        if host.isEnabled() and store.read("PrioritizeHammerFirstRoomEnabled") and
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
