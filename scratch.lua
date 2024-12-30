local repo = 'https://raw.githubusercontent.com/violin-suzutsuki/LinoriaLib/main/'
local esp = loadstring(game:HttpGet("https://raw.githubusercontent.com/gayscallop/reupload/refs/heads/main/esp", true))()

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

esp.customsettings.enabled = true
esp.customsettings.maxdist = 1000
esp.customsettings.ai.enabled = true
esp.customsettings.aichams = true
esp.customsettings.extract.enabled = true

-- player list basically
local players = game:GetService("Players")

-- localplayer
local localplayer = game.Players.LocalPlayer
local mouse = game.Players.LocalPlayer:GetMouse()

-- games workspace
local workspace = game:GetService("Workspace")

-- our camera
local camera = workspace.CurrentCamera

-- direct center
local centerofscreen = Vector2.new(camera.ViewportSize.X / 2, camera.ViewportSize.Y / 2)

-- copy of ammos so we can restore
local realAmmoTypes = game.ReplicatedStorage:FindFirstChild("realAmmoTypes") or game.ReplicatedStorage:FindFirstChild("AmmoTypes") and game.ReplicatedStorage:FindFirstChild("AmmoTypes"):Clone(); 
if realAmmoTypes then 
    realAmmoTypes.Name = "realAmmoTypes" 
end

-- copy of player so we can restore
local defaultFov = 0
local plr = game.ReplicatedStorage.Players:FindFirstChild(localplayer.Name)
for i,v in plr:GetDescendants() do
    if v:FindFirstChild("GameplaySettings") then
        defaultFov = v.GameplaySettings:GetAttribute("DefaultFOV")
    end
end

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

        if settings.zoomBindHeld then
            local plr = game.ReplicatedStorage.Players:FindFirstChild(localplayer.Name)
            for i,v in plr:GetDescendants() do
                if v:FindFirstChild("GameplaySettings") then
                    v.GameplaySettings:SetAttribute("DefaultFOV", settings.zoomFov)
                end
            end
        else
            local plr = game.ReplicatedStorage.Players:FindFirstChild(localplayer.Name)
            for i,v in plr:GetDescendants() do
                if v:FindFirstChild("GameplaySettings") then
                    v.GameplaySettings:SetAttribute("DefaultFOV", defaultFov)
                end
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

    getgenv().esp.enabled = false
    getgenv().esp.settings_chams.enabled = false

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
