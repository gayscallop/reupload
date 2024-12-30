local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'

local Library = loadstring(game:HttpGet(repo .. 'Library.lua'))()
local ThemeManager = loadstring(game:HttpGet(repo .. 'addons/ThemeManager.lua'))()
local SaveManager = loadstring(game:HttpGet(repo .. 'addons/SaveManager.lua'))()

local Window = Library:CreateWindow({
    Title = 'freakhack | project delta',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2
})

local rs = game:GetService("RunService")

-- player list basically
local players = game:GetService("Players")

-- localplayer
local localplayer = game.Players.LocalPlayer

-- games workspace
local workspace = game:GetService("Workspace")

-- direct center
local centerofscreen = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

-- copy of ammos so we can restore
local realAmmoTypes = game.ReplicatedStorage:FindFirstChild("realAmmoTypes") or game.ReplicatedStorage:FindFirstChild("AmmoTypes") and game.ReplicatedStorage:FindFirstChild("AmmoTypes"):Clone(); 
if realAmmoTypes then 
    realAmmoTypes.Name = "realAmmoTypes" 
end

-- copy of player so we can restore
local defaultFov = 0
local localsettings = game.ReplicatedStorage.Players:FindFirstChild(localplayer.Name).Settings
if localsettings then
   defaultFov = localsettings.GameplaySettings:GetAttribute("DefaultFOV", defaultFov)  
end

local mouse = localplayer:GetMouse()
local camera = workspace.CurrentCamera
local worldToViewportPoint = camera.worldToViewportPoint
local emptyCFrame = CFrame.new();
local pointToObjectSpace = emptyCFrame.PointToObjectSpace

--[Optimisation Variables]

local Drawingnew = Drawing.new
local Color3fromRGB = Color3.fromRGB
local Vector3new = Vector3.new
local Vector2new = Vector2.new
local mathfloor = math.floor
local mathceil = math.ceil
local cross = Vector3new().Cross;

--[Setup Table]

local esp = {
    players = {},
    objects = {},
    enabled = false,
    teamcheck = false,
    fontsize = 13,
    font = 3,
    maxdist = 0,
    settings = {
        name = {enabled = false, outline = true, displaynames = false, color = Color3fromRGB(255, 255, 255)},
        box = {enabled = false, outline = true, color = Color3fromRGB(255, 255, 255)},
        filledbox = {enabled = false, outline = true, transparency = 0.5, color = Color3fromRGB(255, 255, 255)},
        healthbar = {enabled = false, size = 3, outline = true},
        healthtext = {enabled = false, outline = true, color = Color3fromRGB(255, 255, 255)},
        distance = {enabled = false, outline = true, color = Color3fromRGB(255, 255, 255)},
        viewangle = {enabled = false, size = 6, color = Color3fromRGB(255, 255, 255)},
        skeleton = {enabled = false, color = Color3fromRGB(255, 255, 255)},
        tracer = {enabled = false, origin = "Middle", color = Color3fromRGB(255, 255, 255)},
        arrow = {enabled = false, radius = 100, size = 25, filled = false, transparency = 1, color = Color3fromRGB(255, 255, 255)}
    },
    settings_chams = {
        enabled = false,
        teamcheck = false,
        outline = false,
        fill_color = Color3fromRGB(255, 255, 255),
        outline_color = Color3fromRGB(0, 0, 0), 
        fill_transparency = 0,
        outline_transparency = 0,
        autocolor = false,
        occluded = false,
        visible_Color = Color3fromRGB(0, 255, 0),
        invisible_Color = Color3fromRGB(255, 0, 0),
    },
    customsettings = {
        enabled = false,
        maxdist = 0,
        corpse = {enabled = false, outline = true, size = 10, color = Color3fromRGB(255, 255, 255)},
        ai = {enabled = false, outline = true, size = 10, color = Color3fromRGB(255, 255, 255)},
        corpsechams = {enabled = false, fill_color = Color3fromRGB(255, 255, 255), outline_color = Color3fromRGB(0,0,0), fill_transparency = 0, outline_transparency = 0, occluded = false},
        aichams = {enabled = false, fill_color = Color3fromRGB(255, 255, 255), outline_color = Color3fromRGB(0,0,0), fill_transparency = 0, outline_transparency = 0, occluded = false},
        corpsedistance = {enabled = false, color = Color3fromRGB(255, 255, 255)},
        aidistance = {enabled = false, color = Color3fromRGB(255, 255, 255)},
        aihealth = {enabled = false, color = Color3fromRGB(255, 255, 255)},
        extract = {enabled = false, outline = true, size = 10, color = Color3fromRGB(255, 255, 255)},
        extractdistance = {enabled = false, color = Color3fromRGB(255, 255, 255)}
    }
}

esp.NewDrawing = function(type, properties)
    local newDrawing = Drawingnew(type)

    for i,v in next, properties or {} do
        newDrawing[i] = v
    end

    return newDrawing
end

esp.NewCham = function(properties)
    local newCham = Instance.new("Highlight", game.CoreGui)

    for i,v in next, properties or {} do
        newCham[i] = v
    end

    return newCham
end

esp.WallCheck = function(v)
    local ray = Ray.new(camera.CFrame.p, (v.Position - camera.CFrame.p).Unit * 300)
    local part, position = game:GetService("Workspace"):FindPartOnRayWithIgnoreList(ray, {localplayer.Character, camera}, false, true)
    if part then
        local hum = part.Parent:FindFirstChildOfClass("Humanoid")
        if not hum then
            hum = part.Parent.Parent:FindFirstChildOfClass("Humanoid")
        end
        if hum and v and hum.Parent == v.Parent then
            local Vector, Visible = camera:WorldToScreenPoint(v.Position)
            if Visible then
                return true
            end
        end
    end
end

esp.TeamCheck = function(v)
    if localplayer.TeamColor == v.TeamColor then
        return false
    end

    return true
end

esp.NewPlayer = function(v)
    esp.players[v] = {
        name = esp.NewDrawing("Text", {Color = Color3fromRGB(255, 255, 255), Outline = true, Center = true, Size = 13, Font = 10}),
        filledbox = esp.NewDrawing("Square", {Color = Color3fromRGB(255, 255, 255), Thickness = 1, Filled = true}),
        boxOutline = esp.NewDrawing("Square", {Color = Color3fromRGB(0, 0, 0), Thickness = 3}),
        box = esp.NewDrawing("Square", {Color = Color3fromRGB(255, 255, 255), Thickness = 1}),
        healthBarOutline = esp.NewDrawing("Line", {Color = Color3fromRGB(0, 0, 0), Thickness = 3}),
        healthBar = esp.NewDrawing("Line", {Color = Color3fromRGB(255, 255, 255), Thickness = 1}),
        healthText = esp.NewDrawing("Text", {Color = Color3fromRGB(255, 255, 255), Outline = true, Center = true, Size = 13, Font = 10}),
        distance = esp.NewDrawing("Text", {Color = Color3fromRGB(255, 255, 255), Outline = true, Center = true, Size = 13, Font = 10}),
        viewAngle = esp.NewDrawing("Line", {Color = Color3fromRGB(255, 255, 255), Thickness = 1}),
        weapon = esp.NewDrawing("Text", {Color = Color3fromRGB(255, 255, 255), Outline = true, Center = true, Size = 13, Font = 10}),
        tracer = esp.NewDrawing("Line", {Color = Color3fromRGB(255, 255, 255), Thickness = 1}),
        cham = esp.NewCham({FillColor = esp.settings_chams.fill_color, OutlineColor = esp.settings_chams.outline_color, FillTransparency = esp.settings_chams.fill_transparency, OutlineTransparency = esp.settings_chams.outline_transparency}),
        arrow = esp.NewDrawing("Triangle", {Color = Color3fromRGB(255, 255, 255), Thickness = 1})
    }
