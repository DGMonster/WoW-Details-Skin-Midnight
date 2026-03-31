local MID = LibStub("AceAddon-3.0"):NewAddon("Details_MID", "AceConsole-3.0")
local LocDetails = _G.LibStub("AceLocale-3.0"):GetLocale("Details")
local LSM = LibStub("LibSharedMedia-3.0")

local skinName = "|cff8080ffMidnight|r"

local playerName = UnitName("player")
local debugMode = (playerName == "Zimtdev") or (playerName == "Zimtdevtwo") or (playerName == "Botlike")

local retail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local version = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata("Details_MID", "Version") or "dev"

local initialized = false
local augmentationHooked = false

function MID:Debug(...)
    if not debugMode then
        return
    end

    self:Print(...)
end

function MID:OnInitialize()
    self:Debug("MID:OnInitialize()")
end

function MID:OnEnable()
    self:Debug("MID:OnEnable()")
    self:RegisterSlashCommand()
end

function MID:OnDisable()
end

function MID:RegisterTextures()
    self:Debug("MID:RegisterTextures()")

    LSM:Register("statusbar", "MidnightHeader", [[Interface\AddOns\Details_MID\Textures\header.tga]])
    LSM:Register("statusbar", "MidnightBar", [[Interface\AddOns\Details_MID\Textures\bar.tga]])
    LSM:Register("statusbar", "MidnightBackground", [[Interface\AddOns\Details_MID\Textures\background.tga]])
end

MID:RegisterTextures()

local skinTable = {
    file = [[Interface\AddOns\Details\images\skins\flat_skin.blp]],
    author = "GrazyMonster",
    version = version,
    site = "https://github.com/DGMonster/WoW-Details-Skin-Midnight",
    desc = "Midnight Skin.",
    no_cache = true,

    micro_frames = {
        color = {1, 1, 1, 1},
        font = "Accidental Presidency",
        size = 10,
        textymod = 1,
    },

    can_change_alpha_head = true,
    icon_anchor_main = {-1, -5},
    icon_anchor_plugins = {-7, -13},
    icon_plugins_size = {19, 18},

    icon_point_anchor = {-37, 0},
    left_corner_anchor = {-107, 0},
    right_corner_anchor = {96, 0},
    icon_point_anchor_bottom = {-37, 12},
    left_corner_anchor_bottom = {-107, 0},
    right_corner_anchor_bottom = {96, 0},
    icon_on_top = true,
    icon_ignore_alpha = true,
    icon_titletext_position = {3, 3},

    instance_cprops = {
        titlebar_shown = true,
        titlebar_height = 32,
        titlebar_texture = "MidnightHeader",
        titlebar_texture_color = {1, 1, 1, 1},

        toolbar_side = 1,
        menu_anchor = {
            10,
            10,
            side = 2,
        },

        attribute_text = {
            enabled = true,
            shadow = false,
            side = 1,
            text_size = 13,
            custom_text = "{name}",
            text_face = "Friz Quadrata TT",
            anchor = {-4, 10},
            text_color = {
                NORMAL_FONT_COLOR.r,
                NORMAL_FONT_COLOR.g,
                NORMAL_FONT_COLOR.b,
                NORMAL_FONT_COLOR.a,
            },
            enable_custom_text = false,
            show_timer = true,
        },

        row_info = {
            texture_highlight = "Interface\\FriendsFrame\\UI-FriendsList-Highlight",
            fixed_text_color = {1, 1, 1},
            height = 28,
            row_offsets = {left = 29, right = -37, top = 0, bottom = 0},
            font_face_file = "Interface\\AddOns\\Details\\fonts\\Accidental Presidency.ttf",

            backdrop = {
                enabled = false,
                size = 12,
                color = {1, 1, 1, 1},
                texture = "Details BarBorder 2",
            },

            icon_file = "Interface\\AddOns\\Details_MID\\Textures\\ClassIconsMID",
            start_after_icon = false,

            textL_enable_custom_text = false,
            textR_enable_custom_text = false,
            textR_custom_text = "{data1} ({data2}, {data3}%)",
            textR_class_colors = false,
            textR_show_data = {true, true, true},

            models = {
                upper_model = "Spells\\AcidBreath_SuperGreen.M2",
                lower_model = "World\\EXPANSION02\\DOODADS\\Coldarra\\COLDARRALOCUS.m2",
                upper_alpha = 0.5,
                lower_enabled = false,
                lower_alpha = 0.1,
                upper_enabled = false,
            },

            texture_custom_file = "Interface\\",
            texture_custom = "",
            alpha = 1,
            no_icon = false,
            texture = "MidnightBar",
            texture_file = "Interface\\AddOns\\Details_MID\\Textures\\bar",
            texture_background = "MidnightBackground",
            percent_type = 1,
            fast_ps_update = false,
            textR_separator = ",",
            use_spec_icons = true,
        },

        show_statusbar = false,
        menu_icons_size = 1.07,
        color = {0.333333333333333, 0.333333333333333, 0.333333333333333, 0},
        bg_r = 0.0941176470588235,
        hide_out_of_combat = false,

        following = {
            bar_color = {1, 1, 1},
            enabled = false,
            text_color = {1, 1, 1},
        },

        color_buttons = {1, 1, 1, 1},
        skin_custom = "",

        menu_anchor_down = {
            16,
            -3,
        },

        micro_displays_locked = true,
        row_show_animation = {anim = "Fade", options = {}},
        tooltip = {n_abilities = 3, n_enemies = 3},

        total_bar = {
            enabled = false,
            only_in_group = true,
            icon = "Interface\\ICONS\\INV_Sigil_Thorim",
            color = {1, 1, 1},
        },

        show_sidebars = false,
        instance_button_anchor = {-27, 1},
        plugins_grow_direction = 1,

        menu_alpha = {
            enabled = false,
            onleave = 1,
            ignorebars = false,
            iconstoo = true,
            onenter = 1,
        },

        micro_displays_side = 2,
        grab_on_top = false,
        strata = "LOW",
        bars_grow_direction = 1,
        bg_alpha = 0,
        hide_in_combat_alpha = 0,

        menu_icons = {
            true,
            true,
            true,
            true,
            true,
            false,
            space = 0,
            shadow = false,
        },

        auto_hide_menu = {left = false, right = false},

        statusbar_info = {
            alpha = 0,
            overlay = {0.333333333333333, 0.333333333333333, 0.333333333333333},
        },

        window_scale = 1,
        libwindow = {
            y = 90.9987335205078,
            x = -80.0020751953125,
            point = "BOTTOMRIGHT",
        },

        backdrop_texture = "Details Ground",
        hide_icon = true,
        bg_b = 0.0941176470588235,
        bg_g = 0.0941176470588235,
        desaturated_menu = false,

        wallpaper = {
            enabled = false,
            texcoord = {0, 1, 0, 0.7},
            overlay = {1, 1, 1, 1},
            anchor = "all",
            height = 114.042518615723,
            alpha = 0.5,
            width = 283.000183105469,
        },

        stretch_button_side = 1,
        bars_sort_direction = 1,
    },
}

