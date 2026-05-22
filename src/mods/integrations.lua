local GOD_AVAILABILITY_INTEGRATION = "run-director.god-availability"
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

function integrations.registerProvider(host)
    host.integrations.register(GOD_AVAILABILITY_INTEGRATION, {
        providerId = MODULE_ID,
        methods = {
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
    })
end

function integrations.bind(deps)
    logic = deps.logic
    return integrations
end

return integrations
