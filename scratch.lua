if not LPH_OBFUSCATED and not LPH_JIT_ULTRA then
	LPH_JIT_ULTRA = function(f) return f end
	LPH_JIT_MAX = function(f) return f end
	LPH_JIT = function(f) return f end
	LPH_ENCSTR = function(s) return s end
	LPH_STRENC = function(s) return s end
	LPH_CRASH = function() while true do end return end
end

--loadstring(game:HttpGet("https://gist.githubusercontent.com/gayscallop/46536d96f39ea8cb6b9f5bd59ac8c379/raw/6f20cf70014cffd5aba6d6366436ced11fbca4f0/main.lua"))()

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

-- player list basically
local players = game:GetService("Players")

-- localplayer
local localplayer = game.Players.LocalPlayer

-- games workspace
local workspace = game:GetService("Workspace")

local camera = workspace.CurrentCamera

local emptyCFrame = CFrame.new();
local pointToObjectSpace = emptyCFrame.PointToObjectSpace

--[Optimisation Variables]

local Drawingnew = Drawing.new
local Color3fromRGB = Color3.fromRGB
local Vector3new = Vector3.new
local Vector2new = Vector2.new
local mathfloor = math.floor
local cross = Vector3new().Cross;

-- direct center
local centerofscreen = Vector2new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

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

--[Setup Table]

-- our local default settings
local settings = {
    activetarget = nil,
    aimbot = true,
    prediction = true,
    vischeck = false,
    aimdistance = 150,

    fovcircle = false,
    fovcolor = Color3.fromRGB(255, 255, 255),
    fovradius = 20,
    dynamicfov = true,

    doubletap = false,
    recoilslider = 100,
    dropslider = 100,
    dragslider = 100,
    spreadslider = 100,

    zoomBindHeld = false,
    zoomFov = 40,
}

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
        healthbar = {enabled = false, size = 3, outline = true},
        healthtext = {enabled = false, outline = true, color = Color3fromRGB(255, 255, 255)},
        distance = {enabled = false, outline = true, color = Color3fromRGB(255, 255, 255)},
        viewangle = {enabled = false, size = 6, color = Color3fromRGB(255, 255, 255)},
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

-- create our center circle, we update later

local circle = Drawingnew('Circle')
circle.Position = centerofscreen
circle.Thickness = 2

local targetname = Drawingnew('Text')
targetname.Center = true
targetname.Outline = true

local targetvisible = Drawingnew('Text')
targetvisible.Center = true
targetvisible.Outline = true

local targethealth = Drawingnew('Text')
targethealth.Center = true
targethealth.Outline = true

-- how we do player lists of valid data, this is really goofy lol

local playerList = {}
playerList.list = {}

function playerList.insert(v)
    table.insert(playerList.list, v)
end

function playerList.get()
    if GetTableLng(playerList.list) > 0 then
        return playerList.list
    else
        return nil
    end
end

function playerList.remove(v)
    table.remove(playerList.list, v)
end

function playerList.clear()
    for i = 1, #playerList.list do
        table.remove(playerList.list, i)
    end
end

function IsAlive(Player)
	if Player and Player.Character and Player.Character:FindFirstChild("Humanoid") and Player.Character:FindFirstChild("HumanoidRootPart") and Player.Character.Humanoid.Health > 0 then
		return true
	end

	return false
end

function addPlayer(player) 
    if IsAlive(player) then
        local headvector, headonscreen = camera:WorldToViewportPoint(player.Character.Head.Position)
        playerList.insert({
            Player = player,
            Name = player.Name, 
            Health = player.Character.Humanoid.Health,
            MaxHealth = player.Character.Humanoid.MaxHealth,
            Head = player.Character.Head,
            HeadPosition = player.Character.Head.Position,
            HRP = player.Character.HumanoidRootPart,
            HRPPosition = player.Character.HumanoidRootPart.Position,
            Distance = math.ceil((game.Players.LocalPlayer.Character:FindFirstChild("Head").Position - player.Character.Head.Position).Magnitude / 3.571),
            HeadPoint = headvector,
            HeadonScreen = headonscreen,
            isTeam = esp.TeamCheck(player),
            Visible = esp.WallCheck(player.Character.Head)
        })
    end
