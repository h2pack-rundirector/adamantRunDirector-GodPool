local lu = require("luaunit")

TestGodPoolLogic = {}

local function allGodsDisabledExcept(enabledKey)
    local config = {
        AphroditeEnabled = false,
        ApolloEnabled = false,
        AresEnabled = false,
        DemeterEnabled = false,
        HephaestusEnabled = false,
        HeraEnabled = false,
        HestiaEnabled = false,
        PoseidonEnabled = false,
        ZeusEnabled = false,
    }
    if enabledKey then
        config[enabledKey .. "Enabled"] = true
    end
    return config
end

function TestGodPoolLogic:testPatchPlanAddsRunDataMutations()
    local harness = ResetGodPoolLogicHarness({
        config = {
            BoostElementGathering = true,
            PreventEarlySeleneHermes = true,
        },
    })
    local plan = MakeGodPoolPlan()

    harness.patches.buildPlan(harness.host, harness.runtime, plan)

    lu.assertEquals(WeaponShopItemData.ToolExorcismBook2.ElementChance, 1.0)
    lu.assertEquals(WeaponShopItemData.ToolShovel2.ElementChance, 1.0)
    lu.assertEquals(WeaponShopItemData.ToolPickaxe2.ElementChance, 1.0)
    lu.assertEquals(WeaponShopItemData.ToolFishingRod2.ElementChance, 1.0)
    lu.assertEquals(#NamedRequirementsData.SpellDropRequirements, 1)
    lu.assertEquals(#NamedRequirementsData.HermesUpgradeRequirements, 1)
    lu.assertEquals(#NamedRequirementsData.HammerLootRequirements, 1)
    lu.assertEquals(#plan.setManyOps, 4)
    lu.assertEquals(#plan.appendUniqueOps, 3)
end

function TestGodPoolLogic:testEligibleLootFiltersDisabledGodsAndKeepsNonGodLoot()
    local harness = ResetGodPoolLogicHarness({
        config = {
            Enabled = true,
            ApolloEnabled = false,
            ZeusEnabled = true,
        },
        CurrentRun = {},
    })

    local result = harness.hookHandlers.GetEligibleLootNames(harness.host, harness.runtime, function()
        return {
            "ApolloUpgrade",
            "ZeusUpgrade",
            "HermesUpgrade",
        }
    end, {})

    lu.assertEquals(result, {
        "ZeusUpgrade",
        "HermesUpgrade",
    })
end

function TestGodPoolLogic:testEligibleLootFallbackUsesEnabledGodsWhenFilterEmptiesPool()
    local config = allGodsDisabledExcept("Zeus")
    config.Enabled = true

    local harness = ResetGodPoolLogicHarness({
        config = config,
        CurrentRun = {},
    })

    local result = harness.hookHandlers.GetEligibleLootNames(harness.host, harness.runtime, function()
        return {
            "ApolloUpgrade",
        }
    end, {})

    lu.assertEquals(result, {
        "ZeusUpgrade",
    })
end

function TestGodPoolLogic:testEligibleLootFallbackPreservesBaseGameStateRequirements()
    local config = allGodsDisabledExcept("Zeus")
    config.Enabled = true

    local harness = ResetGodPoolLogicHarness({
        config = config,
        CurrentRun = {},
        LootData = {
            ApolloUpgrade = { GodLoot = true },
            ZeusUpgrade = { GodLoot = true, GameStateRequirements = "blocked" },
        },
        IsGameStateEligible = function(_, requirements)
            return requirements ~= "blocked"
        end,
    })

    local result = harness.hookHandlers.GetEligibleLootNames(harness.host, harness.runtime, function()
        return {
            "ApolloUpgrade",
        }
    end, {})

    lu.assertEquals(result, {})
end

function TestGodPoolLogic:testKeepsakeCanTemporarilyAddDisabledGodToPool()
    local config = allGodsDisabledExcept("Zeus")
    config.Enabled = true
    config.KeepsakeAddsGod = true
    config.MaxGodsPerRun = 2

    local harness = ResetGodPoolLogicHarness({
        config = config,
        CurrentRun = {},
    })

    harness.hookHandlers.GiveLoot(harness.host, harness.runtime, function(args)
        return args
    end, { ForceLootName = "ApolloUpgrade" })

    local state = harness.runState.get(harness.runtime)
    lu.assertEquals(state.EnabledGodsOverride.ApolloUpgrade, true)
    lu.assertEquals(state.MaxGodsPerRunOverride, 3)

    local result = harness.hookHandlers.GetEligibleLootNames(harness.host, harness.runtime, function()
        return {
            "ApolloUpgrade",
        }
    end, {})

    lu.assertEquals(result, {
        "ApolloUpgrade",
    })
end

function TestGodPoolLogic:testReachedMaxGodsUsesConfiguredLimit()
    local harness = ResetGodPoolLogicHarness({
        config = {
            Enabled = true,
            MaxGodsPerRun = 2,
        },
        CurrentRun = {},
        GetInteractedGodsThisRun = function()
            return {
                "ApolloUpgrade",
                "ZeusUpgrade",
            }
        end,
    })

    local result = harness.hookHandlers.ReachedMaxGods(harness.host, harness.runtime, function()
        return false
    end, {})

    lu.assertTrue(result)
end

function TestGodPoolLogic:testFirstRoomHammerOverrideMutatesRewardArgsOnlyWhenEnabled()
    local harness = ResetGodPoolLogicHarness({
        config = {
            Enabled = true,
            PrioritizeHammerFirstRoomEnabled = true,
        },
        CurrentRun = {
            CurrentRoom = {
                BiomeStartRoom = true,
            },
        },
    })

    local args = {
        WaitUntilPickup = true,
        LootName = "ZeusUpgrade",
    }
    harness.hookHandlers.SpawnRoomReward(harness.host, harness.runtime, function(_, rewardArgs)
        return rewardArgs
    end, nil, args)

    lu.assertEquals(args.RewardOverride, "WeaponUpgrade")
    lu.assertNil(args.LootName)
end

function TestGodPoolLogic:testGodAvailabilitySharedDataReflectsModuleAndGodState()
    local config = allGodsDisabledExcept("Zeus")
    config.Enabled = true

    local harness = ResetGodPoolLogicHarness({
        config = config,
    })

    local snapshot = harness.shared.buildSnapshot(harness.runtime.data)
    lu.assertTrue(snapshot.active)
    lu.assertFalse(snapshot.available.Apollo)
    lu.assertTrue(snapshot.available.Zeus)
end
