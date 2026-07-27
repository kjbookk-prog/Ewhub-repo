--//========================================================--
--// EWEHUB UNIVERSAL LOADER
--// Version : 1.0.0
--// Author  : EWEHUB
--//========================================================--

repeat task.wait() until game:IsLoaded()

--========================================================--
-- SERVICES
--========================================================--

local Players            = game:GetService("Players")
local TweenService       = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")
local HttpService        = game:GetService("HttpService")
local CoreGui            = game:GetService("CoreGui")
local RunService         = game:GetService("RunService")
local Lighting           = game:GetService("Lighting")

local LocalPlayer = Players.LocalPlayer

--========================================================--
-- CONFIG
--========================================================--

local Config = {

    Name = "EWEHUB Universal Loader",

    Version = "1.0.0",

    Debug = true,

    FadeTime = .25,

    ScaleTime = .35,

    ProgressSpeed = .45,

    ResultDelay = 1.75,

    UnsupportedDelay = 2,

    DestroyDelay = .15,

    UISize = Vector2.new(285,145),

    CornerRadius = UDim.new(0,14),

    StrokeThickness = 1,

    GlowTransparency = .35,

    RegistryURL = "",

    DefaultScript = "",

    AllowRemoteRegistry = false,

    EnableLogger = true,

    DisplayOrder = 999999,

}

--========================================================--
-- THEME
--========================================================--

local Theme = {

    Background = Color3.fromRGB(17,17,17),

    Surface = Color3.fromRGB(24,24,24),

    Border = Color3.fromRGB(40,40,40),

    Accent = Color3.fromRGB(0,255,150),

    Success = Color3.fromRGB(0,255,120),

    Error = Color3.fromRGB(255,70,70),

    Warning = Color3.fromRGB(255,185,0),

    Text = Color3.fromRGB(255,255,255),

    SubText = Color3.fromRGB(170,170,170),

    Shadow = Color3.new(),

}

--========================================================--
-- LOGGER
--========================================================--

local Logger = {}

local function printLog(prefix,...)

    if not Config.EnableLogger then
        return
    end

    print(
        ("[%s] %s")
        :format(Config.Name,prefix),
        ...
    )

end

function Logger:Info(...)
    printLog("INFO",...)
end

function Logger:Success(...)
    printLog("SUCCESS",...)
end

function Logger:Warn(...)
    warn(
        ("[%s] WARN")
        :format(Config.Name),
        ...
    )
end

function Logger:Error(...)
    warn(
        ("[%s] ERROR")
        :format(Config.Name),
        ...
    )
end

--========================================================--
-- MAID
--========================================================--

local Maid = {}

Maid.__index = Maid

function Maid.new()

    return setmetatable({

        Tasks = {}

    },Maid)

end

function Maid:Give(Task)

    table.insert(self.Tasks,Task)

    return Task

end

function Maid:Cleanup()

    for _,Task in ipairs(self.Tasks) do

        pcall(function()

            if typeof(Task) == "RBXScriptConnection" then

                Task:Disconnect()

            elseif typeof(Task) == "Instance" then

                Task:Destroy()

            elseif type(Task) == "function" then

                Task()

            end

        end)

    end

    table.clear(self.Tasks)

end

local Cleaner = Maid.new()

--========================================================--
-- UTILITIES
--========================================================--

local Utility = {}

function Utility:Tween(Object,Info,Properties)

    local Tween = TweenService:Create(

        Object,

        Info,

        Properties

    )

    Tween:Play()

    return Tween

end

function Utility:SafeCall(Func,...)

    local Success,Result = pcall(Func,...)

    if not Success then

        Logger:Error(Result)

    end

    return Success,Result

end

function Utility:Create(Class,Properties)

    local Object = Instance.new(Class)

    for Property,Value in pairs(Properties) do

        Object[Property] = Value
    end

    return Object

end

function Utility:FormatNumber(Number)

    local Left,Num,Right = tostring(Number):match("^([^%d]*%d)(%d*)(.-)$")

    return Left..(Num:reverse():gsub("(%d%d%d)","%1,"):reverse())..Right

end

Logger:Success("Core Initialized.")
--========================================================--
-- LOADER UI
--========================================================--

local LoaderUI = {}

LoaderUI.Gui = nil
LoaderUI.Main = nil

LoaderUI.Status = nil
LoaderUI.Detail = nil
LoaderUI.Progress = nil
LoaderUI.Icon = nil

