
local MID = LibStub("AceAddon-3.0"):NewAddon("Details_MID", "AceConsole-3.0")
local LocDetails = _G.LibStub("AceLocale-3.0"):GetLocale("Details")
local LSM = LibStub("LibSharedMedia-3.0")

local skinName = "|cff8080ffMidnight|r"

local name = UnitName("player")
local debugMode = (name == "Zimtdev") or (name == "Zimtdevtwo") or (name == "Botlike")

local retail = WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
local version = C_AddOns.GetAddOnMetadata("Details_MID", "Version")

local isSetupComplete = false
local isAugmentationHooked = false
local isSpecHooked = false
local frame

local function GetDetails()
    return _G.Details
end

local function IsDetailsReady()
    local details = GetDetails()
    return details and details.IsLoaded and details.IsLoaded()
end

local function IsInstanceUsable(instance)
    return instance and instance.baseframe and instance.IsEnabled and instance:IsEnabled()
end

local BLZ_SPECICON_TO_SPECID = {
    [1247264] = 577, -- Havoc / Verwüstung
    -- vengeance id hier ergänzen, falls nötig
    -- [VENIANCE_ICON_FILEID] = 581,
    -- [DEVOURER_ICON_FILEID] = 1480,
}

local function GetLineSpecID(line)
    if not line then
        return nil
    end

    local actor = line.minha_tabela or line.actor or line.my_table or line.displayedActor

    -- 1. Normaler Weg
    local specID =
        line.specId
        or line.specID
        or line.specid
        or line.spec
        or (actor and (actor.specId or actor.specID or actor.specid or actor.spec))

    if specID then
        return specID
    end

    -- 2. Blizzard Icon Mapping
    if line.blzSpecIcon and BLZ_SPECICON_TO_SPECID[line.blzSpecIcon] then
        return BLZ_SPECICON_TO_SPECID[line.blzSpecIcon]
    end

    -- 3. NEU: Fallback über Klasse
    local class = actor and actor.classe

    if class == "DEMONHUNTER" then
        -- Default fallback (z.B. Tank → Vengeance)
        return 581
    end

    return nil
end

local function GetEvokerColor(details)
    return (details and details.class_colors and details.class_colors["EVOKER"]) or {0.2, 0.58, 0.5, 1}
end

local function ApplyAugmentationStyle(line, color)
    if not line or not line.extraStatusbar then
        return
    end

    local extraStatusbar = line.extraStatusbar
    extraStatusbar:SetStatusBarTexture([[Interface\AddOns\Details_MID\Textures\augment]])

    local statusbarTexture = extraStatusbar:GetStatusBarTexture()
    if statusbarTexture then
        statusbarTexture:SetVertexColor(unpack(color))
    end

    if extraStatusbar.texture then
        extraStatusbar.texture:SetVertexColor(unpack(color))
    end
end

function MID:OnInitialize()
    MID:Debug("MID:OnInitialize()")
end

function MID:OnEnable()
    MID:Debug("MID:OnEnable()")
    MID:RegisterSlashCommand()
end

function MID:OnDisable()
end

function MID:Debug(str, ...)
    if not debugMode then
        return
    end

    self:Print(str, ...)
end

function MID:OnEvent(event, arg1, ...)
    MID:Debug(event, arg1, ...)

    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        MID:SetupAfterLogin()
    end
end

function MID:SetupAfterLogin()
    if isSetupComplete then
        return
    end

    if not IsDetailsReady() then
        C_Timer.After(0.2, function()
            MID:SetupAfterLogin()
        end)
        return
    end

    local details = GetDetails()
    if not details then
        C_Timer.After(0.2, function()
            MID:SetupAfterLogin()
        end)
        return
    end

    MID:RegisterSkin()
    MID:FixSpecCoords()

    for instanceId = 1, details:GetNumInstances() do
        local instance = details:GetInstance(instanceId)
        if IsInstanceUsable(instance) then
            instance:ChangeSkin()
        end
    end

    MID:ApplySpecIconsToAllLines()
    MID:HookSpecIcons()

    if retail then
        MID:ChangeAugmentationBar()
    end

    isSetupComplete = true

    if frame then
        frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
    end
end

