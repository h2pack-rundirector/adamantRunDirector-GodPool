local GOD_AVAILABILITY_CACHE = "run-director.god-availability"
local RUN_STATE_CACHE = "RunState"
local GOD_AVAILABILITY_REF = "GodAvailability"
local cache = {}
local logic
local godList

function cache.runStateName()
    return RUN_STATE_CACHE
end

function cache.buildDeclarations()
    return {
        [RUN_STATE_CACHE] = {
            domain = "currentRun",
            key = "run",
            factory = function()
                return {
                    EnabledGodsOverride = {},
                    MaxGodsPerRunOverride = nil,
                }
            end,
        },
    }
end

function cache.registerShared(host)
    host.shared.data.owner(GOD_AVAILABILITY_REF, {
        id = GOD_AVAILABILITY_CACHE,
        default = {
            active = false,
            available = {},
        },
    })
end

function cache.writeGodAvailability(store)
    if not store or not store.cache then
        return false
    end
    local available = {}
    for _, god in ipairs(godList or {}) do
        available[god.key] = logic.isGodEnabledInPool(god.key, store) ~= false
    end
    store.shared.set(GOD_AVAILABILITY_REF, {
        active = true,
        available = available,
    })
    return true
end

function cache.bind(deps)
    logic = deps.logic
    godList = deps.godList
    return cache
end

return cache
