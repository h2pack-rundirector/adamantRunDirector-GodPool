local internal = RunDirectorGodPool_Internal

local GOD_AVAILABILITY_INTEGRATION = "run-director.god-availability"
local MODULE_ID = "GodPool"

function internal.RegisterIntegrations(host, store)
    lib.integrations.register(GOD_AVAILABILITY_INTEGRATION, MODULE_ID, {
        isActive = function()
            return host.isEnabled()
        end,

        isAvailable = function(godKey)
            if not host.isEnabled() then
                return true
            end
            if internal.IsGodEnabledInPool then
                return internal.IsGodEnabledInPool(godKey, store) ~= false
            end
            return true
        end,
    })
end

return internal
