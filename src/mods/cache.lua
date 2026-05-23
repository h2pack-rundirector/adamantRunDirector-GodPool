local GOD_AVAILABILITY_CACHE = "run-director.god-availability"
local DEFAULT_AVAILABILITY = {
    active = false,
    available = {},
}
local cache = {}
local logic
local godList

local function BuildAvailabilitySnapshot(read)
    local available = {}
    for _, god in ipairs(godList or {}) do
        available[god.key] = logic.isGodEnabledInPool(god.key, read) ~= false
    end
    return {
        active = true,
        available = available,
    }
end

function cache.publishGodAvailability(host)
    host.cache.shared.publish(GOD_AVAILABILITY_CACHE, {
        default = DEFAULT_AVAILABILITY,
    })
end

function cache.writeGodAvailability(source, read)
    return source.cache.shared.write(GOD_AVAILABILITY_CACHE, BuildAvailabilitySnapshot(read))
end

function cache.bind(deps)
    logic = deps.logic
    godList = deps.godList
    return cache
end

return cache