end

game:GetService("RunService").RenderStepped:Connect(function()
    for i,v in pairs(esp.players) do
        if i.Character and i.Character:FindFirstChild("Humanoid") and i.Character:FindFirstChild("HumanoidRootPart") and i.Character:FindFirstChild("Head") and i.Character:FindFirstChild("Humanoid").Health > 0 and (esp.maxdist == 0 or (i.Character.HumanoidRootPart.Position - localplayer.Character.HumanoidRootPart.Position).Magnitude < esp.maxdist) then
            local hum = i.Character.Humanoid
            local hrp = i.Character.HumanoidRootPart
            local head = i.Character.Head

            local Vector, onScreen = camera:WorldToViewportPoint(i.Character.HumanoidRootPart.Position)
    
            local Size = (camera:WorldToViewportPoint(hrp.Position - Vector3new(0, 3, 0)).Y - camera:WorldToViewportPoint(hrp.Position + Vector3new(0, 2.6, 0)).Y) / 2
            local BoxSize = Vector2new(mathfloor(Size * 1.5), mathfloor(Size * 1.9))
            local BoxPos = Vector2new(mathfloor(Vector.X - Size * 1.5 / 2), mathfloor(Vector.Y - Size * 1.6 / 2))
    
            local BottomOffset = BoxSize.Y + BoxPos.Y + 1

            if onScreen and esp.settings_chams.enabled then
                v.cham.Adornee = i.Character
                v.cham.Enabled = esp.settings_chams.enabled
                v.cham.OutlineTransparency = esp.settings_chams.outline and esp.settings_chams.outline_transparency or 1
                v.cham.OutlineColor = esp.settings_chams.autocolor and esp.settings_chams.autocolor_outline and esp.WallCheck(i.Character.Head) and esp.settings_chams.visible_Color or esp.settings_chams.autocolor and esp.settings_chams.autocolor_outline and not esp.WallCheck(i.Character.Head) and esp.settings_chams.invisible_Color or esp.settings_chams.outline_color
                v.cham.FillColor = esp.settings_chams.autocolor and esp.WallCheck(i.Character.Head) and esp.settings_chams.visible_Color or esp.settings_chams.autocolor and not esp.WallCheck(i.Character.Head) and esp.settings_chams.invisible_Color or esp.settings_chams.fill_color
                v.cham.FillTransparency = esp.settings_chams.fill_transparency
                if esp.settings_chams.occluded then
                	v.cham.DepthMode = "Occluded"
				else
					v.cham.DepthMode = "AlwaysOnTop"	
				end

                if esp.settings_chams.teamcheck then
                    if not esp.TeamCheck(i) then
                        v.cham.Enabled = false
                    end
                end
            else
                v.cham.Enabled = false
            end

            if esp.settings.tracer.enabled and esp.enabled then
                if esp.settings.tracer.origin == "Bottom" then
                    v.tracer.From = Vector2new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y)
                elseif esp.settings.tracer.origin == "Top" then
                    v.tracer.From = Vector2new(workspace.CurrentCamera.ViewportSize.X / 2,0)
                elseif esp.settings.tracer.origin == "Middle" then
                    v.tracer.From = Vector2new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
                else
                    v.tracer.From = Vector2new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2)
                end

                v.tracer.To = Vector2new(Vector.X, Vector.Y)
                v.tracer.Color = esp.settings.tracer.color
                v.tracer.Visible = true
            else
                v.tracer.Visible = false
            end

            if onScreen and esp.enabled then
                if esp.settings.name.enabled then
                    v.name.Position = Vector2new(BoxSize.X / 2 + BoxPos.X, BoxPos.Y - 16)
                    v.name.Outline = esp.settings.name.outline
                    v.name.Color = esp.settings.name.color

                    v.name.Font = esp.font
                    v.name.Size = esp.fontsize

                    if esp.settings.name.displaynames then
                        v.name.Text = i.DisplayName
                    else
                        v.name.Text = i.Name
                    end

                    v.name.Visible = true
                else
                    v.name.Visible = false
                end

                if esp.settings.distance.enabled and localplayer.Character and localplayer.Character:FindFirstChild("HumanoidRootPart") then
                    v.distance.Position = Vector2new(BoxSize.X / 2 + BoxPos.X, BottomOffset)
                    v.distance.Outline = esp.settings.distance.outline
                    v.distance.Text = "[" .. mathfloor((hrp.Position - localplayer.Character.HumanoidRootPart.Position).Magnitude / 3) .. "m]"
                    v.distance.Color = esp.settings.distance.color
                    BottomOffset = BottomOffset + 15

                    v.distance.Font = esp.font
                    v.distance.Size = esp.fontsize

                    v.distance.Visible = true
                else
                    v.distance.Visible = false
                end

                if esp.settings.filledbox.enabled then
                    v.filledbox.Size = BoxSize + Vector2.new(-2, -2)
                    v.filledbox.Position = BoxPos + Vector2.new(1, 1)
                    v.filledbox.Color = esp.settings.filledbox.color
                    v.filledbox.Transparency = esp.settings.filledbox.transparency
                    v.filledbox.Visible = true
                else
                    v.filledbox.Visible = false
                end

                if esp.settings.box.enabled then
                    v.boxOutline.Size = BoxSize
                    v.boxOutline.Position = BoxPos
                    v.boxOutline.Visible = esp.settings.box.outline
    
                    v.box.Size = BoxSize
                    v.box.Position = BoxPos
                    v.box.Color = esp.settings.box.color
                    v.box.Visible = true
                else
                    v.boxOutline.Visible = false
                    v.box.Visible = false
                end

                if esp.settings.healthbar.enabled then
                    v.healthBar.From = Vector2new((BoxPos.X - 5), BoxPos.Y + BoxSize.Y)
                    v.healthBar.To = Vector2new(v.healthBar.From.X, v.healthBar.From.Y - (hum.Health / hum.MaxHealth) * BoxSize.Y)
                    v.healthBar.Color = Color3fromRGB(255 - 255 / (hum["MaxHealth"] / hum["Health"]), 255 / (hum["MaxHealth"] / hum["Health"]), 0)
                    v.healthBar.Visible = true
                    v.healthBar.Thickness = esp.settings.healthbar.size

                    v.healthBarOutline.From = Vector2new(v.healthBar.From.X, BoxPos.Y + BoxSize.Y + 1)
                    v.healthBarOutline.To = Vector2new(v.healthBar.From.X, (v.healthBar.From.Y - 1 * BoxSize.Y) -1)
                    v.healthBarOutline.Visible = esp.settings.healthbar.outline
                    v.healthBarOutline.Thickness = esp.settings.healthbar.size + 2
                else
                    v.healthBarOutline.Visible = false
                    v.healthBar.Visible = false
                end

                if esp.settings.healthtext.enabled then
                    v.healthText.Text = tostring(mathfloor(hum.Health))
                    v.healthText.Position = Vector2new((BoxPos.X - 20), (BoxPos.Y + BoxSize.Y - 1 * BoxSize.Y) -1)
                    v.healthText.Color = esp.settings.healthtext.color
                    v.healthText.Outline = esp.settings.healthtext.outline

                    v.healthText.Font = esp.font
                    v.healthText.Size = esp.fontsize

                    v.healthText.Visible = true
                else
                    v.healthText.Visible = false
                end

                if esp.settings.viewangle.enabled and head and head.CFrame then
                    v.viewAngle.From = Vector2new(camera:worldToViewportPoint(head.CFrame.p).X, camera:worldToViewportPoint(head.CFrame.p).Y)
                    v.viewAngle.To = Vector2new(camera:worldToViewportPoint((head.CFrame + (head.CFrame.lookVector * esp.settings.viewangle.size)).p).X, camera:worldToViewportPoint((head.CFrame + (head.CFrame.lookVector * esp.settings.viewangle.size)).p).Y)
                    v.viewAngle.Color = esp.settings.viewangle.color
                    v.viewAngle.Visible = true
                else
                    v.viewAngle.Visible = false
                end
                v.arrow.Visible = false
                --[[if esp.settings.weapon.enabled then
                    v.weapon.Visible = true
                    v.weapon.Position = Vector2new(BoxSize.X + BoxPos.X + v.weapon.TextBounds.X / 2 + 3, BoxPos.Y - 3)
                    v.weapon.Outline = esp.settings.name.outline
                    v.weapon.Color = esp.settings.name.color

                    v.weapon.Font = esp.font
                    v.weapon.Size = esp.fontsize

                    v.weapon.Text = esp.GetEquippedTool(i)
                else
                    v.weapon.Visible = false
                end]]

                if esp.teamcheck then
                    if esp.TeamCheck(i) then
                        v.name.Visible = esp.settings.name.enabled
                        v.box.Visible = esp.settings.box.enabled
                        v.filledbox.Visible = esp.settings.box.enabled
                        v.healthBar.Visible = esp.settings.healthbar.enabled
                        v.healthText.Visible = esp.settings.healthtext.enabled
                        v.distance.Visible = esp.settings.distance.enabled
                        v.viewAngle.Visible = esp.settings.viewangle.enabled
                        v.weapon.Visible = esp.settings.weapon.enabled
                        v.tracer.Visible = esp.settings.tracer.enabled
                        v.arrow.Visible = esp.settings.arrow.enabled
                    else
                        v.name.Visible = false
                        v.boxOutline.Visible = false
                        v.box.Visible = false
                        v.filledbox.Visible = false
                        v.healthBarOutline.Visible = false
                        v.healthBar.Visible = false
                        v.healthText.Visible = false
                        v.distance.Visible = false
                        v.viewAngle.Visible = false
                        v.weapon.Visible = false
                        v.tracer.Visible = false
                        v.arrow.Visible = false
                    end
                end
            else
                v.name.Visible = false
                v.boxOutline.Visible = false
                v.box.Visible = false
                v.filledbox.Visible = false
                v.healthBarOutline.Visible = false
                v.healthBar.Visible = false
                v.healthText.Visible = false
                v.distance.Visible = false
                v.viewAngle.Visible = false
                v.weapon.Visible = false
                v.tracer.Visible = false
                if esp.enabled and esp.settings.arrow.enabled then
                    local currentCamera = workspace.CurrentCamera
                    local screenCenter = Vector2new(workspace.CurrentCamera.ViewportSize.X / 2, workspace.CurrentCamera.ViewportSize.Y / 2);
                    local objectSpacePoint = (pointToObjectSpace(currentCamera.CFrame, hrp.Position) * Vector3new(1, 0, 1)).Unit;
                    local crossVector = cross(objectSpacePoint, Vector3new(0, 1, 1));
                    local rightVector = Vector2new(crossVector.X, crossVector.Z);

                    local arrowRadius, arrowSize = esp.settings.arrow.radius, esp.settings.arrow.size;
                    local arrowPosition = screenCenter + Vector2new(objectSpacePoint.X, objectSpacePoint.Z) * arrowRadius;
                    local arrowDirection = (arrowPosition - screenCenter).Unit;

                    local pointA, pointB, pointC = arrowPosition, screenCenter + arrowDirection * (arrowRadius - arrowSize) + rightVector * arrowSize, screenCenter + arrowDirection * (arrowRadius - arrowSize) + -rightVector * arrowSize;

                    v.arrow.Visible = true
                    v.arrow.Filled = esp.settings.arrow.filled;
                    v.arrow.Transparency = esp.settings.arrow.transparency;
                    v.arrow.Color = esp.settings.arrow.color
                    v.arrow.PointA = pointA;
                    v.arrow.PointB = pointB;
                    v.arrow.PointC = pointC;
                else
                    v.arrow.Visible = false
                end
            end
        else
            v.name.Visible = false
            v.boxOutline.Visible = false
            v.box.Visible = false
            v.filledbox.Visible = false
            v.healthBarOutline.Visible = false
            v.healthBar.Visible = false
            v.healthText.Visible = false
            v.distance.Visible = false
            v.viewAngle.Visible = false
            v.cham.Enabled = false
            v.weapon.Visible = false
            v.tracer.Visible = false
            v.arrow.Visible = false
        end
    end
