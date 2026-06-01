local deps = ...

local pool = import("mods/logic/pool.lua", nil, {
    godLookup = deps.godLookup,
})
local runState = import("mods/logic/run_state.lua", nil, {
    runStateCacheName = deps.runStateCacheName,
})
local patches = import("mods/logic/patches.lua")
local hooks = import("mods/logic/hooks.lua", nil, {
    godList = deps.godList,
    lootKeyLookup = deps.lootKeyLookup,
    pool = pool,
    runState = runState,
})
local shared = import("mods/logic/shared.lua", nil, {
    godList = deps.godList,
    pool = pool,
})

local logic = {}

logic.GetRunState = runState.get
logic.isGodEnabledInPool = pool.isGodEnabledInPool
logic.registerCache = function(module)
    module.cache.define(runState.buildCacheDeclarations())
end
logic.registerActivation = function(module)
    module.onActivate(function(host, runtime)
        shared.publish(host, runtime)
    end)
end
logic.registerCommit = function(module)
    module.onCommit(function(host, runtime, commit)
        if commit.hadConfigChanges() then
            shared.publish(host, runtime)
        end
    end)
end
logic.registerMutation = function(module)
    module.mutation.patch(patches.buildPlan)
end
logic.registerShared = shared.register
logic.registerHooks = hooks.register

function logic.register(module)
    logic.registerCache(module)
    logic.registerShared(module)
    logic.registerActivation(module)
    logic.registerCommit(module)
    logic.registerMutation(module)
    logic.registerHooks(module)
end

return logic
