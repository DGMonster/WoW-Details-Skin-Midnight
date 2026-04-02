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

---------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------

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

local function GetLineIconTextureObject(line)
    if not line then return nil end

    return line.icon_texture
        or line.iconTexture
        or line.icon_tex
        or line.icon
        or (line.icon_frame and line.icon_frame.texture)
        or (line.Icon and line.Icon.texture)
end

---------------------------------------------------------------------
-- Spec Handling
---------------------------------------------------------------------

local BLZ_SPECICON_TO_SPECID = {
    [1247264] = 577,
    [1234567] = 577, -- placeholder / debug
}

local function GetLineSpecID(line)
    if not line then return nil end

    local actor = line.minha_tabela or line.actor or line.my_table or line.displayedActor

    local specID =
        line.specId
        or line.specID
        or line.specid
        or line.spec
        or (actor and (actor.specId or actor.specID or actor.specid or actor.spec))

    if specID then
        return specID
    end

    if line.blzSpecIcon then
        DEFAULT_CHAT_FRAME:AddMessage("MID blzSpecIcon: " .. tostring(line.blzSpecIcon))

        if BLZ_SPECICON_TO_SPECID[line.blzSpecIcon] then
            return BLZ_SPECICON_TO_SPECID[line.blzSpecIcon]
        end
    end

    return nil
end

---------------------------------------------------------------------
-- Augmentation Styling
---------------------------------------------------------------------

local function GetEvokerColor(details)
    return (details and details.class_colors and details.class_colors["EVOKER"]) or {0.2, 0.58, 0.5, 1}
end

local function ApplyAugmentationStyle(line, color)
    if not line or not line.extraStatusbar then return end

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

---------------------------------------------------------------------
-- Core Lifecycle
---------------------------------------------------------------------

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
    if not debugMode then return end
    self:Print(str, ...)
end

function MID:OnEvent(event, arg1, ...)
    MID:Debug(event, arg1, ...)

    if event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
        MID:SetupAfterLogin()
    end
end

---------------------------------------------------------------------
-- Setup
---------------------------------------------------------------------

function MID:SetupAfterLogin()
    if isSetupComplete then return end

    if not IsDetailsReady() then
        C_Timer.After(0.2, function() MID:SetupAfterLogin() end)
        return
    end

    local details = GetDetails()
    if not details then
        C_Timer.After(0.2, function() MID:SetupAfterLogin() end)
        return
    end

    MID:RegisterSkin()
    MID:FixSpecCoords()

    for i = 1, details:GetNumInstances() do
        local instance = details:GetInstance(i)
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

---------------------------------------------------------------------
-- Spec Icon Apply
---------------------------------------------------------------------

function MID:ApplySpecIconToLine(line)
    local details = GetDetails()
    if not details or not line then return end

    local specID = GetLineSpecID(line)
    if not specID then
        MID:Debug("No specID for line:", line:GetName() or "unknown")
        return
    end

    local coords = details.class_specs_coords and details.class_specs_coords[specID]
    if not coords then
        MID:Debug("Missing coords for specID:", specID)
        return
    end

    local atlasPath = "Interface\\AddOns\\Details_MID\\Textures\\specs"
    local texture = GetLineIconTextureObject(line)

    line.blzSpecIcon = nil

    if line.SetLineIconTexture then
        pcall(line.SetLineIconTexture, line, atlasPath, coords[1], coords[2], coords[3], coords[4])
    end

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
            border:SetFrameLevel(borderParent:GetFrameLevel() + 1)

            border:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })

            border:SetBackdropColor(0.05, 0.04, 0.10, 0.72)
            border:SetBackdropBorderColor(0.34, 0.28, 0.62, 0.95)

            local glow = border:CreateTexture(nil, "ARTWORK")
            glow:SetAllPoints(border)
            glow:SetColorTexture(0.40, 0.30, 0.75, 0.10)

            border.Glow = glow
            line.MidnightIconBorder = border
        end
    end
end

---------------------------------------------------------------------
-- Hooks
---------------------------------------------------------------------

function MID:HookSpecIcons()
    local details = GetDetails()
    if isSpecHooked or not details then return end

    if details.gump and details.gump.CreateNewLine then
        hooksecurefunc(details.gump, "CreateNewLine", function(_, instance, index)
            C_Timer.After(0, function()
                if not IsInstanceUsable(instance) then return end

                local line = (instance.GetLine and instance:GetLine(index))
                    or _G["DetailsBarra_" .. instance.meu_id .. "_" .. index]

                if line then
                    MID:ApplySpecIconToLine(line)

                    if retail then
                        ApplyAugmentationStyle(line, GetEvokerColor(details))
                    end
                end
            end)
        end)
    end

    if details.SetBarSpecIconSettings then
        hooksecurefunc(details, "SetBarSpecIconSettings", function(_, line)
            C_Timer.After(0, function()
                if line then
                    MID:ApplySpecIconToLine(line)
                end
            end)
        end)
    end

    isSpecHooked = true
end