end)

local function DrawLine()
    local l = Drawing.new("Line")
    l.Visible = false
    l.From = Vector2.new(0, 0)
    l.To = Vector2.new(1, 1)
    l.Color = esp.settings.skeleton.color
    l.Thickness = 1
    l.Transparency = 1
    return l
end

local function Skeletonesp(localplayer)
    task.spawn(function()
        repeat wait() until localplayer.Character ~= nil and localplayer.Character:FindFirstChild("Humanoid") ~= nil
        local limbs = {}
        local R15 = (localplayer.Character.Humanoid.RigType == Enum.HumanoidRigType.R15) and true or false
        limbs = {
            -- Spine
            Head_UpperTorso = DrawLine(),
            UpperTorso_LowerTorso = DrawLine(),
            -- Left Arm
            UpperTorso_LeftUpperArm = DrawLine(),
            LeftUpperArm_LeftLowerArm = DrawLine(),
            LeftLowerArm_LeftHand = DrawLine(),
            -- Right Arm
            UpperTorso_RightUpperArm = DrawLine(),
            RightUpperArm_RightLowerArm = DrawLine(),
            RightLowerArm_RightHand = DrawLine(),
            -- Left Leg
            LowerTorso_LeftUpperLeg = DrawLine(),
            LeftUpperLeg_LeftLowerLeg = DrawLine(),
            LeftLowerLeg_LeftFoot = DrawLine(),
            -- Right Leg
            LowerTorso_RightUpperLeg = DrawLine(),
            RightUpperLeg_RightLowerLeg = DrawLine(),
            RightLowerLeg_RightFoot = DrawLine(),
        }
        local function Visibility(state)
            for i, v in pairs(limbs) do
                v.Visible = state
            end
        end

        local function Colorize(color)
            for i, v in pairs(limbs) do
                v.Color = color
            end
        end

        local function UpdaterR15()
            local connection
            connection = game:GetService("RunService").RenderStepped:Connect(function()
                if localplayer.Character ~= nil and localplayer.Character:FindFirstChild("Humanoid") ~= nil and localplayer.Character:FindFirstChild("HumanoidRootPart") ~= nil and localplayer.Character.Humanoid.Health > 0 then
                    local HUM, vis = camera:WorldToViewportPoint(localplayer.Character.HumanoidRootPart.Position)
                    if vis and esp.settings.skeleton.enabled and esp.enabled then
                        -- Head
                        local H = camera:WorldToViewportPoint(localplayer.Character.Head.Position)
                        if limbs.Head_UpperTorso.From ~= Vector2.new(H.X, H.Y) then
                            --Spine
                            local UT = camera:WorldToViewportPoint(localplayer.Character.UpperTorso.Position)
                            local LT = camera:WorldToViewportPoint(localplayer.Character.LowerTorso.Position)
                            -- Left Arm
                            local LUA = camera:WorldToViewportPoint(localplayer.Character.LeftUpperArm.Position)
                            local LLA = camera:WorldToViewportPoint(localplayer.Character.LeftLowerArm.Position)
                            local LH = camera:WorldToViewportPoint(localplayer.Character.LeftHand.Position)
                            -- Right Arm
                            local RUA = camera:WorldToViewportPoint(localplayer.Character.RightUpperArm.Position)
                            local RLA = camera:WorldToViewportPoint(localplayer.Character.RightLowerArm.Position)
                            local RH = camera:WorldToViewportPoint(localplayer.Character.RightHand.Position)
                            -- Left leg
                            local LUL = camera:WorldToViewportPoint(localplayer.Character.LeftUpperLeg.Position)
                            local LLL = camera:WorldToViewportPoint(localplayer.Character.LeftLowerLeg.Position)
                            local LF = camera:WorldToViewportPoint(localplayer.Character.LeftFoot.Position)
                            -- Right leg
                            local RUL = camera:WorldToViewportPoint(localplayer.Character.RightUpperLeg.Position)
                            local RLL = camera:WorldToViewportPoint(localplayer.Character.RightLowerLeg.Position)
                            local RF = camera:WorldToViewportPoint(localplayer.Character.RightFoot.Position)

                            --Head
                            limbs.Head_UpperTorso.From = Vector2.new(H.X, H.Y)
                            limbs.Head_UpperTorso.To = Vector2.new(UT.X, UT.Y)

                            --Spine
                            limbs.UpperTorso_LowerTorso.From = Vector2.new(UT.X, UT.Y)
                            limbs.UpperTorso_LowerTorso.To = Vector2.new(LT.X, LT.Y)

                            -- Left Arm
                            limbs.UpperTorso_LeftUpperArm.From = Vector2.new(UT.X, UT.Y)
                            limbs.UpperTorso_LeftUpperArm.To = Vector2.new(LUA.X, LUA.Y)

                            limbs.LeftUpperArm_LeftLowerArm.From = Vector2.new(LUA.X, LUA.Y)
                            limbs.LeftUpperArm_LeftLowerArm.To = Vector2.new(LLA.X, LLA.Y)

                            limbs.LeftLowerArm_LeftHand.From = Vector2.new(LLA.X, LLA.Y)
                            limbs.LeftLowerArm_LeftHand.To = Vector2.new(LH.X, LH.Y)

                            -- Right Arm
                            limbs.UpperTorso_RightUpperArm.From = Vector2.new(UT.X, UT.Y)
                            limbs.UpperTorso_RightUpperArm.To = Vector2.new(RUA.X, RUA.Y)

                            limbs.RightUpperArm_RightLowerArm.From = Vector2.new(RUA.X, RUA.Y)
                            limbs.RightUpperArm_RightLowerArm.To = Vector2.new(RLA.X, RLA.Y)

                            limbs.RightLowerArm_RightHand.From = Vector2.new(RLA.X, RLA.Y)
                            limbs.RightLowerArm_RightHand.To = Vector2.new(RH.X, RH.Y)

                            -- Left Leg
                            limbs.LowerTorso_LeftUpperLeg.From = Vector2.new(LT.X, LT.Y)
                            limbs.LowerTorso_LeftUpperLeg.To = Vector2.new(LUL.X, LUL.Y)

                            limbs.LeftUpperLeg_LeftLowerLeg.From = Vector2.new(LUL.X, LUL.Y)
                            limbs.LeftUpperLeg_LeftLowerLeg.To = Vector2.new(LLL.X, LLL.Y)

                            limbs.LeftLowerLeg_LeftFoot.From = Vector2.new(LLL.X, LLL.Y)
                            limbs.LeftLowerLeg_LeftFoot.To = Vector2.new(LF.X, LF.Y)

                            -- Right Leg
                            limbs.LowerTorso_RightUpperLeg.From = Vector2.new(LT.X, LT.Y)
                            limbs.LowerTorso_RightUpperLeg.To = Vector2.new(RUL.X, RUL.Y)

                            limbs.RightUpperLeg_RightLowerLeg.From = Vector2.new(RUL.X, RUL.Y)
                            limbs.RightUpperLeg_RightLowerLeg.To = Vector2.new(RLL.X, RLL.Y)

                            limbs.RightLowerLeg_RightFoot.From = Vector2.new(RLL.X, RLL.Y)
                            limbs.RightLowerLeg_RightFoot.To = Vector2.new(RF.X, RF.Y)
                        end

                        Colorize(esp.settings.skeleton.color)

                        if limbs.Head_UpperTorso.Visible ~= true then
                            Visibility(true)
                        end
                    else 
                        if limbs.Head_UpperTorso.Visible ~= false then
                            Visibility(false)
                        end
                    end
                else 
                    if limbs.Head_UpperTorso.Visible ~= false then
                        Visibility(false)
                    end
                    if game.Players:FindFirstChild(localplayer.Name) == nil then 
                        for i, v in pairs(limbs) do
                            v:Remove()
                        end
                        connection:Disconnect()
                    end
                end
            end)
        end
        coroutine.wrap(UpdaterR15)()
    end)
