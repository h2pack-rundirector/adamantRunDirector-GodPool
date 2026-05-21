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

local function DrawSectionHeading(draw, text)
    draw.widgets.text(text)
    draw.widgets.separator()
end

function ui.drawTab(draw, data)
    local imgui = draw.imgui
    local widgets = draw.widgets

    DrawSectionHeading(draw, "God Pool")

    widgets.dropdown(data.get("MaxGodsPerRun"), {
        label = "Max Gods Per Run",
        values = { 1, 2, 3, 4, 5, 6, 7, 8, 9 },
        controlGap = 20,
        controlWidth = 60,
    })

    widgets.checkbox(data.get("AphroditeEnabled"), { label = "Aphrodite", color = COLORS.AphroditeEnabled })
    imgui.SameLine()
    imgui.SetCursorPosX(150)
    widgets.checkbox(data.get("ApolloEnabled"), { label = "Apollo", color = COLORS.ApolloEnabled })
    imgui.SameLine()
    imgui.SetCursorPosX(300)
    widgets.checkbox(data.get("AresEnabled"), { label = "Ares", color = COLORS.AresEnabled })
    widgets.checkbox(data.get("DemeterEnabled"), { label = "Demeter", color = COLORS.DemeterEnabled })
    imgui.SameLine()
    imgui.SetCursorPosX(150)
    widgets.checkbox(data.get("HephaestusEnabled"), { label = "Hephaestus", color = COLORS.HephaestusEnabled })
    imgui.SameLine()
    imgui.SetCursorPosX(300)
    widgets.checkbox(data.get("HeraEnabled"), { label = "Hera", color = COLORS.HeraEnabled })
    widgets.checkbox(data.get("HestiaEnabled"), { label = "Hestia", color = COLORS.HestiaEnabled })
    imgui.SameLine()
    imgui.SetCursorPosX(150)
    widgets.checkbox(data.get("PoseidonEnabled"), { label = "Poseidon", color = COLORS.PoseidonEnabled })
    imgui.SameLine()
    imgui.SetCursorPosX(300)
    widgets.checkbox(data.get("ZeusEnabled"), { label = "Zeus", color = COLORS.ZeusEnabled })

    imgui.Spacing()
    DrawSectionHeading(draw, "Options")

    widgets.checkbox(data.get("KeepsakeAddsGod"), {
        label = "God Keepsakes Add to The Pool",
    })
    widgets.checkbox(data.get("PreventEarlySeleneHermes"), {
        label = "Prevent Early Selene/Hermes",
    })
    widgets.checkbox(data.get("BoostElementGathering"), {
        label = "Guarantee Element from Gathering Tool",
    })
    widgets.checkbox(data.get("PrioritizeHammerFirstRoomEnabled"), {
        label = "Force Hammer First Room",
    })
end

function ui.drawQuickContent(draw, data)
    local imgui = draw.imgui

    draw.widgets.checkbox(data.get("PrioritizeHammerFirstRoomEnabled"), {
        label = "Force Hammer First Room",
    })

    imgui.SameLine()
    imgui.SetCursorPosX(imgui.GetCursorPosX() + 50)

    draw.widgets.confirmButton("god_pool_quick_reset_all", "Reset All", {
        confirmLabel = "Confirm Reset All",
        onConfirm = function()
            data.resetToDefaults()
        end,
    })
end

function ui.bind()
    return ui
end

return ui
