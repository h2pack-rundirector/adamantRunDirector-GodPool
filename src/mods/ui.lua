local ui = {}

local function BuildColor(colorKey)
    local color = game.Color[colorKey]
    return {
        color[1] / 255,
        color[2] / 255,
        color[3] / 255,
        color[4] / 255,
    }
end

local function BuildColors()
    return {
        AphroditeEnabled  = BuildColor("AphroditeVoice"),
        ApolloEnabled     = BuildColor("ApolloVoice"),
        AresEnabled       = BuildColor("AresVoice"),
        DemeterEnabled    = BuildColor("DemeterVoice"),
        HephaestusEnabled = BuildColor("HephaestusVoice"),
        HeraEnabled       = BuildColor("HeraDamage"),
        HestiaEnabled     = BuildColor("HestiaVoice"),
        PoseidonEnabled   = BuildColor("PoseidonVoice"),
        ZeusEnabled       = BuildColor("ZeusVoice"),
    }
end

local COLORS = BuildColors()

local function DrawSectionHeading(imgui, text)
    lib.widgets.text(imgui, text)
    lib.widgets.separator(imgui)
end

function ui.drawTab(imgui, session)
    DrawSectionHeading(imgui, "God Pool")

    lib.widgets.dropdown(imgui, session, "MaxGodsPerRun", {
        label = "Max Gods Per Run",
        values = { 1, 2, 3, 4, 5, 6, 7, 8, 9 },
        controlGap = 20,
        controlWidth = 60,
    })

    lib.widgets.checkbox(imgui, session, "AphroditeEnabled", { label = "Aphrodite", color = COLORS.AphroditeEnabled })
    imgui.SameLine()
    imgui.SetCursorPosX(150)
    lib.widgets.checkbox(imgui, session, "ApolloEnabled", { label = "Apollo", color = COLORS.ApolloEnabled })
    imgui.SameLine()
    imgui.SetCursorPosX(300)
    lib.widgets.checkbox(imgui, session, "AresEnabled", { label = "Ares", color = COLORS.AresEnabled })
    lib.widgets.checkbox(imgui, session, "DemeterEnabled", { label = "Demeter", color = COLORS.DemeterEnabled })
    imgui.SameLine()
    imgui.SetCursorPosX(150)
    lib.widgets.checkbox(imgui, session, "HephaestusEnabled", { label = "Hephaestus", color = COLORS.HephaestusEnabled })
    imgui.SameLine()
    imgui.SetCursorPosX(300)
    lib.widgets.checkbox(imgui, session, "HeraEnabled", { label = "Hera", color = COLORS.HeraEnabled })
    lib.widgets.checkbox(imgui, session, "HestiaEnabled", { label = "Hestia", color = COLORS.HestiaEnabled })
    imgui.SameLine()
    imgui.SetCursorPosX(150)
    lib.widgets.checkbox(imgui, session, "PoseidonEnabled", { label = "Poseidon", color = COLORS.PoseidonEnabled })
    imgui.SameLine()
    imgui.SetCursorPosX(300)
    lib.widgets.checkbox(imgui, session, "ZeusEnabled", { label = "Zeus", color = COLORS.ZeusEnabled })

    imgui.Spacing()
    DrawSectionHeading(imgui, "Options")

    lib.widgets.checkbox(imgui, session, "KeepsakeAddsGod", {
        label = "God Keepsakes Add to The Pool",
    })
    lib.widgets.checkbox(imgui, session, "PreventEarlySeleneHermes", {
        label = "Prevent Early Selene/Hermes",
    })
    lib.widgets.checkbox(imgui, session, "BoostElementGathering", {
        label = "Guarantee Element from Gathering Tool",
    })
    lib.widgets.checkbox(imgui, session, "PrioritizeHammerFirstRoomEnabled", {
        label = "Force Hammer First Room",
    })
end

function ui.drawQuickContent(imgui, session)
    lib.widgets.checkbox(imgui, session, "PrioritizeHammerFirstRoomEnabled", {
        label = "Force Hammer First Room",
    })

    imgui.SameLine()
    imgui.SetCursorPosX(imgui.GetCursorPosX() + 50)

    lib.widgets.confirmButton(imgui, session, "god_pool_quick_reset_all", "Reset All", {
        confirmLabel = "Confirm Reset All",
        onConfirm = function()
            session.resetToDefaults()
        end,
    })
end

function ui.bind()
    return ui
end

return ui
