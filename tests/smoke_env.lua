local function configureGodPoolEnv(env)
    env.CurrentRun = nil
    env.WeaponShopItemData = {
        ToolExorcismBook2 = { ElementChance = 0.25 },
        ToolShovel2 = { ElementChance = 0.25 },
        ToolPickaxe2 = { ElementChance = 0.25 },
        ToolFishingRod2 = { ElementChance = 0.25 },
    }
    env.NamedRequirementsData = {
        SpellDropRequirements = {},
        HermesUpgradeRequirements = {},
        HammerLootRequirements = {},
    }
    env.LootData = {
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
    }
    env.GetEligibleLootNames = function()
        return {
            "ApolloUpgrade",
            "ZeusUpgrade",
            "HermesUpgrade",
        }
    end
    env.ReachedMaxGods = function()
        return false
    end
    env.GiveLoot = function(args)
        return args
    end
    env.SpawnRoomReward = function(_, args)
        return args
    end
    env.GetInteractedGodsThisRun = function()
        return {}
    end
    env.TableLength = function(values)
        local count = 0
        for _ in pairs(values or {}) do
            count = count + 1
        end
        return count
    end
end

return configureGodPoolEnv
