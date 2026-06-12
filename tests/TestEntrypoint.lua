local lu = require("luaunit")
local function loadModpackToolsTest(name)
    local candidates = {
        (os.getenv("MODPACK_TOOLS_DIR") or ".modpacktools") .. "/tests/" .. name,
        "../../ModpackTools/tests/" .. name,
    }

    local failures = {}
    for _, path in ipairs(candidates) do
        local ok, result = pcall(dofile, path)
        if ok then
            return result
        end
        failures[#failures + 1] = tostring(result)
    end
    error("unable to load ModpackTools test helper: " .. table.concat(failures, "; "), 2)
end

local harness = loadModpackToolsTest("module_entrypoint_harness.lua")

TestEntrypoint = {}

local function configureGodPoolEnv(env)
    env.rom.game.Color = harness.makeColorTable()
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

function TestEntrypoint:testMainLuaBootsRealModule()
    local boot = harness.bootModule({
        pluginGuid = "adamantRunDirector-GodPool",
        moduleSrcDir = "src",
        configureEnv = configureGodPoolEnv,
    })

    lu.assertNotNil(boot.liveModule)
    lu.assertEquals(boot.liveModule.getOwnerId(), "adamantRunDirector-GodPool")
    lu.assertEquals(boot.liveModule.getModuleId(), "GodPool")
    lu.assertEquals(boot.liveModule.getPackId(), "run-director")
    lu.assertEquals(#boot.callbacks.imgui, 1)
    lu.assertEquals(#boot.callbacks.menuBar, 2)
end
