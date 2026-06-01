local deps = ...
local godList = deps.godList
local pool = deps.pool

local GOD_AVAILABILITY_CACHE = "run-director.god-availability"
local GOD_AVAILABILITY_REF = "GodAvailability"

local shared = {}

local function buildGodAvailabilityFromRuntime(runtimeData)
    local available = {}
    for _, god in ipairs(godList or {}) do
        available[god.key] = pool.isGodEnabledInPool(god.key, runtimeData) ~= false
    end
    return {
        active = true,
        available = available,
    }
end

function shared.register(module)
    module.shared.data.owner(GOD_AVAILABILITY_REF, {
        id = GOD_AVAILABILITY_CACHE,
        default = {
            active = false,
            available = {},
        },
    })
end

function shared.publish(_, runtime)
    if not runtime or not runtime.shared then
        return false
    end
    runtime.shared.set(GOD_AVAILABILITY_REF, buildGodAvailabilityFromRuntime(runtime.data))
    return true
end

return shared