function MID:FixSpecCoords()
    local details = GetDetails()
    if not details or not details.default_profile then
        return
    end

    local customCoords = {
        -- Demon Hunter
        [577] = {128/512, 192/512, 256/512, 320/512}, -- Havoc
        [581] = {192/512, 256/512, 256/512, 320/512}, -- Vengeance

        -- Death Knight
        [250] = {0/512,   64/512,  0/512,   64/512},  -- Blood
        [251] = {64/512,  128/512, 0/512,   64/512},  -- Frost
        [252] = {128/512, 192/512, 0/512,   64/512},  -- Unholy

        -- Druid
        [102] = {192/512, 256/512, 0/512,   64/512},  -- Balance
        [103] = {256/512, 320/512, 0/512,   64/512},  -- Feral
        [104] = {320/512, 384/512, 0/512,   64/512},  -- Guardian
        [105] = {384/512, 448/512, 0/512,   64/512},  -- Restoration

        -- Hunter
        [253] = {448/512, 512/512, 0/512,   64/512},  -- Beast Mastery
        [254] = {0/512,   64/512,  64/512,  128/512}, -- Marksmanship
        [255] = {64/512,  128/512, 64/512,  128/512}, -- Survival

        -- Mage
        [62] = {(128/512) + 0.001953125, 192/512, 64/512, 128/512}, -- Arcane
        [63] = {192/512, 256/512, 64/512, 128/512}, -- Fire
        [64] = {256/512, 320/512, 64/512, 128/512}, -- Frost

        -- Monk
        [268] = {320/512, 384/512, 64/512, 128/512}, -- Brewmaster
        [270] = {384/512, 448/512, 64/512, 128/512}, -- Mistweaver
        [269] = {448/512, 512/512, 64/512, 128/512}, -- Windwalker

        -- Paladin
        [65] = {0/512,   64/512,  128/512, 192/512}, -- Holy
        [66] = {64/512,  128/512, 128/512, 192/512}, -- Protection
        [70] = {(128/512) + 0.001953125, 192/512, 128/512, 192/512}, -- Retribution

        -- Priest
        [256] = {192/512, 256/512, 128/512, 192/512}, -- Discipline
        [257] = {256/512, 320/512, 128/512, 192/512}, -- Holy
        [258] = {(320/512) + (0.001953125 * 4), 384/512, 128/512, 192/512}, -- Shadow

        -- Rogue
        [259] = {384/512, 448/512, 128/512, 192/512}, -- Assassination
        [260] = {448/512, 512/512, 128/512, 192/512}, -- Outlaw / Combat
        [261] = {0/512,   64/512,  192/512, 256/512}, -- Subtlety

        -- Shaman
        [262] = {64/512,  128/512, 192/512, 256/512}, -- Elemental
        [263] = {128/512, 192/512, 192/512, 256/512}, -- Enhancement
        [264] = {192/512, 256/512, 192/512, 256/512}, -- Restoration

        -- Warlock
        [265] = {256/512, 320/512, 192/512, 256/512}, -- Affliction
        [266] = {320/512, 384/512, 192/512, 256/512}, -- Demonology
        [267] = {384/512, 448/512, 192/512, 256/512}, -- Destruction

        -- Warrior
        [71] = {448/512, 512/512, 192/512, 256/512}, -- Arms
        [72] = {0/512,   64/512,  256/512, 320/512}, -- Fury
        [73] = {64/512,  128/512, 256/512, 320/512}, -- Protection

        -- Evoker
        [1467] = {256/512, 320/512, 256/512, 320/512}, -- Devastation
        [1468] = {320/512, 384/512, 256/512, 320/512}, -- Preservation
        [1473] = {384/512, 448/512, 256/512, 320/512}, -- Augmentation

        -- Devourer / Verschlinger
        [1480] = {448/512, 512/512, 448/512, 512/512},
    }

    details.default_profile.class_specs_coords = details.default_profile.class_specs_coords or {}
    details.class_specs_coords = details.class_specs_coords or {}

    for specID, coords in pairs(customCoords) do
        details.default_profile.class_specs_coords[specID] = coords
        details.class_specs_coords[specID] = coords
    end
end