function LoaderUI:Create()

    if self.Gui then
        self.Gui:Destroy()
    end

    local Gui = Utility:Create("ScreenGui",{
        Name = "EWEHUB_Loader",
        IgnoreGuiInset = true,
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = Config.DisplayOrder,
        Parent = CoreGui
    })

    self.Gui = Gui

    --------------------
    -- SCALE
    --------------------

    local Scale = Utility:Create("UIScale",{
        Scale = .85,
        Parent = Gui
    })

    --------------------
    -- MAIN
    --------------------

    local Main = Utility:Create("Frame",{

        AnchorPoint = Vector2.new(.5,.5),

        Position = UDim2.fromScale(.5,.5),

        Size = UDim2.fromOffset(
            Config.UISize.X,
            Config.UISize.Y
        ),

        BackgroundColor3 = Theme.Background,

        BackgroundTransparency = 1,

        Parent = Gui

    })

    self.Main = Main

    Utility:Create("UICorner",{

        CornerRadius = Config.CornerRadius,

        Parent = Main

    })

    Utility:Create("UIStroke",{

        Color = Theme.Border,

        Thickness = Config.StrokeThickness,

        Transparency = .4,

        Parent = Main

    })

    --------------------
    -- SHADOW
    --------------------

    local Shadow = Utility:Create("ImageLabel",{

        AnchorPoint = Vector2.new(.5,.5),

        Position = UDim2.fromScale(.5,.5),

        Size = UDim2.new(1,30,1,30),

        BackgroundTransparency = 1,

        Image = "rbxassetid://1316045217",

        ImageTransparency = .75,

        ScaleType = Enum.ScaleType.Slice,

        SliceCenter = Rect.new(10,10,118,118),

        ZIndex = 0,

        Parent = Main

    })

    --------------------
    -- TITLE
    --------------------

    local Title = Utility:Create("TextLabel",{

        BackgroundTransparency = 1,

        Position = UDim2.fromOffset(15,10),

        Size = UDim2.new(1,-30,0,20),

        Font = Enum.Font.GothamBold,

        Text = Config.Name,

        TextColor3 = Theme.Text,

        TextSize = 16,

        TextXAlignment = Enum.TextXAlignment.Left,

        Parent = Main

    })

    --------------------
    -- STATUS
    --------------------

    local Status = Utility:Create("TextLabel",{

        BackgroundTransparency = 1,

        Position = UDim2.fromOffset(15,38),

        Size = UDim2.new(1,-30,0,18),

        Font = Enum.Font.Gotham,

        Text = "Initializing...",

        TextColor3 = Theme.SubText,

        TextSize = 13,

        TextXAlignment = Enum.TextXAlignment.Left,

        Parent = Main

    })

    self.Status = Status

    --------------------
    -- DETAIL
    --------------------

    local Detail = Utility:Create("TextLabel",{

        BackgroundTransparency = 1,

        Position = UDim2.fromOffset(15,62),

        Size = UDim2.new(1,-30,0,38),

        Font = Enum.Font.Gotham,

        Text = "Universe : -\nPlace : -",

        TextColor3 = Theme.SubText,

        TextSize = 12,

        TextWrapped = true,

        TextXAlignment = Enum.TextXAlignment.Left,

        TextYAlignment = Enum.TextYAlignment.Top,

        Parent = Main

    })

    self.Detail = Detail

    --------------------
    -- BAR
    --------------------

    local Bar = Utility:Create("Frame",{

        Position = UDim2.fromOffset(15,113),

        Size = UDim2.new(1,-30,0,8),

        BackgroundColor3 = Theme.Surface,

        Parent = Main

    })

    Utility:Create("UICorner",{

        CornerRadius = UDim.new(1,0),

        Parent = Bar

    })

    --------------------
    -- PROGRESS
    --------------------

    local Progress = Utility:Create("Frame",{

        Size = UDim2.fromScale(0,1),

        BackgroundColor3 = Theme.Accent,

        Parent = Bar

    })

    Utility:Create("UICorner",{

        CornerRadius = UDim.new(1,0),

        Parent = Progress

    })

    self.Progress = Progress

    --------------------
    -- ICON
    --------------------

    local Icon = Utility:Create("TextLabel",{

        BackgroundTransparency = 1,

        AnchorPoint = Vector2.new(1,0),

        Position = UDim2.new(1,-15,0,10),

        Size = UDim2.fromOffset(24,24),

        Font = Enum.Font.GothamBold,

        Text = "●",

        TextColor3 = Theme.Accent,

        TextScaled = true,

        Parent = Main

    })

    self.Icon = Icon

    --------------------
    -- OPEN STATE
    --------------------

    Main.BackgroundTransparency = 1

    Status.TextTransparency = 1
    Detail.TextTransparency = 1
    Title.TextTransparency = 1
    Icon.TextTransparency = 1

end