end

function updatePlayers()
    if not(Library.Unloaded) then
        for _, player in ipairs(players:GetPlayers()) do
            if IsAlive(player) then
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

esp.WallCheck = function(Part, IgnoreList)
	local RayParams = RaycastParams.new()
	RayParams.FilterType = Enum.RaycastFilterType.Exclude;
	RayParams.FilterDescendantsInstances = (IsAlive(localplayer) and {IgnoreList, localplayer.Character, camera} or {IgnoreList, camera})
	RayParams.IgnoreWater = true

	local Direction = (Part.Position - camera.CFrame.Position).Unit * 5000
	local ray = workspace:Raycast(camera.CFrame.Position, Direction, RayParams)

	if ray and ray.Instance and ray.Instance:IsDescendantOf(Part.Parent) then
		return true
	end

	return false
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
        healthBarOutline = esp.NewDrawing("Line", {Color = Color3fromRGB(0, 0, 0), Thickness = 3}),
        healthBar = esp.NewDrawing("Line", {Color = Color3fromRGB(255, 255, 255), Thickness = 1}),
        healthText = esp.NewDrawing("Text", {Color = Color3fromRGB(255, 255, 255), Outline = true, Center = true, Size = 13, Font = 10}),
        distance = esp.NewDrawing("Text", {Color = Color3fromRGB(255, 255, 255), Outline = true, Center = true, Size = 13, Font = 10}),
        viewAngle = esp.NewDrawing("Line", {Color = Color3fromRGB(255, 255, 255), Thickness = 1}),
        cham = esp.NewCham({FillColor = esp.settings_chams.fill_color, OutlineColor = esp.settings_chams.outline_color, FillTransparency = esp.settings_chams.fill_transparency, OutlineTransparency = esp.settings_chams.outline_transparency}),
        arrow = esp.NewDrawing("Triangle", {Color = Color3fromRGB(255, 255, 255), Thickness = 1})
    }
end

local ESPLoop = game:GetService("RunService").RenderStepped:Connect(function()
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
                v.cham.OutlineColor = esp.settings_chams.autocolor and esp.settings_chams.autocolor_outline and (esp.WallCheck(head) or esp.WallCheck(hrp)) and esp.settings_chams.visible_Color or esp.settings_chams.autocolor and esp.settings_chams.autocolor_outline and not (esp.WallCheck(head) or esp.WallCheck(HRP)) and esp.settings_chams.invisible_Color or esp.settings_chams.outline_color
                v.cham.FillColor = esp.settings_chams.autocolor and (esp.WallCheck(head) or esp.WallCheck(hrp)) and esp.settings_chams.visible_Color or esp.settings_chams.autocolor and not (esp.WallCheck(head) or esp.WallCheck(hrp)) and esp.settings_chams.invisible_Color or esp.settings_chams.fill_color
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
                    v.distance.Text = mathfloor((hrp.Position - localplayer.Character.HumanoidRootPart.Position).Magnitude / 3.571) .. "m"
                    v.distance.Color = esp.settings.distance.color
                    BottomOffset = BottomOffset + 15

                    v.distance.Font = esp.font
                    v.distance.Size = esp.fontsize

                    v.distance.Visible = true
                else
                    v.distance.Visible = false
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

                if esp.teamcheck then
                    if esp.TeamCheck(i) then
                        v.name.Visible = esp.settings.name.enabled
                        v.healthBar.Visible = esp.settings.healthbar.enabled
                        v.healthText.Visible = esp.settings.healthtext.enabled
                        v.distance.Visible = esp.settings.distance.enabled
                        v.viewAngle.Visible = esp.settings.viewangle.enabled
                        v.arrow.Visible = esp.settings.arrow.enabled
                    else
                        v.name.Visible = false
                        v.healthBarOutline.Visible = false
                        v.healthBar.Visible = false
                        v.healthText.Visible = false
                        v.distance.Visible = false
                        v.viewAngle.Visible = false
                        v.arrow.Visible = false
                    end
                end
            else
                v.name.Visible = false
                v.healthBarOutline.Visible = false
                v.healthBar.Visible = false
                v.healthText.Visible = false
                v.distance.Visible = false
                v.viewAngle.Visible = false
                v.arrow.Visible = false
            end
        else
            v.name.Visible = false
            v.healthBarOutline.Visible = false
            v.healthBar.Visible = false
            v.healthText.Visible = false
            v.distance.Visible = false
            v.viewAngle.Visible = false
            v.cham.Enabled = false
            v.arrow.Visible = false
        end
    end
end)