function MID:ApplySpecIconToLine(line)
    local details = GetDetails()
    if not details or not line then
        return
    end

    local specID = GetLineSpecID(line)
    local coords = specID and details.class_specs_coords and details.class_specs_coords[specID]
    if not coords then
        return
    end

    local atlasPath = "Interface\\AddOns\\Details_MID\\Textures\\specs"

    -- Details internal fallback
    line.blzSpecIcon = nil

    if line.SetLineIconTexture then
        pcall(line.SetLineIconTexture, line, atlasPath, coords[1], coords[2], coords[3], coords[4])
    end

    local texture = GetLineIconTextureObject(line)
    if texture then
        texture:SetTexture(atlasPath)
        texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])

        if not line.MidnightIconMask then
            local mask = texture:CreateMaskTexture()
            mask:SetTexture("Interface\\CHARACTERFRAME\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
            mask:SetAllPoints(texture)
            texture:AddMaskTexture(mask)
            line.MidnightIconMask = mask
        end

        if not line.MidnightIconBorder then
            local borderParent = line.icon_frame or line
            local border = CreateFrame("Frame", nil, borderParent, "BackdropTemplate")
            border:SetPoint("TOPLEFT", texture, -1, 1)
            border:SetPoint("BOTTOMRIGHT", texture, 1, -1)
            border:SetFrameLevel(texture:GetDrawLayer() and (borderParent:GetFrameLevel() + 1) or (borderParent:GetFrameLevel() + 1))
            border:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            border:SetBackdropColor(0.05, 0.04, 0.10, 0.72)
            border:SetBackdropBorderColor(0.34, 0.28, 0.62, 0.95)

            local glow = border:CreateTexture(nil, "ARTWORK")
            glow:SetAllPoints(border)
            glow:SetTexture("Interface\\Buttons\\WHITE8X8")
            glow:SetColorTexture(0.40, 0.30, 0.75, 0.10)
            border.Glow = glow

            line.MidnightIconBorder = border
        end
    end
end

function MID:ApplySpecIconsToAllLines()
    local details = GetDetails()
    if not details or not details.GetNumInstances then
        return
    end

    for instanceId = 1, details:GetNumInstances() do
        local instance = details:GetInstance(instanceId)
        if IsInstanceUsable(instance) and instance.GetAllLines then
            for _, line in ipairs(instance:GetAllLines()) do
                MID:ApplySpecIconToLine(line)
            end
        end
    end
end

function MID:HookSpecIcons()
    local details = GetDetails()
    if isSpecHooked or not details or not details.gump then
        return
    end

    hooksecurefunc(details.gump, "CreateNewLine", function(_, instance, index)
        C_Timer.After(0, function()
            if not IsInstanceUsable(instance) then
                return
            end

            local line = (instance.GetLine and instance:GetLine(index)) or _G["DetailsBarra_" .. instance.meu_id .. "_" .. index]
            if line then
                MID:ApplySpecIconToLine(line)

                if retail then
                    ApplyAugmentationStyle(line, GetEvokerColor(details))
                end
            end
        end)
    end)

    isSpecHooked = true
end

function MID:RegisterTextures()
    MID:Debug("MID:RegisterTextures()")

    LSM:Register("statusbar", "MidnightHeader", [[Interface\AddOns\Details_MID\Textures\header.tga]])
    LSM:Register("statusbar", "MidnightBar", [[Interface\AddOns\Details_MID\Textures\bar.blp]])
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
        textymod = 1
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
        titlebar_texture_color = {1.0, 1.0, 1.0, 1.0},

        toolbar_icon_file = "Interface\\AddOns\\Details\\images\\toolbar_icons_shadow",
        toolbar_side = 1,

        menu_anchor = {
            10,
            10,
            side = 2
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
                NORMAL_FONT_COLOR.a
            },
            enable_custom_text = false,
            show_timer = true
        },

        row_info = {
            texture_highlight = "Interface\\FriendsFrame\\UI-FriendsList-Highlight",

            fixed_text_color = {1, 1, 1},

            height = 28,
            space = {
                right = 0,
                left = 0,
                between = 4
            },

            row_offsets = {
                left = 29,
                right = -37,
                top = 0,
                bottom = 0
            },

            texture_background_class_color = false,
            font_face_file = "Interface\\AddOns\\Details\\fonts\\Accidental Presidency.ttf",

            backdrop = {
                enabled = false,
                size = 12,
                color = {1, 1, 1, 1},
                texture = "Details BarBorder 2"
            },

            icon_file = "Interface\\AddOns\\Details_MID\\Textures\\ClassIconsMID",
            start_after_icon = false,
            icon_offset = {-30, 0},

            textL_show_number = true,
            textL_outline = false,
            textL_enable_custom_text = false,
            textL_custom_text = "{data1}. {data3}{data2}",
            textL_class_colors = false,

            textR_outline = false,
            textR_bracket = "(",
            textR_enable_custom_text = false,
            textR_custom_text = "{data1} ({data2}, {data3}%)",
            textR_class_colors = false,
            textR_show_data = {true, true, true},

            fixed_texture_color = {0, 0, 0},

            models = {
                upper_model = "Spells\\AcidBreath_SuperGreen.M2",
                lower_model = "World\\EXPANSION02\\DOODADS\\Coldarra\\COLDARRALOCUS.m2",
                upper_alpha = 0.5,
                lower_enabled = false,
                lower_alpha = 0.1,
                upper_enabled = false
            },

            texture_custom_file = "Interface\\",
            texture_custom = "",
            alpha = 1,
            no_icon = false,

            texture = "MidnightBar",
            texture_file = "Interface\\AddOns\\Details_MID\\Textures\\bar",
            texture_background = "MidnightBackground",
            texture_background_file = "Interface\\AddOns\\Details_MID\\Textures\\background",

            fixed_texture_background_color = {1, 1, 1, 1},
            font_face = "Friz Quadrata TT",
            font_size = 11,
            textL_offset = 0,
            text_yoffset = 7,
            texture_class_colors = true,
            percent_type = 1,
            fast_ps_update = false,
            textR_separator = ",",
            use_spec_icons = true,
            spec_file = "Interface\\AddOns\\Details_MID\\Textures\\specs",
            icon_size_offset = 1.2
        },

        menu_icons_alpha = 1,
        show_statusbar = false,
        menu_icons_size = 1.07,

        color = {0.333333333333333, 0.333333333333333, 0.333333333333333, 0},

        bg_r = 0.0941176470588235,
        hide_out_of_combat = false,

        following = {
            bar_color = {1, 1, 1},
            enabled = false,
            text_color = {1, 1, 1}
        },

        color_buttons = {0.90, 0.75, 0.25, 1},

        skin_custom = "",
        menu_anchor_down = {16, -3},

        micro_displays_locked = true,
        row_show_animation = {
            anim = "Fade",
            options = {}
        },

        tooltip = {
            n_abilities = 3,
            n_enemies = 3
        },

        total_bar = {
            enabled = false,
            only_in_group = true,
            icon = "Interface\\ICONS\\INV_Sigil_Thorim",
            color = {1, 1, 1}
        },

        show_sidebars = false,
        instance_button_anchor = {-27, 1},

        plugins_grow_direction = 1,

        menu_alpha = {
            enabled = false,
            onleave = 1,
            ignorebars = false,
            iconstoo = true,
            onenter = 1
        },

        micro_displays_side = 2,
        grab_on_top = false,
        strata = "LOW",
        bars_grow_direction = 1,
        bg_alpha = 0,
        ignore_mass_showhide = false,
        hide_in_combat_alpha = 0,

        menu_icons = {
            true, true, true, true, true, false,
            space = 0,
            shadow = false
        },

        auto_hide_menu = {
            left = false,
            right = false
        },

        statusbar_info = {
            alpha = 0,
            overlay = {0.333333333333333, 0.333333333333333, 0.333333333333333}
        },

        window_scale = 1,

        libwindow = {
            y = 90.9987335205078,
            x = -80.0020751953125,
            point = "BOTTOMRIGHT"
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
            width = 283.000183105469
        },

        stretch_button_side = 1,
        bars_sort_direction = 1
    }
}

