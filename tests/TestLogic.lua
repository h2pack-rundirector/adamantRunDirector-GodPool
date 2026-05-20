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

    local okApply, applyErr = harness.liveHost.applyMutation()
    lu.assertTrue(okApply, tostring(applyErr))

    lu.assertEquals(WeaponShopItemData.ToolExorcismBook2.ElementChance, 1.0)
    lu.assertEquals(WeaponShopItemData.ToolShovel2.ElementChance, 1.0)
    lu.assertEquals(WeaponShopItemData.ToolPickaxe2.ElementChance, 1.0)
    lu.assertEquals(WeaponShopItemData.ToolFishingRod2.ElementChance, 1.0)
    lu.assertEquals(#NamedRequirementsData.SpellDropRequirements, 1)
    lu.assertEquals(#NamedRequirementsData.HermesUpgradeRequirements, 1)
    lu.assertEquals(#NamedRequirementsData.HammerLootRequirements, 1)

    local okRevert, revertErr = harness.liveHost.revertMutation()
    lu.assertTrue(okRevert, tostring(revertErr))

    lu.assertEquals(WeaponShopItemData.ToolExorcismBook2.ElementChance, 0.25)
    lu.assertEquals(WeaponShopItemData.ToolShovel2.ElementChance, 0.25)
    lu.assertEquals(WeaponShopItemData.ToolPickaxe2.ElementChance, 0.25)
    lu.assertEquals(WeaponShopItemData.ToolFishingRod2.ElementChance, 0.25)
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

    local state = harness.logic.GetRunState(harness.authorHost)
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

function TestGodPoolLogic:testGodAvailabilityIntegrationReflectsModuleAndGodState()
    local config = allGodsDisabledExcept("Zeus")
    config.Enabled = true

    local harness = ResetGodPoolHarness({
        registerProvider = true,
        config = config,
    })

    local available = harness.authorHost.integrations.invoke(
        "run-director.god-availability",
        "isAvailable",
        true,
        "Apollo"
    )
    lu.assertFalse(available)

    local zeusAvailable = harness.authorHost.integrations.invoke(
        "run-director.god-availability",
        "isAvailable",
        false,
        "Zeus"
    )
    lu.assertTrue(zeusAvailable)
end
