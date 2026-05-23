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

local MAX_GODS_DROPDOWN_OPTS = {
    label = "Max Gods Per Run",
    values = { 1, 2, 3, 4, 5, 6, 7, 8, 9 },
    controlGap = 20,
    controlWidth = 60,
}

local GOD_CHECKBOX_OPTS = {
    AphroditeEnabled = { label = "Aphrodite", color = COLORS.AphroditeEnabled },
    ApolloEnabled = { label = "Apollo", color = COLORS.ApolloEnabled },
    AresEnabled = { label = "Ares", color = COLORS.AresEnabled },
    DemeterEnabled = { label = "Demeter", color = COLORS.DemeterEnabled },
    HephaestusEnabled = { label = "Hephaestus", color = COLORS.HephaestusEnabled },
    HeraEnabled = { label = "Hera", color = COLORS.HeraEnabled },
    HestiaEnabled = { label = "Hestia", color = COLORS.HestiaEnabled },
    PoseidonEnabled = { label = "Poseidon", color = COLORS.PoseidonEnabled },
    ZeusEnabled = { label = "Zeus", color = COLORS.ZeusEnabled },
}

local KEEPSAKE_ADDS_GOD_OPTS = {
    label = "God Keepsakes Add to The Pool",
}

local PREVENT_EARLY_SELENE_HERMES_OPTS = {
    label = "Prevent Early Selene/Hermes",
}

local BOOST_ELEMENT_GATHERING_OPTS = {
    label = "Guarantee Element from Gathering Tool",
}

local FORCE_HAMMER_FIRST_ROOM_OPTS = {
    label = "Force Hammer First Room",
}

local QUICK_RESET_ALL_CONFIRM_OPTS = {
    confirmLabel = "Confirm Reset All",
}

local function DrawSectionHeading(draw, text)
    draw.widgets.text(text)
    draw.widgets.separator()
end

function ui.drawTab(draw, state)
    local imgui = draw.imgui
    local widgets = draw.widgets

    DrawSectionHeading(draw, "God Pool")

    widgets.dropdown(state.get("MaxGodsPerRun"), MAX_GODS_DROPDOWN_OPTS)

    widgets.checkbox(state.get("AphroditeEnabled"), GOD_CHECKBOX_OPTS.AphroditeEnabled)
    imgui.SameLine()
    imgui.SetCursorPosX(150)
    widgets.checkbox(state.get("ApolloEnabled"), GOD_CHECKBOX_OPTS.ApolloEnabled)
    imgui.SameLine()
    imgui.SetCursorPosX(300)
    widgets.checkbox(state.get("AresEnabled"), GOD_CHECKBOX_OPTS.AresEnabled)
    widgets.checkbox(state.get("DemeterEnabled"), GOD_CHECKBOX_OPTS.DemeterEnabled)
    imgui.SameLine()
    imgui.SetCursorPosX(150)
    widgets.checkbox(state.get("HephaestusEnabled"), GOD_CHECKBOX_OPTS.HephaestusEnabled)
    imgui.SameLine()
    imgui.SetCursorPosX(300)
    widgets.checkbox(state.get("HeraEnabled"), GOD_CHECKBOX_OPTS.HeraEnabled)
    widgets.checkbox(state.get("HestiaEnabled"), GOD_CHECKBOX_OPTS.HestiaEnabled)
    imgui.SameLine()
    imgui.SetCursorPosX(150)
    widgets.checkbox(state.get("PoseidonEnabled"), GOD_CHECKBOX_OPTS.PoseidonEnabled)
    imgui.SameLine()
    imgui.SetCursorPosX(300)
    widgets.checkbox(state.get("ZeusEnabled"), GOD_CHECKBOX_OPTS.ZeusEnabled)

    imgui.Spacing()
    DrawSectionHeading(draw, "Options")

    widgets.checkbox(state.get("KeepsakeAddsGod"), KEEPSAKE_ADDS_GOD_OPTS)
    widgets.checkbox(state.get("PreventEarlySeleneHermes"), PREVENT_EARLY_SELENE_HERMES_OPTS)
    widgets.checkbox(state.get("BoostElementGathering"), BOOST_ELEMENT_GATHERING_OPTS)
    widgets.checkbox(state.get("PrioritizeHammerFirstRoomEnabled"), FORCE_HAMMER_FIRST_ROOM_OPTS)
end

function ui.drawQuickContent(draw, state, actions)
    local imgui = draw.imgui

    draw.widgets.checkbox(state.get("PrioritizeHammerFirstRoomEnabled"), FORCE_HAMMER_FIRST_ROOM_OPTS)

    imgui.SameLine()
    imgui.SetCursorPosX(imgui.GetCursorPosX() + 50)

    QUICK_RESET_ALL_CONFIRM_OPTS.action = actions.get("resetAll")
    draw.widgets.confirmButton("god_pool_quick_reset_all", "Reset All", QUICK_RESET_ALL_CONFIRM_OPTS)
end

function ui.bind()
    return ui
end

return ui
