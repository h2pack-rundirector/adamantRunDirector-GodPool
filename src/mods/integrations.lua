local GOD_AVAILABILITY_INTEGRATION = "run-director.god-availability"
local GOD_AVAILABILITY_CHANGED_EVENT = "availabilityChanged"
local MODULE_ID = "GodPool"
local GOD_AVAILABILITY_READS = {
    "AphroditeEnabled",
    "ApolloEnabled",
    "AresEnabled",
    "DemeterEnabled",
    "HephaestusEnabled",
    "HeraEnabled",
    "HestiaEnabled",
    "PoseidonEnabled",
    "ZeusEnabled",
}
local integrations = {}
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

function integrations.provideGodAvailability(host)
    host.integrations.provide(GOD_AVAILABILITY_INTEGRATION, {
        providerId = MODULE_ID,
        methods = {
            snapshot = {
                reads = GOD_AVAILABILITY_READS,
                handler = function(scope)
                    return BuildAvailabilitySnapshot(scope.read)
                end,
            },

            isActive = {
                handler = function()
                    return true
                end,
            },

            isAvailable = {
                reads = GOD_AVAILABILITY_READS,
                handler = function(scope, godKey)
                    if logic and logic.isGodEnabledInPool then
                        return logic.isGodEnabledInPool(godKey, scope.read) ~= false
                    end
                    return true
                end,
            },
        },
        events = {
            [GOD_AVAILABILITY_CHANGED_EVENT] = true,
        },
    })
end

function integrations.emitGodAvailabilityChanged(host, store)
    local emitted = host.integrations.emit(
        GOD_AVAILABILITY_INTEGRATION,
        GOD_AVAILABILITY_CHANGED_EVENT,
        BuildAvailabilitySnapshot(store)
    )
    return emitted
end

function integrations.bind(deps)
    logic = deps.logic
    godList = deps.godList
    return integrations
end

return integrations
