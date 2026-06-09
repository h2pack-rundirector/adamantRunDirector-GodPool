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

function TestGodPoolLogic:testPatchPlanAppliesAndRevertsRunDataMutations()
    local harness = ResetGodPoolHarness({
        config = {
            BoostElementGathering = true,
            PreventEarlySeleneHermes = true,
        },
    })

    local okApply, applyErr = harness.liveModule.applyMutation()
    lu.assertTrue(okApply, tostring(applyErr))

    lu.assertEquals(WeaponShopItemData.ToolExorcismBook2.ElementChance, 1.0)
    lu.assertEquals(WeaponShopItemData.ToolShovel2.ElementChance, 1.0)
    lu.assertEquals(WeaponShopItemData.ToolPickaxe2.ElementChance, 1.0)
    lu.assertEquals(WeaponShopItemData.ToolFishingRod2.ElementChance, 1.0)
    lu.assertEquals(#NamedRequirementsData.SpellDropRequirements, 1)
    lu.assertEquals(#NamedRequirementsData.HermesUpgradeRequirements, 1)
    lu.assertEquals(#NamedRequirementsData.HammerLootRequirements, 1)

    local okRevert, revertErr = harness.liveModule.revertMutation()
    lu.assertTrue(okRevert, tostring(revertErr))

    lu.assertEquals(WeaponShopItemData.ToolExorcismBook2.ElementChance, 0.5)
    lu.assertEquals(WeaponShopItemData.ToolShovel2.ElementChance, 0.5)
    lu.assertEquals(WeaponShopItemData.ToolPickaxe2.ElementChance, 0.5)
    lu.assertEquals(WeaponShopItemData.ToolFishingRod2.ElementChance, 0.5)
    lu.assertEquals(#NamedRequirementsData.SpellDropRequirements, 0)
    lu.assertEquals(#NamedRequirementsData.HermesUpgradeRequirements, 0)
    lu.assertEquals(#NamedRequirementsData.HammerLootRequirements, 0)
end

function TestGodPoolLogic:testEligibleLootFiltersDisabledGodsAndKeepsNonGodLoot()
    ResetGodPoolHarness({
        registerHooks = true,
        config = {
            Enabled = true,
            ApolloEnabled = false,
            ZeusEnabled = true,
        },
        CurrentRun = {},
        GetEligibleLootNames = function()
            return {
                "ApolloUpgrade",
                "ZeusUpgrade",
                "HermesUpgrade",
            }
        end,
    })

    lu.assertEquals(GetEligibleLootNames({}), {
        "ZeusUpgrade",
        "HermesUpgrade",
    })
end

function TestGodPoolLogic:testEligibleLootFallbackUsesEnabledGodsWhenFilterEmptiesPool()
    local config = allGodsDisabledExcept("Zeus")
    config.Enabled = true

    ResetGodPoolHarness({
        registerHooks = true,
        config = config,
        CurrentRun = {},
        GetEligibleLootNames = function()
            return {
                "ApolloUpgrade",
            }
        end,
    })

    lu.assertEquals(GetEligibleLootNames({}), {
        "ZeusUpgrade",
    })
end

function TestGodPoolLogic:testEligibleLootFallbackPreservesBaseGameStateRequirements()
    local config = allGodsDisabledExcept("Zeus")
    config.Enabled = true

    ResetGodPoolHarness({
        registerHooks = true,
        config = config,
        CurrentRun = {},
        LootData = {
            ApolloUpgrade = { GodLoot = true },
            ZeusUpgrade = { GodLoot = true, GameStateRequirements = "blocked" },
        },
        GetEligibleLootNames = function()
            return {
                "ApolloUpgrade",
            }
        end,
        IsGameStateEligible = function(_, requirements)
            return requirements ~= "blocked"
        end,
    })

    lu.assertEquals(GetEligibleLootNames({}), {})
end

function TestGodPoolLogic:testKeepsakeCanTemporarilyAddDisabledGodToPool()
    local config = allGodsDisabledExcept("Zeus")
    config.Enabled = true
    config.KeepsakeAddsGod = true
    config.MaxGodsPerRun = 2

    local harness = ResetGodPoolHarness({
        registerHooks = true,
        config = config,
        CurrentRun = {},
        GetEligibleLootNames = function()
            return {
                "ApolloUpgrade",
            }
        end,
    })

    GiveLoot({ ForceLootName = "ApolloUpgrade" })

    local state = harness.logic.GetRunState(harness.runtime)
    lu.assertEquals(state.EnabledGodsOverride.ApolloUpgrade, true)
    lu.assertEquals(state.MaxGodsPerRunOverride, 3)
    lu.assertEquals(GetEligibleLootNames({}), {
        "ApolloUpgrade",
    })
end

function TestGodPoolLogic:testReachedMaxGodsUsesConfiguredLimit()
    ResetGodPoolHarness({
        registerHooks = true,
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

    lu.assertTrue(ReachedMaxGods({}))
end

function TestGodPoolLogic:testFirstRoomHammerOverrideMutatesRewardArgsOnlyWhenEnabled()
    ResetGodPoolHarness({
        registerHooks = true,
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
    SpawnRoomReward(nil, args)

    lu.assertEquals(args.RewardOverride, "WeaponUpgrade")
    lu.assertNil(args.LootName)
end

function TestGodPoolLogic:testGodAvailabilitySharedDataReflectsModuleAndGodState()
    local config = allGodsDisabledExcept("Zeus")
    config.Enabled = true

    local harness = ResetGodPoolHarness({
        pluginGuid = "adamantRunDirector-GodPool",
        publishGodAvailability = true,
        config = config,
    })

    local snapshot = harness.store.shared.read("GodAvailability")
    lu.assertTrue(snapshot.active)
    lu.assertFalse(snapshot.available.Apollo)
    lu.assertTrue(snapshot.available.Zeus)
end