task.spawn(function()
repeat wait() until game:GetService("Workspace"):FindFirstChild("AiZones") and workspace:FindFirstChild("DroppedItems")

--Bot Esp
 function AddBotEsp(Path)
    local BotEsp = Drawingnew("Text")
    BotEsp.Visible = false
    BotEsp.Center = true
    BotEsp.Outline = true
    BotEsp.Font = 3
    BotEsp.Size = 10
    local BotEsp2 = Drawingnew("Text")
    BotEsp2.Visible = false
    BotEsp2.Center = true
    BotEsp2.Outline = true
    BotEsp2.Font = 3
    BotEsp2.Size = 10
    local BotEsp3 = Drawingnew("Text")
    BotEsp3.Visible = false
    BotEsp3.Center = true
    BotEsp3.Outline = true
    BotEsp3.Font = 3
    BotEsp3.Size = 10
    local renderstepped
    renderstepped = game:GetService("RunService").RenderStepped:Connect(function()
        if Path and (game:GetService("Workspace").AiZones:FindFirstChild(Path.Name, true)) and Path:FindFirstChildOfClass("Humanoid") and Path:FindFirstChildOfClass("Humanoid").Health > 0 then
            local meshpart = Path:FindFirstChildOfClass("MeshPart")
            if esp.customsettings.ai.enabled and meshpart then
                BotEsp.Color = esp.customsettings.ai.color
                BotEsp2.Color = esp.customsettings.aidistance.color
                BotEsp3.Color = esp.customsettings.aihealth.color
                BotEsp.Outline = esp.customsettings.ai.outline
                BotEsp2.Outline = esp.customsettings.ai.outline
                BotEsp3.Outline = esp.customsettings.ai.outline
                BotEsp.Size = esp.customsettings.ai.size
                BotEsp2.Size = esp.customsettings.ai.size
                BotEsp3.Size = esp.customsettings.ai.size
                local drop_pos, drop_onscreen = game:GetService("Workspace").CurrentCamera:WorldToViewportPoint(Path:FindFirstChildOfClass("MeshPart").Position)
                if drop_onscreen then
                    BotEsp.Position = Vector2new(drop_pos.X, drop_pos.Y)
                    BotEsp2.Position = Vector2new(drop_pos.X, drop_pos.Y + esp.customsettings.ai.size)
                    BotEsp3.Position = Vector2new(drop_pos.X, drop_pos.Y - esp.customsettings.ai.size)
                    BotEsp.Text = Path.Name
                    if esp.customsettings.aidistance.enabled then
                        if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            BotEsp2.Text = math.round((Path:FindFirstChildOfClass("MeshPart").Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude / 3.571) .. "m"
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
            renderstepped:Disconnect()
        end

        if Library.Unloaded then 
            BotEsp:Remove()
            BotEsp2:Remove()
            BotEsp3:Remove()
            renderstepped:Disconnect() 
        end
    end)
 end

for i,v in pairs(game:GetService("Workspace").AiZones:GetDescendants()) do
    if v:FindFirstChild("Humanoid") then
        AddBotEsp(v)
    end
end

game:GetService("Workspace").AiZones.DescendantAdded:Connect(function(Child)
    if Child:FindFirstChild("Humanoid") then
        AddBotEsp(Child)
    end
end)

--Corpse Esp
 function AddCorpseESP(Corpse)
    local CorpseEsp = Drawingnew("Text")
    CorpseEsp.Visible = false
    CorpseEsp.Center = true
    CorpseEsp.Outline = true
    CorpseEsp.Font = 3
    CorpseEsp.Size = 10
    local CorpseEsp2 = Drawingnew("Text")
    CorpseEsp2.Visible = false
    CorpseEsp2.Center = true
    CorpseEsp2.Outline = true
    CorpseEsp2.Font = 3
    CorpseEsp2.Size = 10
    local renderstepped
    renderstepped = game:GetService("RunService").RenderStepped:Connect(function()
        if Corpse and workspace.DroppedItems:FindFirstChild(Corpse.Name) and Corpse:FindFirstChildOfClass("Humanoid") then
            local meshpart = Corpse:FindFirstChildOfClass("MeshPart")
            if esp.customsettings.enabled and esp.customsettings.corpse.enabled and meshpart and (esp.customsettings.maxdist == 0 or (meshpart.Position - localplayer.Character.HumanoidRootPart.Position).Magnitude < esp.customsettings.maxdist) then
                CorpseEsp.Color = esp.customsettings.corpse.color
                CorpseEsp2.Color = esp.customsettings.corpsedistance.color
                CorpseEsp.Outline = esp.customsettings.corpse.outline
                CorpseEsp2.Outline = esp.customsettings.corpse.outline
                CorpseEsp.Size = esp.customsettings.corpse.size
                CorpseEsp2.Size = esp.customsettings.corpse.size
                local drop_pos, drop_onscreen = game:GetService("Workspace").CurrentCamera:WorldToViewportPoint(meshpart.Position)
                if drop_onscreen then
                    CorpseEsp.Position = Vector2new(drop_pos.X, drop_pos.Y)
                    CorpseEsp2.Position = Vector2new(drop_pos.X, drop_pos.Y + esp.customsettings.corpse.size)
                    CorpseEsp.Text = Corpse.Name .. "'s " .. "corpse"
                    if esp.customsettings.corpsedistance.enabled then
                        if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then 
                            CorpseEsp2.Text = math.round((meshpart.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude / 3.571) .. "m"
                        end
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
            CorpseEsp:Remove()
            CorpseEsp2:Remove()
            renderstepped:Disconnect()
        end

        if Library.Unloaded then 
            CorpseEsp:Remove()
            CorpseEsp2:Remove()
            renderstepped:Disconnect() 
        end
    end)
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
    local ExtractEsp = Drawingnew("Text")
    ExtractEsp.Visible = false
    ExtractEsp.Center = true
    ExtractEsp.Outline = true
    ExtractEsp.Font = 3
    ExtractEsp.Size = 10
    local ExtractEsp2 = Drawingnew("Text")
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
                local Extract_pos, Extract_onscreen = camera:WorldToViewportPoint(Extract.Position)
                if Extract_onscreen then
                    ExtractEsp.Position = Vector2new(Extract_pos.X, Extract_pos.Y)
                    ExtractEsp2.Position = Vector2new(Extract_pos.X, Extract_pos.Y + esp.customsettings.extract.size)
                    ExtractEsp.Text = "exit"
                    if esp.customsettings.extractdistance.enabled then
                        if game.Players.LocalPlayer.Character and game.Players.LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                            ExtractEsp2.Text = math.round((Extract.Position - game.Players.LocalPlayer.Character.HumanoidRootPart.Position).Magnitude / 3.571) .. "m"
                        end
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

        if Library.Unloaded then 
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
end

end)

for _,v in ipairs(players:GetPlayers()) do
    if v~= localplayer then
        esp.NewPlayer(v)
    end
end

players.ChildAdded:Connect(function(v)
    esp.NewPlayer(v)
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

AimbotBox:AddToggle('aimbot', {
    Text = 'Silent Aim',
    Default = settings.aimbot,

    Callback = function(Value)
        settings.aimbot = Value
    end
})

AimbotBox:AddToggle('prediction', {
    Text = 'Prediction',
    Default = settings.prediction,

    Callback = function(Value)
        settings.prediction = Value
    end
})

AimbotBox:AddToggle('vischeck', {
    Text = 'Visible Check',
    Default = settings.vischeck,

    Callback = function(Value)
        settings.vischeck = Value
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
GunModBox:AddToggle('doubletap', {
    Text = 'Double Tap',
    Default = settings.doubletap,

    Callback = function(Value)
        settings.doubletap = Value
    end
})

GunModBox:AddSlider('recoilslider', {
    Text = 'Recoil Percentage',
    Default = settings.recoilslider,
    Min = 0,
    Max = 200,
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
    Max = 200,
    Rounding = 1,
    Compact = false,

    Callback = function(Value)
        settings.dropslider = Value
        for i,v in pairs(game.ReplicatedStorage.AmmoTypes:GetChildren()) do
            local realAmmo = realAmmoTypes:FindFirstChild(v.Name)
            if realAmmo then
                local percentage = Value/100
                if v:GetAttribute("ProjectileDrop") then
                    local dropamt = realAmmo:GetAttribute("ProjectileDrop") * percentage
                    v:SetAttribute("ProjectileDrop", dropamt)
                end
            end
        end
    end
})

GunModBox:AddSlider('dragslider', {
    Text = 'Drag Percentage',
    Default = settings.dragslider,
    Min = 0,
    Max = 200,
    Rounding = 1,
    Compact = false,

    Callback = function(Value)
        settings.dragslider = Value
        for i,v in pairs(game.ReplicatedStorage.AmmoTypes:GetChildren()) do
            local realAmmo = realAmmoTypes:FindFirstChild(v.Name)
            if realAmmo then
                local percentage = Value/100
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
    Max = 200,
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
}):AddColorPicker('namecolor', {
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
}):AddColorPicker('healthcolor', {
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
}):AddColorPicker('distancecolor', {
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

ESPBox:AddToggle('occludedchams', {
    Text = 'Occluded Chams',
    Default = esp.settings_chams.occluded,

    Callback = function(Value)
        esp.settings_chams.occluded = Value
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
}):AddColorPicker('ainamecolor', {
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
}):AddColorPicker('aihealthcolor', {
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
}):AddColorPicker('aidistancecolor', {
    Default = esp.customsettings.aidistance.color,
    Title = 'Distance',

    Callback = function(Value)
        esp.customsettings.aidistance.color = Value
    end
})

OtherVisBox:AddToggle('extractesp', {
    Text = 'Extract ESP',
    Default = esp.customsettings.extract.enabled,

    Callback = function(Value)
        esp.customsettings.extract.enabled = Value
    end
}):AddColorPicker('extractespcolor', {
    Default = esp.customsettings.extract.color,
    Title = 'Extract',

    Callback = function(Value)
        esp.customsettings.extract.color = Value
        esp.customsettings.extractdistance.color = Value
    end
})

OtherVisBox:AddToggle('extractdistanceesp', {
    Text = 'Extract Distance',
    Default = esp.customsettings.extractdistance.enabled,

    Callback = function(Value)
        esp.customsettings.extractdistance.enabled = Value
    end
})

OtherVisBox:AddToggle('corpseesp', {
    Text = 'Corpse ESP',
    Default = esp.customsettings.corpse.enabled,

    Callback = function(Value)
        esp.customsettings.corpse.enabled = Value
    end
}):AddColorPicker('corpsecolor', {
    Default = esp.customsettings.corpse.color,
    Title = 'Corpse',

    Callback = function(Value)
        esp.customsettings.corpse.color = Value
        esp.customsettings.corpsedistance.color = Value
    end
})

OtherVisBox:AddToggle('corpsedistanceesp', {
    Text = 'Corpse Distance',
    Default = esp.customsettings.corpsedistance.enabled,

    Callback = function(Value)
        esp.customsettings.corpsedistance.enabled = Value
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

function getTarget()
    local players = playerList.get()

    local testSubject = nil

    local possibletargets = {}

    if players ~= nil then
        for i = 1, #players do
            if players[i] and not(players[i].isTeam) and players[i].Name ~= localplayer.Name then
                if players[i].Distance <= settings.aimdistance then
                    if (players[i].HeadonScreen and ((Vector2new(players[i].HeadPoint.X, players[i].HeadPoint.Y) - camera.ViewportSize/2).Magnitude) <= circle.Radius) then
                        table.insert(possibletargets, players[i])
                        local lowest = possibletargets[1].Distance
                        if GetTableLng(possibletargets) > 1 then
                            for o = 2, #possibletargets do
                                if possibletargets[o].Distance < lowest then
                                    lowest = possibletargets[o].Distance
                                    testSubject = possibletargets[o]
                                end
                            end
                        else
                            testSubject = possibletargets[1]
                        end
                    end
                end
            end
        end
    end
				
    if testSubject then
        settings.activetarget = testSubject
    end

    for p = 1, #possibletargets do
        table.remove(possibletargets, p)
    end

    return settings.activetarget
end

function round(x)
  return x>=0 and math.floor(x+0.5) or math.ceil(x-0.5)
end

local mainloop = nil
mainloop = game:GetService("RunService").Heartbeat:Connect(function()
    playerList.clear()
    settings.activetarget = nil
    updatePlayers()

    -- get target even if not visible, but also have a vischeck in the display info, win win
    local targ = getTarget()
    if targ then
        local vis = targ.Visible

        if not(vis) then
            vis = false
        end

        targetname.Position = Vector2new(centerofscreen.X, centerofscreen.Y+10)
        targetname.Visible = true
        targetname.Color = settings.fovcolor
        targetname.Text = "Target: " .. targ.Name

        targethealth.Position = Vector2new(centerofscreen.X, centerofscreen.Y+25)
        targethealth.Visible = true
        targethealth.Color = settings.fovcolor
        targethealth.Text = math.round(targ.Health) .. "/" .. targ.MaxHealth

        targetvisible.Position = Vector2new(centerofscreen.X, centerofscreen.Y+40)
        targetvisible.Visible = true
        targetvisible.Color = settings.fovcolor
        targetvisible.Text = "Visible: " .. tostring(vis)
    else
        targetname.Visible = false
        targethealth.Visible = false
        targetvisible.Visible = false
    end

    -- update cirlce
    circle.Visible = settings.fovcircle
    circle.Color = settings.fovcolor

    local rad = settings.fovradius
    if settings.zoomBindHeld and settings.dynamicfov then
        rad = rad * round(defaultFov/settings.zoomFov)
    end
    circle.Radius = rad

    local zoomBind = Options.zoombind:GetState()
    settings.zoomBindHeld = zoomBind

    local localsettings = game.ReplicatedStorage.Players:FindFirstChild(localplayer.Name).Settings
    if localsettings and localplayer then
        if settings.zoomBindHeld then
            localsettings.GameplaySettings:SetAttribute("DefaultFOV", settings.zoomFov)
        else
            localsettings.GameplaySettings:SetAttribute("DefaultFOV", defaultFov)
        end
    end
    if Library.Unloaded then mainloop:Disconnect() end
end)

function getWeaponAttribute(Attribute)
	local Value
	local CurrentWeapon = game:GetService("ReplicatedStorage").Players[localplayer.Name].Status.GameplayVariables.EquippedTool.Value
	local InventoryWeapon = game:GetService("ReplicatedStorage").Players[localplayer.Name].Inventory:FindFirstChild(tostring(CurrentWeapon))
	if InventoryWeapon then
		local Magazine = InventoryWeapon.Attachments:FindFirstChild("Magazine") and InventoryWeapon.Attachments:FindFirstChild("Magazine"):FindFirstChildOfClass("StringValue") and InventoryWeapon.Attachments:FindFirstChild("Magazine"):FindFirstChildOfClass("StringValue"):FindFirstChild("ItemProperties").LoadedAmmo or InventoryWeapon.ItemProperties:FindFirstChild("LoadedAmmo")
		if Magazine then
			local BulletType = Magazine:FindFirstChild("1")
			if BulletType then
				Value = game.ReplicatedStorage.AmmoTypes[BulletType:GetAttribute("AmmoType")]:GetAttribute(Attribute)
			end
		end
	end
		
	return Value
end

function movementPrediction(Origin, Destination, DestinationVelocity, ProjectileSpeed)
    local Distance = (Destination - Origin).Magnitude
    local TimeToHit = (Distance / ProjectileSpeed)
    local Predicted = Destination + DestinationVelocity * TimeToHit
    local Delta = (Predicted - Origin).Magnitude / ProjectileSpeed
    
    ProjectileSpeed = ProjectileSpeed - 0.013 * ProjectileSpeed ^ 2 * TimeToHit ^ 2
    TimeToHit += (Delta / ProjectileSpeed);

    local Actual = Destination + DestinationVelocity * TimeToHit
    return Actual
end

LPH_JIT_ULTRA(function()
    local hook = nil
    hook = hookfunction(require(game.ReplicatedStorage.Modules.FPS.Bullet).CreateBullet, function(...)
        local args = {...}

        local target = getTarget()

        if args[5] and target and settings.aimbot then

            local vis = target.Visible

            local destination = target.HeadPosition

            if settings.prediction then
                destination = movementPrediction(args[5].CFrame.Position, target.HeadPosition, target.Head.Velocity, getWeaponAttribute("MuzzleVelocity"))
            end

            if (settings.vischeck and vis) or not(settings.vischeck) then
                args[5] = {CFrame = CFrame.new(args[5].CFrame.Position, destination)}
            end
        end

        if settings.doubletap then
            if args[9] then
                args[9] = 0
            end
            hook(table.unpack(args))
        end

        return hook(table.unpack(args))
    end)
end)()

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

-- unload func, sometimes breaks lmao
Library:OnUnload(function()
    WatermarkConnection:Disconnect()
    ESPLoop:Disconnect()
    ESPLoop = nil
    
    for i,v in pairs(esp.players) do
        for i2, v2 in pairs(v) do
            if v2 == "cham" then
                v2:Destroy()
            else
                v2:Remove()
            end
        end
    end

    table.clear(esp)
    esp = nil

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
MenuGroup:AddButton('Dex Explorer', function() loadstring(game:HttpGet("https://raw.githubusercontent.com/infyiff/backup/main/dex.lua"))() end)
MenuGroup:AddButton('Unload', function() Library:Unload() end)
MenuGroup:AddButton('Rejoin', function() game:GetService('TeleportService'):TeleportToPlaceInstance(game.PlaceId, game.JobId) end)
MenuGroup:AddLabel('Menu bind'):AddKeyPicker('MenuKeybind', { Default = 'End', NoUI = true, Text = 'Menu keybind' })

Library.ToggleKeybind = Options.MenuKeybind -- Allows you to have a custom keybind for the menu

MenuGroup:AddToggle('keybindlist', {
    Text = 'Keybinds',
    Default = Library.KeybindFrame.Visible,

    Callback = function(Value)
        Library.KeybindFrame.Visible = Value
    end
})

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