function MID:RegisterSkin()
    self:Debug("MID:RegisterSkin()")

    if not Details or not Details.InstallSkin then
        self:Debug("Details or Details.InstallSkin not ready yet.")
        return false
    end

    Details:InstallSkin(skinName, skinTable)
    return true
end

function MID:FixTitleBar()
    if not Details or not Details.GetNumInstances then
        return
    end

    for instanceId = 1, Details:GetNumInstances() do
        local instance = Details:GetInstance(instanceId)
        if instance and instance.baseframe and instance.ativa and instance.ChangeSkin then
            instance:ChangeSkin()
        end
    end
end

function MID:ChangeAugmentationBar()
    if augmentationHooked then
        return
    end

    if not retail or not Details or not Details.gump or not Details.class_colors or not Details.class_colors["EVOKER"] then
        return
    end

    self:Debug("MID:ChangeAugmentationBar()")

    local evokerColor = Details.class_colors["EVOKER"]

    local function ApplyAugmentTexture(line)
        if not line or not line.extraStatusbar then
            return
        end

        local extraStatusbar = line.extraStatusbar
        extraStatusbar:SetStatusBarTexture([[Interface\AddOns\Details_MID\Textures\augment]])
        if extraStatusbar.GetStatusBarTexture then
            local texture = extraStatusbar:GetStatusBarTexture()
            if texture then
                texture:SetVertexColor(unpack(evokerColor))
            end
        end

        if extraStatusbar.texture then
            extraStatusbar.texture:SetVertexColor(unpack(evokerColor))
        end
    end

    for instanceId = 1, Details:GetNumInstances() do
        local instance = Details:GetInstance(instanceId)
        if instance and instance.baseframe and instance.ativa and instance.GetAllLines then
            for _, line in ipairs(instance:GetAllLines()) do
                ApplyAugmentTexture(line)
            end
        end
    end

    hooksecurefunc(Details.gump, "CreateNewLine", function(_, instance, index)
        local newLine = _G["DetailsBarra_" .. instance.meu_id .. "_" .. index]
        ApplyAugmentTexture(newLine)
    end)

    augmentationHooked = true
end

function MID:SetupAfterLogin()
    if initialized then
        return
    end

    if not Details or (Details.IsLoaded and not Details.IsLoaded()) then
        C_Timer.After(1, function()
            MID:SetupAfterLogin()
        end)
        return
    end

    self:Debug("MID:SetupAfterLogin()")

    local registered = self:RegisterSkin()
    if not registered then
        C_Timer.After(1, function()
            MID:SetupAfterLogin()
        end)
        return
    end

    self:FixTitleBar()

    if retail then
        self:ChangeAugmentationBar()
    end

    initialized = true
end

function MID:RegisterSlashCommand()
    self:RegisterChatCommand("mid", "SlashCommand")
end

function MID:SlashCommand(msg)
    msg = msg and strtrim(msg) or ""
    self:Debug("MID:SlashCommand()", msg)

    if msg == "import" then
        self:ShowImportProfile()
    else
        self:Print("Unknown command. Try /mid import")
    end
end

function MID:ShowImportProfile()
    self:Debug("MID:ShowImportProfile()")
    self:Print("Import default profile...")

    if not Details or not Details.ImportProfile or not Details.ShowImportProfileConfirmation then
        self:Print("Details import API is not available.")
        return
    end

    local askForNewProfileName = function(newProfileName, importAutoRunCode)
        Details:ImportProfile(MID.DefaultProfileImport, newProfileName, importAutoRunCode, true)
    end

    Details.ShowImportProfileConfirmation(
        LocDetails["STRING_OPTIONS_IMPORT_PROFILE_NAME"] .. " [Skin: |cff8080ffDetails_MID|r]:",
        askForNewProfileName
    )
end

function MID:OnEvent(event, ...)
    self:Debug("MID:OnEvent()", event, ...)

    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        self:SetupAfterLogin()
    end
end

local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:SetScript("OnEvent", function(_, event, ...)
    MID:OnEvent(event, ...)
end)