function MID:RegisterSkin()
    MID:Debug("MID:RegisterSkin()")
    local details = GetDetails()
    if details and details.InstallSkin then
        details:InstallSkin(skinName, skinTable)
    end
end

function MID:ChangeAugmentationBar()
    local details = GetDetails()
    if not retail or not details or isAugmentationHooked then
        return
    end

    MID:Debug("MID:ChangeAugmentationBar()")

    local evokerColor = GetEvokerColor(details)

    for instanceId = 1, details:GetNumInstances() do
        local instance = details:GetInstance(instanceId)
        if IsInstanceUsable(instance) and instance.GetAllLines then
            for _, line in ipairs(instance:GetAllLines()) do
                ApplyAugmentationStyle(line, evokerColor)
            end
        end
    end

    hooksecurefunc(details.gump, "CreateNewLine", function(_, instance, index)
        C_Timer.After(0, function()
            if not IsInstanceUsable(instance) then
                return
            end

            local line = (instance.GetLine and instance:GetLine(index)) or _G["DetailsBarra_" .. instance.meu_id .. "_" .. index]
            if line then
                ApplyAugmentationStyle(line, evokerColor)
            end
        end)
    end)

    isAugmentationHooked = true
end

function MID:RegisterSlashCommand()
    MID:RegisterChatCommand("mid", "SlashCommand")
end

function MID:SlashCommand(msg)
    MID:Debug("MID:SlashCommand()", msg)

    if msg == "import" then
        MID:ShowImportProfile()
    else
        MID:Print([[Slashcommand not found. Did you mean '/mid import'?]])
    end
end

function MID:ShowImportProfile()
    MID:Debug("MID:ShowImportProfile()")
    MID:Print("Import default profile...")

    local askForNewProfileName = function(newProfileName, importAutoRunCode)
        local details = GetDetails()
        if details then
            details:ImportProfile(MID.DefaultProfileImport, newProfileName, importAutoRunCode, true)
        end
    end

    local details = GetDetails()
    if details and details.ShowImportProfileConfirmation then
        details.ShowImportProfileConfirmation(
            LocDetails["STRING_OPTIONS_IMPORT_PROFILE_NAME"] .. " [Skin: |cff8080ffDetails_MID|r]:",
            askForNewProfileName
        )
    end
end

frame = CreateFrame("FRAME")
frame:SetScript("OnEvent", function(_, event, ...)
    MID:OnEvent(event, ...)
end)
frame:RegisterEvent("PLAYER_LOGIN")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
