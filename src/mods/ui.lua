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

local function DrawSectionHeading(ctx, text)
    ctx.widgets.text(text)
    ctx.widgets.separator()
end

function ui.drawTab(ctx)
    local imgui = ctx.imgui
    local widgets = ctx.widgets

    DrawSectionHeading(ctx, "God Pool")

    widgets.dropdown("MaxGodsPerRun", {
        label = "Max Gods Per Run",
        values = { 1, 2, 3, 4, 5, 6, 7, 8, 9 },
        controlGap = 20,
        controlWidth = 60,
    })

    widgets.checkbox("AphroditeEnabled", { label = "Aphrodite", color = COLORS.AphroditeEnabled })
    imgui.SameLine()
    imgui.SetCursorPosX(150)
    widgets.checkbox("ApolloEnabled", { label = "Apollo", color = COLORS.ApolloEnabled })
    imgui.SameLine()
    imgui.SetCursorPosX(300)
    widgets.checkbox("AresEnabled", { label = "Ares", color = COLORS.AresEnabled })
    widgets.checkbox("DemeterEnabled", { label = "Demeter", color = COLORS.DemeterEnabled })
    imgui.SameLine()
    imgui.SetCursorPosX(150)
    widgets.checkbox("HephaestusEnabled", { label = "Hephaestus", color = COLORS.HephaestusEnabled })
    imgui.SameLine()
    imgui.SetCursorPosX(300)
    widgets.checkbox("HeraEnabled", { label = "Hera", color = COLORS.HeraEnabled })
    widgets.checkbox("HestiaEnabled", { label = "Hestia", color = COLORS.HestiaEnabled })
    imgui.SameLine()
    imgui.SetCursorPosX(150)
    widgets.checkbox("PoseidonEnabled", { label = "Poseidon", color = COLORS.PoseidonEnabled })
    imgui.SameLine()
    imgui.SetCursorPosX(300)
    widgets.checkbox("ZeusEnabled", { label = "Zeus", color = COLORS.ZeusEnabled })

    imgui.Spacing()
    DrawSectionHeading(ctx, "Options")

    widgets.checkbox("KeepsakeAddsGod", {
        label = "God Keepsakes Add to The Pool",
    })
    widgets.checkbox("PreventEarlySeleneHermes", {
        label = "Prevent Early Selene/Hermes",
    })
    widgets.checkbox("BoostElementGathering", {
        label = "Guarantee Element from Gathering Tool",
    })
    widgets.checkbox("PrioritizeHammerFirstRoomEnabled", {
        label = "Force Hammer First Room",
    })
end

function ui.drawQuickContent(ctx)
    local imgui = ctx.imgui

    ctx.widgets.checkbox("PrioritizeHammerFirstRoomEnabled", {
        label = "Force Hammer First Room",
    })

    imgui.SameLine()
    imgui.SetCursorPosX(imgui.GetCursorPosX() + 50)

    ctx.widgets.confirmButton("god_pool_quick_reset_all", "Reset All", {
        confirmLabel = "Confirm Reset All",
        onConfirm = function()
            ctx.session.resetToDefaults()
        end,
    })
end

function ui.bind()
    return ui
end

return ui