end

task.spawn(function()
repeat wait() until game:GetService("Workspace"):FindFirstChild("AiZones") and workspace:FindFirstChild("DroppedItems")

--Bot Esp
 function AddBotEsp(Path)
    local BotEsp = Drawing.new("Text")
    BotEsp.Visible = false
    BotEsp.Center = true
    BotEsp.Outline = true
    BotEsp.Font = 3
    BotEsp.Size = 10
    local BotEsp2 = Drawing.new("Text")
    BotEsp2.Visible = false
    BotEsp2.Center = true
    BotEsp2.Outline = true
    BotEsp2.Font = 3
    BotEsp2.Size = 10
    local BotEsp3 = Drawing.new("Text")
    BotEsp3.Visible = false
    BotEsp3.Center = true
    BotEsp3.Outline = true
    BotEsp3.Font = 3
    BotEsp3.Size = 10
    --local chamcham = esp.NewCham({FillColor = esp.customsettings.aichams.color, OutlineColor = Color3.new(0,0,0), FillTransparency = 0, OutlineTransparency = 1})
    local renderstepped
    renderstepped =
        game:GetService("RunService").RenderStepped:Connect(
        function()
            --[[if esp.customsettings.aichams.enabled then
                chamcham.Enabled = true
                if esp.customsettings.aichams.occluded then
                    chamcham.DepthMode = "Occluded"
                else
                    chamcham.DepthMode = "AlwaysOnTop"	
                end
                chamcham.FillColor = esp.customsettings.aichams.fill_color
                chamcham.OutlineColor = esp.customsettings.aichams.outline_color
                chamcham.OutlineTransparency = esp.customsettings.aichams.outline_transparency
                chamcham.FillTransparency = esp.customsettings.aichams.fill_transparency
            else
                chamcham.Enabled = false
            end]]
            if
                Path and (game:GetService("Workspace").AiZones:FindFirstChild(Path.Name, true)) and
                    Path:FindFirstChildOfClass("Humanoid") and
                    Path:FindFirstChildOfClass("Humanoid").Health > 0
             then
                --chamcham.Adornee = Path
                local meshpart = Path:FindFirstChildOfClass("MeshPart")
                if
                    esp.customsettings.ai.enabled and meshpart then
                    BotEsp.Color = esp.customsettings.ai.color
                    BotEsp2.Color = esp.customsettings.aidistance.color
                    BotEsp3.Color = esp.customsettings.aihealth.color
                    BotEsp.Outline = esp.customsettings.ai.outline
                    BotEsp2.Outline = esp.customsettings.ai.outline
                    BotEsp3.Outline = esp.customsettings.ai.outline
                    BotEsp.Size = esp.customsettings.ai.size
                    BotEsp2.Size = esp.customsettings.ai.size
                    BotEsp3.Size = esp.customsettings.ai.size
                    local drop_pos, drop_onscreen =
                        game:GetService("Workspace").CurrentCamera:WorldToViewportPoint(
                        Path:FindFirstChildOfClass("MeshPart").Position
                    )
                    if drop_onscreen then
                        BotEsp.Position = Vector2.new(drop_pos.X, drop_pos.Y)
                        BotEsp2.Position = Vector2.new(drop_pos.X, drop_pos.Y + esp.customsettings.ai.size)
                        BotEsp3.Position = Vector2.new(drop_pos.X, drop_pos.Y - esp.customsettings.ai.size)
                        BotEsp.Text = Path.Name
                        if esp.customsettings.aidistance.enabled then
                            if
                                game.Players.LocalPlayer.Character and
                                    game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                             then
                                BotEsp2.Text =
                                    math.round(
                                    (Path:FindFirstChildOfClass("MeshPart").Position -
                                        game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude / 3
                                ) .. "m"
                                BotEsp2.Visible = true
                            else
                                BotEsp2.Visible = false
                            end
                        else
                            BotEsp2.Visible = false
                        end
                        if esp.customsettings.aihealth.enabled then
                            BotEsp3.Text = tostring(math.round(Path:FindFirstChildOfClass("Humanoid").Health)) .. "%"
                            BotEsp3.Visible = true
                        else
                            BotEsp3.Visible = false
                        end
                        BotEsp.Visible = esp.customsettings.ai.enabled
                    else
                        BotEsp.Visible = false
                        BotEsp2.Visible = false
                        BotEsp3.Visible = false
                    end
                else
                    BotEsp.Visible = false
                    BotEsp2.Visible = false
                    BotEsp3.Visible = false
                end
            else
                BotEsp:Remove()
                BotEsp2:Remove()
                BotEsp3:Remove()
                --chamcham:Destroy()
                renderstepped:Disconnect()
            end
        end
    )
 end

for i,v in pairs(game:GetService("Workspace").AiZones:GetDescendants()) do
    if v:FindFirstChild("Humanoid") then
        AddBotEsp(v)
    end
end

game:GetService("Workspace").AiZones.DescendantAdded:Connect(function(Child)
    wait(1)
    if Child:FindFirstChild("Humanoid") then
        AddBotEsp(Child)
    end
end)

--Corpse Esp
 function AddCorpseESP(Corpse)
    local CorpseEsp = Drawing.new("Text")
    CorpseEsp.Visible = false
    CorpseEsp.Center = true
    CorpseEsp.Outline = true
    CorpseEsp.Font = 3
    CorpseEsp.Size = 10
    local CorpseEsp2 = Drawing.new("Text")
    CorpseEsp2.Visible = false
    CorpseEsp2.Center = true
    CorpseEsp2.Outline = true
    CorpseEsp2.Font = 3
    CorpseEsp2.Size = 10
    --local chamcham = esp.NewCham({FillColor = esp.customsettings.corpsechams.color, OutlineColor = Color3.new(0,0,0), FillTransparency = 0, OutlineTransparency = 1})
    local renderstepped
    renderstepped =
        game:GetService("RunService").RenderStepped:Connect(
        function()
            --[[ if esp.customsettings.corpsechams.enabled then
                chamcham.Enabled = true
                if esp.customsettings.corpsechams.occluded then
                    chamcham.DepthMode = "Occluded"
                else
                    chamcham.DepthMode = "AlwaysOnTop"	
                end
                chamcham.FillColor = esp.customsettings.corpsechams.fill_color
                chamcham.OutlineColor = esp.customsettings.corpsechams.outline_color
                chamcham.OutlineTransparency = esp.customsettings.corpsechams.outline_transparency
                chamcham.FillTransparency = esp.customsettings.corpsechams.fill_transparency
            else
                chamcham.Enabled = false
            end]]
            if
                Corpse and workspace.DroppedItems:FindFirstChild(Corpse.Name) and
                    Corpse:FindFirstChildOfClass("Humanoid")
             then
                --chamcham.Adornee = Corpse
                local meshpart = Corpse:FindFirstChildOfClass("MeshPart")
                if
                    esp.customsettings.enabled and esp.customsettings.corpse.enabled and meshpart and
                        (esp.customsettings.maxdist == 0 or
                            (meshpart.Position - localplayer.Character.HumanoidRootPart.Position).Magnitude <
                                esp.customsettings.maxdist)
                 then
                    CorpseEsp.Color = esp.customsettings.corpse.color
                    CorpseEsp2.Color = esp.customsettings.corpsedistance.color
                    CorpseEsp.Outline = esp.customsettings.corpse.outline
                    CorpseEsp2.Outline = esp.customsettings.corpse.outline
                    CorpseEsp.Size = esp.customsettings.corpse.size
                    CorpseEsp2.Size = esp.customsettings.corpse.size
                    local drop_pos, drop_onscreen =
                        game:GetService("Workspace").CurrentCamera:WorldToViewportPoint(meshpart.Position)
                    if drop_onscreen then
                        CorpseEsp.Position = Vector2.new(drop_pos.X, drop_pos.Y)
                        CorpseEsp2.Position = Vector2.new(drop_pos.X, drop_pos.Y + esp.customsettings.corpse.size)
                        CorpseEsp.Text = Corpse.Name .. "'s " .. "corpse"
                        if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            CorpseEsp2.Text =
                                math.round(
                                (meshpart.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude /
                                    3
                            ) .. "m"
                        end
                        
                        if esp.customsettings.corpsedistance.enabled then
                            CorpseEsp2.Visible = true
                        else
                            CorpseEsp2.Visible = false
                        end
                        CorpseEsp.Visible = esp.customsettings.corpse.enabled
                    else
                        CorpseEsp.Visible = false
                        CorpseEsp2.Visible = false
                    end
                else
                    CorpseEsp.Visible = false
                    CorpseEsp2.Visible = false
                end
            else
                CorpseEsp.Visible = false
                CorpseEsp:Remove()
                CorpseEsp2:Remove()
                --chamcham:Destroy()
                renderstepped:Disconnect()
            end
        end
    )
 end

for _,v in next, workspace.DroppedItems:GetChildren() do 
    if v:FindFirstChildOfClass("Humanoid") then
        AddCorpseESP(v)
    end
end

workspace.DroppedItems.DescendantAdded:Connect(function(Child)
    wait(1)
    if Child:FindFirstChildOfClass("Humanoid") then
        AddCorpseESP(Child)
    end
end)

--Extract Esp
 function AddExtractEsp(Extract)
    local ExtractEsp = Drawing.new("Text")
    ExtractEsp.Visible = false
    ExtractEsp.Center = true
    ExtractEsp.Outline = true
    ExtractEsp.Font = 3
    ExtractEsp.Size = 10
    local ExtractEsp2 = Drawing.new("Text")
    ExtractEsp2.Visible = false
    ExtractEsp2.Center = true
    ExtractEsp2.Outline = true
    ExtractEsp2.Font = 3
    ExtractEsp2.Size = 10
    local renderstepped
    renderstepped = game:GetService("RunService").RenderStepped:Connect(function()
        if Extract then
            if esp.customsettings.extract.enabled then
                ExtractEsp.Color = esp.customsettings.extract.color
                ExtractEsp2.Color = esp.customsettings.extractdistance.color
                ExtractEsp.Outline = esp.customsettings.extract.outline
                ExtractEsp2.Outline = esp.customsettings.extract.outline
                ExtractEsp.Size = esp.customsettings.extract.size
                ExtractEsp2.Size = esp.customsettings.extract.size
                local Extract_pos, Extract_onscreen = game:GetService("Workspace").CurrentCamera:WorldToViewportPoint(Extract.Position)
                if Extract_onscreen then
                    ExtractEsp.Position = Vector2.new(Extract_pos.X, Extract_pos.Y)
                    ExtractEsp2.Position = Vector2.new(Extract_pos.X, Extract_pos.Y + esp.customsettings.extract.size)
                    ExtractEsp.Text = "exit"
                    if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        ExtractEsp2.Text = math.round((Extract.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude / 3) .. "m"
                    end
                    if esp.customsettings.extractdistance.enabled then
                        ExtractEsp2.Visible = true
                    else
                        ExtractEsp2.Visible = false
                    end
                    ExtractEsp.Visible = true
                else
                    ExtractEsp.Visible = false
                    ExtractEsp2.Visible = false
                end
            else
                ExtractEsp.Visible = false
                ExtractEsp2.Visible = false
            end
        else
            ExtractEsp:Remove()
            ExtractEsp2:Remove()
            renderstepped:Disconnect()
        end
    end)
 end
if workspace.NoCollision:FindFirstChild("ExitLocations") then
    for _,v in next, workspace.NoCollision.ExitLocations:GetChildren() do 
        AddExtractEsp(v)
    end

    workspace.NoCollision.ExitLocations.DescendantAdded:Connect(function(Child)
        wait(1)
        AddExtractEsp(Child)
    end)
end

end)

for _,v in ipairs(players:GetPlayers()) do
    if v ~= localplayer then
        esp.NewPlayer(v)
        Skeletonesp(v)
    end
end

players.ChildAdded:Connect(function(v)
    esp.NewPlayer(v)
    Skeletonesp(v)
end)

players.PlayerRemoving:Connect(function(v)
    for i2,v2 in pairs(esp.players[v]) do
        pcall(function()
            v2:Remove()
            v2:Destroy()
        end)
    end

    esp.players[v] = nil
end)

getgenv().esp = esp

-- our local default settings
local settings = {
    activetarget = nil,
    aimbot = true,
    vischeck = false,
    aimdistance = 150,
    aimBindHeld = false,

    fovcircle = false,
    fovcolor = Color3.fromRGB(255, 255, 255),
    fovradius = 20,
    dynamicfov = true,

    recoilslider = 100,
    dropslider = 100,
    spreadslider = 100,
    bulletspeed = 100,

    zoomBindHeld = false,
    zoomFov = 40,
}

-- create our center circle, we update later

local circle = Drawing.new('Circle')
circle.Position = centerofscreen
circle.Thickness = 2

-- how we do player lists of valid data, this is really goofy lol

local playerList = {}
playerList.list = {}

function playerList.insert(v)
    table.insert(playerList.list, v)
end

function playerList.get()
    return playerList.list
end

function playerList.remove(v)
    table.remove(playerList.list, v)
end

function playerList.clear()
    for i = 1, #playerList.list do
        table.remove(playerList.list, i)
    end
end

function addPlayer(player) 
    local vector, onScreen = camera:WorldToViewportPoint(player.Character.Head.Position)
    playerList.insert({
        Name = player.Name, 
        Head = player.Character.Head,
        HeadPosition = player.Character.Head.Position,
        Distance = math.ceil((game.Players.LocalPlayer.Character:FindFirstChild("Head").Position - player.Character.Head.Position).Magnitude / 3.571),
        HeadPoint = vector,
        isOnScreen = onScreen,
        isTeam = esp.TeamCheck(player)
    })
end

-- runs every fucking nanosecond, somehow doesnt lag though

function updatePlayers()
    if not(Library.Unloaded) then
        for _, player in ipairs(players:GetPlayers()) do
            if player ~= game:GetService("Players").LocalPlayer and player.Character and player.Character:FindFirstChild("Head") then
                addPlayer(player)
            end
        end
    end
end

-- just gets table length, theres no lua stuff to do this automatically which is dumb asf
function GetTableLng(tbl)
    local getN = 0
    for n in pairs(tbl) do 
        getN = getN + 1 
    end
    return getN
end

-- tabs, i leave the ui one completely alone because everything breaks if u mess with it

local Tabs = {
    Main = Window:AddTab('Main'),
    Visuals = Window:AddTab('Visuals'),
    Misc = Window:AddTab('Misc'),

    ['UI Settings'] = Window:AddTab('UI Settings'),
}

local AimbotBox = Tabs.Main:AddLeftGroupbox('Aimbot')
local GunModBox = Tabs.Main:AddRightGroupbox('Gun Mods')

local ESPBox = Tabs.Visuals:AddLeftGroupbox('ESP')
local AIESPBox = Tabs.Visuals:AddRightGroupbox('AI')
local OtherVisBox = Tabs.Visuals:AddLeftGroupbox('Other')


local MiscBox = Tabs.Misc:AddLeftGroupbox('Misc')

-- left side (aimbot related)

AimbotBox:AddToggle('memoryaimbot', {
    Text = 'Memory Aimbot',
    Default = settings.aimbot,

    Callback = function(Value)
        settings.aimbot = Value
    end
})

AimbotBox:AddToggle('vischeck', {
    Text = 'Visible Check',
    Default = settings.vischeck,

    Callback = function(Value)
        settings.vischeck = Value
    end
})

AimbotBox:AddLabel('Aimbot Bind'):AddKeyPicker('aimbind', {
    Default = 'MB2',
    SyncToggleState = false,
    Mode = 'Hold',

    Text = 'Memory Aim',
    NoUI = false,

    Callback = function(Value)
        
    end
})

AimbotBox:AddSlider('aimdistance', {
    Text = 'Max Distance',
    Default = settings.aimdistance,
    Min = 0,
    Max = 1000,
    Rounding = 1,
    Compact = false,

    Callback = function(Value)
        settings.aimdistance = Value
    end
})

AimbotBox:AddToggle('fovcircle', {
    Text = 'FOV Circle',
    Default = settings.fovcircle,

    Callback = function(Value)
        settings.fovcircle = Value
    end
})

AimbotBox:AddLabel('FOV Color'):AddColorPicker('fovcolor', {
    Default = settings.fovcolor,
    Title = 'FOV',
    Transparency = 0,

    Callback = function(Value)
        settings.fovcolor = Value
    end
})

AimbotBox:AddSlider('fovradius', {
    Text = 'FOV Radius',
    Default = settings.fovradius,
    Min = 0,
    Max = 300,
    Rounding = 1,
    Compact = false,

    Callback = function(Value)
        settings.fovradius = Value
    end
})

AimbotBox:AddToggle('dynamicfov', {
    Text = 'Dynamic FOV',
    Default = settings.dynamicfov,

    Callback = function(Value)
        settings.dynamicfov = Value
    end
})

-- right side (gun mods)
GunModBox:AddSlider('recoilslider', {
    Text = 'Recoil Percentage',
    Default = settings.recoilslider,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Compact = false,

    Callback = function(Value)
        settings.recoilsliders = Value
        for i,v in pairs(game.ReplicatedStorage.AmmoTypes:GetChildren()) do
            local realAmmo = realAmmoTypes:FindFirstChild(v.Name)
            if realAmmo then
                local percentage = Value/100
                if v:GetAttribute("RecoilStrength") then
                    local recoilamt = realAmmo:GetAttribute("RecoilStrength") * percentage
                    v:SetAttribute("RecoilStrength", recoilamt)
                end
            end
        end
    end
})

GunModBox:AddSlider('dropslider', {
    Text = 'Drop Percentage',
    Default = settings.dropslider,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Compact = false,

    Callback = function(Value)
        settings.dropslider = Value
        for i,v in pairs(game.ReplicatedStorage.AmmoTypes:GetChildren()) do
            local realAmmo = realAmmoTypes:FindFirstChild(v.Name)
            if realAmmo then
                local percentage = Value/100
                -- drop
                if v:GetAttribute("ProjectileDrop") then
                    local dropamt = realAmmo:GetAttribute("ProjectileDrop") * percentage
                    v:SetAttribute("ProjectileDrop", dropamt)
                end
                -- drag, kinda like dropping but going random direc idfk
                if v:GetAttribute("Drag") then
                    local dragamt = realAmmo:GetAttribute("Drag") * percentage
                    v:SetAttribute("Drag", dragamt)
                end
            end
        end
    end
})

GunModBox:AddSlider('spreadslider', {
    Text = 'Spread Percentage',
    Default = settings.spreadslider,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Compact = false,

    Callback = function(Value)
        settings.spreadslider = Value
        for i,v in pairs(game.ReplicatedStorage.AmmoTypes:GetChildren()) do
            local realAmmo = realAmmoTypes:FindFirstChild(v.Name)
            if realAmmo then
                local percentage = Value/100
                if v:GetAttribute("AccuracyDeviation") then
                    local recoilamt = realAmmo:GetAttribute("AccuracyDeviation") * percentage
                    v:SetAttribute("AccuracyDeviation", recoilamt)
                end
            end
        end
    end
})

GunModBox:AddSlider('bulletslider', {
    Text = 'Bullet Speed Percentage',
    Default = settings.bulletspeed,
    Min = 0,
    Max = 300,
    Rounding = 1,
    Compact = false,

    Callback = function(Value)
        settings.bulletspeed = Value
        for i,v in pairs(game.ReplicatedStorage.AmmoTypes:GetChildren()) do
            local realAmmo = realAmmoTypes:FindFirstChild(v.Name)
            if realAmmo then
                local percentage = Value/100
                if v:GetAttribute("MuzzleVelocity") then
                    local recoilamt = realAmmo:GetAttribute("MuzzleVelocity") * percentage
                    v:SetAttribute("MuzzleVelocity", recoilamt)
                end
            end
        end
    end
})

ESPBox:AddToggle('esptoggle', {
    Text = 'ESP Mainswitch',
    Default = esp.enabled,

    Callback = function(Value)
        esp.enabled = Value
    end
})

ESPBox:AddToggle('espnames', {
    Text = 'Name ESP',
    Default = esp.settings.name.enabled,

    Callback = function(Value)
        esp.settings.name.enabled = Value
    end
})

ESPBox:AddLabel('Name Color'):AddColorPicker('namecolor', {
    Default = esp.settings.name.color,
    Title = 'Names',

    Callback = function(Value)
        esp.settings.name.color = Value
    end
})

ESPBox:AddToggle('healthbar', {
    Text = 'Health Bar',
    Default = esp.settings.healthbar.enabled,

    Callback = function(Value)
        esp.settings.healthbar.enabled = Value
    end
})

ESPBox:AddToggle('healthtext', {
    Text = 'Health Text',
    Default = esp.settings.healthtext.enabled,

    Callback = function(Value)
        esp.settings.healthtext.enabled = Value
    end
})

ESPBox:AddLabel('Health Text Color'):AddColorPicker('healthcolor', {
    Default = esp.settings.healthtext.color,
    Title = 'Health',

    Callback = function(Value)
        esp.settings.healthtext.color = Value
    end
})

ESPBox:AddToggle('distancetext', {
    Text = 'Distance Text',
    Default = esp.settings.distance.enabled,

    Callback = function(Value)
        esp.settings.distance.enabled = Value
    end
})

ESPBox:AddLabel('Distance Text Color'):AddColorPicker('distancecolor', {
    Default = esp.settings.distance.color,
    Title = 'Distance',

    Callback = function(Value)
        esp.settings.distance.color = Value 
    end
})

ESPBox:AddToggle('espchams', {
    Text = 'Player Chams',
    Default = esp.settings_chams.enabled,

    Callback = function(Value)
        esp.settings_chams.enabled = Value
    end
})

ESPBox:AddToggle('chamautocolor', {
    Text = 'Cham Autocolor',
    Default = esp.settings_chams.autocolor,

    Callback = function(Value)
        esp.settings_chams.autocolor = Value
    end
})

ESPBox:AddLabel('Cham Vis Color'):AddColorPicker('chamviscolor', {
    Default = esp.settings_chams.fill_color,
    Title = 'Names',

    Callback = function(Value)
        esp.settings_chams.fill_color = Value
        esp.settings_chams.visible_Color = Value
    end
})

ESPBox:AddLabel('Cham Invis color'):AddColorPicker('chaminviscolor', {
    Default = esp.settings_chams.invisible_Color,
    Title = 'Names',

    Callback = function(Value)
        esp.settings_chams.invisible_Color = Value
    end
})

AIESPBox:AddToggle('aiespmaintoggle', {
    Text = 'AI ESP Mainswitch',
    Default = esp.customsettings.enabled,

    Callback = function(Value)
        esp.customsettings.enabled = Value
    end
})

AIESPBox:AddToggle('ainameesp', {
    Text = 'Name ESP',
    Default = esp.customsettings.ai.enabled,

    Callback = function(Value)
        esp.customsettings.ai.enabled = Value
    end
})

AIESPBox:AddLabel('Name Color'):AddColorPicker('ainamecolor', {
    Default = esp.customsettings.ai.color,
    Title = 'Names',

    Callback = function(Value)
        esp.customsettings.ai.color = Value
    end
})

AIESPBox:AddToggle('aihealthesp', {
    Text = 'Health Text',
    Default = esp.customsettings.aihealth.enabled,

    Callback = function(Value)
        esp.customsettings.aihealth.enabled = Value
    end
})

AIESPBox:AddLabel('Health Color'):AddColorPicker('aihealthcolor', {
    Default = esp.customsettings.aihealth.color,
    Title = 'Health',

    Callback = function(Value)
        esp.customsettings.aihealth.color = Value
    end
})

AIESPBox:AddToggle('aidistanceesp', {
    Text = 'Distance Text',
    Default = esp.customsettings.aidistance.enabled,

    Callback = function(Value)
        esp.customsettings.aidistance.enabled = Value
    end
})

AIESPBox:AddLabel('Distance Color'):AddColorPicker('aidistancecolor', {
    Default = esp.customsettings.aidistance.color,
    Title = 'Distance',

    Callback = function(Value)
        esp.customsettings.aidistance.color = Value
    end
})

AIESPBox:AddToggle('aivischams', {
    Text = 'Chams',
    Default = esp.customsettings.aichams.enabled,

    Callback = function(Value)
        esp.customsettings.aichams.enabled = Value
    end
})

AIESPBox:AddLabel('Chams Color'):AddColorPicker('aichamscolor', {
    Default = esp.customsettings.aichams.fill_color,
    Title = 'Chams',

    Callback = function(Value)
        esp.customsettings.aichams.fill_color = Value
    end
})

OtherVisBox:AddToggle('extractesp', {
    Text = 'Extract ESP',
    Default = esp.customsettings.extract.enabled,

    Callback = function(Value)
        esp.customsettings.extract.enabled = Value
    end
})

OtherVisBox:AddToggle('extractdistanceesp', {
    Text = 'Extract Distance',
    Default = esp.customsettings.extractdistance.enabled,

    Callback = function(Value)
        esp.customsettings.extractdistance.enabled = Value
    end
})

OtherVisBox:AddLabel('Extract Color'):AddColorPicker('extractespcolor', {
    Default = esp.customsettings.extract.color,
    Title = 'Extract',

    Callback = function(Value)
        esp.customsettings.extract.color = Value
        esp.customsettings.extractdistance.color = Value
    end
})

OtherVisBox:AddToggle('corpseesp', {
    Text = 'Corpse ESP',
    Default = esp.customsettings.corpse.enabled,

    Callback = function(Value)
        esp.customsettings.corpse.enabled = Value
    end
})

OtherVisBox:AddToggle('corpsedistanceesp', {
    Text = 'Corpse Distance',
    Default = esp.customsettings.corpsedistance.enabled,

    Callback = function(Value)
        esp.customsettings.corpsedistance.enabled = Value
    end
})

OtherVisBox:AddLabel('Corpse Color'):AddColorPicker('corpsecolor', {
    Default = esp.customsettings.corpse.color,
    Title = 'Corpse',

    Callback = function(Value)
        esp.customsettings.corpse.color = Value
        esp.customsettings.corpsedistance.color = Value
    end
})

OtherVisBox:AddToggle('corpsechamesp', {
    Text = 'Corpse Chams',
    Default = esp.customsettings.corpsechams.enabled,

    Callback = function(Value)
        esp.customsettings.corpsechams.enabled = Value
    end
})

OtherVisBox:AddLabel('Corpse Cham Color'):AddColorPicker('corpsechamcolor', {
    Default = esp.customsettings.corpsechams.fill_color,
    Title = 'Corpse',

    Callback = function(Value)
        esp.customsettings.corpsechams.fill_color = Value
    end
})


MiscBox:AddLabel('Zoom Bind'):AddKeyPicker('zoombind', {
    Default = 'Comma',
    SyncToggleState = false,
    Mode = 'Hold',

    Text = 'Zoom',
    NoUI = false,

    Callback = function(Value)
        
    end
})

MiscBox:AddSlider('zoomvalue', {
    Text = 'Zoom FOV',
    Default = settings.zoomFov,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Compact = false,

    Callback = function(Value)
        settings.zoomFov = Value
    end
})

MiscBox:AddSlider('defaultfov', {
    Text = 'Default FOV',
    Default = defaultFov,
    Min = 0,
    Max = 120,
    Rounding = 1,
    Compact = false,

    Callback = function(Value)
        defaultFov = Value
    end
})

-- OUR LOOP  YIPPEE

function round(x)
  return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end


task.spawn(function()
    while true do
        -- skull
        wait(0.000001)

        -- update cirlce
        circle.Visible = settings.fovcircle
        circle.Color = settings.fovcolor

        local rad = settings.fovradius
        if settings.zoomBindHeld and settings.dynamicfov then
            rad = rad * round(defaultFov/settings.zoomFov)
        end
        circle.Radius = rad

        -- check bind and update 
        local aimBind = Options.aimbind:GetState()
        settings.aimBindHeld = aimBind

        local zoomBind = Options.zoombind:GetState()
        settings.zoomBindHeld = zoomBind
    
        -- update players list
        updatePlayers()

        -- get our players list in here
        local players = playerList.get()

        local localsettings = game.ReplicatedStorage.Players:FindFirstChild(localplayer.Name).Settings
        if localsettings then
            if settings.zoomBindHeld then
                localsettings.GameplaySettings:SetAttribute("DefaultFOV", settings.zoomFov)
            else
                localsettings.GameplaySettings:SetAttribute("DefaultFOV", defaultFov)
            end
        end

        -- memory aimbot, its just here cuz idc and has to run a lot
        -- all done if enabled but not aiming until bind held so we can calc and not calc the second the button gets held, less tweaky
        if settings.aimbot then
            local possibletargets = {}
            for i = 1, #players do
                if players[i] then
                    if players[i].Distance <= settings.aimdistance then
                        if players[i].isOnScreen and ((Vector2.new(players[i].HeadPoint.X, players[i].HeadPoint.Y) - camera.ViewportSize/2).Magnitude) <= circle.Radius then
                            table.insert(possibletargets, players[i])
                            local lowest = possibletargets[1].Distance
                            if GetTableLng(possibletargets) > 1 then
                                for o = 2, #possibletargets do
                                    if possibletargets[o].Distance < lowest then
                                        lowest = possibletargets[o].Distance
                                        settings.activetarget = possibletargets[o]
                                    end
                                    table.remove(possibletargets, o)
                                end
                            else
                                settings.activetarget = players[i]
                            end
                            
                            if settings.activetarget and settings.aimBindHeld and not(settings.activetarget.isTeam) then
                                if (settings.vischeck and esp.WallCheck(settings.activetarget.Head)) or not(settings.vischeck) then
                                    workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, settings.activetarget.HeadPosition)
                                end
                            end
                        else
                            settings.activetarget = nil
                        end
                    end
                end
            end
        end

        -- clear list
        playerList.clear()
        if Library.Unloaded then break end
    end
end)

-- watermark
local watermark = false

local FrameTimer = tick()
local FrameCounter = 0;
local FPS = 60;

local WatermarkConnection = game:GetService('RunService').RenderStepped:Connect(function()
    if watermark then
        FrameCounter = FrameCounter + 1;

        if (tick() - FrameTimer) >= 1 then
            FPS = FrameCounter;
            FrameTimer = tick();
            FrameCounter = 0;
        end;

        Library:SetWatermark(('freakhack | %s fps | %s ms'):format(
            math.floor(FPS),
            math.floor(game:GetService('Stats').Network.ServerStatsItem['Data Ping']:GetValue())
        ));
    end
end);

-- keybinds
Library.KeybindFrame.Visible = true; -- todo: add a function for this

-- unload func, sometimes breaks lmao
Library:OnUnload(function()
    WatermarkConnection:Disconnect()

    circle:Remove()

    playerList.clear()

    for i,v in pairs(game.ReplicatedStorage.AmmoTypes:GetChildren()) do
        local realAmmo = realAmmoTypes:FindFirstChild(v.Name)
        if realAmmo then
            if v:GetAttribute("MuzzleVelocity") then
                v:SetAttribute("MuzzleVelocity", realAmmo:GetAttribute("MuzzleVelocity"))
            end
            if v:GetAttribute("AccuracyDeviation") then
                v:SetAttribute("AccuracyDeviation", realAmmo:GetAttribute("AccuracyDeviation"))
            end
            if v:GetAttribute("RecoilStrength") then
                v:SetAttribute("RecoilStrength", realAmmo:GetAttribute("RecoilStrength"))
            end
            if v:GetAttribute("ProjectileDrop") then
                v:SetAttribute("ProjectileDrop", realAmmo:GetAttribute("ProjectileDrop"))
            end
            if v:GetAttribute("Drag") then
                v:SetAttribute("Drag", realAmmo:GetAttribute("Drag"))
            end
        end
    end

    print('Unloaded!')
    Library.Unloaded = true
end)

-- all menu tab under this

-- UI Settings
local MenuGroup = Tabs['UI Settings']:AddLeftGroupbox('Menu')

-- I set NoUI so it does not show up in the keybinds menu
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' })

Library.ToggleKeybind = Options.MenuKeybind -- Allows you to have a custom keybind for the menu

-- Addons:
-- SaveManager (Allows you to have a configuration system)
-- ThemeManager (Allows you to have a menu theme system)

-- Hand the library over to our managers
ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)

-- Ignore keys that are used by ThemeManager.
-- (we dont want configs to save themes, do we?)
SaveManager:IgnoreThemeSettings()

-- Adds our MenuKeybind to the ignore list
-- (do you want each config to have a different menu key? probably not.)
SaveManager:SetIgnoreIndexes({ 'MenuKeybind' })

-- use case for doing it this way:
-- a script hub could have themes in a global folder
-- and game configs in a separate folder per game
ThemeManager:SetFolder('freakhack')
SaveManager:SetFolder('freakhack/pd')

-- Builds our config menu on the right side of our tab
SaveManager:BuildConfigSection(Tabs['UI Settings'])

-- Builds our theme menu (with plenty of built in themes) on the left side
-- NOTE: you can also call ThemeManager:ApplyToGroupbox to add it to a specific groupbox
ThemeManager:ApplyToTab(Tabs['UI Settings'])

-- You can use the SaveManager:LoadAutoloadConfig() to load a config
-- which has been marked to be one that auto loads!
SaveManager:LoadAutoloadConfig()
