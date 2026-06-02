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
local godAvailability = import("mods/shared/god_availability.lua", nil, {
    godList = deps.godList,
    pool = pool,
})

local logic = {}

logic.GetRunState = runState.get
logic.isGodEnabledInPool = pool.isGodEnabledInPool
logic.defineCache = function(module)
    module.cache.define(runState.buildCacheDeclarations())
end
logic.attachActivation = function(module)
    module.onActivate(function(host, runtime)
        godAvailability.publish(host, runtime)
    end)
end
logic.attachCommit = function(module)
    module.onCommit(function(host, runtime, commit)
        if commit.hadConfigChanges() then
            godAvailability.publish(host, runtime)
        end
    end)
end
logic.attachMutation = function(module)
    module.mutation.patch(patches.buildPlan)
end
logic.attachShared = godAvailability.attach
logic.attachHooks = hooks.register

return logic
